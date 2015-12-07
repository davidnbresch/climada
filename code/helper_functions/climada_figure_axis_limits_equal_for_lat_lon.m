function climada_figure_axis_limits_equal_for_lat_lon(ax_limits)
% set axis limits and set equal aspect ratio for maps (based on distance in km)
% MODULE:
%   core/helper_functions
% NAME:
%   climada_figure_axis_limits_equal_for_lat_lon
% PURPOSE:
%   set axis limits and set equal aspect ratio for maps (based on distance in km)
%   so that distance in x- and y-direction correspond to the same distance
%   in km. This is necessary for coordinates in lat/lon as 1° degree in lat
%   and lon are not the same distance in km. E.g. in Switzerland (47°N,
%   8°E) 1° lon are 75km, and 1°lat are 111km.
% CALLING SEQUENCE:
%   climada_figure_axis_limits_equal_for_lat_lon(ax_limits)
% EXAMPLE:
%   climada_figure_axis_limits_equal_for_lat_lon([-89 -90 14 15])
% INPUTS: 
%   ax_limits: an array with 4 elements, specifying x_min, x_max, y_min,
%              y_max
% OUTPUTS:      
%   figure axis limits are set and data aspect ratio set to equal
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150730, init
% Lea Mueller, muellele@gmail.com, 20151106, move to advanced
% Lea Mueller, muellele@gmail.com, 20151106, move to core/helper_functions
%-


global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('ax_limits'    ,'var'),ax_limits     = []; end

if isempty(ax_limits) % get current limits
    fig_axes = gca;
    ax_limits = zeros(1,4);
    ax_limits(1:2) = get(fig_axes, 'xlim');
    ax_limits(3:4) = get(fig_axes, 'ylim');
end


% calculate ratio between 1° lon and 1° lat
x_mean = mean(ax_limits(1:2));
y_mean = mean(ax_limits(3:4));
delta_x = diff(ax_limits(1:2));
x_y_ratio = climada_geo_distance(x_mean, y_mean, x_mean+delta_x, y_mean)...
           /climada_geo_distance(x_mean, y_mean, x_mean        , y_mean+delta_x);

% set axis limits
axis([ax_limits])

% set box aspect ratio
x_ = diff(ax_limits(1:2));
y_ = diff(ax_limits(3:4));
set(gca, 'PlotBoxAspectRatio', [x_ y_*x_y_ratio 1]);

