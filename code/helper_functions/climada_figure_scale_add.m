function climada_figure_scale_add(fig_axes,left_corner,bottom_corner)
% add figure scale to a figure 
% MODULE:
%   climada core
% NAME:
%   climada_figure_scale_add
% PURPOSE:
%   Add figure scale to a figure, in km
% CALLING SEQUENCE:
%   climada_figure_scale_add(fig_axes,left_corner,bottom_corner)
% EXAMPLE:
%   climada_figure_scale_add
%   climada_figure_scale_add('',1,1) % to position first from left and bottom
%   climada_figure_scale_add('',-1,-1) % to position first from right and top
% INPUTS: 
% OPTIONAL INPUT PARAMETERS:
%   fig_axes: axes of figures 
%   left_corner: position of scale in the figure, default is 1, scale is 
%       positioned on first x-grid from the left, set to -1 to start from the right
%   bottom_corner: position of scale in the figure, default is 1, scale is 
%       positioned on first y-grid from the bottom, set to -1 to start from the top
% OUTPUTS:      
%   scale with km information appears on the current axis
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150724, init
% Lea Mueller, muellele@gmail.com, 20150729, return if x_tick is empty
% Lea Mueller, muellele@gmail.com, 20150729, add option for utm (no conversion to lat/lon)
% Lea Mueller, muellele@gmail.com, 20150729, limit top_corner and right_corner to maximum number of tick elements
% Lea Mueller, muellele@gmail.com, 20151106, move to core
% Lea Mueller, muellele@gmail.com, 20160311, start from the left and bottom
% Lea Mueller, muellele@gmail.com, 20160404, only half of the x-tick length
%-


global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('fig_axes','var'),fig_axes = []; end
if ~exist('left_corner','var'),left_corner = []; end
if ~exist('bottom_corner','var'),bottom_corner = []; end

if isempty(fig_axes),fig_axes = gca; end
if isempty(left_corner),left_corner = 1; end
if isempty(bottom_corner),bottom_corner = 1; end

xticks = get(fig_axes, 'xtick');
yticks = get(fig_axes, 'ytick');
if isempty(xticks), fprintf('Unable to proceed.\n'), return; end

% calculate distance between two ticks
if xticks(1)<=180 
    % in lat/lon
    scale_text = sprintf('%2.1f km', climada_geo_distance(xticks(1),yticks(end),xticks(2),yticks(end))/1000);
else
    % no conversion, probably in utm in m
    scale_text = sprintf('%2.1f km', abs(xticks(1)-xticks(2))/1000);
end
hold on

% start from the right and top
if left_corner<0, left_corner = numel(xticks)+left_corner;end
if bottom_corner<0, bottom_corner = numel(yticks)+bottom_corner+1;end

% correct if too extreme
if left_corner>=numel(xticks), left_corner = numel(xticks)-1;end
if bottom_corner>numel(yticks), bottom_corner = numel(yticks);end

if abs(left_corner)>numel(xticks), left_corner = numel(xticks)-1;end
if abs(bottom_corner)>numel(yticks), bottom_corner = numel(yticks);end

% only half of the xtick length
% finally plot the line and the length in meter
x_coordinate = [xticks(left_corner) mean(xticks(left_corner:left_corner+1))];
plot([xticks(left_corner) mean(xticks(left_corner:left_corner+1))], ones(2,1)*yticks(bottom_corner),'-k','linewidth',3)
text(mean(x_coordinate), yticks(bottom_corner),scale_text,...
    'verticalalignment','bottom','HorizontalAlignment','center','fontsize',14)

% % finally plot the line and the length in meter
% plot(xticks(left_corner:left_corner+1), ones(2,1)*yticks(bottom_corner),'-k','linewidth',3)
% text(mean(xticks(left_corner:left_corner+1)), yticks(bottom_corner),scale_text,...
%     'verticalalignment','bottom','HorizontalAlignment','center','fontsize',14)





