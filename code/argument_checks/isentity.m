function ok = isentity(entity)
% check if valid entity struct
% MODULE:
%   core
% NAME:
%   isentity
% PURPOSE:
%   For quick arg checking, defining and standardising entity structs to have the
%   minimum required fields. For the entity, .assets and .damagefunctions
%   are required, function gives warning if entity doesn't contain
%   .measures or .discount fields, but still returns 1. Function calls
%   isassets and isdamagefunctions
% PREVIOUS STEP:
% CALLING SEQUENCE:
%   ok = isentity(entity)
% EXAMPLE:
%   ok = isentity(entity)
% INPUTS:
%   entity:     any struct
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   ok:         1 if input satisfies the conditions to be an entity struct
%               0 otherwise
% MODIFICATION HISTORY:
%   Gilles Stassen, gillesstassen@hotmail.com, 20150826 init
%-
ok = 0; % init

err_msg = '';

if ~exist('entity', 'var'), err_msg = 'invalid argument';           end
if isempty(entity),         err_msg = 'argument empty';             end
if ~isstruct(entity),       err_msg = 'entity must be a structure'; end

if ~isempty(err_msg)
    cprintf([1 0 0],'ERROR: %s\n',err_msg)
    return;
end

% assets and damagefunctions required
if ~isfield(entity,'assets')
    cprintf([1 0 0],'ERROR: entity structure requires ''assets'' field\n')
else
    ok = isassets(entity.assets);
end

if ~isfield(entity,'damagefunctions')
    cprintf([1 0.5 0],'ERROR: entity structure requires ''damagefunctions'' field\n')
else
    ok = isdamagefunctions(entity.damagefunctions);
end

% measures and discount field optional, but give warning
if ok &&(~isfield(entity,'measures') || ~isfield(entity,'discount')) 
    cprintf([1 0.5 0],'WARNING: entity structure missing fields:\n')
    if ~isfield(entity,'measures') 
        cprintf([1 0.5 0],'\t\t - measures\n')
    end
    if ~isfield(entity,'discount') 
        cprintf([1 0.5 0],'\t\t - discount\n')
    end
end

return
    