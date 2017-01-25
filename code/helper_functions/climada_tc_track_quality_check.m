function tc_track=climada_tc_track_quality_check(tc_track)
% climada tc track info
% MODULE:
%   core
% NAME:
%   climada_tc_track_quality_check
% PURPOSE:
%   run quality check, i.e. reject tracks moving too fast (>10 degrees in
%   one timestep, see delta_node_dlonlat in PARAMETERS in code) and fix
%   dateline issue. Report fixed and spotted issues to stdout (for
%   dateline, just report the number of tracks that needed fixing).
%
%3684: nodes too far apart (11>10 degree)
%1442: nodes too far apart (14>10 degree)
%476: nodes too far apart (14>10 degree)
%   Prior call: climada_tc_track_info
%   Possible subsequent call: hold on;climada_entity_plot
% CALLING SEQUENCE:
%   tc_track=climada_tc_track_quality_check(tc_track)
% EXAMPLE:
%   tc_track=climada_tc_read_unisys_database('tracks.atl.txt');
% INPUTS:
%   tc_track: a tc_track structure, as returned by
%       climada_tc_read_unisys_database or climada_tc_read_unisys_tc_track
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   tc_track: the tc_track structure, quality checked and cleaned up.
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20170125, initial, moved from climada_tc_track_info to a separate routine
%-

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('tc_track','var'),return;end

% PARAMETERS
%
% parameters for sanity check:
delta_node_dlonlat=10; % in degree

tracks_selected=1:length(tc_track);

dateline_fixed_p360=0;
dateline_fixed_n360=0;

n_tracks=length(tc_track);
fprintf('\ncleanup:\n');

for track_i=1:n_tracks
    
    max_node_dlon=max(abs(diff(tc_track(track_i).lon)));
    if max_node_dlon>delta_node_dlonlat
        % try to fix, likely the dateline issue
        pos_pos=tc_track(track_i).lon>0;
        neg_pos=tc_track(track_i).lon<0;
        if sum(pos_pos)>sum(neg_pos)
            tc_track(track_i).lon(neg_pos)=mod(tc_track(track_i).lon(neg_pos)+360,360);
            dateline_fixed_p360=dateline_fixed_p360+1;
        else
            tc_track(track_i).lon(pos_pos)=tc_track(track_i).lon(pos_pos)-360;
            dateline_fixed_n360=dateline_fixed_n360+1;
        end
    end
                
    % check for nodes not to be further apart than delta_node_dlonlat
    max_node_dlonlat=max(max(abs(diff(tc_track(track_i).lon))),max(abs(diff(tc_track(track_i).lat))));
    if max_node_dlonlat>delta_node_dlonlat
        fprintf('%i: nodes too far apart (%2.0f>%2.0f degree)\n',track_i,max_node_dlonlat,delta_node_dlonlat);
        tracks_selected(track_i)=0; % remove
    end
    
end % track_i

if sum(dateline_fixed_p360+dateline_fixed_n360)>0
    fprintf('dateline fixed: %i (+360), %i (-360) tracks\n',dateline_fixed_p360,dateline_fixed_n360);
end

tc_track=tc_track(tracks_selected>0);
fprintf('originally %i tracks: %i tracks seem ok, %i tracks rejected\n',n_tracks,length(tc_track),n_tracks-length(tc_track));

end % climada_tc_track_quality_check