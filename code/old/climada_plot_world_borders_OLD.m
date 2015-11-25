function climada_plot_world_borders(linewidth, check_country, map_border_file, keep_boundary, country_color)
% world border map country political
% NAME:
%	climada_plot_world_borders
% PURPOSE:
%   plot (world= borders for map in lat/lon
%   
%   Reads the file with border information (.gen or .shp) and plots it
%   (line plot) in existing figure (do not forget hold on before) or create
%   new one.
%
%   The first the a particular (.gen or .shp) file is read, it saves the
%   resulting border struct in a .mat file.
%   
%   If the file is *.gen it stores into a borders structure with:
%   borders.name{i}: name of country i
%   borders.poly{i}.lon{j}: polygon j of country i, longitudes
%   borders.poly{i}.lat{j}: polygon j of country i, latitudes
%   and a struct whole_world_borders with the whole in one (speeds up plot)

%   If the file is *.shp it stores into a borders structure with:
%   borders.poly{i}.lon{j}: polygon j of country i, longitudes
%   borders.poly{i}.lat{j}: polygon j of country i, latitudes
%   and a struct whole_world_borders with the whole in one (speeds up plot)
%   uses this .mat file with the borders info in subsequent calls for
%   speedup

%   uses this .mat file with the borders info in subsequent calls for
%   speedup
%
%   NOTE: in case of troubles, first delete the border .mat file to force
%   its re-generation.
% CALLING SEQUENCE:
%   climada_plot_world_borders(linewidth,map_border_file,keep_boundary);
% EXAMPLE:
%   climada_plot_world_borders
%   climada_plot_world_borders(0.8,'United States (USA)')
%   climada_plot_world_borders(0.8,{'Canada' 'Germany'})
%   climada_plot_world_borders(1,'','ASK') % prompt for border file
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   linewidth: line width of borders, default is 1
%   check_country (for *.gen map file only): name of one or multiple 
%       countries, e.g. 'Germany' or {'Germany' 'Ghana'},that will be gray
%       shaded in the world plot, default is no shading of countries. 
%       Note that 'United States (USA)' is used, hence both 'United States' and 'USA' work.   
%   map_border_file: filename and path to a *.gen or *.shp border file
%       if set to 'ASK', prompt for the .gen broder file
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
%   keep_boundary: if =1, keep axes boundaries, default =0, undefined
%   country_color: the RGB triple for country coloring (e.g. [255 236
%       139]/255). Default set in code (yellow)
%
%   See also climada module naturalearthdata
% OUTPUTS:
%   plot borders as line plot
% RESTRICTIONS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20080926
% Lea Mueller,   20110805
% Martin Heynen, 20120426
% David N. Bresch, david.bresch@gmail.com, 20120430
% Lea Mueller,   20120731
% David N. Bresch, david.bresch@gmail.com, 20141124, 'ASK' added and line 166
% David N. Bresch, david.bresch@gmail.com, 20141125, '.shp' added
% David N. Bresch, david.bresch@gmail.com, 20141125, compatibility with climada_shaperead
%-

% import/setup global variables
global climada_global
if ~climada_init_vars,return;end;

if ~exist('linewidth'       , 'var'), linewidth        = 1; end
if ~exist('check_country'   , 'var'), check_country    = []; end
if ~exist('map_border_file' , 'var'), map_border_file  = []; end
if ~exist('keep_boundary'   , 'var'), keep_boundary    = 0; end
if ~exist('country_color'   , 'var'), country_color    = []; end

% PARAMETERS
%
border_color = [81 81 81]/255; %dark gray
if isempty(country_color),country_color=[255 236 139]/255;end % default yellow

if strcmp(map_border_file,'ASK')
    map_border_file=[climada_global.data_dir filesep 'system' filesep '*.gen'];
    [filename, pathname] = uigetfile(map_border_file, 'Select map border file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        map_border_file=fullfile(pathname,filename);
    end
end

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

[fP,fN,fE]=fileparts(map_border_file);
map_border_file_bin=[fP filesep fN '.mat'];
if climada_check_matfile(map_border_file)
    % load previously stored border data (faster)
    load(map_border_file_bin);
    
elseif strcmp(fE,'.gen')
    
    % read the .gen border file (the first time)
    fid  = fopen(map_border_file);
    
    % read first line
    line = fgetl(fid);
    
    counter_country               = 1;
    borders.name{counter_country} = line;
    first_country                 = line;
    counter_poly                  = 0;
    
    % test that not end of file (keyword END)
    while not(feof(fid))
        
        % read next segment and plot it
        pts = fscanf(fid,'%f, %f',[2 inf]);
        if ~isempty(pts)
            %make struct
            if strcmp(line, 'END')==0
                if strcmp(line,first_country)==0 % was 'Canada', not general
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
    
elseif strcmp(lower(fE),'.shp')
    
    % read the .shp border file (the first time)
    shapes=climada_shaperead(map_border_file);

%     borders.poly=climada_shaperead(map_border_file);
%     
%     if ~strcmp(borders.poly(1).Geometry,'Line')
%         fprintf('WARNING: %s might not contain lines\n',map_border_file);
%     end
%     
%     % store also in one contiguous list (for plot speedup)
%     whole_world_borders.lon = [];
%     whole_world_borders.lat = [];
%     for i=1:length(borders.poly)
%         whole_world_borders.lon = [whole_world_borders.lon; borders.poly(i).X']; % NaN at end already there
%         whole_world_borders.lat = [whole_world_borders.lat; borders.poly(i).Y']; % NaN at end already there
%     end
%     
%     % rename fields for consistency with *.gen
%     borders.poly(i).lon=borders.poly(i).X;
%     borders.poly(i).lat=borders.poly(i).Y;
%     borders.poly=rmfield(borders.poly,'X');
%     borders.poly=rmfield(borders.poly,'Y');
%     
%     save(map_border_file_bin,'borders','whole_world_borders');
    
end % exist(map_border_file_bin,'file')

% plot all in one (speedy)
plot(whole_world_borders.lon, whole_world_borders.lat, 'color', border_color,'LineWidth',linewidth);

hold on

if ~isempty(check_country) && isfield(borders,'name') % shade selected country (only *.gen)
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