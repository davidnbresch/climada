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
%   Note: climada_git_push is not implemented, as this might cause
%   trouble, i.e. as it might automatically check in (large) .mat files or
%   other stuff one did not check. For the time, use a git tool or operate
%   git add, git commit and gut push on the command line yourself.
%
%   Hint: If you encounter troubles on cluster, start matlab with matlab -nojvm
%   See also git command in MATLAB and http://git-scm.com/documentation
%
%   OLD VERSION: there is still climada_git_pull_repositories, which used a
%   c-shell (csh) to issue the git commands (hence needed a local git
%   installation). Please do NOT use climada_git_pull_repositories any
%   more.
%
%   previous call: startup (usually already executed)
%   next call: climada_data_check, see also Note above
% CALLING SEQUENCE:
%   climada_git_pull
% EXAMPLE:
%   climada_git_pull(1) % to TEST first
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   TEST_mode: =1 only show which paths will be processed, do not pull
%       default=0, i.e. run git pull
% OUTPUTS:
%   all messaging to stdout
% MODIFICATION HISTORY:
% david.bresch@gmail.com, 20160606, initial
% david.bresch@gmail.com, 20160609, added remark about old climada_git_pull_repositories
% david.bresch@gmail.com, 20160616, pathsep
% david.bresch@gmail.com, 20161013, note about error on cluster added
% david.bresch@gmail.com, 20170106, using simple system command, not git.m (had some troubles e.g. on cluster)
% david.bresch@gmail.com, 20170523, try..catch in module update
% david.bresch@gmail.com, 20170824, trial attempt to fix issue for machines with no LD_LIBRARY_PATH
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('TEST_mode','var'),TEST_mode=[];end

% PARAMETERS
%
if isempty(TEST_mode),TEST_mode=0;end % default=0

current_path=pwd; % get active path (to restore later)

% first, update the climada root folder
% -------------------------------------
fprintf('* updating %s\n',climada_global.root_dir);
cd(climada_global.root_dir)
%if ~TEST_mode,git pull,end
if ~TEST_mode,climada_git_pull_local_git_pull;end


% second, update all climada modules
% ----------------------------------

P=path; % get all paths

while ~isempty(P)
    [token,P] = strtok(P,pathsep);
    % check for a climada module path
    if ~isempty(strfind(token,climada_global.modules_dir)) % a module
        module_folder=strrep(token,[climada_global.modules_dir filesep],'');
        module_folder=fileparts(module_folder);
        if isempty(strfind(module_folder,filesep)) % only top level module folder
            try
                if isempty(strfind(module_folder(1),'_')) && isempty(strfind(module_folder,'TEST')) % avoid modules starting with _
                    full_module_folder=[climada_global.modules_dir filesep module_folder];
                    fprintf('* updating %s\n',module_folder);
                    cd(full_module_folder)
                    %if ~TEST_mode,git pull,end
                    if ~TEST_mode,climada_git_pull_local_git_pull;end
                end
            catch ME
                fprintf('%s\n',ME.message);
            end % catch
        end
    end
end % while ~isempty(P)

% restore path
cd(current_path)

if climada_data_check(0)
    fprintf('It is strongly recommended to update listed files, consider running climada_data_check(-1)\n');
end

end % climada_git_pull


function ok=climada_git_pull_local_git_pull
% local simple system command to execute git pull, return status=0 if OK
ok=0; % init output
%[status,result]=system('git pull'); % works on MAC, but not on cluster
[status,result]=system('LD_LIBRARY_PATH="" git pull'); % fix to avoid using Matlab-Libs for git command
ok=~status;
if status>0 % =0 mean success
    fprintf('ERROR: %s',result) % seems to contain EoL, hence no \n
    % try again (might work on some devices with git installed but not UNIX/LINUX) 20170824
    [status,result]=system('git pull'); % fix to avoid using Matlab-Libs for git command
    ok=~status;
    if status>0 % =0 mean success
        fprintf('ERROR: %s',result) % seems to contain EoL, hence no \n
    else
        fprintf('%s',result); % seems to contain EoL, hence no \n
    end
else
    fprintf('%s',result); % seems to contain EoL, hence no \n
end
end % climada_git_pull_local_git_pull