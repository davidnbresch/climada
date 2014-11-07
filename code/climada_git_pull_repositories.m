function climada_git_pull_repositories(TEST_mode,git_pull_command)
% climada
% NAME:
%   climada_git_pull_repositories
% PURPOSE:
%   Execute a git pull on core climada and all repositories
%   
%   Automatically updates all local repositories' code, including core
%   climada. Only prerequisite: git installed locally (such that the system
%   command 'git pull' is valied, see OPTIONAL INPUT git_pull_command)
%   
%   see also climada_code_copy
% CALLING SEQUENCE:
%   climada_git_pull_repositories(TEST_mode,git_pull_command)
% EXAMPLE:
%   climada_git_pull_repositories
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   TEST_mode: idf =1, do not execute any system command, just lost them to
%       stdout, =0, execute (default)
%   git_pull_command: the local operating system's <git pull> command
%       default ='git pull'
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141102, initial
% David N. Bresch, david.bresch@gmail.com, 20141107, TEST_mode added
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('TEST_mode','var'), TEST_mode = 0;end
if ~exist('git_pull_command','var'), git_pull_command = 'git pull';end

% PARAMETERS
%


% run the git pull for climada code
fprintf('-- processing climada core:\n');
command_str=sprintf('cd %s ; %s',climada_global.root_dir,git_pull_command);
fprintf(' > %s\n',command_str)
if ~TEST_mode,system(command_str);end

% get all local modules
D=dir(climada_global.modules_dir);
rep_i=1;
for module_i=1:length(D)
    if D(module_i).isdir && ~strcmp(D(module_i).name(1),'.')
        repository_list{rep_i}=D(module_i).name;
        rep_i=rep_i+1;
    end
end % module_i

% run the git pull for all local modules
fprintf('-- processing climada modules:\n');
for repository_i=1:length(repository_list)
    command_str=sprintf('cd %s%s%s ; %s',climada_global.modules_dir,filesep,repository_list{repository_i},git_pull_command);
    fprintf(' > %s\n',command_str)
    if ~TEST_mode,system(command_str);end
end % repository_i

return
