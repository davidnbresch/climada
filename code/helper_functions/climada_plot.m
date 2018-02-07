function res=climada_plot(lon,lat,value,markersize,peril_ID,params)
% climada plot
% NAME:
%   climada_plot
% PURPOSE:
%   basic plotting function on a (world) map
%
%   see also climada_entity_plot, climada_hazard_plot
% CALLING SEQUENCE:
%   res=climada_plot(lon,lat,value,markersize,peril_ID,params)
% EXAMPLE:
%   hazard=climada_hazard_load('TCNA_today_small');
%   climada_plot(hazard.lon,hazard.lat,full(hazard.intensity(7121,:)),hazard.peril_ID)
%   climada_hazard_plot(hazard,-1) % the same
%   params=climada_plot; % obtain default parameters
% INPUTS:
%   IF all inputs empty, or lon='params', return default params
%   lon(i), lat(i): longitute and latitude i
%   value(i): the value to be displayed at lon(i)/lat(i)
%   markersize: the size of the 'tiles', one might need to experiment a
%       bit (that's why markersize is not part of params.), as the code
%       tries (hard) to set a reasonabls default (based on resolution).
%       If <0, plot ocean blue and land grey (looks nicer, but takes a bit longer)
%   peril_ID: the (usually 2-char) peril ID, such as 'TC', used to define
%       colorscale etc. as in climada_colormap, see there for all valid
%       value, also such as 'difference' (or ='d') or 'assets'
% OPTIONAL INPUT PARAMETERS:
%   params: a structure with fields (see also entity='params' above):
%    plot_centroids: =1: plot centroids as small red dots
%       =0: do not plot centroids (default)
%    max_value: the maximum value to color, default is max(entity.assets.Value)
%       if =-1, use largest Value in entity.assets.Values, instead of .Value
%    cbar_ylabel: label for the color bar, default 'Value'
%       if empty, indicate entity value locations by black circles, e.g. for
%       climada_plot(hazard);hold on;climada_entity_plot(entity,1,0,[],'')
%    title_str: the title of the plot, if empty, use contents of hazard to define it
%    blue_ocean: plot ocean bliue, if =1 (default=0, since faster)
%    intensity_threshold: the intensity threshold below which we do not plot
%       intensities, default=0.
%    label: a struct with a label to add on the plot (i.e. a place)
%       longitude: the longitude (decimal)
%       latitude: the latitude (decimal)
%       name: the label itself, like 'this city'
%    figure_scale: if =1, plot figure scale (default), =0 not
%    FontSize: the font size, default =12
%    c_ax: just pass on the color range, as [c_ax(1) c_ax(2)]. By default,
%       this is deztermined by the function
% OUTPUTS:
%   creates a figure
%   res: a structure with the core data, i.e. lon,lat and value as shown
%   params: the params structure, filled wit defaults, see
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20180126, initial copy from climada_hazard_plot
%-

res=[]; % init

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('lon','var'),        lon=[];end
if ~exist('lat','var'),        lat=[];end
if ~exist('value','var'),      value=[];end
if ~exist('markersize','var'), markersize=[];end
if ~exist('peril_ID','var'),   peril_ID='';end
if ~exist('params','var'),     params=struct;end

if isempty(lon),lon='params';end

% check for some parameter fields we need
if ~isfield(params,'plot_centroids'), params.plot_centroids=[];end
if ~isfield(params,'cbar_ylabel'),    params.cbar_ylabel='';end
if ~isfield(params,'title_str'),      params.title_str='';end
if ~isfield(params,'blue_ocean'),     params.blue_ocean=[];end
if ~isfield(params,'intensity_threshold'),params.intensity_threshold=[];end
if ~isfield(params,'label'),          params.label=[];end
if ~isfield(params,'max_value'),      params.max_value=[];end
if ~isfield(params,'figure_scale'),   params.figure_scale=[];end
if ~isfield(params,'FontSize'),       params.FontSize=[];end
if ~isfield(params,'units'),          params.units='';end

% PARAMETERS
%
% the threshold up to which the original centroid coordinates are used to
% create the meshgrid (using fewer points for speedup, if above)
% see code below for details (search for max_numel_lonlat)
%
% color of land, only used, if markersize<0
country_color=[.6 .6 .6]; % light gray
%
% populate default parameters in params
if isempty(params.plot_centroids),  params.plot_centroids=0;end
if isempty(params.cbar_ylabel),     params.cbar_ylabel='';end
if isempty(params.blue_ocean),      params.blue_ocean=0;end
if isempty(params.figure_scale),    params.figure_scale=1;end
if isempty(params.FontSize),        params.FontSize=12;end

if strcmpi(lon,'params'),res=params;return;end % special case, return the full params structure

% calculate figure characteristics
scale  = max( max(lon)-min(lon), max(lat)-min(lat));
ax_lim_buffer = scale/20;
ax_lim = [min(lon)-ax_lim_buffer max(lon)+ax_lim_buffer ...
    max(min(lat),-60)-ax_lim_buffer  min(max(lat),95)+ax_lim_buffer];

if isempty(markersize)
    % a crude way to get an appropriate markersize
    markersize=max(2,15-ceil(scale));
    fprintf('markersize = %i\n',markersize);
end

if strcmpi(peril_ID,'d'),peril_ID='difference';end

if isempty(peril_ID)
    % we generate a genuine map
    c_ax = [min(value) max(value)];
    xtickvals = c_ax(1):10:c_ax(2);
    intensity_threshold = 10;
    cmap = makeColorMap([1 0.8 0.2],[0.7098 0.1333 0],[0.3333 0.1020 0.5451],abs(c_ax(2)/5-3));
    cmap = [1 1 1;0.81 0.81 0.81; 0.63 0.63 0.63;cmap];
else
    [cmap,c_ax,xtickvals,params.cbar_ylabel,params.intensity_threshold,params.units]=climada_colormap(peril_ID,'',params.units);
end

if isempty(cmap),return;end

if strcmpi(peril_ID,'difference')
    mimax=max(abs(min(value)),abs(max(value)));
    mimax=ceil(mimax*10)/10; % round
    c_ax=[-mimax mimax];dmimax=mimax/5; % in essence 5=floor(size(cmap,1)/2)
    xtickvals=-mimax:dmimax:mimax;
end
if isempty(params.cbar_ylabel),params.cbar_ylabel=params.units;end
if ~isempty(params.intensity_threshold);value(value<params.intensity_threshold)=NaN;end
if isempty(params.max_value),params.max_value=max(c_ax);end

if sum(abs(value(not(isnan(value)))))>0 % nansum(value)>0
        
    hold off
    if params.blue_ocean
        climada_plot_world_borders(-1,'','',0,[],country_color);
        hold on
    end
    
    [hcbar,~]= plotclr(lon,lat,value,'s'   ,abs(markersize),1          ,c_ax(1),c_ax(2),cmap,0       ,0    );
    %          plotclr(x  ,y  ,v     ,marker,markersize     ,colorbar_on,miv    , mav   ,map ,zero_off,v_exp)
    hold on
    set(gca,'FontSize',params.FontSize)
    set(hcbar,'XTick',xtickvals);
    set(get(hcbar,'xlabel'),'String',params.cbar_ylabel,'FontSize',params.FontSize)
    set(hcbar,'FontSize',params.FontSize)
    
    if ~isempty(params.title_str),title(params.title_str,'FontSize',params.FontSize);end
    xlabel('Longitude','FontSize',params.FontSize);ylabel('Latitude','FontSize',params.FontSize);
    
    axis equal
    axis(ax_lim)
    box % box axes
    climada_plot_world_borders(0.7*sign(markersize),'','',1,[],country_color);
    
    if params.plot_centroids,plot(lon,lat,'.r','MarkerSize',1);end
    
    if ~climada_global.octave_mode && params.figure_scale,climada_figure_scale_add;end
    hold off
    drawnow
else
    fprintf('all intensities < %2.2f\n',params.intensity_threshold);
    return
end

if ~isempty(params.label)
    text(params.label.longitude,params.label.latitude,params.label.name)
    plot(params.label.longitude,params.label.latitude,'xk');
end

set(gcf,'Color',[1 1 1])

end % climada_plot