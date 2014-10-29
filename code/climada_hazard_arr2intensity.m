function hazard=climada_hazard_arr2intensity(hazard_file)
% climada
% NAME:
%   climada_hazard_arr2intensity
% PURPOSE:
%   switch from hazard.arr to hazard.intensity, i.e. load a hazard set and
%   rename the field.
%
%   We decided 20141017 to switch from hazard.arr to hazard.intensity,
%   sincde this fieldname is more telling.
% CALLING SEQUENCE:
%   hazard=climada_hazard_arr2intensity(hazard_file)
% EXAMPLE:
%   hazard=climada_hazard_arr2intensity(hazard_file)
% INPUTS:
%   hazard_file: the filename with path of a previously saved hazard event set
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   hazard: a struct, see e.g. climada_tc_hazard_set
%   the hazard with the fielname changed is saved back to the original .mat
%   file
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141017
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
    [filename, pathname] = uigetfile(hazard_file, 'Load hazard event set:');
    if isequal(filename,0) || isequal(pathname,0)
        hazard = []; return; % cancel
    else
        hazard_file=fullfile(pathname,filename);
    end
end

load(hazard_file); % really the only code line, loads hazard
if isfield(hazard,'arr')
    hazard.intensity=hazard.arr;
    hazard=rmfield(hazard,'arr');
    fprintf('hazard saved as %s\n',hazard_file);
    save(hazard_file,'hazard');
elseif isfield(hazard,'intensity')
    fprintf('hazard does already contain a field hazard.intensity, no change necessary\n');
else
    fprintf('WARNING: further inspection needed, hazard does not contain neither .arr nor .intensity\n'); 
end

return

