function climada_git_clone(TEST_mode)
% climada git clone
% MODULE:
%   core
% NAME:
%   climada_git_clone
% PURPOSE:
%   clone (most) climada modules (eases installation from scratch).
%
%   once you have core climada installed, run this code to get all other
%   modules installed (as sub-folders in climada_modules).
%   This code then creates the folder climada_data and copies
%   content of core climada's data into it.
%
%   DOES NOT YET WORK ON cluster, see same issue with climada_git_pull
%   See also git command in MATLAB and http://git-scm.com/documentation
%
%   previous call: startup (usually already executed)
%   next call: climada_demo_step_by_step
% CALLING SEQUENCE:
%   climada_git_clone
% EXAMPLE:
%   climada_git_clone(1)
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   TEST_mode: =1 only show which modules will be processed, do not create
%       default=0, i.e. run as stated above
% OUTPUTS:
%   all messaging to stdout
% MODIFICATION HISTORY:
% david.bresch@gmail.com, 20161013, initial
% david.bresch@gmail.com, 20161109, most modules switched on
% david.bresch@gmail.com, 20170106, climada_data_check
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('TEST_mode','var'),TEST_mode=[];end

% PARAMETERS
%
if isempty(TEST_mode),TEST_mode=0;end % default=0
%
module_list={
    'https://github.com/davidnbresch/climada_advanced.git'
    'https://github.com/davidnbresch/climada_module_isimip.git'
    'https://github.com/davidnbresch/climada_module_tropical_cyclone.git'
    'https://github.com/davidnbresch/climada_module_country_risk.git'
    'https://github.com/davidnbresch/climada_module_elevation_models.git'
    'https://github.com/davidnbresch/climada_module_storm_europe.git'
    'https://github.com/davidnbresch/climada_module_meteorite.git'
    'https://github.com/davidnbresch/climada_module_flood.git'
    'https://github.com/davidnbresch/climada_module_earthquake_volcano.git'
    'https://github.com/davidnbresch/climada_module_drought_fire.git'
    'https://github.com/davidnbresch/climada_module_kml_toolbox.git'
    %'https://github.com/davidnbresch/climada_module_salvador_demo.git'
    %'%https://github.com/davidnbresch/climada_module_barisal_demo.git'
    };

current_path=pwd; % get active path (to restore later)

% check for climada_modules folder
% --------------------------------
if isempty(climada_global.modules_dir)
    fP=fileparts(climada_global.root_dir);
    climada_global.modules_dir=[fP filesep 'climada_modules'];
end
if ~isdir(climada_global.modules_dir)
    [fP,fN]=fileparts(climada_global.modules_dir);
    fprintf('creating folder %s ...',climada_global.modules_dir);
    mkdir(fP,fN); % create it
    fprintf(' done\n');
end

% clone all modules not yet present
% ---------------------------------
cd(climada_global.modules_dir)
for module_i=1:length(module_list)
    module_name=module_list{module_i};
    % figure the folder name git clones to
    orig_module_dir=strrep(module_name,'https://github.com/davidnbresch/','');
    orig_module_dir=strrep(orig_module_dir,'.git','');
    % define the shorter folder name we want
    module_dir=strrep(orig_module_dir,'climada_','');
    module_dir=strrep(module_dir,'module_','');
    if exist(module_dir,'file')
        fprintf('%s already cloned, skipped\n',module_dir);
    else
        fprintf('cloning %s to >> %s\n',module_name,module_dir);
        system_cmd=['git clone ' module_list{module_i}];
        if TEST_mode
            fprintf('TEST: %s\n',system_cmd);
        else
            % clone the repository
            [status,result] = system(system_cmd);
            if status>0 % =0 mean success
                fprintf('ERROR: %s\n',result)
                fprintf('aborted\n')
                return
            end
            % move to the shorted folder name
            [SUCCESS,MESSAGE] = movefile(orig_module_dir,module_dir);
            if ~SUCCESS
                fprintf('ERROR: %s\n',MESSAGE)
                fprintf('aborted\n')
                return
            end
        end % TEST_mode
    end % exist(module_dir,'file')
end % module_i

% restore path
cd(current_path)

% check for climada_data folder
% -----------------------------

fP=fileparts(climada_global.root_dir);
local_data_dir=[fP filesep 'climada_data'];
if ~isdir(local_data_dir)
    [fP,fN]=fileparts(local_data_dir);
    fprintf('creating folder %s ...',local_data_dir);
    mkdir(fP,fN); % create it
    fprintf(' done\n');
    
    % copy data folder to local data folder
    % -------------------------------------
    % move to the shorted folder name
    fprintf('copying %s to %s',climada_global.data_dir,local_data_dir);
    if TEST_mode
        fprintf('\nTEST: copyfile(%s,%s)\n',climada_global.data_dir,local_data_dir);
    else
        [SUCCESS,MESSAGE] = copyfile(climada_global.data_dir,local_data_dir);
        if ~SUCCESS
            fprintf('\nERROR: %s\n',MESSAGE)
            fprintf('aborted\n')
            return
        else
            climada_global.data_dir=local_data_dir; % switch
            fprintf(' done\n');
        end
    end
else
    fprintf('note: %s already exists (occasionally check for updated content in climada/data)\n',local_data_dir);
    climada_data_check(TEST_mode)
end % ~isdir(local_data_dir)

end % climada_git_clone