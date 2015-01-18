function info=climada_tc_track_info(tc_track)
% climada tc track info
% MODULE:
%   core
% NAME:
%   climada_tc_track_info
% PURPOSE:
%   Prints information of tracks to stdout (name, date....)
%
%   Prior call: climada_tc_read_unisys_tc_track
% CALLING SEQUENCE:
%   info=climada_tc_track_info(tc_track)
% EXAMPLE:
%   info=climada_tc_track_info(tc_track)
% INPUTS:
%   tc_track: a tc_track structure, as returned by
%       climada_tc_read_unisys_database or climada_tc_read_unisys_tc_track
%       > promted for if not given
%       Note: if a tc_track struct is passed, the user is prompted for the
%       specific single track (a plot shows all tracks to select from)
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   info contains some information, but to stdout is main purpose of this
%       routine
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150118, initial
%-

info=[]; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('tc_track','var'),tc_track=[];end

% PARAMETERS
%

% prompt for tc_track
if isempty(tc_track),[tc_track,tc_track_mat]=climada_tc_read_unisys_database;end % get tc_track

tc_track=climada_tc_stormcategory(tc_track); % add storm category

fprintf('iiii: name          yyyymmdd  category\n'); % header

for track_i=1:length(tc_track)
    info{track_i}=sprintf('%4.4i: %s (%4.4i%2.2i%2.2i) %i',track_i,...
        char(tc_track(track_i).name),...
        tc_track(track_i).yyyy(1),tc_track(track_i).mm(1),tc_track(track_i).dd(1),...
        max(tc_track(track_i).category));
    fprintf('%s\n',char(info{track_i}));
end

end % climada_tc_track_info