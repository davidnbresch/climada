function [varagout] = climada_plot_world_borders(linewidth, check_country, map_border_file, keep_boundary, country_color)

% world border map country political
% NAME:
%	climada_plot_world_borders
% PURPOSE:
%   read file with ASCII border information and plot it
%   in existing figure (do not forget hold on before) or create new one
%
%   reads the ASCII file (*.gen) the first time, stores into a borders
%   structure with:
%   borders.name{i}: name of country i
%   borders.poly{i}.lon{j}: polygon j of country i, longitudes
%   borders.poly{i}.lat{j}: polygon j of country i, latitudes
%   uses this .mat file with the borders info in subsequent calls for
%   speedup
%
%   NOTE: in case of troubles, first delete the border .mat file to force
%   its re-generation.
% CALLING SEQUENCE:
%   climada_plot_world_borders(linewidth,map_border_file,keep_boundary);
% EXAMPLE:
%   climada_plot_world_borders(0.8,'United States (USA)')
%   climada_plot_world_borders(0.8,{'Canada' 'Germany'})
%   climada_plot_world_borders
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   linewidth:       line width of borders, default is 1
%   check_country:   name of one or multiple countries, e.g. 'Germany' or
%                    {'Germany' 'Ghana'},that will be gray shaded in the world
%                    plot, default is no shading of countries
%                    Note that 'United States (USA)' is used, hence
%                    both 'United States' and 'USA' work
%   map_border_file: filename and path to a *.gen border file
%
%       the *.gen file has to be of the following format
%       file content                        description (NOT in file)
%       -------------------------------------------------------------------
%       country_name                        Name of the country
%       -70.6,35.2                          longitude,latitude of first polygon point
%       -75.3,23.5                          longitude,latitude of second polygon point
%       -75.3,23.5                          longitude,latitude of next polygon point
%       END                                 marks end of one closed contour
%       -45.45,23-6                         next colsed polygon (eg island)
%       -67.3,23.7
%       END                                 marks end of one closed contour
%       country_name                        next country name
%       -70.6,35.2                          longitude,latitude of first polygon point
%       ...                                 etc...
%       END                                 marks end of one closed contour
%       END                                 last (double) end to close file (optional)
%
%       SPECIAL: if the path contains TC_data\geodata\bathymetry, the code
%       assumes the map_border_file points to the Sandville bathymetry and
%       thus plots the high-res coastline, not using any *.gen file but the
%       Sandville info instead.
%   keep_boundary: if =1, keep axes boundaries, default =0, undefined
% OUTPUTS:
% RESTRICTIONS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20080926
% Lea Mueller,   20110805
% Martin Heynen, 20120426
% David N. Bresch, david.bresch@gmail.com, 20120430
% Lea Mueller,   20120731
%-

% import/setup global variables
global climada_global
if ~climada_init_vars,return;end;

if ~exist('linewidth'       , 'var'), linewidth        = []; end
if ~exist('check_country'   , 'var'), check_country    = []; end
if ~exist('map_border_file' , 'var'), map_border_file  = []; end
if ~exist('keep_boundary'   , 'var'), keep_boundary    = []; end
if ~exist('country_color'   , 'var'), country_color    = []; end
if isempty(linewidth)               , linewidth        = 1 ; end
if isempty(keep_boundary)           , keep_boundary    = 0 ; end
if isempty(country_color)           , country_color    = [255 236 139]/255; end % default yellow

% PARAMETERS
%
% border_color = [255 236 139]/255;
% border_color = [238 224 229 ]/255;
border_color = [81 81 81]/255; %dark gray

if isempty(map_border_file)
    % check for map_border_file
    if isfield(climada_global,'map_border_file')
        map_border_file = climada_global.map_border_file;
    else
        % try default file (has to be in path)
        map_border_file = 'world_50m.gen';
    end
end

% locate the map_border_file:
if ~exist(map_border_file,'file')
    fprintf('ERROR %s: file with map border information not found:\n',mfilename);
    fprintf('   %s\n',map_border_file);
    fprintf('   ask david.bresch@gmail.com for further assistance\n');
    return
end;

if keep_boundary
    hold on
    XLim = get(get(gcf,'CurrentAxes'),'XLim');
    YLim = get(get(gcf,'CurrentAxes'),'YLim');
end

map_border_file_bin=strrep(map_border_file,'.gen','.mat');
if climada_check_matfile(map_border_file)
    % load previously stored border data (faster)
    load(map_border_file_bin);
else
    
    % read border file (the first time)
    fid  = fopen(map_border_file);
    
    % read first line
    line = fgetl(fid);
    
    counter_country               = 1;
    borders.name{counter_country} = line;
    counter_poly                  = 0;
    
    % test that not end of file (keyword END)
    while not(feof(fid))
        
        % read next segment and plot it
        pts = fscanf(fid,'%f, %f',[2 inf]);
        if ~isempty(pts)
            %make struct
            if strcmp(line, 'END')==0
                if strcmp(line, 'Canada')==0
                    counter_country               = counter_country+1;
                    borders.name{counter_country} = line;
                    counter_poly                  = 0;
                end
            end
            % store to structure
            counter_poly                                    = counter_poly+1;
            borders.poly{counter_country}.lon{counter_poly} = pts(1,:);
            borders.poly{counter_country}.lat{counter_poly} = pts(2,:);
        else
            line = fgetl(fid);
        end
    end
    
    fclose(fid);
    
    % store also in one contiguous list (for plot speedup)
    whole_world_borders.lon = [];
    whole_world_borders.lat = [];
    for i=1:length(borders.poly)
        for  j=1:length(borders.poly{i}.lon)
            whole_world_borders.lon = [whole_world_borders.lon; borders.poly{i}.lon{j}'; NaN]; % separate with NaN
            whole_world_borders.lat = [whole_world_borders.lat; borders.poly{i}.lat{j}'; NaN];
        end
    end
    
    % add ISO3 country codes, groupID and region
    txt_file = [climada_global.system_dir filesep 'countryname_ISO3_groupID_region.txt'];
    if exist(txt_file,'file')
        fid = fopen(txt_file);
        C   = textscan(fid, '%f %s %s %s', 'Delimiter','\t','headerLines',1);
        borders.ISO3    = cell (1,length(C{1}));
        borders.groupID = zeros(1,length(C{1}));
        borders.region  = cell (1,length(C{1}));
        
        for c_i = 1:length(borders.name)
            index = strcmp(borders.name{c_i},C{3});
            if ~isempty(C{1}(index))
                borders.ISO3{c_i}    = C{2}{index};
                if ~isnan(C{1}(index))
                    borders.groupID(c_i) = C{1}(index);
                end
                borders.region{c_i} = C{4}{index};
            else
                fprintf('No match found for country %s\n', borders.name{c_i})
            end
        end
    end
    
    save(map_border_file_bin,'borders','whole_world_borders');
end % exist(map_border_file_bin,'file')

% plot all in one (speedy)
plot(whole_world_borders.lon, whole_world_borders.lat, 'color', border_color,'LineWidth',linewidth);

hold on;
if ~isempty(check_country) % shade selected country
    for country_i = 1:length(borders.poly)
        if any(strcmpi(borders.name{country_i},check_country)) %shade
            for poly_j = 1:length(borders.poly{country_i}.lon)
                fill(borders.poly{country_i}.lon{poly_j}, borders.poly{country_i}.lat{poly_j}, country_color,'LineWidth',linewidth);
            end % poly_j
        end
    end % country_i
end % ~isempty(check_country)

if keep_boundary
    axis([XLim YLim])
else
    axis([-200 200 -100 100])
end

if nargout > 0
    varagout{1} = hlines;
end

