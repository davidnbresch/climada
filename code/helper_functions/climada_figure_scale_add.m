function climada_figure_scale_add(fig_axes,top_corner,right_corner)
% add figure scale to a figure 
% MODULE:
%   climada core
% NAME:
%   climada_figure_scale_add
% PURPOSE:
%   Add figure scale to a figure, in km
% CALLING SEQUENCE:
%   climada_figure_scale_add(gca,top_corner,right_corner)
% EXAMPLE:
%   climada_figure_scale_add
% INPUTS: 
% OPTIONAL INPUT PARAMETERS:
%   fig_axes       : axes of figures 
%   top_corner     : position of scale in the figure, default is 2, scale
%                    is positioned on second y-grid from the top
%   right_corner   : position of scale in the figure, default is 1, scale
%                    is positioned on first x-grid from the right
% OUTPUTS:      
%   scale with km information appears on the current axis
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150724, init
% Lea Mueller, muellele@gmail.com, 20150729, return if x_tick is empty
% Lea Mueller, muellele@gmail.com, 20150729, add option for utm (no conversion to lat/lon)
% Lea Mueller, muellele@gmail.com, 20150729, limit top_corner and right_corner to maximum number of tick elements
% Lea Mueller, muellele@gmail.com, 20151106, move to core
%-


global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('fig_axes'    ,'var'),fig_axes     = []; end
if ~exist('top_corner'  ,'var'),top_corner   = []; end
if ~exist('right_corner','var'),right_corner = []; end

if isempty(fig_axes)    ,fig_axes     = gca; end
if isempty(top_corner)  ,top_corner   =   2; end
if isempty(right_corner),right_corner =   1; end

xticks = get(fig_axes, 'xtick');
yticks = get(fig_axes, 'ytick');
if isempty(xticks)
    fprintf('Unable to proceed.\n')
    return
end

% calculate distance between two ticks
if xticks(1)<=180 
    % in lat/lon
    scale_text = sprintf('%2.1f km', climada_geo_distance(xticks(1),yticks(end),xticks(2),yticks(end))/1000);
else
    % no conversion, probably in utm in m
    scale_text = sprintf('%2.1f km', abs(xticks(1)-xticks(2))/1000);
end
hold on
if right_corner>=numel(xticks)-1, right_corner = numel(xticks)-1;end
if top_corner>=numel(yticks)-1, top_corner = numel(yticks)-1;end
plot(xticks(end-right_corner:end-(right_corner-1)), ones(2,1)*yticks(end-top_corner),'-k','linewidth',3)
text(mean(xticks(end-right_corner:end-(right_corner-1))), yticks(end-top_corner),scale_text,...
    'verticalalignment','bottom','HorizontalAlignment','center','fontsize',14)




