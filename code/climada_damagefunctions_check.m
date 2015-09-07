function entity_out = climada_damagefunctions_check(entity,hazard,silent_mode)
% climada_damagefunctions_check
% NAME:
%   climada_damagefunctions_check
% PURPOSE:
%   Given an entity.damagefunctions structure we check that we have defined 
%   MDD and PAA values for occurring hazard intensities. If MDD and PAA are
%   only defined for smaller intensity values, entity.damagefunction fields
%   are enlarged by an additional line (for .Intentiy, .MDD, .PAA, etc.)
%
%   can be called from: climada_EDS_calc if set to sanity_check
% CALLING SEQUENCE:
%   entity = climada_damagefunctions_check(entity,hazard)
% EXAMPLE:
%   entity = climada_damagefunctions_check(entity,hazard)
% INPUTS:
%   entity: an entity structure or an entity .mat file, see climada_assets_encode(climada_assets_read)
%       If a file and no path provided, default path ../data/entities is
%       used (and name can be without extension .mat)
%       > promted for if not given
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       If a file and no path provided, default path ../data/hazards is
%       used (and name can be without extension .mat)
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   entity with enlarged entity.damagefunctions fields (.Intentiy, .MDD, .PAA, etc.)
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150907, init
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('hazard','var'),hazard=[];end
if ~exist('silent_mode','var'),silent_mode=1;end

entity_out = []; %init

% PARAMETERS
        
% prompt for entity if not given
if isempty(entity) % local GUI
    entity=[climada_global.data_dir filesep 'entities' filesep '*.mat'];
    [filename, pathname] = uigetfile(entity, 'Select encoded entity:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity=fullfile(pathname,filename);
    end
end
% load the entity, if a filename has been passed
if ~isstruct(entity)
    entity_file=entity;entity=[];
    
    % complete path, if missing
    [fP,fN,fE]=fileparts(entity_file);
    if isempty(fP),entity_file=[climada_global.data_dir filesep 'entities' filesep fN fE];end
    
    load(entity_file);
end

% prompt for hazard_set if not given
if isempty(hazard) % local GUI
    hazard=[climada_global.data_dir filesep 'hazards' filesep '*.mat'];
    [filename, pathname] = uigetfile(hazard, 'Select hazard event set for EDS calculation:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard=fullfile(pathname,filename);
    end
end
% load the hazard set, if a filename has been passed
if ~isstruct(hazard)
    hazard_file=hazard;hazard=[];
    
    % complete path, if missing
    [fP,fN,fE]=fileparts(hazard_file);
    if isempty(fP),hazard_file=[climada_global.data_dir filesep 'hazards' filesep fN fE];end
    
    load(hazard_file);
end

hazard=climada_hazard2octave(hazard); % Octave compatibility for -v7.3 mat-files

% copy entity to entity_out
entity_out = entity;

% min and max occurring hazard intensity
intensity_max = max(nonzeros(hazard.intensity));
intensity_min = min(nonzeros(hazard.intensity));

% check that MDD and PAA are defined for the entire range of hazard intensity
if ~isfield(entity,'damagefunctions'), return, end
is_peril = strcmp(entity.damagefunctions.peril_ID,hazard.peril_ID);
if isfield(entity.damagefunctions,'Intensity_unit')
    is_intensity_unit = strcmp(entity.damagefunctions.Intensity_unit,hazard.units);
else
    is_intensity_unit = entity.damagefunctions.Intensity*0+1;
end
is_valid = logical(is_peril.* is_intensity_unit);

DamageFunID_all = unique(entity.damagefunctions.DamageFunID);
[DamageFunID_valid,is_unique,position_valid_damagefun] = unique(entity.damagefunctions.DamageFunID(is_valid));
if ~silent_mode
    fprintf('%d from %d damage function IDs are valid (peril_ID=%s,intensity_unit=%s)\n',...
        numel(DamageFunID_valid),numel(DamageFunID_all), hazard.peril_ID, hazard.units)
end

% define number of damage function entries
total_lines = numel(entity.damagefunctions.DamageFunID);

% get all field names that should be enlarged in case of additional
% intensity, MDD, PAA entries
names = fieldnames(entity.damagefunctions);
is_variable_field = zeros(size(names));
for n_i = 1:numel(names)
    if numel(getfield(entity.damagefunctions, names{n_i})) == total_lines
        is_variable_field(n_i) = 1;
    end
end
is_variable_field = logical(is_variable_field);
fields_to_enlarge = names(is_variable_field);


% loop over valid DamageFunIDs to define min damagefun intensity
for damagefunction_i = 1:numel(DamageFunID_valid)
    
    % set min and max defined intensity
    this_damagefunction = position_valid_damagefun==damagefunction_i;
    [intensity_min_this, is_min]= min(entity_out.damagefunctions.Intensity(this_damagefunction));
    
    this_damagefunction = find(this_damagefunction);
    MDD_min = entity_out.damagefunctions.MDD(this_damagefunction(is_min));
    PAA_min = entity_out.damagefunctions.PAA(this_damagefunction(is_min));
        
    if intensity_min<intensity_min_this
        if ~silent_mode
            fprintf('DamageFunID %d: Actual occuring intensity (%4.2f %s) is smaller than defined damage fun intensity (%4.2f %s)\n', ...
                DamageFunID_valid(damagefunction_i),intensity_min,hazard.units,intensity_min_this,hazard.units)
        end
        % add a new minimum value in the damage function
        additonal_line_position = this_damagefunction(is_min);
        additional_value_min = 0; %intensity_min*0.9;
    else
        additonal_line_position = [];
        additional_value_min = [];
    end

    if ~isempty(additional_value_min)
        
        if ~silent_mode
        	rintf('Enlarge DamageFunID %d\n',DamageFunID_valid(damagefunction_i))
        end
        
        % loop over all fields (that containt intensity, MDD, PAA, etc
        % information) to add the additional line
        for n_i = 1:numel(fields_to_enlarge)
            values = getfield(entity_out.damagefunctions, fields_to_enlarge{n_i});
            if strcmp(fields_to_enlarge{n_i},'Intensity')
                additional_value = additional_value_min;
            elseif strcmp(fields_to_enlarge{n_i},'MDD')
                additional_value = MDD_min;
            elseif strcmp(fields_to_enlarge{n_i},'PAA')
                additional_value = PAA_min;
            else
                additional_value = values(additonal_line_position+1);
            end
            if iscell(additional_value)
                if ~silent_mode
                    fprintf('\t- Additional entry %s: %s \n',fields_to_enlarge{n_i},additional_value{:})
                end
            else
                if ~silent_mode
                    fprintf('\t- Additional entry %s: %4.2f \n',fields_to_enlarge{n_i},additional_value)
                end
            end
            values_enlarged = [values(1:additonal_line_position-1); additional_value; values(additonal_line_position:end)];
            entity_out.damagefunctions = setfield(entity_out.damagefunctions,fields_to_enlarge{n_i},values_enlarged);
        end

        % recreate vector position_valid_damagefun to find unique DamageFunIDs
        [DamageFunID_valid,is_unique,position_valid_damagefun] = unique(entity_out.damagefunctions.DamageFunID(is_valid));
    end

end


% loop over valid DamageFunIDs to define max damagefun intensity
for damagefunction_i = 1:numel(DamageFunID_valid)
    
    % set max defined intensity
    this_damagefunction = position_valid_damagefun==damagefunction_i;
    [intensity_max_this, is_max]= max(entity_out.damagefunctions.Intensity(this_damagefunction));
    
    this_damagefunction = find(this_damagefunction);
    MDD_max = entity_out.damagefunctions.MDD(this_damagefunction(is_max));
    PAA_max = entity_out.damagefunctions.PAA(this_damagefunction(is_max));
    
    if intensity_max>intensity_max_this
        if ~silent_mode
            fprintf('DamageFunID %d: Actual occuring intensity (%4.2f %s) is greater than defined damage fun intensity (%4.2f %s)\n', ...
                DamageFunID_valid(damagefunction_i),intensity_max, hazard.units, intensity_max_this, hazard.units)
        end
        % add a new maximum value in the damage function
        additonal_line_position = this_damagefunction(is_max)+1;
        additional_value_max = intensity_max*1.1;
    else
        additonal_line_position = [];
        additional_value_max = [];
    end
    
    
    if ~isempty(additional_value_max)
        
        if ~silent_mode
            fprintf('Enlarge DamageFunID %d\n',DamageFunID_valid(damagefunction_i))
        end
        
        % loop over all fields (that containt intensity, MDD, PAA, etc
        % information) to add the additional line
        for n_i = 1:numel(fields_to_enlarge)
            values = getfield(entity_out.damagefunctions, fields_to_enlarge{n_i});
            if strcmp(fields_to_enlarge{n_i},'Intensity')
                additional_value = additional_value_max;
            elseif strcmp(fields_to_enlarge{n_i},'MDD')
                additional_value = MDD_max;
            elseif strcmp(fields_to_enlarge{n_i},'PAA')
                additional_value = PAA_max;
            else
                additional_value = values(additonal_line_position-1);
            end
            if iscell(additional_value)
                if ~silent_mode
                    fprintf('\t- Additional entry %s: %s \n',fields_to_enlarge{n_i},additional_value{:})
                end
            else
                if ~silent_mode
                    fprintf('\t- Additional entry %s: %4.2f \n',fields_to_enlarge{n_i},additional_value)
                end
            end
            values_enlarged = [values(1:additonal_line_position-1); additional_value; values(additonal_line_position:end)];
            entity_out.damagefunctions = setfield(entity_out.damagefunctions,fields_to_enlarge{n_i},values_enlarged);
        end

        % recreate vector position_valid_damagefun to find unique DamageFunIDs
        [DamageFunID_valid,is_unique,position_valid_damagefun] = unique(entity_out.damagefunctions.DamageFunID(is_valid));
    end
end




