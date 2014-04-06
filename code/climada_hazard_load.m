function hazard=climada_hazard_load(hazard_file)
% climada
% NAME:
%   climada_hazard_load
% PURPOSE:
%   load a hazard event set (just to avoid typing long paths and
%   filenames in the cmd window)
% CALLING SEQUENCE:
%   entity_out=climada_hazard_load(hazard_file)
% EXAMPLE:
%   entity_out=climada_hazard_load(hazard_file)
% INPUTS:
%   hazard_file: the filename with path of a previously saved hazard event
%       set
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   hazard: a struct, see e.g. climada_tc_hazard_set
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20140302
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('hazard_file','var'),hazard_file=[];end

% PARAMETERS
%

% prompt for hazard_file if not given
if isempty(hazard_file) % local GUI
    hazard_file=[climada_global.data_dir filesep 'hazards' filesep '*.mat'];
    [filename, pathname] = uigetfile(hazard_file, 'Load hazatd event set:');
    if isequal(filename,0) || isequal(pathname,0)
        hazard = []; return; % cancel
    else
        hazard_file=fullfile(pathname,filename);
    end
end

load(hazard_file); % really the only code line

return

