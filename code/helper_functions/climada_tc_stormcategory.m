function  tc_track = climada_tc_stormcategory(tc_track)
% add  Saffir Simpson category for every tc track (former
% climada_add_tc_track_stormcategory)
% NAME:
%   climada_tc_stormcategory
% PURPOSE:
%   add storm category for every tc track according to saffir-simpson
%   hurricane scale
%   -1 tropical depression
%    0 tropical storm
%    1 Hurrican category 1
%    2 Hurrican category 2
%    3 Hurrican category 3
%    4 Hurrican category 4
%    5 Hurrican category 5
% CALLING SEQUENCE:
%   [tc_track] = climada_tc_stormcategory(tc_track)
% EXAMPLE:
%   [tc_track] = climada_tc_stormcategory(tc_track)
% INPUTS:
%	tc_track:    one or more tc_tracks (structure)
% OPTIONAL INPUT PARAMETERS:
%   none
% OUTPUTS:
%   tc_track:    tc_track with tc_track.category (array)
% Lea Mueller, 20110614
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




%% check wind speed record in knots
for track_i = 1:length(tc_track)
    if strcmp(tc_track(track_i).MaxSustainedWindUnit,'kn') ~= 1
        fprintf('Wind not recorded in kn, conversion to kn needed')
        return
    end
end

            
%% add storm category to tc track
%  Saffir-Simpson Scale in kn
v_categories = [34 64 83 96 113 135 1000];
track_count  = length(tc_track);
for track_i = 1:track_count %every track
    max_wind = max(tc_track(track_i).MaxSustainedWind);
    v_cat    = find (max_wind < v_categories)-2;
    tc_track(track_i).category = v_cat(1);
end


return            
            
            
            