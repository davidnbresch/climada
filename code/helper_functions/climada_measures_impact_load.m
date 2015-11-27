function measures_impact=climada_measures_impact_load(measures_impact_file)
% climada
% MODULE:
%   climada core
% NAME:
%   climada_measures_impact_load
% PURPOSE:
%   load a previously saved measures_impact (just to avoid typing long paths and
%   filenames in the command window)
% CALLING SEQUENCE:
%   measures_impact_out=climada_measures_impact_load(measures_impact_file)
% EXAMPLE:
%   measures_impact_out=climada_measures_impact_load(measures_impact_file)
% INPUTS:
%   measures_impact_file: the filename (with path, optional) of a previously saved
%       measures_impact, see salvador_calc_measures
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   measures_impact_out: a struct, see e.g. salvador_calc_measures for details
% MODIFICATION HISTORY:
% Jacob Anz, j.anz@gmx.net, 20151106, init
% Lea Mueller, muellele@gmail.com, 20151127, enhance to work with complete measures_impact as input
%-

measures_impact=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('measures_impact_file','var'),measures_impact_file=[];end

% PARAMETERS
%

% if already a complete entity, return
if isfield(measures_impact_file,'EDS'), measures_impact = measures_impact_file; return, end


% prompt for entity_file if not given
if isempty(measures_impact_file) % local GUI
    measures_impact_file=[climada_global.data_dir filesep 'results' filesep '*.mat'];
    [filename, pathname] = uigetfile(measures_impact_file, 'Select measures_impact to open:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        measures_impact_file=fullfile(pathname,filename);
    end
end

% complete path, if missing
[fP,fN,fE]=fileparts(measures_impact_file);
if isempty(fP),measures_impact_file=[climada_global.data_dir filesep 'results' filesep fN fE];end

load(measures_impact_file); % contains measures_impact, the only line that really matters ;-)

end % climada_measures_impact_load



