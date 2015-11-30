function [struct_data, struct_name] = climada_load(struct_file,struct_type,silent_mode)
% climada
% MODULE:
%   core/helper_functions
% NAME:
%   climada_load
% PURPOSE:
%   load any climada struct (entity, EDS, hazard, centroids) and set
%   variable_name yourself with struct_data
% CALLING SEQUENCE:
%   [struct_data, struct_name] = climada_load(struct_file,struct_type)
% EXAMPLE:
%   [struct_data, struct_name] = climada_load(struct_file,struct_type)
%   entity = climada_load('demo_today')
%   measures_impact = climada_load('','measures_impact')
%   hazard = climada_load('TCNA_today_small')
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   struct_file: the filename (with path, optional) of a previously saved
%       climada structure
%       If no path provided, default path ../data/... is used (and
%       name can be without extension .mat)
%       > promted for if not given
%   struct_type: a string to define the type of a climada struct, i.e 
%       'entity', 'hazard', 'measures_impact'. If no struct_file given, the
%       prompt will reflect the appropiate folder (data/entities, or
%       data/results, ...)
%   silent_mode: suppress any output, default=0 (output to command window), =1: no output
% OUTPUTS:
%   struct_data: a struct, i.e. hazard, entity, EDS, centroids, etc.
%   struct_name: a char that contains the name of the struct, i.e.
%   'hazard', 'entity', etc.
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151124, init from climada_entity_load
% Lea Mueller, muellele@gmail.com, 20151130, move to climada/code/helper_functions
%-

% init output
struct_data = []; struct_name = [];

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('struct_file','var'),struct_file=[];end
if ~exist('struct_type','var'),struct_type='';end
if ~exist('silent_mode','var'),silent_mode=0;end

% PARAMETERS


% if already a complete entity, return
if isfield(struct_file,'Value')
    struct_data = struct_file;
    struct_name = 'entity';
    return
end

% if already a complete hazard, return
if isfield(struct_file,'intensity')
    struct_data = struct_file;
    struct_name = 'hazard';
    return
end

% if already a complete EDS, return
if isfield(struct_file,'ED') && ~isfield(struct_file,'benefit')
    struct_data = struct_file;
    struct_name = 'EDS';
    return
end

% if already a complete measures_impact, return
if isfield(struct_file,'benefit')
    struct_data = struct_file;
    struct_name = 'measures_impact';
    return
end

% struct_type defines the type of climada struct, either 'entity',
% 'hazard', 'EDS', 'measures_impact', etc
if ischar(struct_type)
    if strcmp(struct_type,'no') || strcmp(struct_type,'NO')
        return
    end
    switch struct_type
        case 'entity'
            struct_type = 'entities';
        case 'Entity'
            struct_type = 'entities';
        case 'measures_impact'
            struct_type = 'results';
        case 'EDS'
            struct_type = 'results';
        case 'eds'
            struct_type = 'results';
    end
else
    struct_type = '';
end


% prompt for struct_file if not given
if isempty(struct_file) % local GUI
    struct_file = [climada_global.data_dir filesep struct_type filesep '*.mat'];
    [filename, pathname] = uigetfile(struct_file, 'Select a climada struct to open:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        struct_file = fullfile(pathname,filename);
    end
end

% complete path, if missing
[fP,fN,fE] = fileparts(struct_file);
if isempty(fE),fE = '.mat'; end

% look for a file in the different data folders, find out the struct_name

if isempty(strfind(fP,filesep)) % not an entire path, just one folder
    fN = fullfile(fP,fN); fP = [];
end
    
    
if isempty(fP) 
    struct_file = ''; %init
    
    % centroids
    struct_file_temp = [climada_global.centroids_dir filesep fN fE];
    if exist(struct_file_temp,'file'), struct_file = struct_file_temp; end
   
    % entity
    struct_file_temp = [climada_global.data_dir filesep 'entities' filesep fN fE];
    if exist(struct_file_temp,'file'), struct_file = struct_file_temp; end
    
    % EDS or measures_impact
    struct_file_temp = [climada_global.data_dir filesep 'results' filesep fN fE];
    if exist(struct_file_temp,'file'), struct_file = struct_file_temp; end
    
    % hazard
    struct_file_temp = [climada_global.data_dir filesep 'hazards' filesep fN fE];
    if exist(struct_file_temp,'file'), struct_file = struct_file_temp; end
else
    % make sure the given file exists
    if ~exist(struct_file,'file'), struct_file = ''; end
end %isempty(fP)

if isempty(struct_file), fprintf('File not found.\n'); return, end

% get information about the variable
vars = whos('-file', struct_file);

% get name of the climada structure as a char
struct_name = vars.name;

% finally load the file 
load(struct_file);

% rename the file to the selected struct_name
eval_str = sprintf('struct_data = %s;',vars.name);
eval(eval_str);
clear(vars.name)

if ~silent_mode
    fprintf('You have loaded a climada struct, originally named %s.\n', struct_name);
end



end % climada_load


