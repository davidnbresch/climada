function climada_centroids_plot(centroids,country_name)
% plot centroids on a map, differentiate for coastal land areas,
% bufferzone, and further away (more inland and on sea)
% NAME:
%   climada_centroids_plot
% PURPOSE:
%   plot centroids on a map, differentiate for coastal land areas,
%   bufferzone, and further away (more inland and on sea)
%   next: diverse
% CALLING SEQUENCE:
%   climada_centroids_plot(centroids,country_name)
% EXAMPLE:
%   climada_centroids_plot(climada_centroids_load)
% INPUTS:
%   centroids: centroids structure
%       > prompts for already read centroids if empty
%   country_name: name of the country (cell or string)
%       Only used to label the plot
% OUTPUTS:
%   plot
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20140205
% David N. Bresch, david.bresch@gmail.com, 20150203, renamed from climada_plot_centroids to climada_centroids_plot
%-


%global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('centroids'          , 'var'), centroids    =[]; end
if ~exist('country_name'       , 'var'), country_name =[]; end

% prompt for centroids if not given
if isempty(centroids),centroids=climada_centroids_load;end
if isempty(centroids),return;end

if ~iscell(country_name)
    country_name = {country_name};
end

% calculate figure parameters
markersize = 1.5;
scale      = max(centroids.lon) - min(centroids.lon);
scale2     =(max(centroids.lon) - min(centroids.lon))/...
    (min(max(centroids.lat),80)-max(min(centroids.lat),-60));
ax_lim = [min(centroids.lon)-scale/30          max(centroids.lon)+scale/30 ...
    max(min(centroids.lat),-60)-scale/30  min(max(centroids.lat),80)+scale/30];

climada_plot_world_borders(0.5);
xlabel('Longitude'); ylabel('Latitude')
axis(ax_lim)
axis equal
axis(ax_lim)
if max(centroids.onLand)== 1 %no buffer
    cmap = ([[255 153  18]/255;...
        jet(max(centroids.onLand))]);
else
    if ~isempty(country_name)
        no_colors = length(country_name);
    else
        no_colors = max(centroids.onLand)-1;
    end
    cmap = ([[255 153  18]/255;...
        jet(no_colors);...
        [205 193 197 ]/255]);
end

if min(centroids.onLand) > 0
    indx = find(centroids.onLand, 1, 'last');
    centroids.onLand(indx) = 0;
end

cbar = plotclr(centroids.lon, centroids.lat, centroids.onLand, '+',markersize, 1, [],[],cmap);
colormap(cmap)
caxis([0 size(cmap,1)])

if ~isempty(country_name)
    cbar_label_ = {};
    for i = 1:length(country_name)
        cbar_label_{i} = sprintf('%d: %s', i, country_name{i});
    end
    cbar_label = ['0: Grid' cbar_label_ [int2str(i+1) ': Buffer']];
else
    cbar_label = num2cell(0:size(cmap,1)-1);
    cbar_label{1} = '0: Grid';
    cbar_label{end} = sprintf('%d: Buffer',cbar_label{end});
end
set(cbar,'YTick',0.5:1:size(cmap,1)-0.5,'yticklabel',cbar_label,'fontsize',12)
title('centroids on land, within buffer and grid')

end % climada_centroids_plot
