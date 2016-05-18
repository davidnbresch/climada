function climada_entity_plot(entity,markersize,plot_centroids,max_value,cbar_ylabel)
% plot an entity, no detailed documentation
% NAME:
%   climada_entity_plot
% PURPOSE:
%   Plot the assets of an entity
%
%   Note that you can overplot, just call hold on before calling
%   climada_entity_plot, i.e. to plot assets on top of tracks (see
%   climada_tc_track_info)
%
%   See also climada_entity_read
%   Possible prior call: climada_tc_track_info;hold on
% CALLING SEQUENCE:
%   climada_entity_plot(entity)
% EXAMPLE:
%   climada_entity_plot(climada_entity_read)
% INPUTS:
%   entity: an entity (see climada_entity_read)
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   markersize: the size of the 'tiles', one might need to experiment a
%       bit, as the code tries (hard) to set a reasonabls default (based on
%       resolution)
%   plot_centroids: =1: plot centroids as small red dots
%       =0: do not plot centroids (default)
%   max_value: the maximum value to color
%       default is max(entity.assets.Value)
%   cbar_ylabel: label for the color bar, default 'Value'
%       if empty, indicate entity value locations by black circles, e.g. for
%       climada_hazard_plot(hazard);hold on;climada_entity_plot(entity,1,0,[],'')
% OUTPUTS:
%   a figure
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141121, ICE initial
% David N. Bresch, david.bresch@gmail.com, 20160514, max_value,cbar_ylabel added
% David N. Bresch, david.bresch@gmail.com, 20160516, added climada_figure_scale_add
% David N. Bresch, david.bresch@gmail.com, 20160516, added option empty cbar_ylabel plus cleanup
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('markersize','var'),markersize=[];end
if ~exist('plot_centroids','var'),plot_centroids=0;end
if ~exist('max_value','var'),max_value=[];end
if ~exist('cbar_ylabel','var'),cbar_ylabel='Value';end

% PARAMETERS
%
% the plot is zoomed to the domain of the assets, plus d degress around
d = 1; % degree

% prompt for entity if not given
if isempty(entity),entity=climada_entity_load;end
if isempty(entity),return;end

if ischar(entity),entity=climada_entity_load(entity);end

beginColor  = [232 232 232 ]/255;
middleColor = [105 105 105 ]/255;
cmap1 = makeColorMap(beginColor, middleColor, 4);
cmap2 = makeColorMap([255 236 139]/255, [255 97 3 ]/255, 6); %[255 153 18]/255 yellow
cmap3 = makeColorMap([255 64 64 ]/255, [176 23 31 ]/255, 2); %[255 153 18]/255 yellow

cmap  = [cmap1; cmap2; cmap3];

% plot the assets
x_range = [min(entity.assets.lon)-d max(entity.assets.lon)+d];
y_range = [min(entity.assets.lat)-d max(entity.assets.lat)+d];
set(gca,'xlim',x_range,'ylim',y_range)

if isempty(markersize)
    % a crude way to get an appropriate markersize
    markersize=max(2,15-ceil(max(abs(diff(x_range)),abs(diff(y_range)))));
    fprintf('markersize = %i\n',markersize);
end

if isempty(max_value)
    mav=max(entity.assets.Value)*1.1; % to be on the safe side for all values to be plotted
else
    mav=max_value*1.1;
end
if ~isempty(cbar_ylabel)
    [cbar,~]= plotclr(entity.assets.lon, entity.assets.lat, entity.assets.Value, 's',markersize, 1,0,mav,cmap,1,0);
else
    pos=find(entity.assets.Value>0);
    if ~isempty(pos),plot(entity.assets.lon(pos),entity.assets.lat(pos),'ok');end
end
hold on
axis equal
xlabel('Longitude')
ylabel('Latitude')
box % box axes

if ~isempty(cbar_ylabel)
    Value_unit=climada_global.Value_unit;
    if isfield(entity.assets,'Value_unit'),Value_unit=entity.assets.Value_unit{1};end
    set(get(cbar,'ylabel'),'string',[cbar_ylabel ' (' Value_unit ')'],'fontsize',12);
end
climada_plot_world_borders(0.7);
set(gca,'xlim',x_range,'ylim',y_range)
if plot_centroids,plot(entity.assets.lon, entity.assets.lat,'.r','MarkerSize',1);end

hold on
climada_figure_scale_add
hold off
drawnow

set(gcf,'Color',[1 1 1])

end % climada_entity_plot