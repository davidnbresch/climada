function  [tc_track, seasons] = climada_tc_season(tc_track)
% add season for every tc track (former climada_add_tc_track_season)
% NAME:
%   climada_tc_season
% PURPOSE:
%   add season for every tc track 
% CALLING SEQUENCE:
%   [tc_track, seasons] = climada_tc_season(tc_track)
% EXAMPLE:
%   [tc_track, seasons] = climada_tc_season(tc_track)
% INPUTS:
%	tc_track:    one or more tc_tracks (structure)
% OPTIONAL INPUT PARAMETERS:
%   none
% OUTPUTS:
%   tc_track:    tc_track with tc_track.season (array)
% Lea Mueller, 20110620
%-


global climada_global
if ~climada_init_vars, return; end

% check inputs, and set default values
if ~exist('tc_track'       , 'var'), tc_track      = []  ; end

% prompt for probabilistic tc_track if not given
if isempty(tc_track)
    tc_track         = [climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    tc_track_default = [climada_global.data_dir filesep 'tc_tracks' filesep 'select tc track .mat'];
    [filename, pathname] = uigetfile(tc_track, 'Select tc track set:',tc_track_default);
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        tc_track = fullfile(pathname,filename);
    end
end
% load the tc track set, if a filename has been passed
if ~isstruct(tc_track)
    tc_track_file = tc_track;
    tc_track      = [];
    vars = whos('-file', tc_track_file);
    load(tc_track_file);
    if ~strcmp(vars.name,'tc_track')
        tc_track = eval(vars.name);
        clear (vars.name)
    end
end

% south indian ocean
season_start = datenum(0,7,1);

% north atlantic
season_start = datenum(0,6,1);

seasons      = [];
for track_i = 1:length(tc_track)
    tc_track(track_i).season =  tc_track(track_i).yyyy(1);
    if tc_track(track_i).mm(1)>6
        tc_track(track_i).season = tc_track(track_i).season+1;
    end
    season_storm(track_i) = tc_track(track_i).season;
end
seasons = unique(season_storm); 

return            
            
            
            