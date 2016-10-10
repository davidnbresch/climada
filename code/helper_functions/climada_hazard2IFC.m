function [IFC,geo_locations] = climada_hazard2IFC(hazard,geo_locations,return_period,check_plot)
% climada
% MODULE:
%   climada/helper_functions
% NAME:
%   climada_hazard2IFC
% PURPOSE:
%   Obtains the intensity frequency curve (IFC) of a given hazard set.
%   See climada_IFC_plot to plot the IFC structure.
%
%   Subsequent call: climada_IFC_plot
% CALLING SEQUENCE:
%   climada_hazard2IFC(hazard,geo_locations)
% EXAMPLE:
%   climada_hazard2IFC(hazard,[23 94 51]) % pass centroid_IDs
%   geo_locations.lon=14.426;geo_locations.lat=40.821; % pass lat/lon
%   climada_hazard2IFC('',geo_locations)
% INPUTS:
%   hazard: A climada hazard set.
% OPTIONAL INPUT PARAMETERS:
%   geo_location: if not given, centroid ID is set to 1.
%       Can be either: a 1xN vector of centroid_IDs;  Or a structure with
%       fields .lon and .lat to specificy coordinates of interest, i.e.
%       geo_locations.lon=14.426;geo_locations.lat=40.821;
%   return_period: a list of return period at which we calculate the intensities
%   check_plot: set to 1 to show plot, default is 1
% OUTPUTS:
%   IFC(i): A structure (array of) to be used as input to climada_IFC_plot,
%       containing information about the intensity-frequency
%       properties of a given hazard. Fields are:
%       .hazard_comment: string
%       .peril_ID: the peril ID, string
%       .centroid_ID: the (integer) centroid ID
%       .intensity(n): hazard intensty for all n events
%       .return_periods(n): hazard return period for each of the n events
%       .fit_return_periods(m): the m return periods for the fit (m<<n)
%       .intensity_fit(m): the m intensities for the fit
%       .polyfit(2): the polyfit parameters, see code
%       .hist_intensity(N): the N historic intensities (if orig_event_flag...)
%       .hist_return_periods: hazard return period for each of the N historic events
% MODIFICATION HISTORY:
% Gilles Stassen, gillesstassen@hotmail.com, 20150130
% David N. Bresch, david.bresch@gmail.com, 20150309, bugfixes
% Lea Mueller, muellele@gmail.com, 20150318, fit parameters only for positive intensity values
% David N. Bresch, david.bresch@gmail.com, 20150405, IFC as struct array
% Lea Mueller, muellele@gmail.com, 20150504, variable intensity threshold depending on peril_ID
% Gilles Stassen, gillesstassen@hotmail.com, 20150615, check_plot and 'SELECT' option added, bug fix order of isstruct/isvector(geo_loc)
% Lea Mueller, muellele@gmail.com, 20160308, introduce return_period as input
% Lea Mueller, muellele@gmail.com, 20160314, bugfix if hazard has only one lat/lon
% david.bresch@gmail.com, 20160609, bugfix if no historical data
%-

IFC = []; % init

%global climada_global
if ~climada_init_vars , return; end % init/import global variables
if ~exist('hazard','var'), hazard = []; end
if ~exist('geo_locations','var'), geo_locations = 'SELECT'; end
if ~exist('return_period','var'), return_period = []; end
if ~exist('check_plot','var'), check_plot = []; end

% prompt for hazard if not given
hazard = climada_hazard_load(hazard);
if isempty(hazard), return, end 
if isempty(return_period), return_period = [1:1:100 120:20:200 250:50:1000]; end

% prompt for centroid ID if not given
if isempty(geo_locations)
    geo_locations = 1;
    fprintf('Centroid_ID set to %d. Please specify otherwise, if required. \n',geo_locations)
end

if ~isfield(hazard,'orig_event_flag')
    hazard.orig_event_flag=hazard.lon*0;
end

if numel(hazard.lon)==1, geo_locations = 1; end

if strcmp(geo_locations,'SELECT')

    check_plot = 1; %interactive mode, so user will probably want a plot
    msg_str = sprintf('Click on points of interest (press enter when done): ');
    figure
    climada_hazard_plot_hr(hazard,0); drawnow; 
    title({'Max intensity at centroid'; msg_str})
    clear geo_locations % to avoid warning message
    [geo_locations.lon,geo_locations.lat] = ginput; 
    close
    geo_locations.name = {};
    for i = 1:length(geo_locations.lon),geo_locations.name{i} = num2str(i); end
end

if isvector(geo_locations),n_points=length(geo_locations);end
if isstruct(geo_locations),n_points=length(geo_locations.lon);end
if n_points>1
    % recursively call to generate more than one IFC
    for point_i = 1:n_points
        if isstruct(geo_locations)
            geo_location.lon=geo_locations.lon(point_i);
            geo_location.lat=geo_locations.lat(point_i);
        elseif isvector(geo_locations)
            geo_location=geo_locations(point_i);
        end
        IFC_i=climada_hazard2IFC(hazard,geo_location);
        if isempty(IFC),IFC=IFC_i;else IFC(point_i)=IFC_i;end
    end
    if check_plot
        figure; hold on; 
        climada_hazard_plot_hr(hazard,0);
        lon_buf = (max(hazard.lon)-min(hazard.lon))*0.05;
        if isstruct(geo_locations) && isfield(geo_locations,'name')
            text(geo_locations.lon+lon_buf,geo_locations.lat,geo_locations.name,...
                'horizontalalignment','left','verticalalignment','middle',...
                'fontweight','bold','backgroundcolor','w'); 
            hold on
            p = plot(geo_locations.lon,geo_locations.lat,'or');
            set(p,'MarkerFaceColor','r')
        else
            geo_ndx = ismember(hazard.centroid_ID,geo_locations);
            p = plot(hazard.lon(geo_ndx),geo_locations.lat(geo_ndx),'or');
            set(p,'MarkerFaceColor','r')
        end
        title({sprintf('%s max intensity at centroid',hazard.peril_ID); 'Points chosen for IFC struct'})
        box on; hold off
    end
    return % recursive
end % n_points>1

% if input is a centroid ID
if isvector(geo_locations) && ~isstruct(geo_locations)
    poi_ID  = sort(geo_locations);
    poi_ndx = find(ismember(hazard.centroid_ID, poi_ID));
    % does not work for multiple centroid IDs
    %poi_ID  = geo_locations;
    %poi_ndx = find(hazard.centroid_ID == poi_ID);
end

% if input has centroids structure
if isstruct(geo_locations)
    poi_lon = geo_locations.lon;
    poi_lat = geo_locations.lat;
    r = climada_geo_distance(poi_lon, poi_lat,hazard.lon,hazard.lat);
    [~, poi_ndx] = min(r);
    poi_ID  = hazard.centroid_ID(poi_ndx);
    geo_locations.centroid_ID=poi_ID;
end

% use 0 as intensity threshold for tc wind speed
int_threshod = 0;
switch hazard.peril_ID
    case 'TR' % for torrential rain use 10 mm as intensity threshold
        int_threshod = 10;
end
if isfield(hazard,'orig_event_count')
    no_generated = hazard.event_count / hazard.orig_event_count;
else
    no_generated=0;
end

% initiate IFC
IFC.hazard_comment     = hazard.comment;
IFC.peril_ID           = hazard.peril_ID;
IFC.centroid_ID        = poi_ID;

IFC.intensity          = zeros(numel(poi_ID), hazard.event_count);
IFC.return_periods     = zeros(numel(poi_ID), hazard.event_count);

IFC.fit_return_periods = return_period;
IFC.intensity_fit      = zeros(numel(poi_ID), numel(IFC.fit_return_periods));
IFC.polyfit            = zeros(numel(poi_ID), 2);

if isfield(hazard,'orig_event_count')
    IFC.hist_intensity     = zeros(numel(poi_ID), hazard.orig_event_count);
    IFC.hist_return_periods= zeros(numel(poi_ID), hazard.orig_event_count);
end

% calculate for each point of interest
for poi_i = 1:numel(poi_ID)
    %1: intensity
    [IFC.intensity(poi_i,:),int_ndx] = sort(full(hazard.intensity(:,poi_ndx(poi_i))),'descend');
    %IFC.orig_event_flag = hazard.orig_event_flag(int_ndx);
    
    %frequency
    IFC.return_periods(poi_i,:) = 1./cumsum(hazard.frequency(int_ndx));
    %IFC(poi_i).cum_event_freq = cumsum(hazard.frequency(int_ndx).*(no_generated+1));
    
    %2: fitted intensity for given return periods
    rel_indx = IFC.intensity(poi_i,:)> int_threshod;
    IFC.polyfit(poi_i,:)       = polyfit(log10(IFC.return_periods(poi_i,rel_indx)), IFC.intensity(poi_i,rel_indx), 1);
    IFC.intensity_fit(poi_i,:) = polyval(IFC.polyfit(poi_i,:), log10(IFC.fit_return_periods));
    
    if isfield(hazard,'orig_event_count')
        %historic data only
        ori_indx = logical(hazard.orig_event_flag);
        if any(ori_indx)
            [IFC.hist_intensity(poi_i,:),int_ndx] = sort(full(hazard.intensity(ori_indx,poi_ndx(poi_i))),'descend');
            IFC.hist_return_periods(poi_i,:) = 1./cumsum(hazard.frequency(int_ndx)*no_generated);
        end
    end
    
    %fit a Gumbel-distribution
    %8: exceedence frequency
    %IFC.return_freq = 1./climada_global.fit_return_periods;
    %6: intensity for given return periods
    %IFC.intensity_rp(poi_i,:) = polyval(IFC.polyfit(poi_i,:), log(IFC.return_period));
    %7: intensity prob.
    %IFC.return_polyfit(poi_i,:) = polyfit(log(IFC.cum_event_freq(poi_i,:)), IFC.intensity(poi_i,:), 1);
    %IFC.return_polyval(poi_i,:) = polyval(IFC.return_polyfit(poi_i,:), log(IFC.return_freq(poi_i,:)));
end
IFC.intensity_fit(IFC.intensity_fit<0) = 0;

if check_plot % for the case n_points = 1
    figure; hold on
    climada_hazard_plot_hr(hazard,0); hold on
    lon_buf = (max(hazard.lon)-min(hazard.lon))*0.05;
    if isstruct(geo_locations) && isfield(geo_locations,'name')
        text(geo_locations.lon,geo_locations.lat+lon_buf,geo_locations.name,...
            'horizontalalignment','center','verticalalignment','top',...
            'fontweight','bold','backgroundcolor','w')
    end
    title({sprintf('%s max intensity at centroid',hazard.peril_ID); 'Points chosen for IFC struct'})
    plot(poi_lon,poi_lat,'xy')
end

end % climada_hazard2IFC
