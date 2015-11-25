function distance_km=climada_distance2coast_km(lon,lat,check_plot)
% climada distance km coast
% NAME:
%   climada_distance2coast
% PURPOSE:
%   calculate distance to coast in km (approx.)
%
%   Run climada_shaperead('SYSTEM_COASTLINE') in case the coastline does
%   not exist (requires the climada module country_risk from
%   https://github.com/davidnbresch/climada_module_country_risk 
% CALLING SEQUENCE:
%   distance_km=climada_distance2coast_km(lon,lat,check_plot)
% EXAMPLE:
%   distance_km=climada_distance2coast_km(lon,lat)
% INPUTS:
%   lon: vector of longitues
%   lat: vector of latitudes
% OPTIONAL INPUT PARAMETERS:
%   check_plot: =1: show circle plot for check
%       =0: no plot (default)
% OUTPUTS:
%   distance_km: distance to coast in km for each lat/lon
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141225, initial
%-

distance_km=[];

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('lon','var'),return;end
if ~exist('lat','var'),return;end
if ~exist('check_plot','var'),check_plot=0;end

% locate the module's data
%module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% PARAMETERS


% check for the map_shape_file
if ~exist(climada_global.coastline_file,'file')
    % try to re-create it
    shapes=climada_shaperead('SYSTEM_COASTLINE');
end

if ~exist(climada_global.coastline_file,'file')
    % it does definitely not exist
    fprintf('ERROR %s: file with coastline information not found: %s\n',mfilename,climada_global.coastline_file);
    fprintf(' - consider installing climada module country_risk from\n');
    fprintf('   https://github.com/davidnbresch/climada_module_country_risk\n');
    return
end

load(climada_global.coastline_file) % contains coastline as 'Point'

cos_lat=cos(lat./180.*pi);
distance_km=cos_lat*0+1e10; % init with large value

for shape_i=1:length(shapes) 
    % usually one shape, but this way, it would work for multiple ones,
    % e.g. if sdhapes would be rather 'Line' than 'Point' 
    for ll_i=1:length(cos_lat)
        dist2=min(( (shapes(shape_i).X-lon(ll_i)).*cos_lat(ll_i) ).^2 + (shapes(shape_i).Y-lat(ll_i)).^2);
        distance_km(ll_i)=min(distance_km(ll_i),dist2);
    end % ll_i
end % shape_i

distance_km=sqrt(distance_km)*111.12; % convert to km (approx.)

if check_plot,climada_circle_plot(distance_km,lon,lat),end

return
