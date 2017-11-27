function [output_file, mat_version] = climada_save_mat_for_octave(input_file,path_out_or_type,mat_version,same_dir,force_overwrite)
% init hazard structure
% MODULE:
%   climada advanced
% NAME: 
%   climada_save_mat_for_octave
% PURPOSE:
%   save .mat file in another (older) version for compatibility with
%   Octave. Typically version -v6, as octave can currently not load v7 and above.
%   Usually applied to make a data set (hazard set, entities, etc.) ready
%   to use in an Octave environment.
% CALLING SEQUENCE:
%   [output_file, mat_version] = climada_save_mat_for_octave(input_file,path_out_or_type,mat_version,same_dir,force_overwrite)
%   could be preceded by any function creating .mat or a struct to save, i.e.:
%   - save
%   - climada_hazard_load
%   - climada_entity_read
% EXAMPLEs:
%   climada_save_mat_for_octave('GLB_0360as_TC','entities',6,0,0);
%   [output_file, mat_version] = climada_save_mat_for_octave(input_file,path_out_or_type)
%   output_file = climada_save_mat_for_octave('MEX_Mexico_atl_TC','hazards');
%   output_file = climada_save_mat_for_octave('entitystruct_example.mat','entities',6,1,0);
%   climada_save_mat_for_octave('~/Documents/MATLAB/climada_data/entities/entitystruct_example.mat','~/Documents/MATLAB/climada_data/entities/',6,1,0);
% INPUTS: 
%   input_file: 
%           Path to .mat-file that should be saved with another version.
%           Note: Filename only can also provided without full path in case
%           path_out_or_type equals either 'centroids', 'entities', 'hazards', 'results',
%           system', 'tc_tracks' or ''. In this case, the full path will be auto-completed.  
%               
% OPTIONAL INPUT PARAMETERS:
%   path_out_or_type:    
%           Path where to save new .mat-file.
%           If not given, set to same as input_path or standard
%           path.
%           If given path_out_or_type ends neither on '/' (i.e. filesep) nor on
%           '.mat' it is assumed to be the path of the folder only and '/'
%           (filesep) is added.
%           If either of the filetypes 'centroids', 'entities', 'hazards', 'results',
%           'system', 'tc_tracks', 'data_dir' or '' is given instead of a path, output is saved
%           in climada_data_octave/'type'.
%           This also Allows to give input_file without full path.
%   mat_version:    
%           String specifying .mat-version used for saving (Default: '-v6')
%           Or: number specifying version (Default: 6) 
%   same_dir:
%           Logical:
%           0 = no effect
%           1 = output file is saved in same folder as input file,
%               with '_oct' added to filename.
%               Warning: same_dir = 1 can overwrite output path handed over in path_out_or_type
%           (Default: 1)
%                Example:
%           same_dir = 1
%           input_file  = '~/Documents/MATLAB/climada_data/hazards/MEX_Mexico_atl_TC.mat'
%           -->
%           output_file = '~/Documents/MATLAB/climada_data/hazards/MEX_Mexico_atl_TC_oct.mat'
%   force_overwrite:
%           Logical:
%           0 = never overwrite existing file
%           1 = force overwrite if file is already given   
%           if variable is not given, user is asked before overwriting
%
% OUTPUTS:
%   output_file: a string specifying where the new .mat-file was saved
%   mat_version: string specifying .mat-version used for saving (Default: '-v6')
%
% COMMENT:
%   It is best practice to give filetypes as path_out_or_type.
%
%   If path_out_or_type is not provided, output is saved to same folder
%   hierarchy as input_file has, but in data folder "climada_data_octave":  
%   Example:
%   input_file  = '~/Documents/MATLAB/climada_data/hazards/MEX_Mexico_atl_TC.mat'
%   -->
%   output_file = '~/Documents/MATLAB/climada_data_octave/hazards/MEX_Mexico_atl_TC.mat'
%
% MODIFICATION HISTORY:
% Samuel Eberenz, samweli@posteo.de, 20171031, init
% Samuel Eberenz, samweli@posteo.de, 20171102, parameters "same_dir" and "force_overwrite" added
% Samuel Eberenz, samweli@posteo.de, 20171109, debugged while loop
%%

% Check whether input_file is a string or char specifying a file or a struct to
% be saved to a.mat-file, and continue accordingly

global climada_global
%% CHECK input parameters and prepare the function's variables
try % input_file is expected to contain file name or path of input_file (*.mat)
    [fP,fN,fE]=fileparts(char(input_file)); % decompose input path
    if isempty(fE),fE='.mat';end
    if isempty(fN), error('Input file name not recognized.');end
catch
    error('*input_file* is expected to contain file name or path of input_file (*.mat)!')
end

if ~exist('mat_version','var') || isempty(mat_version) || isequal(mat_version,''),mat_version='-v6';end
if isnumeric(mat_version), mat_version = ['-v' num2str(mat_version)] ; end
if ~exist('same_dir','var') || isempty(same_dir),same_dir=1;end
if ~exist('force_overwrite','var') || isempty(force_overwrite),force_overwrite=-1;end

if exist('path_out_or_type','var') && ~isempty(path_out_or_type) 
    switch path_out_or_type
        case 'centroids'
            ipath = climada_global.centroids_dir;
        case 'entities'
            ipath = climada_global.entities_dir;
        case 'hazards'
            ipath = climada_global.hazards_dir;
        case 'results'
            ipath = climada_global.results_dir;
        case 'system'
            ipath = climada_global.system_dir;
        case 'tc_tracks'
            ipath = [climada_global.data_dir filesep path_out_or_type];
        case ''
            ipath = climada_global.data_dir;
        case 'data_dir'
            ipath = climada_global.data_dir;
        otherwise
            clear ipath;
    end
else    % if no path_out_or_type is given
    fprintf('No output path specified.');
    path_out_or_type = false;
end

if exist('ipath','var') && ~same_dir
    path_out_or_type = replace(ipath,climada_global.data_dir,[climada_global.data_dir '_octave']);
elseif exist('ipath','var') && same_dir
    path_out_or_type = ipath;
end

if isempty(fP) %... check input file path
    if exist('ipath','var')
        fP = ipath;
    else
        error('Input path not specified.');
    end
end

%% SET output file name
if ~path_out_or_type
    % If path_out_or_type is not provided, output is saved to same folder (...)
    % hierarchy as input_file has, but in data folder "climada_data_octave" or in same folder with "_oct" added:    
    if same_dir % ammend output file name with "_oct" 
        fPo = fP;          % output path
        fNo = [fN '_oct']; % output file name
        fEo = fE;          % output file ending
    else % ammend output file path with "_octave"
        fPo = replace(fP,climada_global.data_dir,[climada_global.data_dir '_octave']); 
        fNo = fN;
        fEo = fE;
    end
else % if path_out_or_type is a complete path check syntax of path_out_or_type 
    if (~isequal(path_out_or_type(end),filesep) && ~isequal(path_out_or_type(end-3:end),fE)),path_out_or_type=[path_out_or_type filesep];end
    [fPo,fNo,fEo]=fileparts(char(path_out_or_type));
    if isempty(fPo) && ~same_dir,fPo = replace(fP,climada_global.data_dir,[climada_global.data_dir '_octave']);end
    if isempty(fEo),fEo=fE;end
    if isempty(fNo),fNo=fN;end
    if same_dir
        fPo = fP;
        fNo = [fNo '_oct'];
    end
end
output_file=[fPo filesep fNo fEo];
if ~exist(fPo,'dir'), mkdir(fPo); end % create output directory if necessary

while force_overwrite~=1 && exist(output_file,'file')
    if force_overwrite==0 || ~input('Overwrite file? 1=yes,0=no : ') % makes sure input file is not overwriten
    output_file = [output_file(1:end-4) '_oct' fE];
    fprintf('Added "_oct" to output file name to avoid overwritting. \n')
    else
        fprintf(['Overwriting file: ' output_file ' \n'])
        force_overwrite = 1;
    end
end
%% LOAD INPUT FILE
inputf=load([fP filesep fN fE]); % load input file

%% SAVE content of input_file to output_file:

save(output_file,'-struct','inputf',mat_version);

end





