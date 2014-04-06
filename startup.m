% startup file to set environment for climada
% (c) David N. Bresch, 2008, 2014, david.bresch@gmail.com
%
% define the climada root directory
% --------------------------------
climada_root_dir=pwd; % current directory (print working directory)
%
%clc % clear command window

fprintf('climada, Copyright (C) 2014, david.bresch@gmail.com\n');
fprintf('This program comes with ABSOLUTELY NO WARRANTY\n');

% create the root dir of additional
climada_root_dir_additional=[fileparts(climada_root_dir) filesep 'climada_additional'];

% add to MATLAB path for code
% these last to be top in path list
addpath([climada_root_dir filesep 'code']);
if exist(climada_root_dir_additional,'dir')  
    fprintf('climada_additional modules found: \n');
    add_dir  = dir(climada_root_dir_additional);
    for a_i = 1:length(add_dir)
        if exist([climada_root_dir_additional filesep add_dir(a_i).name filesep 'code'],'dir')  
            addpath([climada_root_dir_additional filesep add_dir(a_i).name filesep 'code']);
            fprintf('\t %s\n',add_dir(a_i).name);
            
            % checking for sub-folders within code (only one level)
            sub_dir=[climada_root_dir_additional filesep add_dir(a_i).name filesep 'code'];
            add_subdir  = dir(sub_dir);
            for as_i = 1:length(add_subdir)
                if add_subdir(as_i).isdir && length(add_subdir(as_i).name)>2
                    addpath([sub_dir filesep add_subdir(as_i).name]);
                    fprintf('\t\t%s\n',add_subdir(as_i).name); 
                end
            end
            clear add_subdir as_i sub_dir
            
        end
    end
    clear add_dir a_i
end

% pass the global root directory
global climada_global
climada_global.root_dir = deblank(climada_root_dir);

fprintf('initializing climada... ');

%initialises the global variables
climada_init_vars;
fprintf('done\n');