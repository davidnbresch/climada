function [X, Y, gridded_VALUE] = climada_gridded_VALUE(values,centroids,interp_method,npoints,stencil_ext)
% NAME:
%   climada_gridded_VALUE
% PURPOSE:
%   gridded data of wind speed in hazard.intensity 
%   for creating color plot
% CALLING SEQUENCE:
%   climada_gridded_VALUE(values,centroids,interp_method,npoints,stencil_ext)
% EXAMPLE:
%   climada_gridded_VALUE(values,centroids)
% INPUTS:
%   values
%   centroids
% OPTIONAL INPUT PARAMETERS:
%   interp_method: method in griddata, like 'linear', 'cubic',...
%   npoints: the number of points used
%   stencil_ext: to extend the stencil range (in units of the target grid,
%       default=0
% OUTPUTS:
%   X, Y, gridded Value
% RESTRICTIONS:
%   none
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20120430
% Lea Mueller, 17.5.2011
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% set defaults
if ~exist('values'        ,'var'), values         = []; end
if ~exist('centroids'     ,'var'), fprintf('Centroids not specified\n'), return; end
if ~exist('interp_method' ,'var'), interp_method  = []; end
if ~exist('npoints'       ,'var'), npoints        = []; end
if ~exist('stencil_ext')         , stencil_ext    = []; end

% PARAMETERS
% set defaults
if isempty(interp_method ), interp_method = 'linear'    ;end
if isempty(npoints       ), npoints       =  199        ;end
if isempty(stencil_ext   ), stencil_ext   =  0          ;end
%
% to avoid masking areas far away from CalcUnits
no_mask = 0;
X = [];
Y = [];
gridded_VALUE = [];

if isfield(centroids,'Longitude')
    lon = centroids.Longitude;
    lat = centroids.Latitude;
elseif isfield(centroids,'lon')
    lon = centroids.lon;
    lat = centroids.lat;
else
    fprintf('Longitude, latitude not gitven. Unable to proceed.\n');
    return
end



% define grid if not existing or if npoints>0
npoints = abs(npoints); % force positive
xx      = linspace(min(lon)-1, max(lon)+1, npoints);
yy      = linspace(min(lat)-1, max(lat)+1, npoints);
[X,Y]   = meshgrid(xx,yy); % construct regular grid
%%fprintf('preparing color plot...\n');
dlon    = abs(max(lon)-min(lon));
dlat    = abs(max(lat)-min(lat));
xstencil_width = floor(npoints/(dlon+2)/2)+1+stencil_ext;
ystencil_width = floor(npoints/(dlat+2)/2)+1+stencil_ext;
xstencil       =-xstencil_width:1:xstencil_width; % figure out the stencil, based on npoints
ystencil       =-ystencil_width:1:ystencil_width; % figure out the stencil, based on npoints
if no_mask
    mask=X*0; % reset mask
else
    mask=X+NaN; % mask points by setting them to NaN

    for ii=1:length(lon)
        [mm,ix]=min(abs(xx-lon(ii)));
        [mm,iy]=min(abs(yy-lat(ii)));
        mask(ystencil+iy,xstencil+ix)=0; % make center and surrounding points visible
    end
end % no_mask


gridded_VALUE = griddata(lon,lat,values,X,Y,interp_method)+mask; % interpolate to grid 'linear'
% gridded_VALUE(gridded_VALUE == 0) = nan;