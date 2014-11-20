function entity_out=climada_entity_load(entity_file)
% climada
% NAME:
%   climada_entity_load
% PURPOSE:
%   load a previously saved entity (just to avoid typing long paths and
%   filenames in the cmd window)
% CALLING SEQUENCE:
%   entity_out=climada_entity_load(entity_file)
% EXAMPLE:
%   entity_out=climada_entity_load(entity_file)
% INPUTS:
%   entity_file: the filename with path of a previously saved entity, see
%       climada_entity_save(climada_assets_encode(climada_assets_read))
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   entity_out: a struct, see e.g. climada_assets_read for details
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091230
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('entity_file','var'),entity_file=[];end

% PARAMETERS
%

% prompt for entity_file if not given
if isempty(entity_file) % local GUI
    entity_file=[climada_global.data_dir filesep 'entities' filesep '*.mat'];
    [filename, pathname] = uigetfile(entity_file, 'Open:');
    if isequal(filename,0) || isequal(pathname,0)
        entity_out = []; return; % cancel
    else
        entity_file=fullfile(pathname,filename);
    end
end

load(entity_file)
vars = whos('-file', entity_file); % in case entity was saved under another name
if ~strcmp(vars.name,'entity')
    entity = eval(vars.name);
    clear (vars.name)
end
    
entity_out=entity;

return

