function [lon_unique, lat_unique, values_sum]= climada_location_sum(lon, lat, values)
% MODULE:
%   core/helper_functions
% NAME:
%   climada_location_sum
% PURPOSE:
%   Sum of values per unique locations
% CALLING SEQUENCE:
%   [lon_unique, lat_unique, values_sum]= climada_location_sum(lon, lat, values)
%EXAMPLE
%   [lon_unique, lat_unique, values_sum]= climada_location_sum([1 1], [2 2], [5 5])
% INPUT:
%   lon: a list of longitude coordinates
%   lat: a list of latitude coordinates
%   value: a list of the same lenght as lon and lat with values                
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   lon_unique: unique longitude coordinates
%   lat_unique: unique longitude coordinates
%   values_sum: summed values per unique location
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150212, init based on climada_assets_sum
%-

if ~climada_init_vars,return;end % init/import global variables

%default values
if ~exist('lon','var'); lon =[]'; end
if ~exist('lat','var'); lat =[]'; end
if ~exist('values','var'); values =[]'; end

lonlat = climada_concatenate_lon_lat(lon, lat);   
[lonlat_unique,~,is_located] = unique(lonlat,'rows','stable');
lon_unique = lonlat_unique(:,1);
lat_unique = lonlat_unique(:,2);

% sum up all values at every unique location
% much faster than looping over every unique location
values_sum = accumarray(is_located,values);

% values_sum = zeros(length(lonlat_unique),1);
% for u_i=1:length(lonlat_unique)
%     values_sum(u_i) = sum(values(is_located == u_i)); 
% end





