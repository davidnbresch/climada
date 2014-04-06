function tc_track_out=climada_tc_add_timestep(tc_track)
% climada tc track timestep
% NAME:
%   climada_tc_add_timestep
% PURPOSE:
%   add TimeStep [hours] to a TC track, which contains only date (yyyymmdd and time
%   in hours) of each node. TimeStep is defined between nodes (thus one
%   element shorter than nodes)
%
% CALLING SEQUENCE:
%   tc_track_out=climada_tc_add_timestep(tc_track)
% EXAMPLE:
%   tc_track_out=climada_tc_add_timestep(tc_track)
% INPUTS:
%   tc_track: a TC structure, e.g. as returned by climada_read_unisys_database
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   tc_track: a TC structure, with added TimeStep
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20120430
%-

tc_track_out=[]; % init output

if ~exist('tc_track','var'),return;end

% PARAMETERS
%

tc_track_out=tc_track; % copy

try
    
    if ~isfield(tc_track,'hh'),tc_track.hh=tc_track.time;end % backward compatibility
    
    % convert yyyymmdd and time to number
    N=datenum(tc_track.yyyy,tc_track.mm,tc_track.dd)+tc_track.hh/24;
    
    % calculate timesteps
    TimeStep=(N(2:end)-N(1:end-1))*24; % [hours]
    tc_track_out.TimeStep=TimeStep; % defined between nodes
    
catch
    fprintf('WARNING: adding TimeStep to tc_track failed\n');
end

% some final checks
[min_TS,min_TS_pos]=min(tc_track_out.TimeStep);
[max_TS,max_TS_pos]=max(tc_track_out.TimeStep);
if max(max_TS,abs(min_TS))>24
    fprintf('WARNING (starts %4.4i%2.2i%2.2i): TimeStep rather questionable, ranging from %f to %f\n',tc_track.yyyy(1),tc_track.mm(1),tc_track.dd(1),min_TS,max_TS);
    fprintf('        -> check original track file (approx. line %i,%i...)!\n',min_TS_pos+4,max_TS_pos+4);
end

return
