function EDS = climada_EDS_load(EDS)
% climada
% NAME:
%   climada_EDS_load
% PURPOSE:
%   load a previously saved EDS (just to avoid typing long paths and
%   filenames in the cmd window)
% CALLING SEQUENCE:
%   EDS = climada_EDS_load(EDS)
% EXAMPLE:
%   EDS = climada_EDS_load(EDS)
% INPUTS:
%   EDS: the filename with path of a previously saved EDS, see
%       climada_EDS_save. If no path provided, default path ../data/results is used
%       (and name can be without extension .mat)  
%       > promted for if not given
%       OR: a EDS structure, in which case it is just returned (to allow
%       calling climada_EDS_load anytime, see e.g. climada_DFC_fit)
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   EDS: a struct, see e.g. climada_EDS_calc for details
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091230
% David N. Bresch, david.bresch@gmail.com, 20130316, ELS->EDS...
% Lea Mueller, muellele@gmail.com, 20160307, enhance to work with complete EDS as input, similar to climada_hazard_load
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('EDS','var'),EDS=[];end

% PARAMETERS
%
% if already a complete EDS, return
if isstruct(EDS)
    return % already a EDS
else
    EDS_file=EDS;EDS=[];
    % from now on, EDS_file is the input and EDS will be output
end

% prompt for EDS_file if not given
if isempty(EDS_file) % local GUI
    EDS_file=[climada_global.data_dir filesep 'results' filesep '*.mat'];
    [filename, pathname] = uigetfile(EDS_file, 'Open EDS:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        EDS_file=fullfile(pathname,filename);
    end
end

% complete path, if missing
[fP,fN,fE]=fileparts(EDS_file);
if isempty(fP),fP=[climada_global.data_dir filesep 'results'];end
if isempty(fE),fE='.mat';end
EDS_file=[fP filesep fN fE];

if ~exist(EDS_file,'file')
    fprintf('ERROR: EDS does not exist %s\n',EDS_file);
    return
else
    load(EDS_file); % contains EDS, the only line that really matters ;-)
end

% check for valid/correct hazard.filename
if isfield(EDS,'filename')
    if ~strcmp(EDS_file,EDS.filename)
        EDS.filename=EDS_file;
        save(EDS_file,'EDS')
    end
end


return % climada_EDS_load

