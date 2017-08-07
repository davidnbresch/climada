function damagefunctions = climada_damagefunctions_complete(damagefunctions)
% climada damagefunctions read import check complete
% NAME:
%   climada_damagefunctions_complete
% PURPOSE:
%   check for completeness of an damagefunctions structure, i.e. that all
%   fields are there and populated with default values (this speeds up all
%   later cimada calls, as we do not need to run many isfield commands
%   etc). This code also makes sure all arrays in damagefunctions are 1xN (they come
%   as Nx1 from Excel read).
%
%   This code is kept as a separate function (i.e. called from but not part of
%   climada_damagefunctions_read) in order to allow calling it for damagefunctions not read
%   from an Excel file, e.g. if a user constructs the entity structure
%   him/herself.
%
%   called from: climada_damagefunctions_read
% CALLING SEQUENCE:
%   damagefunctions = climada_damagefunctions_complete(damagefunctions)
% EXAMPLE:
%   entity.damagefunctions=climada_damagefunctions_complete(entity.damagefunctions)
% INPUTS:
%   damagefunctions: the damagefunctions structure of entity.damagefunctions, 
%       see climada_entity_read
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%    damagefunctions: same as input, with fields completed
% MODIFICATION HISTORY:
% david.bresch@gmail.com, 20160918, initial
% david.bresch@gmail.com, 20170807, fields transposed, see cldaco_LOCAL_TRANSPOSE
%-

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('damagefunctions','var'),damagefunctions=[];end
if isempty(damagefunctions),return;end

% PARAMETERS
%

% check for minimal field requiremenets
if ~isfield(damagefunctions,'DamageFunID'),fprintf('Severe warning: DamageFunID missing, invalid damagefunctions structure\n');end
if ~isfield(damagefunctions,'Intensity'),fprintf('Severe warning: Intensity missing, invalid damagefunctions structure\n');end
if ~isfield(damagefunctions,'MDD'),fprintf('Severe warning: MDD missing, invalid damagefunctions structure\n');end
           
% add missing fields
if ~isfield(damagefunctions,'filename'),  damagefunctions.filename = 'undefined';end
if ~isfield(damagefunctions,'PAA'),       damagefunctions.PAA      = damagefunctions.MDD*0+1;end
if ~isfield(damagefunctions,'peril_ID'),  damagefunctions.peril_ID = repmat({'XX'},size(damagefunctions.MDD));end
if ~isfield(damagefunctions,'Intensity_unit'),damagefunctions.Intensity_unit = repmat({'-'},size(damagefunctions.MDD));end
if ~isfield(damagefunctions,'name'),      damagefunctions.name     = repmat({'undef'},size(damagefunctions.MDD));end
if ~isfield(damagefunctions,'datenum'),   damagefunctions.datenum  = repmat(now,size(damagefunctions.MDD));end

% make sure we have Nx1 arrays
if isfield(damagefunctions,'DamageFunID'),damagefunctions.DamageFunID = cldaco_LOCAL_TRANSPOSE(damagefunctions.DamageFunID);end
if isfield(damagefunctions,'Intensity'),  damagefunctions.Intensity   = cldaco_LOCAL_TRANSPOSE(damagefunctions.Intensity);end
if isfield(damagefunctions,'MDD'),        damagefunctions.MDD         = cldaco_LOCAL_TRANSPOSE(damagefunctions.MDD);end
if isfield(damagefunctions,'PAA'),        damagefunctions.PAA         = cldaco_LOCAL_TRANSPOSE(damagefunctions.PAA);end
if isfield(damagefunctions,'peril_ID'),   damagefunctions.peril_ID    = cldaco_LOCAL_TRANSPOSE(damagefunctions.peril_ID);end
if isfield(damagefunctions,'Intensity_unit'),damagefunctions.Intensity_unit =cldaco_LOCAL_TRANSPOSE(damagefunctions.Intensity_unit);end
if isfield(damagefunctions,'name'),       damagefunctions.name        = cldaco_LOCAL_TRANSPOSE(damagefunctions.name);end
if isfield(damagefunctions,'datenum'),    damagefunctions.datenum     = cldaco_LOCAL_TRANSPOSE(damagefunctions.datenum);end
           
end % climada_damagefunctions_complete

function arr=cldaco_LOCAL_TRANSPOSE(arr)
%if size(arr,1)<size(arr,2),arr=arr';end % until 20170807
if size(arr,1)>size(arr,2),arr=arr';end
end % cldaco_LOCAL_TRANSPOSE