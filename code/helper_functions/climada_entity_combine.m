function [entity,entity_save_file] = climada_entity_combine(entity,entity2,entity_save_file,purge_flag)
% climada entity import, read assets, damagefunctions, discount and measures
% NAME:
%   climada_entity_combine
% PURPOSE:
%   Combine two climada entities, just appends assets, keeps everything
%   else the same.
%
%   previous steps: climada_entity_read, climada_entity_load
%   next step: likely climada_ELS_calc
% CALLING SEQUENCE:
%   [entity,entity_save_file] = climada_entity_combine(entity,entity2,entity_save_file)
% EXAMPLE:
%   entity = climada_entity_combine(entity,entity2)
% INPUTS:
%   entity: a climada entity structure, as returned by climada_entity_read
%   entity2: a climada entity structure, as returned by climada_entity_read
% OPTIONAL INPUT PARAMETERS:
%   entity_filename: the filename to save the combined entity to
%       NOT asked if not provided, as in this case, the combined entity is
%       NOT saves back to disk
%   purge_flag: =1 delete array entries where entity.assets.Value=0 in
%       combinded assets, =0 keep all (default) 
% OUTPUTS:
%   entity: an entity structure, see climada_entity_read
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20160120, initial
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

entity_save_file = [];

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('entity','var'), entity = [];end
if ~exist('entity2','var'), entity2 = [];end
if ~exist('entity_save_file','var'), entity_save_file = '';end
if ~exist('purge_flag','var'), purge_flag = 0;end

% PARAMETERS
%

% prompt for entity if not given
if isempty(entity) % local GUI
    entity_filename      = [climada_global.data_dir filesep 'entities' filesep '*.mat'];
    [filename, pathname] = uigetfile(entity_filename, 'Select first entity:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_filename = fullfile(pathname,filename);
        entity=climada_entity_load(entity_filename);
    end
end

% prompt for entity if not given
if isempty(entity) % local GUI
    entity_filename      = [climada_global.data_dir filesep 'entities' filesep '*.mat'];
    [filename, pathname] = uigetfile(entity_filename, 'Select first entity:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_filename = fullfile(pathname,filename);
        entity2=climada_entity_load(entity_filename);
    end
end

% combine the assets of the two entities
entity.assets.lon=[entity.assets.lon entity2.assets.lon];
entity.assets.lat=[entity.assets.lat entity2.assets.lat];
entity.assets.Value=[entity.assets.Value entity2.assets.Value];
entity.assets.DamageFunID=[entity.assets.DamageFunID entity2.assets.DamageFunID];
entity.assets.Deductible=[entity.assets.Deductible entity2.assets.Deductible];
entity.assets.Cover=[entity.assets.Cover entity2.assets.Cover];

fprintf('Warning: only assets (lon,lat,Value,DamageFunID,Deductible and Cover) combined\n');

if purge_flag
    nonzero_pos=find(entity.assets.Value>0);
    entity.assets.lon=entity.assets.lon(nonzero_pos);
    entity.assets.lat=entity.assets.lat(nonzero_pos);
    entity.assets.Value=entity.assets.Value(nonzero_pos);
    entity.assets.DamageFunID=entity.assets.DamageFunID(nonzero_pos);
    entity.assets.Deductible=entity.assets.Deductible(nonzero_pos);
    entity.assets.Cover=entity.assets.Cover(nonzero_pos);
end

if ~isempty(entity_save_file)
    fprintf('saving entity as %s\n',entity_save_file);
    save(entity_save_file,'entity');
end

end % climada_entity_combine
