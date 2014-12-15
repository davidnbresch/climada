% climada_demo_step_by_step
% climada
% NAME:
%   climada_demo_step_by_step
% PURPOSE:
%   show the core climada key functionality step-by-step. Not a function,
%   just a batch-file to allow the user to step trough and inspect all
%   individual steps
% CALLING SEQUENCE:
%   climada_demo_step_by_step
% EXAMPLE:
%   climada_demo_step_by_step
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141215, updated
%-

global climada_global % make global variables accessible
if ~climada_init_vars,return;end % init/import global variables

% define the name and location of the raw text file with a sample of
% historical tropical cyclone tracks (obtained from weather.unisys.com/hurricane)
tc_track_file=[climada_global.data_dir filesep 'tc_tracks' filesep 'tracks.atl.txt'];

% read the track information into a structure
tc_track=climada_tc_read_unisys_database(tc_track_file);
% tc_track(i) contains position tc_track(i).lon(j) and tc_track(i).lat(j)
% for each timesetp j as well as the corresponding intensity tc_track(i).MaxSustainedWind

% for illustration purpose, show one track, track number 1170 is hurrican andrew
figure; plot(tc_track(1170).lon,tc_track(1170).lat,'-r'); hold on; set(gcf,'Color',[1 1 1]); axis equal
climada_plot_world_borders(2,'','',1) % plot world borders (for orinentation)

% in order to calculate the windfield of this particular single track,
% generate a series of points on which to evaluate the windfield, we call
% these points centroids
centroids.Longitude=[];centroids.Latitude=[]; % init
next_centroid=1; % ugly code, but explicit
for i=1:10
    for j=1:10
        centroids.Longitude(next_centroid)=i+(-85);
        centroids.Latitude(next_centroid) =j+  20;
        next_centroid=next_centroid+1;
    end % j
end % i
centroids.centroid_ID=1:length(centroids.Latitude); % we later needs this, just numbering the centroids

% next, calculate the windfield for this single track
res = climada_tc_windfield(tc_track(1170),centroids);

figure; climada_color_plot(res.gust,res.lon,res.lat); % plot the windfield

% generate the windfield not for one single hurricane, but for all events
% and store them in an organized way, the so-called hazard event set:
hazard_set_file=[climada_global.data_dir filesep 'hazards' filesep 'atl_hist'];
hazard = climada_tc_hazard_set(tc_track,hazard_set_file,centroids);

% and now this hazard evetn set contains the single andrew windfield we
% generated before in hazard.intensity(1170,:) and therefore we can
% reproduce the same windfield as (note the full(*), as we store a sparse
% matrix) 
figure; subplot(2,1,1)
climada_color_plot(full(hazard.intensity(1170,:)),hazard.lon,hazard.lat,'none'); % plot the windfield again
hold on;plot(-81,26,'Og');plot(centroids.Longitude(36),centroids.Latitude(36),'Og','MarkerSize',10);

% or, instead, we can plot all hazard intensities at a given point (green circle), e.g.
subplot(2,1,2)
plot(full(hazard.intensity(:,36))); set(gcf,'Color',[1 1 1]);
xlabel(sprintf('storm number, years %i..%i',tc_track(1).yyyy(1),tc_track(end).yyyy(end)))
ylabel('Intensity [m/s]')

% instead of only historic tracks, we can generate artificial or
% probabilistic track, simply by 'wiggling' the original tracks, eg for
% Andrew 1992 again:
tc_track_prob=climada_tc_random_walk(tc_track(1170));
figure; plot(tc_track(1170).lon,tc_track(1170).lat,'-r','LineWidth',2); hold on; set(gcf,'Color',[1 1 1]); axis equal
climada_plot_world_borders(2,'','',1) % plot world borders (for orinentation)
for track_i=1:length(tc_track_prob),plot(tc_track_prob(track_i).lon,tc_track_prob(track_i).lat,'-b');end

% and repeated for all historic tracks, we obtain the full probabilistic track set
waitbar_toggle % switch waitbar off, speeds up, hence the next line will take approx. 3 sec
tc_track_prob=climada_tc_random_walk(tc_track);

figure; 
for track_i=1:length(tc_track_prob),plot(tc_track_prob(track_i).lon,tc_track_prob(track_i).lat,'-b');hold on;end
for track_i=1:length(tc_track),plot(tc_track(track_i).lon,tc_track(track_i).lat,'-r');end
climada_plot_world_borders(2,'','',1); set(gcf,'Color',[1 1 1]); % plot world borders (for orinentation)


% next, we generate the windfields for all 14450 probabilistic tracks
% (takes a bit less than 2 min)
hazard_set_file=[climada_global.data_dir filesep 'hazards' filesep 'atl_prob'];
hazard = climada_tc_hazard_set(tc_track_prob,hazard_set_file,centroids);





