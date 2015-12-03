function measures_impact=climada_measures_impact_load(measures_impact_file,time_estimate)
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
% Jacob Anz, j.anz@gmx.net, 20151202, enable the loading of variables which are internally not exactly named measures_impact
% and add loading time estimate
%-

measures_impact=[];h_msgbox=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('measures_impact_file','var'),measures_impact_file=[];end
if ~exist('time_estimate','var'),time_estimate=0;end
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
 
%get an estimate for the loading time
if time_estimate==1;
    dirInfo = dir(pathname);info_location = strcmp({dirInfo.name},filename);
    filesize = dirInfo(info_location).bytes/1000000;duration=filesize*0.2; 
    %average estimated loading speed of 0.2 sec/MB, machine dependent
    h_msgbox=msgbox(sprintf('loading of %0.0f MB will take a minimum of %d seconds',filesize,ceil(duration)));
    child = get(h_msgbox,'Children');delete(child(2)); %delet 'ok' button, doesn't work if called from GUI
end

load(measures_impact_file); % contains measures_impact, the only line that really matters ;-)
close(h_msgbox)
%rename if named differently
clear dirInfo duration filesize info_location measures_impact_file h_msgbox child time_estimate
var=who; workspace_loc = strfind(var,'measures_imp');
for i=1:length(var);if workspace_loc{i}==1,ind=i;end;end
eval_name=sprintf('%s',var{ind});measures_impact=eval(eval_name);

end % climada_measures_impact_load



