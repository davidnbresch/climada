function climada_code_copy(verbose)
% climada code copy
% NAME:
%   climada_code_copy
% PURPOSE:
%   Copy all climada code and code of all active modules into a new folder
%   structure for easy exchange (e.g. to be zipped and sent by email).
%   Overwrites any existing climada_code_bucket folder (in order to have a
%   clean code version, delete any possibly existing climada_code_bucket
%   folder before calling)
%
%   It's mainly intended to be used to support users unable to get git
%   installed. That's why there is no 'code extract' or the like, as the
%   local names of the user's repositories might differ etc.
%
%   see also climada_git_pull_repositories (recommended for all with local
%   git installed, since much more comprehensive, user-friendly etc.)
% CALLING SEQUENCE:
%   climada_code_copy(verbose)
% EXAMPLE:
%   climada_code_copy
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   verbose: if =1, lost copied files to stdout
%       if =2, only list filenames, without folder
%       if =0, silent, only notify errors (default)
% OUTPUTS:
%   writes a folder [climada_global.root_dir]\climada_code_bucket with code
%       for core climada and modules as sub-folders
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141105
% David N. Bresch, david.bresch@gmail.com, 20141107, cleanup (on flight to Dubai)
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('verbose','var'),verbose=0;end

% PARAMETERS
%
dest_code_folder=[fileparts(climada_global.root_dir) filesep 'climada_code_bucket'];

% copy core climada code
fprintf('-- processing climada core\n');
climada_code_copy_folder([climada_global.root_dir filesep 'code'],[dest_code_folder filesep 'code'],verbose);

% copy all modules code:
D=dir(climada_global.modules_dir);
for module_i=1:length(D)
    if D(module_i).isdir && ~strcmp(D(module_i).name(1),'.')
        fprintf('-- processing climada module %s\n',D(module_i).name);
        source_folder=[climada_global.modules_dir filesep D(module_i).name filesep 'code'];
        dest_folder=[dest_code_folder filesep deblank(D(module_i).name) '_code'];
        %fprintf('%s --> %s\n',source_folder,dest_folder);
        climada_code_copy_folder(source_folder,dest_folder,verbose);
    end
end % module_i

fprintf('Note: now zip %s and distribute by e-mail...\n',dest_code_folder);

end

function climada_code_copy_folder(source_folder,dest_folder,verbose)

D=dir(source_folder);

[fP,fN]=fileparts(dest_folder);
if ~exist(dest_folder,'dir'),mkdir(fP,fN);end

if verbose,fprintf('\n%s:\n',source_folder);end

for file_i=1:length(D)
    if ~D(file_i).isdir
        source_file=[source_folder filesep D(file_i).name];
        dest_file=[dest_folder filesep D(file_i).name];
        if verbose==1
            fprintf('%s --> %s\n',source_file,dest_file);
        elseif verbose==2
            fprintf('%s\n',D(file_i).name);
        end
        [SUCCESS,MESSAGE] = copyfile(source_file,dest_file);
        if ~SUCCESS,fprintf('%s\n',MESSAGE);end
    elseif ~strcmp(D(file_i).name(1),'.')
        % recursively copy sub-folders (except the .* ones)
        climada_code_copy_folder([source_folder filesep D(file_i).name],[dest_folder filesep D(file_i).name],verbose);
    end
end % file_i

if verbose,fprintf('\n');end

end
