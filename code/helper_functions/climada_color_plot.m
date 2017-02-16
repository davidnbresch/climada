function fig = climada_color_plot(values,lon,lat,figure_name,title_str,plot_method,interp_method,npoints,plot_centroids,caxis_range,cmap,stencil_ext)
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
%   plot_method: 'pcolor', 'contour', 'plotclr', default is matrix
%   interp_method: method in griddata, like 'linear', 'cubic',...
%   npoints: the number of points used
%   plot_centroids: =1 plor centroids, =0 not (default)
%   caxis_range: [min max] data values for constant color bars
%   stencil_ext: to extend the stencil range (in units of the target grid,
%       default=0
% OUTPUTS:
%   makes new figure
% RESTRICTIONS:
%   none
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20120430
% Lea Mueller, muellele@gmail.com, 20151124, add fig output
% Lea Mueller, muellele@gmail.com, 20151130, add plotclr option
% Lea Mueller, muellele@gmail.com, 20151130, set marker to '' so it is taken from climada_global.marker
% Lea Mueller, muellele@gmail.com, 20150226, correct type (contourF instead of contour)
% Lea Mueller, muellele@gmail.com, 20160229, introduce climada_global.admin1_plot, if 1, show all admin1 lines
% Lea Mueller, muellele@gmail.com, 20160229, rename to climada_shapeplotter from shape_plotter
% Lea Mueller, muellele@gmail.com, 20160314, add figure scale (climada_figure_scale_add)
% Lea Mueller, muellele@gmail.com, 20160314, add caxis_range (also for contourf)
%-

fig = []; %init

% set defaults
global climada_global
if ~climada_init_vars,return;end % init/import global variables
if ~exist('figure_name','var'),figure_name='';end
if ~exist('title_str','var'),title_str=[];end
if ~exist('plot_method','var'),plot_method=[];end
if ~exist('interp_method','var'),interp_method=[];end
if ~exist('npoints','var'),npoints=[];end
if ~exist('plot_centroids','var'),plot_centroids=[];end
if ~exist('caxis_range','var'),caxis_range=[];end
if ~exist('cmap','var'),cmap=[];end
if ~exist('stencil_ext','var'),stencil_ext=[];end

% PARAMETERS
%
% set defaults
if isempty(figure_name),figure_name='none';end
if isempty(title_str),title_str='color plot';end
if isempty(plot_method),plot_method='pcolor';end
if isempty(interp_method),interp_method='linear';end
if isempty(npoints),npoints=199;end
if isempty(plot_centroids),plot_centroids=0;end
if isempty(cmap),cmap=jet;end
if isempty(stencil_ext),stencil_ext=0;end
%
% to avoid masking areas far away from CalcUnits
no_mask = 0;
no_mask = 1;

values = full(values); % make sure we have no sparse

if not(strcmp(figure_name,'none'))
    fig = figure('Name',figure_name,'NumberTitle','off');
    set(fig,'Color',[1 1 1]); % change BG color to white
else
    fig = gcf;
end;

% calculate buffer of 10% around lon/lat, to define axis limits
dlon=abs(max(lon)-min(lon));dlat=abs(max(lat)-min(lat));
buffer_percentage = 10; %add buffer of 10% around the lon,lat extent
buffer = max(dlon/buffer_percentage/2, dlat/buffer_percentage/2);

% only needed for pcolor and contourf
if ~strcmp(plot_method,'plotclr')
    % define grid if not existing or if npoints>0
    npoints=abs(npoints); % force positive
    xx=linspace(min(lon)-1, max(lon)+1, npoints);
    yy=linspace(min(lat)-1, max(lat)+1, npoints);
    [X,Y]=meshgrid(xx,yy); % construct regular grid
    %%fprintf('preparing color plot...\n');
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
end %~strcmp(plot_method,'plotclr')
    
switch plot_method
    case 'contourf'
        centroids.lon = lon; centroids.lat = lat;
        [X, Y, gridded_VALUE] = climada_gridded_VALUE(values,centroids);
        gridded_VALUE(gridded_VALUE<(0.1)) = NaN; %gridded_VALUE(gridded_VALUE<(0.1)) = NaN;
        contourf(X, Y, gridded_VALUE,200,'linecolor','none');hold on;axis equal; % filled contour plot   
        if ~isempty(caxis_range),caxis(caxis_range);end
        %contourf(X,Y,full(gridded_VALUE));hold on;axis equal; % filled contour plot
        colormap(cmap)
    case 'plotclr'
        marker = '';
        markersize = ''; colorbar_on = 1; miv = ''; mav = '';
        if numel(caxis_range)>1; miv = caxis_range(1); mav = caxis_range(2); end
        plotclr(lon,lat,values,marker,markersize,colorbar_on,miv,mav,cmap);
        box on; grid off %hold on;axis equal; % filled contour plot
    otherwise
        pcolor(X,Y,gridded_VALUE);hold on;shading flat;axis equal;
        if ~isempty(caxis_range),caxis(caxis_range);end;axis off
        colormap(cmap)
end;
hold on; 
if plot_centroids,plot(lon,lat,'+r','MarkerSize',1);end;% red + at each centroid
if climada_global.admin1_plot
    admin1_shapes = climada_admin1_get_shapes('','all');
    % admin1_shape_selection = climada_admin1_get_shapes(admin0_name,admin1_name);
    if ~isempty(admin1_shapes)
        climada_shapeplotter(admin1_shapes,'','X','Y','linewidth',1,'color',[ 186 186 186  ]/255) % light grey
    end
end
climada_plot_world_borders(1);title(title_str,'FontSize',9); hold off;
colorbar;
axlim = [min(lon)-buffer max(lon)+buffer min(lat)-buffer max(lat)+buffer];
% axis(axlim); % set axis for good zoom
climada_figure_axis_limits_equal_for_lat_lon(axlim)
climada_figure_scale_add
% climada_figure_scale_add('',10,10)
drawnow;
