function params=climada_entity_plot(entity,markersize,params)
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
%   Possible prior call: climada_entity_load;climada_entity_read
% CALLING SEQUENCE:
%   climada_entity_plot(entity,markersize,params)
% EXAMPLE:
%   entity=climada_entity_load
%   climada_entity_plot(entity); % standard use
%   climada_entity_plot; % interactively select
%   params=climada_entity_plot('params') % return parameters
%   params.year_i=1;params.max_value=-1;params.plot_log_value=1;
%   climada_entity_plot(entity,2,params) % today, if entity contains Values
%   params.year_i=-2100;climada_entity_plot(entity,2,params) % 2100
% INPUTS:
%   entity: an entity (see climada_entity_read)
%       > promted for if not given
%       if ='params', just return default parameters
% OPTIONAL INPUT PARAMETERS:
%   markersize: the size of the 'tiles', one might need to experiment a
%       bit (that's why markersize is not part of params.), as the code
%       tries (hard) to set a reasonabls default (based on resolution).
%       If <0, plot ocean blue and land grey (looks nicer, but takes a bit longer)
%   params: a structure with fields (see also entity='params' above):
%    plot_centroids: =1: plot centroids as small red dots
%       =0: do not plot centroids (default)
%    max_value: the maximum value to color, default is max(entity.assets.Value)
%       if =-1, use largest Value in entity.assets.Values, instead of .Value
%    cbar_ylabel: label for the color bar, default 'Value'
%       if empty, indicate entity value locations by black circles, e.g. for
%       climada_hazard_plot(hazard);hold on;climada_entity_plot(entity,1,0,[],'')
%    year: the year we'd like to plot, if entity.assets.Values and .Values_yyyy
%       exist, to plot year instead of the first year (just passes on to
%       year_i=-year, i.e. year overrides year_i). Default=[];
%    year_i: the year index, if entity.assets.Values and .Values_yyyy
%       exist, to plot year_i instead of the first (or only) data in
%       entity.assets.Value. If negative, search for abs(year_i) in
%       Values_yyyy to plot the corresponding year (on output, params.year_i
%       contains the index, not the year any more. See also params.year,
%       which overrides year_i).
%    title_str: the title of the plot, if empty, use contents of
%       entity.assets to define it
%    plot_log_value: if =1, plot log(entity.assets.Value), default=0
% OUTPUTS:
%   params: the params structure, filled wit defaults, see
%   a figure
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141121, ICE initial
% David N. Bresch, david.bresch@gmail.com, 20160514, max_value,cbar_ylabel added
% David N. Bresch, david.bresch@gmail.com, 20160516, added climada_figure_scale_add
% David N. Bresch, david.bresch@gmail.com, 20160516, added option empty cbar_ylabel plus cleanup
% David N. Bresch, david.bresch@gmail.com, 20161001, check for all Values=NaN added
% David N. Bresch, david.bresch@gmail.com, 20161022, markersize<0 allowed
% David N. Bresch, david.bresch@gmail.com, 20161023, land color defined in PARAMETERS
% David N. Bresch, david.bresch@gmail.com, 20161121, check for sum(Values)=0
% David N. Bresch, david.bresch@gmail.com, 20170204, params introduced, and year_i
% David N. Bresch, david.bresch@gmail.com, 20170208, year introduced
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('entity','var'),     entity=[];end
if ~exist('markersize','var'), markersize=[];end
if ~exist('params','var'),     params=struct;end

% check for some parameter fields we need
if ~isfield(params,'plot_centroids'),params.plot_centroids=[];end
if ~isfield(params,'max_value'),     params.max_value=[];end
if ~isfield(params,'cbar_ylabel'),   params.cbar_ylabel='';end
if ~isfield(params,'year'),          params.year=[];end
if ~isfield(params,'year_i'),        params.year_i=[];end
if ~isfield(params,'title_str'),     params.title_str='';end
if ~isfield(params,'plot_log_value'),params.plot_log_value=[];end

% PARAMETERS
%
% the plot is zoomed to the domain of the assets, plus d degress around
d = 1; % degree
%
% color of land, only used, if markersize<0
country_color=[.6 .6 .6]; % light gray
%
% populate default parameters in params
if isempty(params.plot_centroids),  params.plot_centroids=0;end
if isempty(params.cbar_ylabel),     params.cbar_ylabel='Value';end
if isempty(params.year_i),          params.year_i=1;end
if ~isempty(params.year),params.year_i=-params.year;end % year does override year_i
if isempty(params.plot_log_value),  params.plot_log_value=0;end

if strcmpi(entity,'params'),return;end % special case, return the full params structure

% prompt for entity if not given
if isempty(entity),entity=climada_entity_load;end
if ischar(entity),entity=climada_entity_load(entity);end
if isempty(entity),return;end

if sum(isnan(entity.assets.Value))==length(entity.assets.Value)
    fprintf('Warning: all Values=NaN, nothing to plot, aborted\n');
    return
end

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

if isempty(params.title_str) % construct a title
    %if isfield(entity.assets,'admin0_ISO3'),params.title_str=admin0_ISO3;end
    [~,fN]=fileparts(entity.assets.filename);
    params.title_str=strrep(fN,'_entity','');
end
    
plot_Value=entity.assets.Value; % make a copy, in case we take log10

if isfield(entity.assets,'Values') && isfield(entity.assets,'Values_yyyy')
    if params.year_i<0
        pos=find(entity.assets.Values_yyyy==abs(params.year_i));
        if length(pos)==1
            fprintf('Note: year %i index %i in entity.assets.Values_yyyy (%i..%i)\n',abs(params.year_i),pos,min(entity.assets.Values_yyyy),max(entity.assets.Values_yyyy));
            params.year_i=pos;
        else
            fprintf('Error: year %i not found in entity.assets.Values_yyyy (%i..%i)\n',abs(params.year_i),min(entity.assets.Values_yyyy),max(entity.assets.Values_yyyy));
            return
        end
    end
    fprintf('Note: Values(%i,:) for year %i used\n',params.year_i,entity.assets.Values_yyyy(params.year_i));
    plot_Value=entity.assets.Values(params.year_i,:);
    params.title_str=[params.title_str sprintf(' year %i',entity.assets.Values_yyyy(params.year_i))]; % append year
    if params.max_value<0,params.max_value=max(max(entity.assets.Values));end
end

if sum(plot_Value)==0
    fprintf('Warning: all Values sum up to zero, nothing to plot, aborted\n');
    return
end

if params.plot_log_value
    gtz_pos=(plot_Value>0);
    plot_Value(gtz_pos)=log10(plot_Value(gtz_pos));
    if params.max_value>0,params.max_value=log10(params.max_value);end
    plot_log_value_str='log10 ';
else
    plot_log_value_str='';
end

if isempty(params.max_value),params.max_value=max(plot_Value);end
mav=params.max_value*1.1; % to be on the safe side for all values to be plotted

if ~isempty(params.cbar_ylabel)
    [cbar,~]= plotclr(entity.assets.lon, entity.assets.lat, plot_Value, 's',abs(markersize), 1,0,mav,cmap,1,0);
else
    pos=find(plot_Value>0);
    if ~isempty(pos),plot(entity.assets.lon(pos),entity.assets.lat(pos),'ok');end
end
hold on
if ~isempty(params.title_str),title(params.title_str);end
axis equal
xlabel('Longitude')
ylabel('Latitude')
box % box axes

if ~isempty(params.cbar_ylabel)
    Value_unit=climada_global.Value_unit;
    if isfield(entity.assets,'Value_unit')
        try
            Value_unit=entity.assets.Value_unit{1};
        catch
            Value_unit=entity.assets.Value_unit(1);
        end
    end
    set(get(cbar,'ylabel'),'string',[plot_log_value_str params.cbar_ylabel ' (' Value_unit ')'],'fontsize',12);
    %set(get(cbar,'ylabel'),'string',['log(damage) [' Value_unit ']'],'fontsize',12);
end
climada_plot_world_borders(0.7*sign(markersize),'','',0,[],country_color);

set(gca,'xlim',x_range,'ylim',y_range)
if params.plot_centroids,plot(entity.assets.lon, entity.assets.lat,'.r','MarkerSize',1);end

hold on
climada_figure_scale_add
hold off
drawnow

set(gcf,'Color',[1 1 1])

end % climada_entity_plot