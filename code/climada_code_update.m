function climada_code_update(code_bucket_folder)
% Import the latest climada code update
% NAME:
%	climada_code_update
% PURPOSE:
%   Automate the import of updated climada code files.
%
%   NOTE: For this routine to work, it is assumed that the existing
%   climada module directories are of the form climada_module_x_x. The code
%   in these directories should be stored in a subfolder named 'code'.
%   Finally, this function relies on the fact that the name of the climada
%   module dirs, i.e. climada_module_x_x, is contained within the name of
%   the respective folder in climada_code_bucket.
%
%   See climada_code_copy, which copies all climada code and code of all
%   active modules into a new folder structure for easy exchange (e.g. to
%   be zipped and sent by email).
% CALLING SEQUENCE:
%   climada_code_update(code_bucket_folder)
% EXAMPLE:
%   climada_code_update(code_bucket_folder)
%   climada_code_update
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   code_bucket_folder: Specify the path of the unzipped climada code
%       bucket, containing the code files to be extracted and copied into
%       the climada code folders.
% OUTPUTS:
% RESTRICTIONS:
% MODIFICATION HISTORY:
% Gilles Stassen, gillesstassen@hotmail.com 20141124
% David N. Bresch, david.bresch@gmail.com, 20141125, reference to climada_code_copy added
%-

global climada_global
if ~climada_init_vars,return;end

if ~exist('code_bucket_folder','var'), code_bucket_folder = []; end

if isempty(code_bucket_folder)
    code_bucket_folder = uigetdir(climada_global.root_dir, 'Select climada code bucket folder:');
    if isequal(code_bucket_folder,0)
        return; % cancel
    end
end

c_b_dir = dir(code_bucket_folder);
mod_dir = dir(climada_global.modules_dir);
new_mod_file = [];

fprintf('Updating code... ')

for i = 1:length(c_b_dir)
    if length(c_b_dir(i).name)<=2
        continue; % Ignore the . and .. files
    end
    
    if strcmp(c_b_dir(i).name, 'code')
        % Update core climada
        s_path = [code_bucket_folder filesep c_b_dir(i).name];
        s_files = dir(s_path);
        for k = 1:length(s_files)
            [~, ext] = strtok(s_files(k).name,'.'); % Get extension
            if  strcmp(ext,'.m')
                % Move each .m file
                movefile([s_path filesep s_files(k).name],...
                    [climada_global.root_dir filesep filesep 'code']);
            end
        end
    else
        % Update climada modules
        mod_exists = 0;
        s_path = [code_bucket_folder filesep c_b_dir(i).name];
        for j = 1: length(mod_dir)
            s_files = dir(s_path);
            
            if ~isempty(strfind(c_b_dir(i).name,mod_dir(j).name)) && ...
                    (length(mod_dir(j).name) > 2)
                mod_exists = 1;
                for k = 1:length(s_files)
                    [~, ext] = strtok(s_files(k).name,'.'); % Get extension
                    if  strcmp(ext,'.m')
                        % Move each .m file
                        movefile([s_path filesep s_files(k).name],...
                            [climada_global.modules_dir filesep mod_dir(j).name filesep 'code']);
                    end
                end
                
                % If there is no existing module with the same name
                % (all existing modules have been checked, i.e. j ==
                % length(mod_dir)), then add new module
            elseif ~mod_exists && length(c_b_dir(i).name)>2 && j == length(mod_dir)
                new_mod = [climada_global.modules_dir filesep c_b_dir(i).name filesep 'code'];
                mkdir(new_mod);
                new_mod_file{end + 1} = cellstr(c_b_dir(i).name);
                for k = 1:length(s_files)
                    [~, ext] = strtok(s_files(k).name,'.'); % Get extension
                    if  strcmp(ext,'.m')
                        % Move each .m file
                        movefile([s_path filesep s_files(k).name],new_mod);
                    end
                end
            end
        end
    end
end

fprintf('Done \n');
if ~isempty(new_mod_file)
    fprintf('New modules added: \n');
    for i = 1:length(new_mod_file)
        fprintf('\t\t%s\n',char(new_mod_file{i}));
    end
end

end