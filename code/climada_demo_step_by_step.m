% climada_demo_step_by_step
% climada
% NAME:
%   climada_demo_step_by_step
% PURPOSE:
%   show the core climada key functionality step-by-step. Not a function,
%   just a batch-file to allow the user to step trough and inspect all
%   individual steps. See climada manual, as this code implements the
%   section "From tropical cyclone hazard generation to the adaptation cost
%   curve ? a step-by-step guide" provided there.
%
%   running it all takes (first time) about 3 minutes (faster on subsequent
%   calls, since the probabilistic hazard event set is loaded rather than
%   re-generated)
%
%   Note for Octave users: due to slower processing speed of Octave, the
%   demo runs with smaller datasets. Somple plots do not look nice, but all
%   calculations and core graphics (adaptation cost curve) work fine.
% CALLING SEQUENCE:
%   climada_demo_step_by_step
% EXAMPLE:
%   climada_demo_step_by_step
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141217, updated
% David N. Bresch, david.bresch@gmail.com, 20141231, octave-compatible
%-

global climada_global % make global variables accessible
if ~climada_init_vars(1),return;end % init/import global variables

climada_global.waitbar=0; % avoid waitbar popping up all the time

% define the name and location of the raw text file with a sample of
% historical tropical cyclone tracks (obtained from weather.unisys.com/hurricane)
tc_track_file=[climada_global.data_dir filesep 'tc_tracks' filesep 'tracks.atl.txt'];
if climada_global.octave_mode,tc_track_file=[climada_global.data_dir filesep 'tc_tracks' filesep 'TEST_tracks.atl.txt'];end % fewer tracks

% read the track information into a structure
tc_track=climada_tc_read_unisys_database(tc_track_file);
% tc_track(i) contains position tc_track(i).lon(j) and tc_track(i).lat(j)
% for each timesetp j as well as the corresponding intensity tc_track(i).MaxSustainedWind

% for illustration purpose, show one track
demo_track_number=1170; % track number 1170 is hurricane ANDREW, 1992
if climada_global.octave_mode,demo_track_number=68;end % JEANNE, 2004
figure; plot(tc_track(demo_track_number).lon,tc_track(demo_track_number).lat,'-r');
hold on; set(gcf,'Color',[1 1 1]); axis equal; title(tc_track(demo_track_number).name)
climada_plot_world_borders(2,'','',1) % plot world borders (for orientation)

% in order to calculate the windfield of this particular single track,
% generate a series of points on which to evaluate the windfield, we call
% these points centroids
centroids.lon=[];centroids.lat=[]; % init
next_centroid=1; % ugly code, but explicit
for i=1:10
    for j=1:10
        centroids.lon(next_centroid)=i+(-85);
        centroids.lat(next_centroid) =j+  20;
        next_centroid=next_centroid+1;
    end % j
end % i
centroids.centroid_ID=1:length(centroids.lat); % we later needs this, just numbering the centroids

% next, calculate the windfield for this single track
res = climada_tc_windfield(tc_track(demo_track_number),centroids);
title(sprintf('%s windfield',tc_track(demo_track_number).name))

figure;climada_color_plot(res.gust,res.lon,res.lat,'none'); % plot the windfield

if ~climada_global.octave_mode
    
    % generate the windfield not for one single hurricane, but for all events
    % and store them in an organized way, the so-called hazard event set:
    hazard_set_file=[climada_global.data_dir filesep 'hazards' filesep 'atl_hist'];
    hazard = climada_tc_hazard_set(tc_track,hazard_set_file,centroids);
    
    % and now this hazard event set contains the single andrew windfield we
    % generated before in hazard.intensity(demo_track_number,:) and therefore we can
    % reproduce the same windfield as (note the full(*), as we store a sparse
    % matrix)
    figure; subplot(2,1,1)
    climada_color_plot(full(hazard.intensity(demo_track_number,:)),hazard.lon,hazard.lat,'none'); % plot the windfield again
    hold on;plot(-81,26,'Og');plot(centroids.lon(36),centroids.lat(36),'Og','MarkerSize',10);
    
    % or, instead, we can plot all hazard intensities at a given point (green circle), e.g.
    subplot(2,1,2)
    plot(full(hazard.intensity(:,36))); set(gcf,'Color',[1 1 1]);
    xlabel(sprintf('storm number, years %i..%i',tc_track(1).yyyy(1),tc_track(end).yyyy(end)))
    ylabel('Intensity [m/s]')
    
    % instead of only historic tracks, we can generate artificial or
    % probabilistic track, simply by 'wiggling' the original tracks, eg for
    % Andrew 1992 again:
    tc_track_prob=climada_tc_random_walk(tc_track(demo_track_number));
    figure; plot(tc_track(demo_track_number).lon,tc_track(demo_track_number).lat,'-r','LineWidth',2); hold on; set(gcf,'Color',[1 1 1]); axis equal
    climada_plot_world_borders(2,'','',1) % plot world borders (for orinentation)
    for track_i=1:length(tc_track_prob),plot(tc_track_prob(track_i).lon,tc_track_prob(track_i).lat,'-b');end
    
    % and repeated for all historic tracks, we obtain the full probabilistic track set
    climada_global.waitbar=0; % switch waitbar off, speeds up, hence the next line will take approx. 3 sec
    tc_track_prob=climada_tc_random_walk(tc_track); % approx 3 sec
    
    figure;
    for track_i=1:length(tc_track_prob),plot(tc_track_prob(track_i).lon,tc_track_prob(track_i).lat,'-b');hold on;end
    for track_i=1:length(tc_track),plot(tc_track(track_i).lon,tc_track(track_i).lat,'-r');end
    climada_plot_world_borders(2,'','',1); set(gcf,'Color',[1 1 1]); % plot world borders (for orinentation)
    
    % next, we generate the windfields for all 14450 probabilistic tracks
    % (takes a bit less than 2 min)
    hazard_set_file=[climada_global.data_dir filesep 'hazards' filesep 'atl_prob.mat'];
    if exist(hazard_set_file,'file')
        load(hazard_set_file) % load to avoid waiting for 2 min
    else
        hazard = climada_tc_hazard_set(tc_track_prob,hazard_set_file,centroids); % approx 2 min
    end
    % let's inspect this hazard event set:
    figure; climada_hazard_plot(hazard); set(gcf,'Color',[1 1 1]); % plot largest event
    climada_hazard_stats(hazard); set(gcf,'Color',[1 1 1]); % plot the hazard intensity maps for various return periods
    
else
    fprintf('OCTAVE: generation of full proabilistic set skipped (takes much longer than in MATLAB)\n')
    
    tc_track_prob=climada_tc_random_walk(tc_track(demo_track_number));
    figure; plot(tc_track(demo_track_number).lon,tc_track(demo_track_number).lat,'-r','LineWidth',2); hold on; set(gcf,'Color',[1 1 1]); axis equal
    climada_plot_world_borders(2,'','',1) % plot world borders (for orinentation)
    for track_i=1:length(tc_track_prob),plot(tc_track_prob(track_i).lon,tc_track_prob(track_i).lat,'-b');end
    title('probabilistic tracks')
    
    hazard_set_file=[climada_global.data_dir filesep 'hazards' filesep 'TCNA_today_small.mat'];
    load(hazard_set_file) % load demo hazard event set
end


% Before we move on, make sure you understood the basic elements of the
% hazard structure, see the manual (approx. p. 11)
% hazard.lon(i) and hazard.lat(i) contain the coordinates of
% centroid i, hence hazard.intensity(j,i) contains the hazard intensity of
% event j at centroid i. Further hazard.frequency(j) contains the single
% event frequency of event j. These are in fact the key elements of the
% hazard structure, note that hazard.intensity is a sparse array (refer to
% e.g. help sparse in MATLAB ). You might refer to functions such as the
% mentioned climada_tc_hazard_set or climada_excel_hazard_set  to see how a
% hazard event set is generated.

% So much for the hazard event set, let?s now import an asset base (the
% small asset example as used in climada_demo, the demonstration GUI as
% shown above):

entity_excel_filename=[climada_global.data_dir filesep 'entities' filesep 'demo_today.xls'];

entity=climada_entity_read(entity_excel_filename,hazard);
% Such an entity structure contains the asset, damage function and
% adaptation measures information (see manual). Such an entity structure
% contains the asset, damage function and adaptation measures information,
% the tabs in Excel are named accordingly, and so are the elements of the
% imported structure . In the asset sub-structure, we find
% entity.assets.lat(k) and entity.assets.lon(k), the
% geographical position of asset k (does not need to be the same geographic
% location as centroid I, since assets are encoded to the hazard )
% entity.assets.Value(k) contains the Value of asset k. Please note that
% Value can be a value of any kind, not necessarily a monetary one, e.g. it
% could be number of people living in a given place. entity.assets
% .DamageFunID(k) contains a reference ID (integer) to link the specific
% asset with the corresponding damage function (see Excel tab
% damagefunctions and entity.damagefunctions). Before we move on the the
% damagefunctions, note that entity.assets.centroid_index(k) contains the
% centroid index onto which asset k is mapped in the hazard event set.

if ~climada_global.octave_mode
    figure; climada_entity_plot(entity,4); set(gcf,'Color',[1 1 1])
end

% The damagefunctions sub-structure contains all damage function
% information, i.e. entity.damagefunctions.DamageFunID contains the IDs
% which refers to the asset?s DamageFunID. This way, we can provide
% different damage functions for different (groups or sets of) assets.
% entity.damagefunctions.Intensity contains the hazard intensity,
% entity.damagefunctions.MDD the mean damage degree and
% entity.damagefunctions.PAA the percentage of affected assets. Last but
% not least, entity.damagefunctions.peril_ID contains the peril ID (2-digit
% character) which allows to indentify specific damage functons with
% perils. This way, we can in fact use DamageFunID 1 in the assets to link
% to damage function one, which can exist several times, one for each
% peril.

figure;climada_damagefunctions_plot(entity)

EDS=climada_EDS_calc(entity,hazard);
% Where EDS contains the event damage set, it contains the annual expected
% damage in EDS.ED, the event damage for event j in EDS.damage(j), the event
% frequency in EDS.frequency(j) and the event ID in EDS.event_ID(j). In
% futher fields it stores the link to the original assets, the
% damagefunctions and hazard set used. Instead of plotting the event damage
% set (here a vector with 14450 elements), one rather refers to the damage
% excess frequency curve:

figure; climada_EDS_DFC(EDS) % show damage excess frequency curve

% While one would in a proper application of climada now calculate the
% damages of future assets (to obtain the effect f economic growth) and
% then further repeat the calculation with a future hazard set (to obtain
% the effect of climate change), we illustrate the benefit of adaptation
% measures by simply using the assets and hazard we have already used.

% As mentioned, the entity structure contains not only assets and
% damagefunctions, it also holds the adaptation measures .
% entity.measures.name{m} contains the name of measure m,
% entity.measures.name.cost(m) the cost . The following fields allow the
% parameterization of the measure?s impact on both the hazard as well as
% the damage function. entity.measures.name.hazard_intensity_impact(m)
% allows to reduce the hazard intensity (e.g. -1 reduces tropical cyclone
% windspeed by 1 m/s) for measure m. The hazard_high_frequency_cutoff
% allows to specify a frequency below which damages are suppressed due to
% the measures, e.g. the construction/design level of a dam
% (hazard_high_frequency_cutoff=1/50 means the dam prevents damages up to
% the 50 year return  period). hazard_event_set allows to specify a
% measure-specific hazard event set, i.e. for this particular measure,
% climada switches to the specified hazard event set instead of the one
% used to assess the damages of the reference case. MDD_impact_a and
% MDD_impact_b allow a linear transformation of the MDD (mean damage
% degree) of the damage function, such that MDDeff = MDD_impact_a +
% MDD_impact_b * MDD. Similarly, PAAeff = PAA_impact_a + PAA_impact_b *
% PAA. damagefunctions_map allows to map to a new damage function to render
% the effect of measure m, i.e. ?1to3? means instead of DamageFunID 1,
% DamageFunID 3 is used . risk_transfer_attachement and risk_transfer_cover
% define the attachement point and cover of a risk transfer layer .

% The simple call
measures_impact=climada_measures_impact(entity,hazard,'no');
% does it all, e.g. it takes the entity and first calculates the EDSref
% using hazard in order to create the baseline (situation with no measure
% applied). It then takes masure m (m=1?), adjusts either hazard and/or
% damagefunctions according to the measure?s specification and calculates a
% new EDSm. The difference to EDSref (i.e. EDSm-EDSref) quantifies the
% benefit (averted damage) of measure m. By doing this on the event damage
% set, a variety of measures can be compared, even account for measures
% which for example only act on high frequency events (see
% hazard_high_frequency_cutoff) or risk transfer layers (see
% risk_transfer_attachement and risk_transfer_cover). This function further
% handles all the measure impact discounting etc.

% Since it would be quite cumbersome for the user to manually construct the
% adaptation cost curve based on the detailed output provided by
% climada_measures_impact, the following function does it all:
climada_adaptation_cost_curve(measures_impact);

% show the event view (effect of adaptation measures on different return
% periods:
figure;climada_adaptation_event_view(measures_impact);

drawnow % to force drawing all figures
