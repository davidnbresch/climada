function [res,params]=climada_hazard_plot_nogrid(hazard,event_i,markersize,params)
% climada plot single hazard event footprint
% NAME:
%   climada_hazard_plot
% PURPOSE:
%   plot hazard event as contour on a map, works for all perils
%
%   see also climada_plot_tc_footprint (works for TC only)
%   and the high-resolution version climada_hazard_plot_hr
%   See also climada_hazard_plot (later to be merged all in one)
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
%   markersize: the size of the 'tiles', one might need to experiment a
%       bit (that's why markersize is not part of params.), as the code
%       tries (hard) to set a reasonabls default (based on resolution).
%       If <0, plot ocean blue and land grey (looks nicer, but takes a bit longer)
% OPTIONAL INPUT PARAMETERS:
%   params: a structure with fields (see also entity='params' above):
%    plot_centroids: =1: plot centroids as small red dots
%       =0: do not plot centroids (default)
%    max_value: the maximum value to color, default is max(entity.assets.Value)
%       if =-1, use largest Value in entity.assets.Values, instead of .Value
%    cbar_ylabel: label for the color bar, default 'Value'
%       if empty, indicate entity value locations by black circles, e.g. for
%       climada_hazard_plot(hazard);hold on;climada_entity_plot(entity,1,0,[],'')
%    title_str: the title of the plot, if empty, use contents of hazard to define it
%    blue_ocean: plot ocean bliue, if =1 (default=0, since faster)
%    intensity_threshold: the intensity threshold below which we do not plot
%       intensities, default=0.
%    label: a struct with a label to add on the plot (i.e. a place)
%       longitude: the longitude (decimal)
%       latitude: the latitude (decimal)
%       name: the label itself, like 'this city'
%    entity: if provided, do not show 'biggest' hazard in terms of itensity,
%       but regarding resulting damage based on entity
%       Only makes sense for event_i<0, as it shows the i-th largest damage
%    figure_scale: if =1, plot figure scale (default), =0 not
% OUTPUTS:
%   creates a figure
%   res: a structure with the core data, i.e. lon,lat and value as shown
%   params: the params structure, filled wit defaults, see
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20170611, initial copy from climada_entity_plot
% David N. Bresch, david.bresch@gmail.com, 20170730, scaling same as climada_entity_plot
% David N. Bresch, david.bresch@gmail.com, 20170801, Octave compatibility
%-

res=[]; % init

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('hazard','var'),     hazard=[];end
if ~exist('event_i','var'),    event_i=-1;end
if ~exist('markersize','var'), markersize=[];end
if ~exist('params','var'),     params=struct;end

% check for some parameter fields we need
if ~isfield(params,'plot_centroids'), params.plot_centroids=[];end
if ~isfield(params,'cbar_ylabel'),    params.cbar_ylabel='';end
if ~isfield(params,'title_str'),      params.title_str='';end
if ~isfield(params,'blue_ocean'),     params.blue_ocean=[];end
if ~isfield(params,'intensity_threshold'),params.intensity_threshold=[];end
if ~isfield(params,'label'),          params.label=[];end
if ~isfield(params,'entity'),         params.entity=[];end
if ~isfield(params,'max_value'),      params.max_value=[];end
if ~isfield(params,'figure_scale'),   params.figure_scale=[];end

% PARAMETERS
%
% the threshold up to which the original centroid coordinates are used to
% create the meshgrid (using fewer points for speedup, if above)
% see code below for details (search for max_numel_lonlat)
%
% Font size on plot, must be 2*n (as we use half the size, too)
FontSize=12; % default=12 or 18
%
% color of land, only used, if markersize<0
country_color=[.6 .6 .6]; % light gray
%
% populate default parameters in params
if isempty(params.plot_centroids),  params.plot_centroids=0;end
if isempty(params.cbar_ylabel),     params.cbar_ylabel='Intensity';end
if isempty(params.blue_ocean),      params.blue_ocean=0;end
if isempty(params.intensity_threshold),params.intensity_threshold=0;end
if isempty(params.figure_scale),    params.figure_scale=1;end

if strcmpi(hazard,'params'),res=params;return;end % special case, return the full params structure

if isempty(hazard),hazard=climada_hazard_load;end % prompt for and load hazard, if empty
if ischar(hazard),hazard=climada_hazard_load(hazard);end % special, if name instead of struct is passed
if isempty(hazard),return;end
hazard=climada_hazard2octave(hazard); % Octave compatibility for -v7.3 mat-files
if isfield(hazard,'units'),params.cbar_ylabel=hazard.units;end

% calculate figure characteristics
scale  = max( max(hazard.lon)-min(hazard.lon), max(hazard.lat)-min(hazard.lat));
ax_lim_buffer = scale/20;
ax_lim = [min(hazard.lon)-ax_lim_buffer           max(hazard.lon)+ax_lim_buffer ...
    max(min(hazard.lat),-60)-ax_lim_buffer  min(max(hazard.lat),95)+ax_lim_buffer];

if isempty(markersize)
    % a crude way to get an appropriate markersize
    markersize=max(2,15-ceil(scale));
    fprintf('markersize = %i\n',markersize);
end

event_sum=[];
if ~isempty(params.entity)
    EDS=climada_EDS_calc(entity,hazard);
    event_sum=EDS.damage; % pass damage instead of intensity
end

event_ii=0;yyyymmdd_str=''; % init
if event_i<0
    % search for i-thlargest event
    if isempty(event_sum),event_sum=sum(hazard.intensity,2);end
    [~,sorted_i]=sort(event_sum);
    event_ii=sorted_i(length(sorted_i)+event_i+1);
    plot_Value=full(hazard.intensity(event_ii,:)); % extract one event
    if isfield(hazard,'yyyy') && isfield(hazard,'mm') && isfield(hazard,'dd')
        yyyymmdd_str=sprintf('%4.4i%2.2i%2.2i',hazard.yyyy(event_ii),hazard.mm(event_ii),hazard.dd(event_ii));
    end
    
    if event_i<-1
        title_str=sprintf('%s %i-largest event %s (%i)',hazard.peril_ID,-event_i,yyyymmdd_str,event_ii);
    else
        title_str=sprintf('%s largest event %s (%i)',hazard.peril_ID,yyyymmdd_str,event_ii);
    end
    % plot some further info to sdout:
    if (isfield(hazard,'name') && isfield(hazard,'yyyy')) && (isfield(hazard,'mm') && isfield(hazard,'dd'))
        fprintf('%s, %4.4i%2.2i%2.2i, event %i\n',hazard.name{event_ii},hazard.yyyy(event_ii),hazard.mm(event_ii),hazard.dd(event_ii),event_ii);
    end
elseif event_i==0
    plot_Value=full(max(hazard.intensity)); % max intensity at each point
    title_str=sprintf('%s max intensity at each centroid',hazard.peril_ID);
else
    plot_Value=full(hazard.intensity(event_i,:)); % extract one event
    if isfield(hazard,'yyyy') && isfield(hazard,'mm') && isfield(hazard,'dd')
        yyyymmdd_str=sprintf('%4.4i%2.2i%2.2i',hazard.yyyy(event_i),hazard.mm(event_i),hazard.dd(event_i));
    end
    if isfield(hazard,'name')
        hazard_name=hazard.name{event_i};
        fprintf('%s, %4.4i%2.2i%2.2i, event %i\n',hazard_name,yyyymmdd_str,event_i);
        gen_check=strfind(hazard_name,'gen'); % check for probabilistic event
        if ~isempty(gen_check)
            gen_str=[' ' hazard_name(gen_check(1):end) ' '];
        else
            gen_str=' ';
        end
        title_str=sprintf('%s %s %s%s(%i)\n',hazard.peril_ID,yyyymmdd_str,hazard_name,gen_str,event_i);
    else
        title_str=sprintf('%s %s (%i)\n',hazard.peril_ID,yyyymmdd_str,event_i);
    end
end

if isempty(params.title_str),params.title_str=title_str;end

plot_Value(plot_Value<params.intensity_threshold)=NaN;

if sum(plot_Value(not(isnan(plot_Value))))>0 % nansum(values)>0
    
    [cmap,c_ax]      = climada_colormap(hazard.peril_ID);
    
    if isempty(params.max_value)
        %params.max_value=max(plot_Value); % until 20170809
        params.max_value=max(c_ax);
    end
    %mav=params.max_value*1.1; % to be on the safe side for all values to be plotted
    mav=params.max_value; % you get what you ask for
    
    if params.blue_ocean
        climada_plot_world_borders(-1,'','',0,[],country_color);
        hold on
    end
    
    [cbar,~]= plotclr(hazard.lon,hazard.lat,plot_Value, 's',abs(markersize), 1,0,mav,cmap,0,0); % 1,0)
    %         plotclr(x,         y,         v,       marker,markersize,colorbar_on, miv, mav, map, zero_off, v_exp)

    hold on
    set(gca,'FontSize',FontSize)
    set(cbar,'FontSize',FontSize) % cbar.FontSize = FontSize;
    %set(get(cbar,'Label' ),'FontSize',FontSize) % cbar.Label.FontSize = FontSize;
    set(get(cbar,'ylabel'),'string',params.cbar_ylabel,'fontsize',FontSize);
    
    if ~isempty(params.title_str),title(params.title_str,'FontSize',FontSize);end
    xlabel('Longitude','FontSize',FontSize);ylabel('Latitude','FontSize',FontSize);
    
    axis equal
    axis(ax_lim)
    box % box axes
    climada_plot_world_borders(0.7*sign(markersize),'','',1,[],country_color);
    
    if params.plot_centroids,plot(entity.assets.lon, entity.assets.lat,'.r','MarkerSize',1);end
    
    if ~climada_global.octave_mode && params.figure_scale,climada_figure_scale_add;end
    set(gcf,'Color',[1 1 1])
    hold off
    drawnow
    
else
    fprintf('all intensities < %2.2f for event %i\n',params.intensity_threshold,event_i);
    return
end

if ~isempty(params.label)
    text(params.label.longitude,params.label.latitude,params.label.name)
    plot(params.label.longitude,params.label.latitude,'xk');
end

res.X=hazard.lon;
res.Y=hazard.lat;
res.VALUE=plot_Value;
res.title_str=title_str;
res.event_i=event_ii;
res.yyyymmdd_str=yyyymmdd_str;
try
    res.name=hazard.name(event_i);
catch % empty catch
end % try

set(gcf,'Color',[1 1 1])

end % climada_hazard_plot