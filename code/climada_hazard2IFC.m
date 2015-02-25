function IFC = climada_hazard2IFC(hazard,geo_locations)
% climada
% NAME:
%   climada_IFC_plot
% PURPOSE:
%   Plots the intensity frequency curve of a given hazard set. See
%   climada_hazard2IFC to create the IFC structure to be plotted from a
%   climada hazard set.
% CALLING SEQUENCE:
%   climada_IFC_plot(IFC, hist_check, prob_check,check_log,color_index)
% EXAMPLE:
%   climada_hazard2IFC(hazard, [23 94 51])
%   climada_hazard2IFC
% INPUTS:
%   hazard:       A climada hazard set.
%   geo_location: Can be either: a 1xN vector of centroid_IDs; a 2xN array
%                 of the form [lon lat] where the 1xN lon and 1xN lat 
%                 vectors specify the longitude and latitude coords of N 
%                 locations of interest; or a struct with fields .lon & .lat
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   IFC:          A structure to be used as input to climada_IFC_plot,
%                 containing information about the intensity-frequency
%                 properties of a given hazard
% MODIFICATION HISTORY:
%   Gilles Stassen, gillesstassen@hotmail.com, 20150130
%-

IFC = [];

global climada_global
if ~climada_init_vars                , return                 ; end % init/import global variables
if ~exist('hazard'            ,'var'), hazard             = []; end
if ~exist('geo_locations'     ,'var'), geo_locations      = []; end

if isempty(hazard) % local GUI
    hazard               = [climada_global.data_dir filesep 'hazards' filesep '*.mat'];
    default_hazard       = [climada_global.data_dir filesep 'hazards' filesep 'select hazard .mat'];
    [filename, pathname] = uigetfile(hazard, 'Select hazard event set for EDS calculation:',default_hazard);
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard=fullfile(pathname,filename);
    end
end

% load the hazard set, if a filename has been passed
if ~isstruct(hazard)
    hazard_file=hazard;
    hazard=[];
    load(hazard_file);
end

if isempty(geo_locations)
    prompt   ='Choose centroid ID of interest:';
    name     ='Centroid ID';
    default_ans = {'1'};
    answer = inputdlg(prompt,name,1,default_ans);
    answer = cell2mat(answer);
    poi_ID = sscanf(answer,'%d');
    poi_ndx = find(hazard.centroid_ID == poi_ID);
else
    
    if isvector(geo_locations) && ~isstruct(geo_locations)
        poi_ID = geo_locations;
        poi_ndx = find(hazard.centroid_ID == poi_ID);
    end
    
    % if input has centroids structure
    if isstruct(geo_locations)
        poi_lon = geo_locations.lon;
        poi_lat = geo_locations.lat;
        r = climada_geo_distance(poi_lon, poi_lat,hazard.lon,hazard.lat);
        [~, poi_ndx] = min(r);
        
        poi_ID = hazard.centroid_ID(poi_ndx);
    end
    
    % if input is Nx2 array of lon lat coords
    if numel(geo_locations)>1 && length(geo_locations) == 2
        poi_lon = geo_locations(:,1);
        poi_lat = geo_locations(:,2);
        r = climada_geo_distance(poi_lon, poi_lat,hazard.lon,hazard.lat);
        [~, poi_ndx] = sort(r);
        
        poi_ID = hazard.centroid_ID(r_min_ndx);
    end    
end

no_generated             = hazard.event_count / hazard.orig_event_count;

% calculate for each point of interest
for poi_i = 1:numel(poi_ID)
    IFC(poi_i).hazard_comment = hazard.comment;
    IFC(poi_i).peril_ID = hazard.peril_ID;
    IFC(poi_i).centroid_ID = poi_ID(poi_i);
    %1: intensity
    [IFC(poi_i).intensity(1,:),int_ndx]  =   sort(full(hazard.intensity(1:end,poi_ndx(poi_i))),'descend');
    IFC(poi_i).orig_event_flag      =   hazard.orig_event_flag(int_ndx);
    
    %frequency
    IFC(poi_i).cum_event_freq    = cumsum(hazard.frequency(int_ndx).*(no_generated+1));
    
    %2: fitted intensity
    IFC(poi_i).polyfit      = polyfit(log(IFC(poi_i).cum_event_freq), IFC(poi_i).intensity, 1);
    IFC(poi_i).polyval      = polyval(IFC(poi_i).polyfit, log(IFC(poi_i).cum_event_freq));
    
    % fit a Gumbel-distribution
    %8: exceedence frequency
    IFC(poi_i).return_freq= 1./climada_global.DFC_return_periods;
    %6: intensity hist.
    IFC(poi_i).return_polyval = polyval(IFC(poi_i).polyfit, log(IFC(poi_i).return_freq));
    
    %7: intensity prob.
    IFC(poi_i).return_polyfit = polyfit(log(IFC(poi_i).cum_event_freq), IFC(poi_i).intensity, 1);
    IFC(poi_i).return_polyval = polyval(IFC(poi_i).return_polyfit, log(IFC(poi_i).return_freq));
end