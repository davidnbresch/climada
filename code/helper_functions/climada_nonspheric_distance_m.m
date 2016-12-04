function [fDistance_km,GridVect] = climada_nonspheric_distance_m(fLon1,fLat1,fLon2,fLat2,CUID, inreach)
% This function calculates the distance for each individual gridpoint from
% the TC center. Distance differences in x direction, depending on
% latitude, are normalized in the whole inreach-box with the value at the
% TC-Center
%
%--------------------------------------------------------------------------
% Modified Haversine Formula to normalize distance differences in y
% (longitudinal) direction at different latitudes 
%--------------------------------------------------------------------------
%-

if ~exist('CUID'   , 'var'), CUID    = [] ; end
if ~exist('inreach', 'var'), inreach = [] ; end

if isempty(CUID)   , CUID    = ones(length(fLon1),1); end
if isempty(inreach), inreach = ones(length(fLon1),1); end

    
% Earth's radius in km
R = 6371;   

%abs() makes it compatible for north and south hemisphere
latrad    = degtorad(abs(fLat2));  %previous version named deg2rad(abs(fLat2));  
% deg2rad(1) = distance for 1 deg longitude on given latitude
delta_lon = 0.0174532925199433;     
% square of half the chord length between the points
a         = cos(latrad)^2 * sin(delta_lon/2)^2;       
% angular distance in radians
c         = 2 * atan2(sqrt(a), sqrt(1-a));              

% distance in m
lon_norm = (R * c)*1000; % in m             
lat_norm = 111194.926644559;

GridVect            = zeros(CUID,2);
GridVect(inreach,1) = fLon1 - fLon2;
GridVect(inreach,2) = fLat1 - fLat2;

% fDistance_m = sqrt(((fLon1-fLon2).*lon_norm).^2 + ((fLat1-fLat2).*lat_norm).^2);
fDistance_km          = zeros(CUID,1);
fDistance_km(inreach) = (sqrt((((GridVect(inreach,1)).*lon_norm).^2 + ...
                        ((GridVect(inreach,2)).*lat_norm).^2)))./1000;
end % climada_nonspheric_distance_m