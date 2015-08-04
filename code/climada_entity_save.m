function climada_entity_save(entity,entity_file)
% climada
% NAME:
%   climada_entity_save
% PURPOSE:
%   save an entity to a .mat file (just to avoid typing long paths and
%   filenames in the cmd window)
% CALLING SEQUENCE:
%   climada_entity_save(entity,entity_file)
% EXAMPLE:
%   climada_entity_save(climada_assets_encode(climada_assets_read))
% INPUTS:
%   entity: the entity struct to be saved, see e.g. climate_assets_encode
%   entity_file: the filename (with path, optional) to save the entity in
%       If no path provided, default path ../data/entities is used
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   entity saved to a .mat file
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091230
% David N. Bresch, david.bresch@gmail.com, 20150804, allow for name without path on input
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('entity','var'),return;end
if ~exist('entity_file','var'),entity_file=[];end

% PARAMETERS
%

% prompt for entity_file if not given
if isempty(entity_file) % local GUI
    entity_file=[climada_global.data_dir filesep 'entities' filesep '*.mat'];
    [filename, pathname] = uiputfile(entity_file, 'Save entity as:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_file=fullfile(pathname,filename);
    end
end

% complete path, if missing
[fP,fN,fE]=fileparts(entity_file);
if isempty(fP),entity_file=[climada_global.data_dir filesep 'entities' filesep fN fE];end

save(entity_file,'entity')

return

