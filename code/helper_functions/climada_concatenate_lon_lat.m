function lonlat = climada_concatenate_lon_lat(lon, lat)
% climada_concatenate_lon_lat
% MODULE:
%   climada core
% NAME:
%   climada_concatenate_lon_lat
% PURPOSE:
%   Concatenate two vectors lon and lat into one matrice with lonlat 
% CALLING SEQUENCE:
%   lonlat = climada_concatenate_lon_lat(lon, lat)
% EXAMPLE:
%   lonlat = climada_concatenate_lon_lat(lon, lat)
% INPUTS: 
%   lon            : a vector, either 1xn or nx1
%   lat            : a vector, either 1xn or nx1, must be same numel as lon
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:      
%   lonlat         : a matrix containing lonlat information, where
%                    lonlat(:,1) = lon and lonlat(:,2) = lat
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150724, init
% Lea Mueller, muellele@gmail.com, 20151106, move to core
%-

lonlat = []; %init

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('lon','var'),lon = []; end
if ~exist('lat','var'),lat = []; end

if isempty(lon),return; end
if isempty(lat),return; end

% check that the same numbers of elements in lon and lat
if numel(lon) ~= numel(lat)
    fprintf('Lon and lat have not the same numbers of elements. Unable to proceed.\n')
    return
end

% check lat lon dimension (1xn or nx1), so that the concatenation work for both dimensions
[lon_i, lon_j] = size(lon);
[lat_i, lat_j] = size(lat);

% create vectors in dimension nx1
if lon_i == 1
    lon = reshape(lon,lon_j,1);    
end
if lat_i == 1
    lat = reshape(lat,lat_j,1);
end

% check again
[lon_i, lon_j] = size(lon);
[lat_i, lat_j] = size(lat);
if ~(lon_j == 1  & lat_j == 1)
    fprintf('Error. Please check.\n')
    return
end

  
% create lonlat matrix
lonlat = [lon lat];
        
    




