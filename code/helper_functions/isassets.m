function ok = isassets(assets)
% check if valid assets struct
% MODULE:
%   core
% NAME:
%   isassets
% PURPOSE:
%   For quick arg checking, defining and standardising assets structs to have the
%   minimum required fields
% PREVIOUS STEP:
% CALLING SEQUENCE:
%   ok = isassets(assets)
% EXAMPLE:
%   ok = isassets(assets)
% INPUTS:
%   assets:     any struct
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   ok:         1 if input satisfies the conditions to be an assets struct
%               0 otherwise
% MODIFICATION HISTORY:
%   Gilles Stassen, gillesstassen@hotmail.com, 20150826 init
%-

ok = 0; % init

err_msg = '';

if ~exist('assets', 'var'), err_msg = 'invalid argument';           end
if isempty(assets),         err_msg = 'argument empty';             end
if ~isstruct(assets),       err_msg = 'assets must be a structure'; end

if ~isempty(err_msg)
    cprintf([1 0 0],'ERROR: %s\n',err_msg)
    return;
end

% required fields which define an assets struct
flds =  { 
    'lon'        
    'lat'        
    'Value'
    'DamageFunID'
    'Deductible'
    'Cover'
    'reference_year'};

ok = 1; % re-init
missing_flds = {}; % init
for fld_i = 1:length(flds)
    if ~isfield(assets,flds(fld_i))
        ok = 0;
        missing_flds{end+1} = flds{fld_i};
    end
end

if ~ok
    cprintf([1 0 0],'ERROR: invalid assets structure - missing required fields:\n')
    for fld_i =1:length(missing_flds)
        fprintf('\t\t- %s\n',missing_flds{fld_i})
    end
end

return
    