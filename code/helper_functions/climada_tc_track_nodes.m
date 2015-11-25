function [tc_track_nodes,tc_track_nodes_file]=climada_tc_track_nodes(tc_track_mat_file)
% climada tc track nodes
% MODULE:
%   core
% NAME:
%   climada_tc_track_nodes
% PURPOSE:
%   Given a .mat file with tc_track(i), usually named *_hist.mat 
%   (for historic, see climada_tc_read_unisys_database), 
%   construct the nodes file, usually named *_nodes.mat, i.e. the
%   file containing tc_track_nodes.lon(j) and tc_track_nodes.lat(j)
%
%   previous call: 
%   called from: centroids_generate_hazard_sets and climada_event_damage_data_tc
% CALLING SEQUENCE:
%   [tc_track_nodes,tc_track_nodes_file]=climada_tc_track_nodes(tc_track_mat_file)
% EXAMPLE:
%   [tc_track_nodes,tc_track_nodes_file]=climada_tc_track_nodes(tc_track_mat_file)
% INPUTS:
%   tc_track_mat_file: the mat file containing tc_track(i), most likely a
%       file *_hist.mat (but one can also use _prob.mat, in wich case the
%       output is named *_prob_nodes.mat instead of *_nodes.mat)
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   tc_track_nodes: a structure with all nodes of TC tracks, i.e.
%       lon(j): the node j
%       lat(j): the node j
%       track_no(j): the track number, tc_track(tc_track_nodes.track_no(j))
%           is the track node j comes from
%   tc_track_nodes_file: the name of the .mat file (*_nodes.mat) containing
%       tc_track_nodes
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150128, initial
%-

tc_track_nodes=[]; % init output
tc_track_nodes_file=''; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('tc_track_mat_file','var'),return;end

% construct the nodes filename
[fP,fN,fE]=fileparts(tc_track_mat_file);
fN=strrep(fN,'_hist','');
tc_track_nodes_file=[fP filesep fN '_nodes' fE];
    
if ~exist(tc_track_nodes_file,'file')
    load(tc_track_mat_file) % contains tc_track
    tc_track_nodes.lon=[];
    tc_track_nodes.lat=[];
    tc_track_nodes.track_no=[];
    fprintf('%s: collecting all nodes for %i TC tracks\n',mfilename,length(tc_track));
    for track_i=1:length(tc_track)
        tc_track_nodes.lon=[tc_track_nodes.lon tc_track(track_i).lon];
        tc_track_nodes.lat=[tc_track_nodes.lat tc_track(track_i).lat];
        tc_track_nodes.track_no=[tc_track_nodes.track_no (tc_track(track_i).lat)*0+track_i];
    end % track_i
    fprintf('saving TC track nodes as %s\n',tc_track_nodes_file);
    save(tc_track_nodes_file,'tc_track_nodes');
else
    load(tc_track_nodes_file) % contains tc_track_nodes
end
    
end % climada_tc_track_nodes