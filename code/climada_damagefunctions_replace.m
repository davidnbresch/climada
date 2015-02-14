function entity=climada_damagefunctions_replace(entity,damagefunctions)
% climada
% NAME:
%   climada_damagefunctions_replace
% PURPOSE:
%   Given an encoded entity, replace select damagefunctions with the ones
%   provided. The code does in fact NOT delete any damage function, but set
%   the DamageFunID of the one replaced to a new number.
%
%   If entity contains a damage function with peril_ID 'TC' and
%   DamageFunID=1 and damagefunctions also contains a damage function with
%   peril_ID 'TC' and DamageFunID=1, the damage function in damagefunctions
%   is added to entity damagefunctions and the previous damagefunction
%   TC_001 is moved to TC_nnn, where nnn is a not yet used DamageFunID. But
%   in case all MDD and PAA values of the existing damagefunction are
%   exactly the same, the curve is NOT replaced (ensures we do not
%   endlessly increase the number of damagefunctions on subsequent calls
%   unnecessarily).
%
%   See also climada_damagefunctions_read, climada_damagefunctions_generate
%   and climada_damagefunctions_plot
% CALLING SEQUENCE:
%   entity=climada_damagefunctions_replace(entity,damagefunctions)
% EXAMPLE:
%   entity=climada_damagefunctions_replace(entity,damagefunctions);
% INPUTS:
%   entity: an entity, see climada_entity_read
%       > promted for if not given (calling climada_entity_load, not
%       climada_entity_read)
%   damagefunctions: see climada_damagefunctions_read, a struct with damage
%       functions. If one does not need to pass on new damage functions,
%       one can also pass the damagefunctions_map in this variable (see 2nd
%       EXAMPLE above). This option comes handy, if one stores several
%       damagefunctions in entity.damagefunctions and uses this code to
%       switch between.
%       No way to prompt for, hence aborted if not provided
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   entity: the entity with damagefunctions added (and DamageFunID of
%       previous - replaced - damage functions set to a new number)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150212, initial
%-

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('damagefunctions','var'),return;end

% PARAMETERS
%

% prompt for entity if not given
if isempty(entity),entity=climada_entity_load;end
if isempty(entity),return;end

if isfield(damagefunctions,'peril_ID')
    % since there might be the same DamageFunID for two different
    % perils, re-define the damage function
    for i=1:length(damagefunctions.DamageFunID)
        unique_ID{i}=sprintf('%s %3.3i',damagefunctions.peril_ID{i},damagefunctions.DamageFunID(i));
    end % i
else
    for i=1:length(entity.damagefunctions.DamageFunID)
        unique_ID{i}=sprintf('%3.3i',damagefunctions.DamageFunID(i));
    end % i
end

unique_IDs=unique(unique_ID);
next_ID=max(max(entity.damagefunctions.DamageFunID),max(damagefunctions.DamageFunID))+1;

for ID_i=1:length(unique_IDs)
    dmf_pos=strmatch(unique_IDs{ID_i},unique_ID);
    if ~isempty(dmf_pos)
        % locate existing
        old_DamageFunID_pos=find(entity.damagefunctions.DamageFunID==damagefunctions.DamageFunID(dmf_pos(1)));
        if isfield(entity.damagefunctions,'peril_ID') && isfield(damagefunctions,'peril_ID')
            old_peril_ID_pos=strcmp(entity.damagefunctions.peril_ID(old_DamageFunID_pos),damagefunctions.peril_ID{dmf_pos(1)});
            old_DamageFunID_pos=old_DamageFunID_pos(old_peril_ID_pos);
        end
        
        % check whether replacement is needed (unless the existing curve is
        % exactly the same)
        replace_it=1; % assume we replace, now check for reasons why not
        
        old_MDD=entity.damagefunctions.MDD(old_DamageFunID_pos);
        new_MDD=damagefunctions.MDD(dmf_pos);
        if length(old_MDD)==length(new_MDD)
            if abs(sum(new_MDD-old_MDD))<10*eps,replace_it=0;end
        end
        old_PAA=entity.damagefunctions.PAA(old_DamageFunID_pos);
        new_PAA=damagefunctions.PAA(dmf_pos);
        if length(old_PAA)==length(new_PAA)
            if abs(sum(new_PAA-old_PAA))<10*eps,replace_it=0;end
        end
        old_INT=entity.damagefunctions.Intensity(old_DamageFunID_pos);
        new_INT=damagefunctions.Intensity(dmf_pos);
        if length(old_INT)==length(new_INT)
            if abs(sum(new_INT-old_INT))<10*eps,replace_it=0;end
        end
        
        if replace_it
            if ~isempty(old_DamageFunID_pos) % replace with new ID
                entity.damagefunctions.DamageFunID(old_DamageFunID_pos)=next_ID;next_ID=next_ID+1;
            end
            % append
            entity.damagefunctions.Intensity=[entity.damagefunctions.Intensity;damagefunctions.Intensity(dmf_pos)];
            entity.damagefunctions.DamageFunID=[entity.damagefunctions.DamageFunID;damagefunctions.DamageFunID(dmf_pos)];
            entity.damagefunctions.MDD=[entity.damagefunctions.MDD;damagefunctions.MDD(dmf_pos)];
            entity.damagefunctions.PAA=[entity.damagefunctions.PAA;damagefunctions.PAA(dmf_pos)];
            entity.damagefunctions.peril_ID=[entity.damagefunctions.peril_ID;damagefunctions.peril_ID(dmf_pos)];
        else
            fprintf('%s not replaced (exists already)\n',char(unique_IDs{ID_i}));
        end
    end
end % ID_i

end % climada_damagefunctions_replace