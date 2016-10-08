function ok = iscentroids(centroids)
% check if valid centroids struct
% MODULE:
%   core
% NAME:
%   iscentroids
% PURPOSE:
%   For quick arg checking, defining and standardising centroids structs to have the
%   minimum required fields
% PREVIOUS STEP:
% CALLING SEQUENCE:
%   ok = iscentroids(centroids)
% EXAMPLE:
%   ok = iscentroids(centroids)
% INPUTS:
%   centroids:     any struct
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   ok:         1 if input satisfies the conditions to be an centroids struct
%               0 otherwise
% MODIFICATION HISTORY:
%   Gilles Stassen, gillesstassen@hotmail.com, 20150826 init
%-

ok = 0; % init

if ~exist('centroids', 'var'), return; end
if isempty(centroids),         return; end
if ~isstruct(centroids),       return; end

% required fields
flds =  { 
    'lon'        
    'lat'        
    'centroid_ID'        
    'onLand'        };

for fld_i = 1:length(flds)
    if ~isfield(centroids,flds(fld_i))
        return;
    end
end

ok = 1;

return
    