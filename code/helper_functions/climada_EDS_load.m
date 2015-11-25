function EDS_out=climada_EDS_load(EDS_file)
% climada
% NAME:
%   climada_EDS_load
% PURPOSE:
%   load a previously saved EDS (just to avoid typing long paths and
%   filenames in the cmd window)
% CALLING SEQUENCE:
%   EDS_out=climada_EDS_load(EDS_file)
% EXAMPLE:
%   EDS_out=climada_EDS_load(EDS_file)
% INPUTS:
%   EDS_file: the filename with path of a previously saved EDS, see
%       climada_EDS_save
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   EDS_out: a struct, see e.g. climada_EDS_calc for details
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091230
% David N. Bresch, david.bresch@gmail.com, 20130316, ELS->EDS...
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('EDS_file','var'),EDS_file=[];end

% PARAMETERS
%

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

load(EDS_file)
EDS_out=EDS;

return

