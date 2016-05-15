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
%   cbar_ylabel: label for the color bar, default 'Values'
% OUTPUTS:
%   a figure
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141121, ICE initial
% David N. Bresch, david.bresch@gmail.com, 20160514, max_value,cbar_ylabel added
%-

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('markersize','var'),markersize=[];end
if ~exist('plot_centroids','var'),plot_centroids=0;end
if ~exist('max_value','var'),max_value=[];end
if ~exist('cbar_ylabel','var'),cbar_ylabel='Values';end

% PARAMETERS
%
% the plot is zoomed to the domain of the assets, plus d degress around
d = 1; % degree

% prompt for entity if not given
if isempty(entity),entity=climada_entity_load;end
if isempty(entity),return;end

% set colormap
% miv = min(arrayfun(@(x) (min(x.Value)),assets));
% mav = max(arrayfun(@(x) (max(x.Value)),assets));
% miv = []; mav = [];
beginColor  = [232 232 232 ]/255;
middleColor = [105 105 105 ]/255;
cmap1 = makeColorMap(beginColor, middleColor, 4);
cmap2 = makeColorMap([255 236 139]/255, [255 97 3 ]/255, 6); %[255 153 18]/255 yellow
cmap3 = makeColorMap([255 64 64 ]/255, [176 23 31 ]/255, 2); %[255 153 18]/255 yellow
% cmap3 = makeColorMap([205 150 205 ]/255, [93 71 139 ]/255, 2); %[255 153 18]/255 yellow

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
[cbar,~]= plotclr(entity.assets.lon, entity.assets.lat, entity.assets.Value, 's',markersize, 1,0,mav,cmap,1,0);
hold on
axis equal
xlabel('Longitude')
ylabel('Latitude')
%set(gca,'layer','top')
box % box axes

set(get(cbar,'ylabel'),'string',cbar_ylabel,'fontsize',12)
climada_plot_world_borders(0.7);
set(gca,'xlim',x_range,'ylim',y_range)
if plot_centroids,plot(entity.assets.lon, entity.assets.lat,'.r','MarkerSize',1);end

set(gcf,'Color',[1 1 1])

return

% below code from Lea Mueller, not active

% if isfield(entity.assets,'excel_file_name')
%
%     % left here, but not really leading to nicer plot...
%
%     set(get(cbar,'ylabel'),'string','USD (exponential)','fontsize',12)
%
%     titlestr = sprintf('%s\n %d assets: %5.0f Bn USD, ', entity.assets.excel_file_name, size(entity.assets.Value,2), sum(entity.assets.Value)*10^-9);
%     title(titlestr,'fontsize',11)
%
%     hb = get(gca,'PlotBoxAspectRatio');
%     hb = hb(1)/hb(2);
%     if hb/(diff(x_range)/diff(y_range))<1
%         dif     = ( diff(x_range)/hb-diff(y_range) )/2;
%         y_range = [y_range(1)-dif y_range(2)+dif];
%         set(gca,'xlim',x_range,'ylim',y_range)
%     else
%         dif     = ( diff(y_range)*hb-diff(x_range) )/2;
%         x_range = [x_range(1)-dif x_range(2)+dif];
%         set(gca,'xlim',x_range,'ylim',y_range)
%     end
%
% end

% for r_i = 1:length(region_str)
%     [cbar asset_handles{r_i}]= plotclr(assets(r_i).lon, assets(r_i).lat, assets(r_i).Value, 's',markersize, 0,0,[],cmap,1,0);
%     miv(r_i) = min(assets(r_i).Value);
%     mav(r_i) = max(assets(r_i).Value);
% end
% set([asset_handles{:}],'markersize',3)
% set([asset_handles{:}],'HandleVisibility','off')

% colormap(cmap)
% cbar_assets = colorbar;
% % freezeColors(handles.axes5) %freezeColors(cbar_assets)
% cbar_assets = colorbar('location','north'); %southoutside
% caxis([0 1])
% set(cbar_assets,'xlim',[0 1],'xtick',[])
% cbar_assets = cbfreeze(cbar_assets);
