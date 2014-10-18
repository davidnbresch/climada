function ok=climada_init_folders(root_folder)
% init variables global
% NAME:
%	climada_init_folders
% PURPOSE:
%	initialize basic folder structure (eg in modules)
%
% CALLING SEQUENCE:
%	ok=climada_init_folders(root_folder)
% EXAMPLE:
%	ok=climada_init_folders
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%
% OUTPUTS:
%	ok: =1 if no troubles, 0 else
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20140825, initial release
%-

ok=0;

global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('root_folder','var'),root_folder=[];end

% PARAMETERS
%

% prompt for root_folder if not given
if isempty(root_folder) % local GUI
    root_folder=climada_global.modules_dir;
    root_folder = uigetdir(root_folder, 'Select module to add folder structure:');
    if isequal(root_folder,0)
        return % cancel
    end
end

% set and check the directory tree
% --------------------------------

if ~exist([root_folder filesep 'code'],'dir'),mkdir(root_folder,'code');end
if ~exist([root_folder filesep 'docs'],'dir'),mkdir(root_folder,'docs');end
data_folder=[root_folder filesep 'data'];
if ~exist([root_folder filesep 'data'],'dir'),mkdir(root_folder,'data');end
if ~exist([data_folder filesep 'entities'],'dir'),mkdir(data_folder,'entities');end
if ~exist([data_folder filesep 'hazards'],'dir'),mkdir(data_folder,'hazards');end
if ~exist([data_folder filesep 'results'],'dir'),mkdir(data_folder,'results');end
if ~exist([data_folder filesep 'system'],'dir'),mkdir(data_folder,'system');end

ok=1; % not really diligent checking... ;-)

return
