function climada_git_pull(TEST_mode)
% climada git pull
% MODULE:
%   core
% NAME:
%   climada_git_pull
% PURPOSE:
%   git pull for climada, first the core module, then all installed modules
%
%   avoids all modules where name starts with '_' or which contain 'TEST',
%   like _local_module, _local_TEST or local_TEST
%
%   Note: climada_git_push is nt implemented yet, as this might cause
%   trouble, i.e. as it might automatically check in (large) .mat files or
%   other stuff one did nort check. For the time, use a git tool or operate
%   git add, git commit and gut push on the command line yourself.
%
%   OLD VERSION: there is still climada_git_pull_repositories, which used a
%   c-shell (csh) to issue the git commands (hence needed a local git
%   installation). Please do NOT use climada_git_pull_repositories any
%   more.
%
%   previous call: startup (usually already executed)
%   next call: See Note above
% CALLING SEQUENCE:
%   climada_git_pull
% EXAMPLE:
%   climada_git_pull(1)
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   TEST_mode: =1 only show which paths will be processed, do not pull
%       default=0, i.e. run git pull
% OUTPUTS:
%   all messaging to stdout
% MODIFICATION HISTORY:
% david.bresch@gmail.com, 20160606, initial
% david.bresch@gmail.com, 20160609, added remark about old climada_git_pull_repositories
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('TEST_mode','var'),TEST_mode=[];end

% PARAMETERS
%
% define the MATLAB path delimiter
path_delimiter=':'; % default ':'
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
    [token,P] = strtok(P,path_delimiter);
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