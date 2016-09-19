function entity = climada_entity_check(entity,fieldname,silent_mode,called_from)
% climada_entity_check
% NAME:
%   climada_entity_check
% PURPOSE:
%   Given an assets, damagefunction or measures structure delete NaN lines
% 
%   can be called from: climada_entity_read, climada_damagefunction_read,
%   climada_measures_read
% CALLING SEQUENCE:
%   entity_out = climada_entity_check(entity,fieldname)
% EXAMPLE:
%   entity_out = climada_entity_check(entity,fieldname)
% INPUTS:
%   entity: an entity structure or an entity .mat file, see climada_assets_encode(climada_assets_read)
%       If a file and no path provided, default path ../data/entities is
%       used (and name can be without extension .mat)
%       > promted for if not given
%   fieldname: fieldname to specify where to look for NaNs
%       default is 'lon'
% OPTIONAL INPUT PARAMETERS:
%   silent_mode: =1 to omit warnings to stdout, default=0
%   called_from: the calling routine name or any other info to issue with
%       each warning message
% OUTPUTS:
%   entity cleaned up, deleted rows with nans
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151016, init
% david.bresch@gmail.com, 20160918, values=getfield(entity,fieldname) replaced with values=entity.(fieldname)
% david.bresch@gmail.com, 20160918, called_from added
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('entity','var'),entity = []; end
if ~exist('fieldname','var'),fieldname = ''; end
if ~exist('silent_mode','var'),silent_mode = 0; end
if ~exist('called_from','var'),called_from = ''; end

% entity_out = []; %init

% PARAMETERS
        
% prompt for entity if not given
if isempty(entity) % local GUI
    entity = [climada_global.data_dir filesep 'entities' filesep '*.mat'];
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

% set fieldname if not given
if isempty(fieldname) % local GUI
    fieldname = 'lon';
end

if isfield(entity, fieldname)
    % get original values and find NaNs
    %values = getfield(entity,fieldname);
    values = entity.(fieldname);
    if iscell(values)    
        is_valid = ~cellfun(@(V) any(isnan(V(:))), values);   
    else
        is_valid = ~isnan(values);
    end
    
    if any(~is_valid) % invalid entries are found
        
        if ~silent_mode
            fprintf('%d invalid entries in %s.%s found\n',sum(~is_valid),called_from,fieldname);
        end
        
        % shorten essential field
        %entity = setfield(entity,fieldname, values(is_valid));
        entity.(fieldname)=values(is_valid);
        
        % loop over all fieldnames
        % get all fieldnames
        names = fieldnames(entity);
        for n_i = 1:numel(names)
                        
            % get original values
            %values_orig = getfield(entity,names{n_i});
            values_orig = entity.(names{n_i});
            
            % check that vector has the same dimension and should be
            % shortened
            if numel(is_valid) == numel(values_orig)
                % shorten values
                %entity = setfield(entity,names{n_i},values_orig(is_valid));
                entity.(names{n_i})=values_orig(is_valid);
                
                if ~silent_mode
                    fprintf('%d invalid entries deleted in %s.%s\n',sum(~is_valid),called_from,names{n_i});
                end
            end
        end %n_i
    end
end

% if entire entity is given with field assets
if isfield(entity,'assets') % check absolute essentials only
    entity.assets = climada_entity_check(entity.assets,'lon',silent_mode);
    entity.assets = climada_entity_check(entity.assets,'lat',silent_mode);
    entity.assets = climada_entity_check(entity.assets,'Value',silent_mode);
end

% if entire entity is given with field damagefunctions
if isfield(entity,'damagefunctions')
    entity.damagefunctions = climada_entity_check(entity.damagefunctions,'DamageFunID',silent_mode);
end

% if entire entity is given with field measures
if isfield(entity,'measures')
    entity.measures = climada_entity_check(entity.measures,'name',silent_mode);
end

end % climada_entity_check