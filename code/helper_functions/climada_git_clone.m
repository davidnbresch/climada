function climada_git_clone(TEST_mode)
% climada git pull
% MODULE:
%   core
% NAME:
%   climada_git_clone
% PURPOSE:
%   clone (most) climada modules (eases installation from scratch).
%
%   first gets core climada, the creates the folder climada_data, copies
%   content of core climada's data into it, then creates the folder
%   climada_modules and clones the module sinto it.
%
%   previous call: startup (usually already executed)
%   next call: climada ;-)
% CALLING SEQUENCE:
%   climada_git_clone
% EXAMPLE:
%   climada_git_clone(1)
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   TEST_mode: =1 only show which paths will be processed, do not pull
%       default=0, i.e. run git pull
% OUTPUTS:
%   all messaging to stdout
% MODIFICATION HISTORY:
% david.bresch@gmail.com, 20161010, initial
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('TEST_mode','var'),TEST_mode=[];end

fprintf('NOT WORKING YET\n');
return

% PARAMETERS
%
if isempty(TEST_mode),TEST_mode=0;end % default=0

current_path=pwd; % get active path (to restore later)

% first, update the climada root folder
% -------------------------------------
fprintf('* updating %s\n',climada_global.root_dir);
cd(climada_global.root_dir)
if ~TEST_mode,git pull,end


% second, update all climada modules
% ----------------------------------

P=path; % get all paths

while ~isempty(P)
    [token,P] = strtok(P,pathsep);
    % chekc for a climada module path
    if ~isempty(strfind(token,climada_global.modules_dir)) % a module
        module_folder=strrep(token,[climada_global.modules_dir filesep],'');
        module_folder=fileparts(module_folder);
        if isempty(strfind(module_folder,filesep)) % only top level modue folder
            if isempty(strfind(module_folder(1),'_')) && isempty(strfind(module_folder,'TEST')) % avoid modules starting with _
                full_module_folder=[climada_global.modules_dir filesep module_folder];
                fprintf('* updating %s\n',module_folder);
                cd(full_module_folder)
                if ~TEST_mode,git pull,end
            end
        end
    end
end % while ~isempty(P)

% restore path
cd(current_path)

end % climada_git_pull