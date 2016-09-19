function assets = climada_assets_complete(assets)
% climada assets read import check complete
% NAME:
%   climada_assets_complete
% PURPOSE:
%   check for completeness of an assets structure, i.e. that all
%   fields are there and populated with default values (this speeds up all
%   later cimada calls, as we do not need to run many isfield commands
%   etc). This code also makes sure all arrays in assets are 1xN (they come
%   as Nx1 from Excel read).
%
%   This code is kept as a separate function (i.e. called from but not part of
%   climada_assets_read) in order to allow calling it for assets not read
%   from an Excel file, e.g. if a user constructs the entity structure
%   him/herself.
%
%   called from: climada_assets_read
% CALLING SEQUENCE:
%   assets = climada_assets_complete(assets)
% EXAMPLE:
%   assets = climada_assets_complete(assets)
% INPUTS:
%   assets: the assets structure of entity.assets, see climada_entity_read
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%    assets: same as input, with fields completed
% MODIFICATION HISTORY:
% david.bresch@gmail.com, 20160918, initial
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('assets','var'),assets=[];end
if isempty(assets),return;end

% PARAMETERS
%

% check for minimal field requiremenets
if ~isfield(assets,'lon'),fprintf('Severe warning: Longitude (lon) missing, invalid assets structure\n');end
if ~isfield(assets,'lat'),fprintf('Severe warning: Latitude (lat) missing, invalid assets structure\n');end
if ~isfield(assets,'Value'),fprintf('Severe warning: Value missing, invalid assets structure\n');end

% make sure we have 1xN arrays (for the core fields)
assets.lon                                         =clasco_LOCAL_TRANSPOSE(assets.lon);
assets.lat                                         =clasco_LOCAL_TRANSPOSE(assets.lat);
assets.Value                                       =clasco_LOCAL_TRANSPOSE(assets.Value);

% add missing fields
if ~isfield(assets,'filename'),assets.filename             ='undefined';end
if ~isfield(assets,'reference_year'),assets.reference_year =climada_global.present_reference_year;end
if ~isfield(assets,'Deductible'),assets.Category_ID        =assets.lon*0;end
if ~isfield(assets,'Cover'),assets.Cover                   =assets.Value;end
if ~isfield(assets,'DamageFunID'),assets.Category_ID       =assets.lon*0+1;end
if ~isfield(assets,'Category_ID'),assets.Category_ID       =assets.lon*0+1;end
if ~isfield(assets,'Region_ID'),assets.Category_ID         =assets.lon*0+1;end
if ~isfield(assets,'Value_unit'),assets.Value_unit         =repmat({climada_global.Value_unit},size(assets.Value));end
    
% make sure we have 1xN arrays (for the all the other fields)
if isfield(assets,'Deductible'), assets.Deductible =clasco_LOCAL_TRANSPOSE(assets.Deductible);end
if isfield(assets,'Cover'),      assets.Cover      =clasco_LOCAL_TRANSPOSE(assets.Cover);end
if isfield(assets,'DamageFunID'),assets.DamageFunID=clasco_LOCAL_TRANSPOSE(assets.DamageFunID);end
if isfield(assets,'Category_ID'),assets.Category_ID=clasco_LOCAL_TRANSPOSE(assets.Category_ID);end
if isfield(assets,'Region_ID'),  assets.Region_ID  =clasco_LOCAL_TRANSPOSE(assets.Region_ID);end
if isfield(assets,'Value_unit'), assets.Value_unit =clasco_LOCAL_TRANSPOSE(assets.Value_unit);end
    
end % climada_assets_complete

function arr=clasco_LOCAL_TRANSPOSE(arr)
if size(arr,1)>size(arr,2),arr=arr';end
end % clasco_LOCAL_TRANSPOSE