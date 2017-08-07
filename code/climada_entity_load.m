function [entity,entity_file]=climada_entity_load(entity,nosave_flag)
% climada
% NAME:
%   climada_entity_load
% PURPOSE:
%   load a previously saved entity (just to avoid typing long paths and
%   filenames in the command window)
% CALLING SEQUENCE:
%   entity_out=climada_entity_load(entity,nosave_flag)
% EXAMPLE:
%   entity=climada_entity_load('demo_today')
% INPUTS:
%   entity: the filename (and path, optional) of a previously saved entity
%       structure. If no path provided, default path ../data/entities is used
%       (and name can be without extension .mat or even without
%       _entity.mat, in some cases even the ISO3 code only is enough)
%       > promted for if empty
%       OR: an entity structure, in which case it is just returned (to allow
%       calling climada_entity_load anytime, see e.g. climada_EDS_calc)
% OPTIONAL INPUT PARAMETERS:
%   nosave_flag: if =1, do not save back (to preserver entity as on disk,
%       just complete fields as necessary. Useful for example to preserve
%       entities in save versions compatible with Octave when re-loading
%       with either MATLAB or Ocatve. Default=0 (save back)
% OUTPUTS:
%   entity: a struct, see climada_entity_read for details
%   entity_file: the full filename the entity was loaded from
%       useful in subsequent call climada_entity_save(entity,entity_file)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091230
% David N. Bresch, david.bresch@gmail.com, 20150804, allow for name without path on input
% David N. Bresch, david.bresch@gmail.com, 20150820, memory use optimized, filename checked
% Lea Mueller, muellele@gmail.com, 20151124, check that field .assets exist
% Lea Mueller, muellele@gmail.com, 20151127, enhance to work with complete entity as input
% Lea Mueller, muellele@gmail.com, 20151127, set entity_file to empty if a struct without .assets
% David N. Bresch, david.bresch@gmail.com, 20160202, speedup if entity structure passed
% David N. Bresch, david.bresch@gmail.com, 20160516, _entity added if needed, too. entity_file as output added
% David N. Bresch, david.bresch@gmail.com, 20160908, entities_dir used
% David N. Bresch, david.bresch@gmail.com, 20161001, check for isentity
% David N. Bresch, david.bresch@gmail.com, 20161120, try also to save with '-v7.3'
% David N. Bresch, david.bresch@gmail.com, 20170503, allow also for ISO3 only
% David N. Bresch, david.bresch@gmail.com, 20170806, nosave_flag added
% David N. Bresch, david.bresch@gmail.com, 20170807, climada_damagefunctions_complete and climada_measures_complete added
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('nosave_flag','var'),nosave_flag=[];end
if isempty(nosave_flag),nosave_flag=0;end

% if already a complete hazard, return
if isstruct(entity)
    if ~isentity(entity),fprintf('ERROR: not an entity\n');entity=[];end
    return % already a hazard
else
    entity_file=entity;entity=[];
    % from now on, entity_file is the input and entity will be output
end

% prompt for entity_file if not given
if isempty(entity_file) % local GUI
    entity_file=[climada_global.entities_dir filesep '*.mat'];
    [filename, pathname] = uigetfile(entity_file, 'Select entity to open:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_file=fullfile(pathname,filename);
    end
end

% complete path, if missing
[fP,fN,fE]=fileparts(entity_file);
if isempty(fP),fP=climada_global.entities_dir;end
if isempty(fE),fE='.mat';end
entity_file=[fP filesep fN fE];
if ~exist(entity_file,'file')
    [fP,fN,fE]=fileparts(entity_file);
    fN=[fN '_entity']; % append _entity
    entity_file=[fP filesep fN fE];
end

if ~exist(entity_file,'file')
    % one last try, could be somebody only entered 3-digit country code
    [fP,fN,fE]=fileparts(entity_file);
    [country_name,country_ISO3]=climada_country_name(strrep(fN,'_entity',''));
    fN=[country_ISO3 '_' strrep(country_name,' ','') '_entity']; % append _entity
    entity_file=[fP filesep fN fE];
end

if ~exist(entity_file,'file')
    fprintf('ERROR: entity does not exist %s\n',entity_file);
    return
else
    try
        load(entity_file); % contains entity, the only line that really matters ;-)
    catch ME
        fprintf('ERROR: entity not loaded (%s)\n',ME.message);
    end % try
end

if isentity(entity)
    % check for valid/correct entity.assets.filename
    if isfield(entity,'assets')
        if ~strcmp(entity_file,entity.assets.filename)
            entity.assets.filename=entity_file;
            entity.damagefunctions.filename=entity_file;
            entity.measures.filename=entity_file;
            entity.discount.filename=entity_file;
            if ~nosave_flag,save(entity_file,'entity',climada_global.save_file_version);end
        end
    end
else
    entity=[];
end % isentity(entity)

% for the time being, since we now expect fields in damagefunctons and measures to be 1xN
entity.damagefunctions = climada_damagefunctions_complete(entity.damagefunctions);
entity.measures = climada_measures_complete(entity.measures);

end % climada_entity_load