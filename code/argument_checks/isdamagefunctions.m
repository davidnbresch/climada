function ok = isdamagefunctions(damagefunctions)
% check if valid damagefunctions struct
% MODULE:
%   core
% NAME:
%   isdamagefunctions
% PURPOSE:
%   For quick arg checking, defining and standardising damagefunctions 
%   structs to have the minimum required fields.
% PREVIOUS STEP:
% CALLING SEQUENCE:
%   ok = isdamagefunctions(damagefunctions)
% EXAMPLE:
%   ok = isdamagefunctions(damagefunctions)
% INPUTS:
%   damagefunctions:     any struct
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   ok:         1 if input satisfies the conditions to be an entity struct
%               0 otherwise
% MODIFICATION HISTORY:
%   Gilles Stassen, gillesstassen@hotmail.com, 20150826 init
%-
ok = 0; % init

err_msg = '';

if ~exist('damagefunctions', 'var'), err_msg = 'invalid argument';           end
if isempty(damagefunctions),         err_msg = 'argument empty';             end
if ~isstruct(damagefunctions),       err_msg = 'damagefunctions must be a structure'; end

if ~isempty(err_msg)
    cprintf([1 0 0],'ERROR: %s\n',err_msg)
    return;
end

% required fields
flds =  { 
    'DamageFunID'        
    'Intensity'        
    'MDD'
    'PAA'
    'peril_ID'  };

ok = 1;
missing_flds = {}; % init
for fld_i = 1:length(flds)
    if ~isfield(damagefunctions,flds(fld_i))
        ok = 0;
        missing_flds{end+1} = flds{fld_i};
    end
end

if ~ok
    cprintf([1 0 0],'ERROR: invalid damagefunctions structure - missing required fields:\n')
    for fld_i =1:length(missing_flds)
        fprintf('\t\t- %s\n',missing_flds{fld_i})
    end
end

return
    