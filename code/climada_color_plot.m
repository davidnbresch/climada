function climada_color_plot(values,lon,lat,figure_name,title_str,plot_method,interp_method,npoints,plot_centroids,caxis_range,stencil_ext)
% color plot
% NAME:
%   climada_color_plot
% PURPOSE:
%   helper function to make nice color plot
%   does only show values in the vicinity of the hazard zone centroids
%
%   for speed up, if one gives the npoints negative, the mask is stored
%
%   %% precedes a switched off option, not a comment
%
% CALLING SEQUENCE:
%   climada_color_plot(values,lon,lat,figure_name,title_str,plot_method,interp_method,npoints)
% EXAMPLE:
%   climada_color_plot(mean(hazard.intensity,2),hazard.lon,hazard.lat)
% INPUTS:
%   values(i): values
%   lon(i),lat(i): coordinates of values, same length as values
%   interactive_mode: 'interactive' allows for GUIs
% OPTIONAL INPUT PARAMETERS:
%   figure_name: name of the figure window, if set to 'none', no figure is opened
%   title_str:plot title
%   plot_method: 'pcolor' or 'contour', default is matrix
%   interp_method: method in griddata, like 'linear', 'cubic',...
%   npoints: the number of points used
%   plot_centroids: if set to 0, do not plot dentroids as red dots
%       (default=1)
%   caxis_range: [min max] data values for constant color bars
%   stencil_ext: to extend the stencil range (in units of the target grid,
%       default=0
% OUTPUTS:
%   makes new figure
% RESTRICTIONS:
%   none
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20120430
%-

% set defaults
%global climada_global
if ~climada_init_vars,return;end % init/import global variables
if ~exist('figure_name','var'),figure_name=[];end
if ~exist('title_str','var'),title_str=[];end
if ~exist('plot_method','var'),plot_method=[];end
if ~exist('interp_method','var'),interp_method=[];end
if ~exist('npoints','var'),npoints=[];end
if ~exist('plot_centroids','var'),plot_centroids=[];end
if ~exist('caxis_range','var'),caxis_range=[];end
if ~exist('stencil_ext','var'),stencil_ext=[];end

% PARAMETERS
%
% set defaults
if isempty(figure_name),figure_name='climada';end
if isempty(title_str),title_str='color plot';end
if isempty(plot_method),plot_method='pcolor';end
if isempty(interp_method),interp_method='linear';end
if isempty(npoints),npoints=199;end
if isempty(plot_centroids),plot_centroids=1;end
if isempty(stencil_ext),stencil_ext=0;end
%
% to avoid masking areas far away from CalcUnits
no_mask=0;

values=full(values); % make sure we have no sparse

if not(strcmp(figure_name,'none'))
    figure('Name',figure_name,'NumberTitle','off');
    set(gcf,'Color',[1 1 1]); % change BG color to white
end;

% define grid if not existing or if npoints>0
npoints=abs(npoints); % force positive
xx=linspace(min(lon)-1, max(lon)+1, npoints);
yy=linspace(min(lat)-1, max(lat)+1, npoints);
[X,Y]=meshgrid(xx,yy); % construct regular grid
%%fprintf('preparing color plot...\n');
dlon=abs(max(lon)-min(lon));dlat=abs(max(lat)-min(lat));
xstencil_width=floor(npoints/(dlon+2)/2)+1+stencil_ext;
ystencil_width=floor(npoints/(dlat+2)/2)+1+stencil_ext;
xstencil=-xstencil_width:1:xstencil_width; % figure out the stencil, based on npoints
ystencil=-ystencil_width:1:ystencil_width; % figure out the stencil, based on npoints
if no_mask
    mask=X*0; % reset mask
else
    mask=X+NaN; % mask points by setting them to NaN

    for ii=1:length(lon)
        [~,ix]=min(abs(xx-lon(ii)));
        [~,iy]=min(abs(yy-lat(ii)));
        mask(ystencil+iy,xstencil+ix)=0; % make center and surrounding points visible
        %     yyy=ystencil+iy;
        %     xxx=xstencil+ix;
        %     pos=find(yyy>0 & xxx>0);
        %     if length(pos)>0
        %         mask(yyy(pos),xxx(pos))=0; % make center and surrounding points visible
        %     end;
    end
end % no_mask

gridded_VALUE=griddata(lon,lat,values,X,Y,interp_method)+mask; % interpolate to grid 'linear'
switch plot_method
    case 'contour'
        contourf(X,Y,full(gridded_VALUE));hold on;axis equal; % filled contour plot
    otherwise
        pcolor(X,Y,gridded_VALUE);hold on;shading flat;axis equal;
        if ~isempty(caxis_range),caxis(caxis_range);end;axis off
end;
if plot_centroids,plot(lon,lat,'+r','MarkerSize',1);end;% red + at each centroid
climada_plot_world_borders(1);title(title_str,'FontSize',9);hold off;colorbar;
axis([min(lon)-1 max(lon)+1 min(lat)-1 max(lat)+1]); % set axis for good zoom
drawnow;