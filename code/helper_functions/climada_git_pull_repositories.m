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
%   On some machines, the MATLAB system command seems not to execute
%   properly. In this case, the code writes a csh (C-Shell) script and
%   tries to execute it. If that fails again, it leaves the script there
%   and informs the user to execute it himself.
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
% David N. Bresch, david.bresch@gmail.com, 20150305, csh script option added
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
all_status=0;
for repository_i=1:length(repository_list)
    command_str=sprintf('cd %s%s%s ; %s',climada_global.modules_dir,filesep,repository_list{repository_i},git_pull_command);
    fprintf(' > %s\n',command_str)
    if ~TEST_mode
        status=system(command_str);
        all_status=all_status+status;
    end
end % repository_i

if all_status>0
    % try again, write a csh (C-Shell) script and execute it
    fprintf('-- 2nd try, using a csh (C-Shell) script:\n');
    fid=fopen('LOCAL_git_update_script','w');
    fprintf(fid,'#! /bin/csh -f\n');
    command_str=sprintf('cd %s ; %s',climada_global.root_dir,git_pull_command);
    fprintf(fid,'%s\n',command_str);
    for repository_i=1:length(repository_list)
        command_str=sprintf('cd %s%s%s ; %s',climada_global.modules_dir,filesep,repository_list{repository_i},git_pull_command);
        fprintf(fid,'%s\n',command_str);
    end % repository_i
    all_status=system('csh LOCAL_git_update_script');
    if all_status==0
        delete('LOCAL_git_update_script')
    end
end

if all_status>0
    fprintf('\nError: automatic git pull failed\n');
    fprintf('> please execute <csh  LOCAL_git_update_script> outside of MATLAB\n');
    fprintf('should this fail too, please execute <git pull> in each directory manually\n');
end

end % climada_git_pull_repositories