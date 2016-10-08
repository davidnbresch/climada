function lon=climada_longitude_unify(lon,maxlon,consistent)
% climada longitude conversion
% MODULE:
%   core
% NAME:
%   climada_longitude_unify
% PURPOSE:
%   make sure longitudes are either all -180..180 or 0..360
% CALLING SEQUENCE:
%   lon=climada_longitude_unify(lon,maxlon)
% EXAMPLE:
%   climada_longitude_unify(180+10,180) % results in -170
% INPUTS:
%   lon: longitude, either scalar or vector
% OPTIONAL INPUT PARAMETERS:
%   maxlon: the maximum longitude, either =180 (range -180..180) or =360 (range 0..360)
%   consistent: only convert, if all elements are converted the same way
%       (i.e. for maxlon=180, if all elements are >180, convert them)
% OUTPUTS:
%   lon: the longitude in range
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20161008
%-

% poor man's version to check arguments and set default values
if ~exist('lon','var'),lon=[];end
if ~exist('maxlon','var'),maxlon=180;end
if ~exist('consistent','var'),consistent=0;end
if isempty(lon),return;end

% PARAMETERS
%

if consistent==0
    if maxlon==180
        lon(lon>180)=lon(lon>180)-360;
    else
        lon(lon<0)=lon(lon<0)+360;
    end
else
    % we convert ALL elements, or none
    if maxlon==180
        gt_pos=find(lon>=180);
        if length(gt_pos)==length(lon) % ALL >=180
            lon=lon-360;
        end
    else
        lt_pos=find(lon<=0);
        if length(lt_pos)==length(lon) % ALL <=0
            lon=lon+360;
        end
    end
end % consistent

end % climada_longitude_unify