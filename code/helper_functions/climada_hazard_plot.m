function res=climada_hazard_plot(hazard,event_i,label,caxis_range,plot_centroids,entity)
% climada plot single hazard event footprint
% NAME:
%   climada_hazard_plot
% PURPOSE:
%   plot hazard event as contour on a map, works for all perils
%
%   see also climada_plot_tc_footprint (works for TC only)
%   and the high-resolution version climada_hazard_plot_hr
%
%   See also climada_hazard_plot_nogrid (later to be merged all in one)
% CALLING SEQUENCE:
%   res=climada_hazard_plot(hazard,event_i,label,caxis_range,plot_centroids,entity)
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
%       Different meaning in case you pass entity (see optional parameters)
% OPTIONAL INPUT PARAMETERS:
%   label: a struct with a label to add on the plot (i.e. a place)
%       longitude: the longitude (decimal)
%       latitude: the latitude (decimal)
%       name: the label itself, like 'gaga'
%   caxis_range: [minval maxval], the range of the color axis, e.g. [20 40]
%       to show colors for values brtween 20 and 40
%   plot_centroids: =1, plot centroids, =0 no (default)
%   entity: if provided, do not show 'biggest' hazard in terms of itensity,
%       but regarding resulting damage based on entity
%       Only makes sense for event_i<0, as it shows the i-th largest damage
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
% David N. Bresch, david.bresch@gmail.com, cleanup
% David N. Bresch, david.bresch@gmail.com, 20160930, legend added, if centroids are plotted
% David N. Bresch, david.bresch@gmail.com, 20170110, entity added
% David N. Bresch, david.bresch@gmail.com, 20170611, FontSize in PARAMETERS for plots
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
if ~exist('entity','var'),entity=[];end

if isempty(hazard),hazard=climada_hazard_load;end % prompt for and load hazard, if empty
if ischar(hazard),hazard=climada_hazard_load(hazard);end % special, if name instead of struct is passed
if isempty(hazard),return;end

% PARAMETERS
%
% the threshold up to which the original centroid coordinates are used to
% create the meshgrid (using fewer points for speedup, if above)
% see code below for details (search for max_numel_lonlat)
max_numel_lonlat=1000000; % 1000
%
verbose=0; % default=0
%
FontSize=18; % default=9

hazard=climada_hazard2octave(hazard); % Octave compatibility for -v7.3 mat-files

if ~isfield(hazard,'units'),hazard.units='';end

if ~isempty(entity)
    EDS=climada_EDS_calc(entity,hazard);
    event_sum=EDS.damage; % pass damage instead of intensity
else
    event_sum=[];
end

% calculate figure scaling parameters
scale  = max(hazard.lon) - min(hazard.lon);

% calculate figure characteristics
ax_lim_buffer = scale/10;
ax_lim = [min(hazard.lon)-ax_lim_buffer           max(hazard.lon)+ax_lim_buffer ...
    max(min(hazard.lat),-60)-ax_lim_buffer  min(max(hazard.lat),95)+ax_lim_buffer];

title_str=''; % init

switch hazard.peril_ID
    case 'TC'
        LevelList=0:10:120;
        caxis_range=[min(LevelList) max(LevelList)];
    otherwise
        LevelList=[];
end % switch

event_ii=0;
if event_i<0
    % search for i-thlargest event
    if isempty(event_sum),event_sum=sum(hazard.intensity,2);end
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
    % plot some further info to sdout:
    if (isfield(hazard,'name') && isfield(hazard,'yyyy')) && (isfield(hazard,'mm') && isfield(hazard,'dd'))
        hazard_name=hazard.name{event_i};
        fprintf('%s, %4.4i%2.2i%2.2i, event %i\n',hazard_name,hazard.yyyy(event_i),hazard.mm(event_i),hazard.dd(event_i),event_i);
        gen_check=strfind(hazard_name,'gen'); % check for probabilistic event
        if ~isempty(gen_check)
            gen_str=[' ' hazard_name(gen_check(1):end)];
        else
            gen_str='';
        end
        title_str=sprintf('%s %4.4i%2.2i%2.2i%s (%i)\n',hazard.peril_ID,...
            hazard.yyyy(event_i),hazard.mm(event_i),hazard.dd(event_i),gen_str,event_i);
    end
end % isfield(hazard,'name')

if sum(values(not(isnan(values))))>0 % nansum(values)>0
    
    [cmap,~]      = climada_colormap(hazard.peril_ID);
    
    ulon=unique(hazard.lon);ulat=unique(hazard.lat);
    if max(numel(ulon),numel(ulat))>max_numel_lonlat
        fprintf('Note: grid on appropriate resolution, not on original centroids,');
        verbose=1;
        ddlon=max(abs(diff(ulon)));ddlat=max(abs(diff(ulat)));
        dlon=(max(ulon)-min(ulon))/1000;
        dlat=(max(ulat)-min(ulat))/1000;
        ulon=min(ulon)-ddlon:dlon:max(ulon)+ddlon;
        ulat=min(ulat)-ddlat:dlat:max(ulat)+ddlat;
    end
    [X, Y]    = meshgrid(ulon,ulat);
    if verbose,fprintf(' gridding ...');end
    gridded_VALUE = griddata(hazard.lon,hazard.lat,values,X,Y);
    if verbose,fprintf(' done\n');end
    contourf(X, Y, gridded_VALUE,'linecolor','none')
    %contourf(X, Y, gridded_VALUE,'linecolor','none','LevelList',LevelList)
    hold on
    box on
    if plot_centroids
        plot(hazard.lon,hazard.lat,'.b','MarkerSize',1);
        legend({['hazard intensity [' hazard.units ']'],'centroids'});
    end % plot_centroids
    climada_plot_world_borders(0.5)
    axis(ax_lim)
    axis equal
    axis(ax_lim)
    if ~isempty(caxis_range),caxis(caxis_range);end
    c=colorbar;
    c.FontSize = FontSize;
    c.Label.FontSize = FontSize;
    colormap(cmap)
    if isfield(hazard,'units')
        try % . notation allowed since version 7...
            c.Label.String = hazard.units;
        catch
            title_str=[title_str ' (' hazard.units ')']; % add units
        end % try
    end % isfield(hazard,'units')
    title(title_str);xlabel('Longitude');ylabel('Latitude');
    
else
    fprintf('all intensities zero for event %i\n',event_i);
    return
end

if ~isempty(label)
    text(label.longitude,label.latitude,label.name)
    plot(label.longitude,label.latitude,'xk');
end

res.X=X;
res.Y=Y;
res.VALUE=gridded_VALUE;
res.title_str=title_str;
res.event_i=event_ii;
try
    res.name=hazard.name(event_i);
catch % empty catch
end % try

set(gcf,'Color',[1 1 1])

end % climada_hazard_plot