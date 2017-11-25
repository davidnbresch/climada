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
%       ='plot': also plot the data in this routine (often handy)
%   npoints: the number of points used, default =499
%   stencil_ext: to extend the stencil range (in units of the target grid,
%       default=0
% OUTPUTS:
%   X, Y, gridded Value
% RESTRICTIONS:
%   none
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20120430
% Lea Mueller, muellele@gmail.com, 20110517
% David N. Bresch, david.bresch@gmail.com, 20161006, npoints default=499
% David N. Bresch, david.bresch@gmail.com, 20171123, interp_method='plot'
%-

X=[];Y=[];gridded_VALUE=[]; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% set defaults
if ~exist('values'        ,'var'), values         = []; end
if ~exist('centroids'     ,'var'), centroids      = []; end
if ~exist('interp_method' ,'var'), interp_method  = []; end
if ~exist('npoints'       ,'var'), npoints        = []; end
if ~exist('stencil_ext'   ,'var'), stencil_ext    = []; end

% PARAMETERS
% set defaults
if isempty(interp_method ), interp_method = 'linear'    ;end
if isempty(npoints       ), npoints       =  499        ;end % 199 until 20161006
if isempty(stencil_ext   ), stencil_ext   =  0          ;end
%
% to avoid masking areas far away from CalcUnits
% no_mask = 1;
no_mask = 0;

check_plot=0; % default
if strcmpi(interp_method,'plot'),check_plot=1;interp_method = 'linear';end

lon = centroids.lon;
lat = centroids.lat;

% define grid if not existing or if npoints>0
npoints = abs(npoints); % force positive
xx      = linspace(min(lon)-1, max(lon)+1, npoints);
yy      = linspace(min(lat)-1, max(lat)+1, npoints);
[X,Y]   = meshgrid(xx,yy); % construct regular grid
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
        [~,ix]=min(abs(xx-lon(ii)));
        [~,iy]=min(abs(yy-lat(ii)));
        mask(ystencil+iy,xstencil+ix)=0; % make center and surrounding points visible
    end
end % no_mask


gridded_VALUE = griddata(lon,lat,values,X,Y,interp_method)+mask; % interpolate to grid 'linear'
% gridded_VALUE(gridded_VALUE == 0) = nan;

if check_plot
    %gridded_VALUE(gridded_VALUE<0.1) = NaN; % avoid tiny values
    contourf(X, Y, gridded_VALUE,200,'linecolor','none')
    hold on
    climada_plot_world_borders(2,'','',0,[],[0 0 0])
    colorbar
    caxis([min(values) max(values)])
end

end % climada_gridded_VALUE