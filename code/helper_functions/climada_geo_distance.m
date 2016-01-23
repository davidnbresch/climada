function dist_m = climada_geo_distance(lon1,lat1,lon2,lat2)
% calculate distance between to points in meters
% NAME:
%   climada_geo_distance
% PURPOSE:
%   calculate distance between two points or a point and a series of points
% CALLING SEQUENCE:
%   dist_m=climada_geo_distance(lon1,lat1,lon2,lat2);
% EXAMPLE:
%   dist_m=climada_geo_distance(0.0,45.0,1.0,45.0); % two points
%   dist_m=climada_geo_distance(0.0,45.0,[1.0 2.0 2.0],[45.0 45.0 46.0]); % point and a series of points
% INPUTS:
%   lon1,lat1: longitude and latitude of first point
%   lon2,lat2: longitude and latitude of second point
%       or, if vectors of the same length, series of points
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   dist_m: distance(s) between points in [m]
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091227
%-

dist_m=[]; % init

% check arguments
if ~exist('lon1'),fprintf('ERROR: enter lon1\n');return;end
if ~exist('lat1'),fprintf('ERROR: enter lat1\n');return;end
if ~exist('lon2'),fprintf('ERROR: enter lon2\n');return;end
if ~exist('lat2'),fprintf('ERROR: enter lat2\n');return;end
if length(lon2)~=length(lat2),fprintf('ERROR: 2nd point vector not same length\n');return;end

% PARAMETERS
%
% constant to convert one degree latitude to km
degree2km = 111.12;

dist_m    =  sqrt( ((lon2-lon1).*cos(lat1./180.*pi) ).^2 + ...
                    (lat2-lat1)                      .^2)...
             .* 111.12 * 1000; % [in meter]

return
