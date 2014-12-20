function climada_plot_world_borders(linewidth,check_country,map_shape_file,keep_boundary,country_color)
% world border map country political
% NAME:
%	climada_plot_world_borders
% PURPOSE:
%   plot (world) borders for map in lat/lon
%   
%   Reads the file with border information (.mat or the original .shp) and
%   plots it (line plot) in existing figure (do not forget hold on before)
%   or create new one. Allows to color (a set of) countries
%
%   The first time the shape file is read, all shapes are read into a
%   second structure for fast plotting, see climada_shaperead(*,1,1).
%   It uses the .mat file written by climada_shaperead with the borders
%   info in subsequent calls for speedup.
%
%   Called from many plot functions, e.g. climada_entity_plot
%   See also: climada_shaperead
% CALLING SEQUENCE:
%   climada_plot_world_borders(linewidth,check_country,map_shape_file,keep_boundary,country_color);
% EXAMPLE:
%   climada_plot_world_borders
%   climada_plot_world_borders(0.8,'United States (USA)')
%   climada_plot_world_borders(0.8,{'Canada' 'Germany'})
%   climada_plot_world_borders(1,'','ASK') % prompt for shape file
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   linewidth: line width of borders, default is 1
%   check_country: name (field in shapes named 'NAME') of one or multiple 
%       countries, e.g. 'Germany' or {'Germany' 'Ghana'},that will be gray
%       shaded in the world plot, default is no shading of countries. 
%       Note that 'United States (USA)' is used, hence both 'United States' and 'USA' work.   
%   map_shape_file: filename and path to a *.shp shapes file
%       if set to 'ASK', prompt for the .shp file. If empty, set to the
%       file as defined in climada_global.map_border_file (default).
%   keep_boundary: to keep the map area (as it looks on input)
%   country_color: a [R G B] triple, see PARAMETERS in code, default is
%       [255 236 139]/255 (yellow). 
%       Currently, it does not color the shape, only draws the boundary.
% OUTPUTS:
%   plot borders as line plot
% RESTRICTIONS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141211, initial, supersedes old version (which read a .gen file)
%-

% import/setup global variables
global climada_global
if ~climada_init_vars,return;end;

if ~exist('linewidth'       , 'var'), linewidth        = 1;  end
if ~exist('check_country'   , 'var'), check_country    = []; end
if ~exist('map_shape_file'  , 'var'), map_shape_file   = ''; end
if ~exist('keep_boundary'   , 'var'), keep_boundary    = 0;  end
if ~exist('country_color'   , 'var'), country_color    = []; end

% PARAMETERS
%
border_color =                           [81  81  81 ]/255;    % dark gray
if isempty(country_color),country_color= [255 236 139]/255;end % default yellow

if strcmp(map_shape_file,'ASK')
    map_shape_file=[climada_global.data_dir filesep 'system' filesep '*.shp'];
    [filename, pathname] = uigetfile(map_shape_file, 'Select shapes file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        map_shape_file=fullfile(pathname,filename);
    end
end

if isempty(map_shape_file),map_shape_file = climada_global.map_border_file;end; % set to default

[fP,fN] = fileparts(map_shape_file);
map_mat_shape_file=[fP filesep fN '.mat'];

% check for the map_shape_file:
if ~(exist(map_shape_file,'file') || exist(map_mat_shape_file,'file'))
    % try to re-create it
    climada_shaperead('SYSTEM_ADMIN0');
end

if ~(exist(map_shape_file,'file') || exist(map_mat_shape_file,'file'))
    % it does definitely not exist
    fprintf('ERROR %s: file with map border shape information not found: %s\n',mfilename,map_shape_file);
    fprintf(' - consider installing climada module country_risk from\n');
    fprintf('   https://github.com/davidnbresch/climada_module_country_risk\n');
    fprintf(' - consider to obtain shape file(s) from\n');
    fprintf('   www.naturalearthdata.com\n');
    return
end

if keep_boundary
    hold on
    XLim = get(get(gcf,'CurrentAxes'),'XLim');
    YLim = get(get(gcf,'CurrentAxes'),'YLim');
end

% read the .shp border file (the first time)
shapes=climada_shaperead(map_shape_file,1,1); % reads .mat subsequent times

for shape_i = 1:length(shapes)
    plot(shapes(shape_i).X,shapes(shape_i).Y, 'color',border_color,'LineWidth',linewidth);
    hold on
end % shape_i

hold on

if ~isempty(check_country) && isfield(shapes,'NAME') % shade selected country (only *.gen)
    for shape_i = 1:length(shapes)
        if any(strcmpi(shapes(shape_i).NAME,check_country)) % shade
            fill(shapes(shape_i).X,shapes(shape_i).Y,country_color,'LineWidth',linewidth);
        end
    end % shape_i
end % ~isempty(check_country)

if keep_boundary
    axis([XLim YLim])
else
    axis([-200 200 -100 100])
end