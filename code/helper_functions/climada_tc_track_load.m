function tc_track=climada_tc_track_load(tc_track_filename,check_plot)
% climada tc track load
% MODULE:
%   core
% NAME:
%   climada_tc_track_load
% PURPOSE:
%   Load a previously generated tc_track strcuture
%
%   Prior call: climada_tc_read_unisys_tc_track
%   Possible subsequent call: climada_tc_track_info
% CALLING SEQUENCE:
%   tc_track=climada_tc_track_load(tc_track_filename,check_plot)
% EXAMPLE:
%   tc_track=climada_tc_track_load(tc_track_filename)
% INPUTS:
%   tc_track_filename: a filename of a .mat file containign a tc_track
%       structure, as returned by climada_tc_read_unisys_database or
%       climada_tc_read_unisys_tc_track
%       If only a filename is given, the default path (../tc_tracks) is
%       presumed, and if only a basin is given (e.g. atl_hist), the
%       filename is completed (to tracks.atl_hist.mat)
%       > promted for (.mat) if not given
% OPTIONAL INPUT PARAMETERS:
%   check_plot: if =1, show checkplot, =0 not (default)
%       =-1; ONLY check plot, do not print info to stdout
%       =-2; only check plot and only historic events (to create the e.g.
%       the slide to show hist/prob, see boundary_rect also)
%       Info: this just calls climada_tc_track_info(tc_track,check_plot)
% OUTPUTS:
%   tc_track: a tc_track structure, as returned by
%       climada_tc_read_unisys_database or climada_tc_read_unisys_tc_track
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20160516, initial
%-

tc_track=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('tc_track_filename','var'),tc_track_filename='';end
if ~exist('check_plot','var'),check_plot=0;end

% PARAMETERS
%

if isempty(tc_track_filename) % local GUI
    tc_track_filename=[climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    [filename, pathname] = uigetfile(tc_track_filename, 'Select tc_track file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        tc_track_filename=fullfile(pathname,filename);
    end
elseif ~exist(tc_track_filename,'file')
    % complete path, if missing
    [fP,fN,fE]=fileparts(tc_track_filename);
    if isempty(fP),fP=[climada_global.data_dir filesep 'tc_tracks'];end
    if isempty(fE),fE='.mat';end
    tc_track_filename=[fP filesep fN fE];
    if ~exist(tc_track_filename,'file')
        [fP,fN,fE]=fileparts(tc_track_filename);
        fN=['tracks.' fN]; % prepend tracks.
        tc_track_filename=[fP filesep fN fE];
    end
end

if exist(tc_track_filename,'file')
    load(tc_track_filename)
    if abs(check_plot)>0,climada_tc_track_info(tc_track,check_plot);end
end

end % climada_tc_track_load