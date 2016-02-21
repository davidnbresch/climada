function lon=climada_dateline_resolve(lon,hemisphere,margin)
% climada template
% MODULE:
%   module name
% NAME:
%   climada_dateline_resolve
% PURPOSE:
%   Resolves dateline issue in Longitude coordinates, re-coding them either
%   all W (hence values <-180 possible) or all East (values >180 possible,
%   default). By default, a margin of 20 degrees is used, such that if
%   hemisphere='E', a value of -161 gets converted to +199, 
%   while -160 remains.
% CALLING SEQUENCE:
%   climada_template(param1,param2);
% EXAMPLE:
%   climada_template(param1,param2);
% INPUTS:
%   lon: a (vector of) longitude values (in degrees) to be resolved
% OPTIONAL INPUT PARAMETERS:
%   hemisphere: whether we convert all to 'E' for Eastern or 'W' for
%       Western hemisphere. Default ='E'
%   margin: the margin for wich values are converted, i.e. for what range
%       around the dateline the correction applied. Default =20, such that
%       if hemisphere='E', a value of -161 gets converted to +199, while
%       -160 remains.  
% OUTPUTS:
%   lon: same as on input, with values 'switched' as described
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20160221
%-

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('lon','var'),return;end
if ~exist('hemisphere','var'),hemisphere='E';end
if ~exist('margin','var'),margin=20;end

% PARAMETERS
%

if strcmp(hemisphere,'E')
    % all 'Eastern' hemisphere
    lon(lon<-(180-margin))=lon(lon<-(180-margin))+360;
else
    % all 'Western' hemisphere
    lon(lon> (180-margin))=lon(lon> (180-margin))-360;
end % strcmp(hemisphere,'E')

end % climada_dateline_resolve