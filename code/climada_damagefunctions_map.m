function entity=climada_damagefunctions_map(entity,damagefunctions,damagefunctions_map)
% climada
% NAME:
%   climada_damagefunctions_map
% PURPOSE:
%   Given an encoded entity, map damagefunctions, e.g. after reading
%   alternative damagefunctions with climada_damagefunction_read
%
%   If only entity is entered, the current DamageFunIDs in entity.assets
%   and entity.damagefunctions are shown. 
%
%   If both entity and damagefunctions are passed, but no map,
%   the DamageFunIDs in both entity and damagefunctions are shown. 
%
%   Only if a valid damage function map is passed, the mapping effectively
%   happens. After mapping, the consistency is checked (a damagefunction
%   definition for each DamageFunID).
%
%   See also climada_damagefunction_read
% CALLING SEQUENCE:
%   entity=climada_damagefunctions_map(entity,damagefunctions,damagefunctions_map)
% EXAMPLE:
%   entity=climada_damagefunctions_map(entity,damagefunctions,'1to3;2to4');
%   entity=climada_damagefunctions_map(entity,'1to3;2to4');
% INPUTS:
%   entity: an entity, see climada_entity_read
%       > promted for if not given (calling climada_entity_load, not
%       climada_entity_read)
% OPTIONAL INPUT PARAMETERS:
%   damagefunctions: see climada_damagefunctions_read, a struct with damage
%       functions. If one does not need to pass on new damage functions,
%       one can also pass the damagefunctions_map in this variable (see 2nd
%       EXAMPLE above). This option comes handy, if one stores several
%       damagefunctions in entity.damagefunctions and uses this code to
%       switch between.
%   damagefunctions_map: the damagefunction map, either
%       - a string with the mappings, e.g.
%       '1to3;2to4', as in the entity.measures.damagefunctions_map
%       - or a structure as in entity.measures.damagefunctions_mapping with
%       fields map_from and map_to, such that we map map_from(i) to map_to(i) 
%       If empty, the DamageFunIDs in both entity and damagefunctions are
%       shown, but no mapping actually occurs.
% OUTPUTS:
%   entity: the entity with damagefunctions mapped (and damagefunction
%       definitions taken from damagefunctions, if passed)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141121, ICE
%-

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('damagefunctions','var'),damagefunctions=[];end
if ~exist('damagefunctions_map','var'),damagefunctions_map=[];end

% PARAMETERS
%
% set default value for param2 if not given

% prompt for param1 if not given
if isempty(entity),entity=climada_entity_load;end
if isempty(entity),return;end

% if a map is passed on in damagefunctions, it's the map...
if ischar(damagefunctions),damagefunctions_map=damagefunctions;damagefunctions=[];end

show_DamageFunIDs=0; % see below

if ~isempty(damagefunctions_map)
    
    if ischar(damagefunctions_map)
        % must contain the map string, like '1to3;4to7'
        measures.damagefunctions_map{1}=damagefunctions_map; % needed that way
        measures=climada_measures_encode(measures); % interpret '1to3' ...
        damagefunctions_mapping=measures.damagefunctions_mapping; clear measures
    elseif isstruct(damagefunctions_map)
        if isfield(damagefunctions_map,'map_from') && isfield(damagefunctions_map,'map_to')
            % contains already a structure
            damagefunctions_mapping=damagefunctions_map;
        else
            fpritnf('ERROR: damagefunctions_map does not contain the required fields\n');
            return
        end
    end
    
    for map_i = 1:length(damagefunctions_mapping(1).map_from) % (1) kept for upgrade
        % damagefunctions mapping
        pos = find(entity.assets.DamageFunID==damagefunctions_mapping(1).map_from(map_i));
        if length(pos)>0
            entity.assets.DamageFunID(pos) = damagefunctions_mapping(1).map_to(map_i);
            fprintf('mapping DamageFunID %i to %i (%i occurrencies)\n',...
                damagefunctions_mapping(1).map_from(map_i),...
                damagefunctions_mapping(1).map_to(map_i),length(pos));
        end
    end % map_i
    
    if ~isempty(damagefunctions)
        fprintf('replacing entity.damagefunctions with damagefunctions\n');
        entity=rmfield(entity,'damagefunctions');
        entity.damagefunctions=damagefunctions;
        damagefunctions=[]; % since used
    end
    
    % check consistency (a damagefunction definition for each DamageFunID)
    asset_DamageFunIDs=unique(entity.assets.DamageFunID);
    damagefunctions_DamageFunIDs=unique(entity.damagefunctions.DamageFunID);
    tf=ismember(asset_DamageFunIDs,damagefunctions_DamageFunIDs);
    if length(find(tf))<length(tf)
        fprintf('WARNING: DamageFunIDs in assets might not all be defined in damagefunctions:\n');
        show_DamageFunIDs=1; % show what's in assets etc.
    end
    
else
    
    show_DamageFunIDs=1;
    
end

if show_DamageFunIDs

    asset_DamageFunIDs=unique(entity.assets.DamageFunID);
    fprintf('DamageFunIDs in entity.assets: %i',asset_DamageFunIDs(1));
    for i=2:length(asset_DamageFunIDs)
        fprintf(', %i',asset_DamageFunIDs(i));
    end
    fprintf('\n');
    
    asset_DamageFunIDs=unique(entity.damagefunctions.DamageFunID);
    fprintf('DamageFunIDs in entity.damagefunctions: %i',asset_DamageFunIDs(1));
    for i=2:length(asset_DamageFunIDs)
        fprintf(', %i',asset_DamageFunIDs(i));
    end
    fprintf('\n');
    
    if ~isempty(damagefunctions)
        damagefunctions_DamageFunIDs=unique(damagefunctions.DamageFunID);
        fprintf('DamageFunIDs in damagefunctions: %i',damagefunctions_DamageFunIDs(1));
        for i=2:length(damagefunctions_DamageFunIDs)
            fprintf(', %i',damagefunctions_DamageFunIDs(i));
        end
        fprintf('\n');
    end
end
