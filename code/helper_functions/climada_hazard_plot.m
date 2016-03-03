function res=climada_hazard_plot(hazard,event_i,label,caxis_range,plot_centroids)
% climada plot single hazard event footprint
% NAME:
%   climada_hazard_plot
% PURPOSE:
%   plot hazard event as contour on a map, works for all perils
%
%   see also climada_plot_tc_footprint (works for TC only)
%   and the high-resolution version climada_hazard_plot_hr
% CALLING SEQUENCE:
%   climada_hazard_plot(hazard,event_i,label)
% EXAMPLE:
%   climada_hazard_plot(climada_hazard_load,1); % plot first event
%   climada_hazard_plot; % prompt for hazard event set, plot largest event
% INPUTS:
%   hazard: hazard structure
%       > prompted for if empty
%   event_i: the i-th event in the hazard event set to be displayed
%       if event_i=0, the maximum intensity at each centroid is shown
%       if event_i=-i, the i-th 'largest' event (sum of intensities) is shown
%           e.g. for event_i=-2, the second largest event is shown
%       default=-1 (just to get something on the screen ;-)
% OPTIONAL INPUT PARAMETERS:
%   label: a struct with a label to add on the plot (i.e. a place)
%       longitude: the longitude (decimal)
%       latitude: the latitude (decimal)
%       name: the label itself, like 'gaga'
%   caxis_range: [minval maxval], the range of the color axis, e.g. [20 40]
%       to show colors for values brtween 20 and 40
%   plot_centroids: =1, plot centroids, =0 no (default)
% OUTPUTS:
%   creates a figure
%   res, a structure with the core data, i.e. X,Y and VALUE as shown
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20140302
% David N. Bresch, david.bresch@gmail.com, 20150114, Octave compatibility for -v7.3 mat-files
% David N. Bresch, david.bresch@gmail.com, 20150225, res instead of [X,Y,gridded_VALUE]
% Lea Mueller, muellele@gmail.com, 20150424, colormap according to peril_ID
% Lea Mueller, muellele@gmail.com, 20150427, higher resolution, npoints set to 2000 (instead of 199)
% Lea Mueller, muellele@gmail.com, 20150512, switched to griddata instead of climada_gridded_Value
%-

res=[]; % init

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('hazard','var'),hazard=[];end
if ~exist('event_i','var'),event_i=-1;end
if ~exist('label','var'),label=[];end
if ~exist('caxis_range','var'),caxis_range=[];end
if ~exist('plot_centroids','var'),plot_centroids=0;end

if isempty(hazard),hazard=climada_hazard_load;end % prompt for and load hazard, if empty
% special, if name instead of struct is passed
if ischar(hazard),hazard=climada_hazard_load(hazard);end
if isempty(hazard),return;end

hazard=climada_hazard2octave(hazard); % Octave compatibility for -v7.3 mat-files

% calculate figure scaling parameters
scale  = max(hazard.lon) - min(hazard.lon);
scale2 =(max(hazard.lon) - min(hazard.lon))/...
    (min(max(hazard.lat),95)-max(min(hazard.lat),-60));
height = 0.5;
if height*scale2 > 1.2; height = 1.2/scale2; end

% calculate figure characteristics
ax_lim_buffer = scale/10;
ax_lim = [min(hazard.lon)-ax_lim_buffer           max(hazard.lon)+ax_lim_buffer ...
          max(min(hazard.lat),-60)-ax_lim_buffer  min(max(hazard.lat),95)+ax_lim_buffer];

if event_i<0
    % search for i-thlargest event
    event_sum=sum(hazard.intensity,2);
    [~,sorted_i]=sort(event_sum);
    event_ii=sorted_i(length(sorted_i)+event_i+1);
    values=full(hazard.intensity(event_ii,:)); % extract one event
    if event_i<-1
        title_str=sprintf('%s %i-largest event (%i)',hazard.peril_ID,-event_i,event_ii);
    else
        title_str=sprintf('%s largest event (%i)',hazard.peril_ID,event_ii);
    end
    % plot some further info to sdout:
    if (isfield(hazard,'name') && isfield(hazard,'yyyy')) && (isfield(hazard,'mm') && isfield(hazard,'dd'))
        fprintf('%s, %4.4i%2.2i%2.2i, event %i\n',hazard.name{event_ii},hazard.yyyy(event_ii),hazard.mm(event_ii),hazard.dd(event_ii),event_ii);
    end
elseif event_i==0
    values=full(max(hazard.intensity)); % max intensity at each point
    title_str=sprintf('%s max intensity at each centroid',hazard.peril_ID);
else
    values=full(hazard.intensity(event_i,:)); % extract one event
    title_str=sprintf('%s event %i',hazard.peril_ID,event_i);
    % plot some further info to sdout:
    if (isfield(hazard,'name') && isfield(hazard,'yyyy')) && (isfield(hazard,'mm') && isfield(hazard,'dd'))
        fprintf('%s, %4.4i%2.2i%2.2i, event %i\n',hazard.name{event_i},hazard.yyyy(event_i),hazard.mm(event_i),hazard.dd(event_i),event_i);
    end
end
if isfield(hazard,'units'),title_str=[title_str ' (' hazard.units ')'];end % add units

if sum(values(not(isnan(values))))>0 % nansum(values)>0
    
    % create figure
    %fig = climada_figuresize(height,height*scale2+0.15);
    %set(fig,'Name',hazard.peril_ID);
    [cmap,c_ax]   = climada_colormap(hazard.peril_ID);
    centroids.lon = hazard.lon; % as the gridding routine needs centroids
    centroids.lat = hazard.lat;
    %npoints       = 2000;
    %npoints       = 500;
    %stencil_ext   = 5;
    %[X, Y, gridded_VALUE] = climada_gridded_VALUE(values,centroids,'linear',npoints,stencil_ext); 
    [X, Y]        = meshgrid(unique(hazard.lon),unique(hazard.lat));
    gridded_VALUE = griddata(hazard.lon,hazard.lat,values,X,Y);
    contourf(X, Y, gridded_VALUE,'edgecolor','none')
    %contourf(X, Y, gridded_VALUE,'edgecolor','none')
    hold on
    box on
    climada_plot_world_borders(0.5)
    axis(ax_lim)
    axis equal
    axis(ax_lim)
    title(title_str);
    if ~isempty(caxis_range),caxis(caxis_range);end
    colorbar;
    colormap(cmap)

else
    fprintf('all intensities zero for event %i\n',event_i);
    return
end

if plot_centroids,plot(hazard.lon,hazard.lat,'.b','MarkerSize',1);end

if ~isempty(label)
    text(label.longitude,label.latitude,label.name)
    plot(label.longitude,label.latitude,'xk');
end

res.X=X;
res.Y=Y;
res.VALUE=gridded_VALUE;

set(gcf,'Color',[1 1 1])
 
return


