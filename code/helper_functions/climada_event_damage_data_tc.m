function [hazard,hazard_TS]=climada_event_damage_data_tc(tc_track,entity,check_mode,params)
% climada tc ts animation
% MODULE:
%   core
% NAME:
%   climada_event_damage_data_tc
% PURPOSE:
%   Animation of climada cyclone impact for illustration - this code
%   calculates all the data and produces simple circle plots for checks. As
%   one often needs to play with visualization parameters, the process is
%   split. See climada_event_damage_animation for nice plots and movie
%   generation.
%
%   See HINT below in description of OUTPUTS for use by other visualization projects
%
%   Usual steps:
%
%   0: load your tc_track and entity with
%     >> tc_track=climada_tc_track_load
%     >> entity=climada_entity_load
%   1. run once with default parameters to check, i.e. for track 777
%     >> climada_event_damage_data_tc(tc_track(777),entity);
%   2. run again, now to silently generate data on higher resolution, e.g.
%     >> climada_event_damage_data_tc(tc_track(777),entity,0); % no plot
%   3. generate the movie, use
%     >> climada_event_damage_animation % generate the .mp4 movie
%
%   Note: as one often needs to set some of the paramers, call
%   climada_event_damage_data_tc without any argument to return the
%   default parameters (same as calling climada_event_damage_data_tc('params')
%
%   Example for Sidr in Bangladesh:
%   >> tc_track=climada_tc_read_unisys_database('nio');tc_track=tc_track(173);tc_track.name='Sidr';
%   >> tc_track.MaxSustainedWind(end-1)=80;tc_track.MaxSustainedWind(end)=40; % 2nd and last timestep far over land, weakened
%   >> entity=climada_entity_load('BGD_Bangladesh');
%   %  previous line the entity for Bangladesh if it does not yet exist:
%   %  entity=climada_nightlight_entity('Bangladesh');
%   >> climada_event_damage_data_tc(tc_track,entity,2); % run with ...,0) for full resolution
%   >> climada_event_damage_animation
%
%   Example for Andrew in Florida:
%   >> tc_track=climada_tc_read_unisys_database('atl');tc_track=tc_track(1170);tc_track.name='Andrew';
%   >> entity=climada_entity_load('USA_UnitedStates_Florida_entity');
%   >> params.focus_region=[-84 -78 23 29];
%   >> climada_event_damage_data_tc(tc_track,entity,0,params);
%   >> climada_event_damage_animation
%
%   Example for all historic tracks in Bangladesh which generate damage:
%   >> tc_track=climada_tc_track_load('nio_hist'); % all historic tracks
%   >> hazard=climada_hazard_load('BGD_Bangladesh_nio_TC_hist'); % historic hazard
%   >> entity=climada_entity_load('BGD_Bangladesh_HR_entity'); % high-res
%   >> entity=climada_assets_encode(entity,hazard);
%   >> EDS=climada_EDS_calc(entity,hazard);
%   >> pos=find(EDS.damage>0);tc_track=tc_track(pos); % only damageing tracks
%   >> climada_event_damage_data_tc(tc_track,entity,0);
%   >> params.plot_tc_track=1;climada_event_damage_animation('',params);

%   >> tc_track=climada_tc_read_unisys_database('atl'); % all historic
%   >> entity=climada_entity_load('USA_UnitedStates_Florida_entity');
%   >> hazard_prob=climada_hazard_load('USA_UnitedStates_atl_TC');
%   >> entity=climada_assets_encode(entity,hazard_prob); % encode
%   >> EDS=climada_EDS_calc(entity,hazard_prob); % calculate damage for all events
%   >> % find non-zero damage of historic events:
%   >> pos=find(EDS.damage(logical(hazard_prob.orig_event_flag))>0);
%   >> tc_track=tc_track(pos); % restrict to historic damageing tracks
%   >> params.focus_region=[-84 -78 23 29];
%   >> climada_event_damage_data_tc(tc_track,entity,2,params);
%   >> climada_event_damage_animation
%
%   Example for all historic tracks in Florida which generate damage:
%   >> tc_track=climada_tc_read_unisys_database('atl'); % all historic
%   >> entity=climada_entity_load('USA_UnitedStates_Florida_entity');
%   >> hazard_prob=climada_hazard_load('USA_UnitedStates_atl_TC');
%   >> entity=climada_assets_encode(entity,hazard_prob); % encode
%   >> EDS=climada_EDS_calc(entity,hazard_prob); % calculate damage for all events
%   >> % find non-zero damage of historic events:
%   >> pos=find(EDS.damage(logical(hazard_prob.orig_event_flag))>0);
%   >> tc_track=tc_track(pos); % restrict to historic damageing tracks
%   >> params.focus_region=[-84 -78 23 29];
%   >> climada_event_damage_data_tc(tc_track,entity,2,params);
%   >> climada_event_damage_animation
%
%   Instead of using a track from any of the ../data/tc_tracks databases,
%   you might also just download a single track from
%   weather.unisys.com/hurricane (click trough to a single track, then
%   save the 'tracking information' as .dat file, i.e. right click and save
%   as...) and then load with tc_track=climada_tc_read_unisys_track (in
%   contrast to climada_tc_read_unisys_database, this reads one single
%   track from a single track .dat file).
%
%   The code produces all the step-by-step data to produce a damage
%   animation. Instead of single events, the resulting hazard event set
%   contains single time steps of the one event and the corresponding
%   damage is also stored as a field into hazard (hazard.damage). If the
%   flag params.show_footprint=0 (default), the intensity shows the
%   instanteneous hazard intensity, while hazard.damage is the cumulated
%   damage. For ease of use, the tc_track and the assets are also stored to
%   hazard, see HINT in description of OUTPUTS below.
%
%   The code determines the plot area based on entity. See
%   params.focus_region in case you'd like to hard-wire the region.
%
%   prior calls: none necessarily, consider climada_tc_track_info to obtain
%       information about all tracks in an ocean basin
%   next call: climada_event_damage_animation
% CALLING SEQUENCE:
%   [hazard,hazard_TS]=climada_event_damage_data_tc(tc_track,entity,check_mode,params)
% EXAMPLE:
%   tc_track=climada_tc_read_unisys_database('atl');tc_track=tc_track(1170);
%   entity=climada_entity_load('USA_UnitedStates_Florida');
%   hazard=climada_event_damage_data_tc(tc_track,entity); % check
%   hazard=climada_event_damage_data_tc(tc_track,entity,0); % high-res
%   climada_event_damage_animation % create the movie
%
%   params=climada_event_damage_data_tc % return default parameters
% INPUTS:
%   tc_track: a tc_track structure, as returned by
%       climada_tc_read_unisys_database or climada_tc_read_unisys_tc_track
%       Note: if a tc_track struct with more than one track is passed, the
%       code does render one after the other of the tracks within, keeping
%       the damaged pixels colored.
%       If ='params', just return the default parameters params in hazard
%       SPECIAL: if a previosuly generated hazard is passed, the 
%           non-mandatory fields for animation purposes are cleared and the
%           'clean up' hazard is retuned. 
%   entity: a climada entity, see climada_entity_read (skip hazard set
%       selection to encode to) or climada_entity_load
%       > promted for if not given
%       Note: for speedup, consider creating an entity covering only the
%       region you'd like to focus on, e.g. avoid full contiguous US if
%       you'd like to animate a TC hitting Floriday, i.e consider
%       entity=climada_nightlight_entity('USA','Florida')
% OPTIONAL INPUT PARAMETERS:
%    check_mode: =2: (default) show plots, use 2h timestep (fast check)
%       =1: show plots, use 1h timestep (pretty detailed check)
%       =0: no plots, 20 min timestep (params.tc_track_timestep=1/3) (the
%       best option to generate the data pretty fast).
%   parameters: a structure with fields (see also tc_track='params' above):
%    animation_data_file: the file where animation data is stored (not the
%       animation itself). If not provided, set to ../results/animation_data.mat
%    add_surge: whether we also treat surge (TS) =1) or not (=0, default)
%    extend_tc_track: if =1 (default=0) extend/extrapolate TC track by one node
%    focus_region: the region we're going to show [minlon maxlon minlat maxlat]
%       default=[], automatically determined by area of entity lat/lon
%       SPECIAL: if =1, use the region around the tc_track, NOT around the entity
%       E.g. for Salvador (Lea, 20150220) focus_region = [-91.5 -86 12 15.5];
%    focus_track_region: if =1, focus on track region instead of focus_region
%    show_footprint: whether we show single steps (=0, default) or the footprint (=1)
%    tc_track_timestep: the timestep (in hours or fractions thereof)
%       between nodes, 0.1 means 6 min, good movie resolution, used if check_mode=0
%    damage_scale: the scale for plots, such that
%       max_damage=max(entity.assets.Value)*damage_scale, default =1/100
%    label_track_nodes: if =1 label track nodes along track, default=0
%    grid_add: add regular (coarse) grid to better show hazard intensity
%       offshore. Default=1, set=0 if centroids cover eg water points already
%    grid_delta: the regular encompassing grid spacing in degrees,
%       default=0.2, see grid_add.
%    hazard_arr_density: very technical, set to rather too large a
%       number, default=0.1.
% OUTPUTS:
%   hazard: a hazard structure (as usual) with additional fields:
%       tc_track_node(i): the node i (tc_track.lon(i)...) for which the other
%       fields (like hazard.intensity(i,:)..) are valid
%       tc_track: the TC track (see climada_tc_read_unisys_database for
%           description of fields)
%       damage: the same dimension as intensity, the damage at each
%           centroid for each timestep of the tc track
%       max_damage: the maximum damage at each centroid (useful to scale or
%           normalize, can also be calculated as =full(max(hazard.damage,[],1));
%       in case of hazard=climada_event_damage_data_tc('params'), hazard
%       contains the default parameters
%
% 	HINT: for data to be directly used by other visualization projects, you
% 	need to consider the following fields:
%   hazard.intensity(time_i,centroid_i): the hazard intensity (here m/s
%       wind speed) for timestep_i at centroid i
%   hazard.damage(time_i,centroid_i): the cumulative damage (here in USD)
%       for timestep_i at centroid i
%   hazard.lon(centroid_i): the longitude of centroid i
%   hazard.lat(centroid_i): the latitude of centroid i
%   hazard.event_name{time_i}: then name (with time stamp) of time step i
%   hazard.focus_region(4): the region for whch the data is valid
%       [minlon maxlon minlat maxlat]
%   hazard.assets.Value(year_i,centroid_j): the asset Value (USD) for year i
%       at centroid j, if first dimension=1, constant/static assets values
%   hazard.assets.lon(centroid_j): the longitude of centroid j
%   hazard.assets.lat(centroid_j): the latitude of centroid j
%   hazard.assets.Values_yyyy(year_i): the actual year for year i (=1 if
%       constant/static assets value
%   hazard.assets.Value(year_i,centroid_j): the asset Value (USD) for year i
%       at centroid j, if first dimension=1, constant/static assets values
%   hazard.tc_track(track_i): the tropical cyclone track data, with:
%   hazard.tc_track_number(time_i): the track_i of time step i, i.e.
%       hazard.tc_track(hazard.tc_track_number(time_i)) is the track
%   hazard.tc_track_node(time_i): the track node of time step i, i.e.
%       hazard.tc_track(hazard.tc_track_number(time_i)).lon(hazard.tc_track_node(time_i))
%       hazard.tc_track(hazard.tc_track_number(time_i)).lat(hazard.tc_track_node(time_i))
%       is the longitude and latitude of the track node at time step i
%
%   hazard_TS: in case add_surge=1, otherwise empty. Does contain the same
%       additional fields tc_track, tc_track_node, damage and max_damage.
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150117, intial
% David N. Bresch, david.bresch@gmail.com, 20150118, TS added
% David N. Bresch, david.bresch@gmail.com, 20150120, check_mode added
% David N. Bresch, david.bresch@gmail.com, 20150128, climada_tc_track_nodes
% David N. Bresch, david.bresch@gmail.com, 20150220, focus_region added
% David N. Bresch, david.bresch@gmail.com, 20150318, low wind to NaN removed
% David N. Bresch, david.bresch@gmail.com, 20170103, overhaul, params added etc.
% David N. Bresch, david.bresch@gmail.com, 20170104, clean up
% David N. Bresch, david.bresch@gmail.com, 20170112, interface to other viz projects improved, see HINT in description of OUTPUTS
%-

hazard=[];hazard_TS=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

if nargin==0,tc_track='params';end % to return params

% poor man's version to check arguments
if ~exist('tc_track','var'),   tc_track='params';end
if ~exist('entity','var'),     entity=[];end
if ~exist('check_mode','var'), check_mode=[];end
if ~exist('params','var'),     params=struct;end

% check for some parameter fields we need
if ~isfield(params,'animation_data_file'),params.animation_data_file='';end
if ~isfield(params,'add_surge'),          params.add_surge=[];end
if ~isfield(params,'focus_region'),       params.focus_region=[];end
if ~isfield(params,'show_footprint'),     params.show_footprint=[];end
if ~isfield(params,'tc_track_timestep'),  params.tc_track_timestep=[];end
if ~isfield(params,'damage_scale'),       params.damage_scale=[];end
if ~isfield(params,'label_track_nodes'),  params.label_track_nodes=[];end
if ~isfield(params,'focus_track_region'), params.focus_track_region=[];end
if ~isfield(params,'extend_tc_track'),    params.extend_tc_track=[];end
if ~isfield(params,'grid_add'),           params.grid_add=[];end
if ~isfield(params,'grid_delta'),         params.grid_delta=[];end
if ~isfield(params,'hazard_arr_density'), params.hazard_arr_density=[];end

% PARAMETERS
%
% set default values (see header for details)
if isempty(check_mode),                   check_mode=2;end
%
if isempty(params.animation_data_file),   params.animation_data_file=...
        [climada_global.data_dir filesep 'results' filesep 'animation_data.mat'];end
if isempty(params.add_surge),             params.add_surge=0;end
if isempty(params.show_footprint),        params.show_footprint=0;end
if isempty(params.tc_track_timestep),     params.tc_track_timestep=1/3;end
if isempty(params.damage_scale),          params.damage_scale=1/100;end
if isempty(params.label_track_nodes),     params.label_track_nodes=0;end
if isempty(params.focus_track_region),    params.focus_track_region=0;end
if isempty(params.extend_tc_track),       params.extend_tc_track=1;end
if isempty(params.grid_add),              params.grid_add=1;end
if isempty(params.grid_delta),            params.grid_delta=0.2;end
if isempty(params.hazard_arr_density),    params.hazard_arr_density=0.01;end
%
% some overriders for check mode
if check_mode==1,params.tc_track_timestep=1;end % 1h for checks
if check_mode==2,params.tc_track_timestep=2;end % 2h for fast checks
%
% the range (in degree) around the tc_track (to show a bit a wider area in plots)
dX=1;dY=1; % default=1
%
climada_global_transition=climada_global.tc.extratropical_transition;
climada_global.tc.extratropical_transition=1;

if strcmpi(tc_track,'params'),hazard=params;return;end % special case, return the full parameters strcture

if isfield(tc_track,'damage')
    fprintf('NOTE: hazard reduced to key fields:\n');
    tc_track=rmfield(tc_track,'centroid_ID');
    tc_track=rmfield(tc_track,'peril_ID');
    tc_track=rmfield(tc_track,'orig_years');
    tc_track=rmfield(tc_track,'date');
    tc_track=rmfield(tc_track,'filename');
    tc_track=rmfield(tc_track,'reference_year');
    tc_track=rmfield(tc_track,'comment');
    tc_track=rmfield(tc_track,'units');
    tc_track=rmfield(tc_track,'event_count');
    tc_track=rmfield(tc_track,'event_ID');
    tc_track=rmfield(tc_track,'orig_event_count');
    tc_track=rmfield(tc_track,'orig_event_flag');
    tc_track=rmfield(tc_track,'frequency');
    tc_track=rmfield(tc_track,'tc_track_ID_no');
    tc_track=rmfield(tc_track,'fraction');
    tc_track=rmfield(tc_track,'max_damage');
    tc_track=rmfield(tc_track,'matrix_density');
    hazard=rmfield(tc_track,'annotation') % last without ; to stdout
    return
end

entity=climada_entity_load(entity); % prompt/check for entity
if isempty(entity),return;end       % Cancel pressed

if isempty(params.focus_region) % define the focus region based on entity
    params.focus_region(1)=min(entity.assets.lon)-dX;
    params.focus_region(2)=max(entity.assets.lon)+dX;
    params.focus_region(3)=min(entity.assets.lat)-dY;
    params.focus_region(4)=max(entity.assets.lat)+dY;
end

if params.focus_track_region==1
    params.focus_region(1)=9999;
    params.focus_region(2)=-9999;
    params.focus_region(3)=9999;
    params.focus_region(4)=-9999;
    for track_i=1:length(tc_track)
        % we focus on the whole track rather than the entity region
        params.focus_region(1)=min(params.focus_region(1),min(tc_track(track_i).lon)-dX);
        params.focus_region(2)=max(params.focus_region(2),max(tc_track(track_i).lon)+dX);
        params.focus_region(3)=min(params.focus_region(3),min(tc_track(track_i).lat)-dY);
        params.focus_region(4)=max(params.focus_region(4),max(tc_track(track_i).lat)+dY);
    end % track_i
    fprintf('focus on TC tack region, not on whole entity\n');
end

centroids.lon=entity.assets.lon;
centroids.lat=entity.assets.lat;
entity.assets.centroid_index=1:length(entity.assets.lon);
entity.assets.hazard.filename='NO_SAVE';

if params.grid_add
    grid_region=params.focus_region;
    for i=grid_region(1):params.grid_delta:grid_region(2)
        for j=grid_region(3):params.grid_delta:grid_region(4)
            centroids.lon(end+1)=i+params.grid_delta/10;
            centroids.lat(end+1)=j+params.grid_delta/10;
        end
    end
end
centroids.centroid_ID=1:length(centroids.lon);

% init hazard structure
hazard.lon=centroids.lon;
hazard.lat=centroids.lat;
hazard.centroid_ID=centroids.centroid_ID;
hazard.peril_ID='TC';
hazard.orig_years=1;
hazard.date=datestr(now);
hazard.filename=mfilename;
hazard.reference_year=climada_global.present_reference_year;
hazard.comment=sprintf('special hazard event set for animation plots, generated by %s',mfilename);
hazard.units='m/s';
hazard.event_count=0; % init

% prep loop over all tracks to figure nodes within frame (focus_region) etc.
n_tracks=length(tc_track);

% for-loop progress to stdout
t0       = clock;
fprintf('pre-processing %i track(s)\n',n_tracks);
mod_step = 1; % first time estimate after 2 steps, then every 10th
format_str='%s';

n_sel=0; % init
N_i=1;
% define rectangular area to search for track nodes within
edges_x = [params.focus_region(1),params.focus_region(1),params.focus_region(2),params.focus_region(2),params.focus_region(1)];
edges_y = [params.focus_region(3),params.focus_region(4),params.focus_region(4),params.focus_region(3),params.focus_region(3)];
d_nodes=ceil(10/params.tc_track_timestep); % 10 if track in hours, 100 if track in 6 min
for track_i=1:n_tracks
    if params.extend_tc_track
        tc_track(track_i).TimeStep(end+1)=tc_track(track_i).TimeStep(end);
        tc_track(track_i).yyyy(end+1)=tc_track(track_i).yyyy(end);
        tc_track(track_i).mm(end+1)=tc_track(track_i).mm(end);
        tc_track(track_i).dd(end+1)=tc_track(track_i).dd(end);
        tc_track(track_i).hh(end+1)=tc_track(track_i).hh(end)+tc_track(track_i).TimeStep(end);
        tc_track(track_i).datenum(end+1)=tc_track(track_i).datenum(end)+(tc_track(track_i).datenum(end)-tc_track(track_i).datenum(end-1));
        tc_track(track_i).lon(end+1)=tc_track(track_i).lon(end)+(tc_track(track_i).lon(end)-tc_track(track_i).lon(end-1));
        tc_track(track_i).lat(end+1)=tc_track(track_i).lat(end)+(tc_track(track_i).lat(end)-tc_track(track_i).lat(end-1));
        tc_track(track_i).MaxSustainedWind(end+1)=0;
        tc_track(track_i).CentralPressure(end+1)=max(tc_track(track_i).CentralPressure);
        if isfield(tc_track,'EnvironmentalPressure'),...
                tc_track(track_i).EnvironmentalPressure(end+1)=max(tc_track(track_i).EnvironmentalPressure);end
         if isfield(tc_track,'RadiusMaxWind'),...
                tc_track(track_i).RadiusMaxWind(end+1)=max(tc_track(track_i).RadiusMaxWind);end
    end % params.extend_tc_track
    
    tc_track_tmp=climada_tc_equal_timestep(tc_track(track_i),params.tc_track_timestep); % tc_track_tmp a bit ugly, but pragmatic
    
    % check for track nodes within params.focus_region
    in_track_poly = inpolygon(tc_track_tmp.lon,tc_track_tmp.lat,edges_x,edges_y);
    node_no=1:length(tc_track_tmp.lon);
    node_no=node_no(in_track_poly);
    max_node=min(max(node_no)+d_nodes,length(tc_track_tmp.lon));
    min_node=max(min(node_no)-d_nodes,2); % never first node
    n_steps=max_node-min_node+1;
    
    tc_track_tmp.min_node=min_node;
    tc_track_tmp.max_node=max_node;
    tc_track_tmp.n_steps=n_steps;
    tc_track_tmp.orig_track_i=track_i;
    
    if n_steps>0
        hazard.event_count=hazard.event_count+n_steps;
        n_sel=n_sel+1;
        tc_track_N(N_i)=tc_track_tmp; % as we added fields (min_node,max_node,n_steps)
        N_i=N_i+1; % point to next
        if check_mode,plot(tc_track(track_i).lon,tc_track(track_i).lat,'-g');hold on;axis equal;end
    end
    
    % the progress management
    if mod(track_i,mod_step)==0
        if n_tracks>1000,mod_step=100;else mod_step=10;end
        t_elapsed_event   = etime(clock,t0)/track_i;
        events_remaining  = n_tracks-track_i;
        t_projected_sec   = t_elapsed_event*events_remaining;
        msgstr = sprintf('est. %3.0f sec left (%i/%i tracks, %i selected) ',t_projected_sec,track_i,n_tracks,n_sel);
        fprintf(format_str,msgstr); % write progress to stdout
        format_str=[repmat('\b',1,length(msgstr)) '%s']; % back to begin of line
    end
    
end % track_i (preprocessing)
fprintf(format_str,''); % move carriage to begin of line

tc_track=tc_track_N; tc_track_N=[]; % re-assign, clear
n_tracks=length(tc_track);

if check_mode
    axis(params.focus_region);
    climada_plot_world_borders(1,'','',1)
    set(gcf,'Color',[1 1 1]) % white background
end

% complete hazard
hazard.event_ID=1:hazard.event_count; % now we know the total count, each node an event
hazard.orig_event_count=hazard.event_count;
hazard.orig_event_flag=hazard.event_ID*0+1;
hazard.frequency=(hazard.event_ID*0+1); % all once

% allocate the hazard array (sparse, to manage memory)
hazard.intensity = spalloc(hazard.event_count,length(hazard.lon),...
    ceil(hazard.event_count*length(hazard.lon)*params.hazard_arr_density));
hazard.tc_track_number=zeros(1,hazard.event_count); % special, to store tc_track node
hazard.tc_track_node=zeros(1,hazard.event_count); % special, to store tc_track node
hazard.damage=hazard.intensity;
max_damage_at_centroid=zeros(1,length(entity.assets.lon));

% for-loop progress to stdout
fprintf('processing total %i nodes of %i track(s)\n',hazard.event_count,n_tracks);
t0=clock;format_str='%s';mod_step = 2; % first time estimate after 2 steps, then every 10th

hazard_i=1; % init
for track_i=1:n_tracks
    
    single_tc_track=tc_track(track_i); 
    min_node=single_tc_track.min_node;
    max_node=single_tc_track.max_node;
    
    tc_track_segment.MaxSustainedWindUnit=single_tc_track.MaxSustainedWindUnit;
    tc_track_segment.CentralPressureUnit =single_tc_track.CentralPressureUnit;
    tc_track_segment.name=single_tc_track.name;
    
    for node_i=min_node:max_node
        
        hazard.tc_track_number(hazard_i)=track_i;
        hazard.tc_track_node(hazard_i)=node_i;
        hazard.tc_track_ID_no(hazard_i)=tc_track(track_i).ID_no;
        
        if params.show_footprint
            node_0=1;
        else
            node_0=max(1,node_i-1);
        end
       
        tc_track_segment.TimeStep=tc_track(track_i).TimeStep(node_0:node_i);
        tc_track_segment.lon=tc_track(track_i).lon(node_0:node_i);
        tc_track_segment.lat=tc_track(track_i).lat(node_0:node_i);
        tc_track_segment.MaxSustainedWind=tc_track(track_i).MaxSustainedWind(node_0:node_i);
        tc_track_segment.CentralPressure=tc_track(track_i).CentralPressure(node_0:node_i);
        tc_track_segment.datenum=tc_track(track_i).datenum(node_0:node_i);
        if check_mode
            plot(tc_track_segment.lon,tc_track_segment.lat,'xg');hold on
            if params.label_track_nodes,text(tc_track_segment.lon(end),tc_track_segment.lat(end),sprintf('%i',node_i),'FontSize',9,'Color','g');end
        end
        
        hazard.event_name{hazard_i}=sprintf('%s %s',strrep(char(tc_track(track_i).name),'_',' '),...
            datestr(tc_track(track_i).datenum(node_i),'dd-mmm-yyyy HH:MM'));
        
        %plot(hazard.tc_track.lon(1:node_i),hazard.tc_track.lat(1:node_i),'-b','LineWidth',2);
        
        if params.show_footprint
            gust=climada_tc_windfield(tc_track_segment,centroids,0,1,0);
        else
            gust=climada_tc_windfield(tc_track_segment,centroids,0,-1,0);
        end
        
        hazard.intensity(hazard_i,:)=gust;
        hazard.fraction=spones(hazard.intensity); % update fraction 100%
        
        if check_mode
            % plot intensity
            LOCAL_circle_plot(hazard.lon,hazard.lat,...
                hazard.intensity(hazard_i,:),100,20,'ob',1); % wind speed blue circles
        end
        
        % calculate damage
        temp_hazard=hazard;temp_hazard.intensity(1:hazard_i-1,:)=0; % we only need present step for damage
        
        EDS=climada_EDS_calc(entity,temp_hazard,'',0,2); % last 2: silent mode
        
        max_damage_at_centroid=max(max_damage_at_centroid,EDS.ED_at_centroid');
        hazard.damage(hazard_i,1:length(EDS.ED_at_centroid))=EDS.ED_at_centroid'; % store damage
        
        if check_mode
            LOCAL_circle_plot(hazard.lon,hazard.lat,max_damage_at_centroid,...
                max(entity.assets.Value)*params.damage_scale,20,'or',3); % damage red circles
            title(sprintf('%s %s',strrep(char(tc_track_segment.name),'_',' '),datestr(tc_track_segment.datenum(end))));
            drawnow
        end
        
        % the progress management
        if mod(hazard_i,mod_step)==0
            if hazard.event_count>500,mod_step=100;else mod_step=50;end
            if hazard_i<100,mod_step=20;end
            if hazard_i<50,mod_step=10;end
            if hazard_i<10,mod_step=2;end
            t_elapsed_event   = etime(clock,t0)/hazard_i;
            events_remaining  = hazard.event_count-hazard_i;
            t_projected_sec   = t_elapsed_event*events_remaining;
            msgstr = sprintf('est. %3.0f sec left (%i/%i total nodes) ',t_projected_sec,hazard_i,hazard.event_count);
            fprintf(format_str,msgstr); % write progress to stdout
            format_str=[repmat('\b',1,length(msgstr)) '%s']; % back to begin of line
        end
        
        hazard_i=hazard_i+1; % point to next event
        
    end % node_i
    
end % track_i
fprintf(format_str,''); % move carriage to begin of line

fprintf('took %2.1f sec\n',etime(clock,t0));
if check_mode,xlabel('assets [USD] green..blue, wind [m/s] grey..red, damage [USD] yellow..red');end

% complete hazard
hazard.max_damage=max_damage_at_centroid'; % store max damage
fprintf('max TC damage %g\n',max(hazard.max_damage));
hazard.matrix_density=nnz(hazard.intensity)/numel(hazard.intensity);
hazard.annotation='assets [USD] green..blue, wind [m/s] grey..red, damage [USD] yellow..red';

% reform hazard to be directly used by other visualization projects

% hazard.intensity(time_i,centroid_i): the hazard intensity (here m/s wind speed) for timestep_i at centroid i
% hazard.damage(time_i,centroid_i): the cumulative damage (here in USD) for timestep_i at centroid i
% hazard.lon(centroid_i): the longitude of centroid i
% hazard.lat(centroid_i): the latitude of centroid i
% hazard.assets.Value(year_i,centroid_j): the asset Value (USD) for year i at centroid j, if first dimension=1, constant/static assets values
% hazard.assets.lon(centroid_j): the longitude of centroid j
% hazard.assets.lat(centroid_j): the latitude of centroid j
% hazard.assets.Values_yyyy(year_i): the actual year for year i (=1 if constant/static assets value
% hazard.assets.Value(year_i,centroid_j): the asset Value (USD) for year i at centroid j, if first dimension=1, constant/static assets values
hazard.assets.Values_yyyy=1; % dummy for the time being

if params.add_surge % add TS (tropical cyclone surge)
    
    % we can do this as fast here (no explicit loop), as we have all windfields
    
    hazard_TS=climada_ts_hazard_set(hazard,'NO_SAVE');
    
    % calculate TS damage
    hazard_TS.damage=hazard_TS.intensity*0; % init
    max_damage_at_centroid=hazard.max_damage*0; % init
    for event_i=1:length(hazard_TS.event_ID)
        temp_hazard=hazard_TS;
        temp_hazard.intensity(1:event_i-1,:)  =0; % we only need present step
        temp_hazard.intensity(event_i+1:end,:)=0; % we only need present step
        
        if check_mode
            hold on
            LOCAL_circle_plot(hazard_TS.lon,hazard_TS.lat,...
                full(temp_hazard.intensity(event_i,:)),10,20,'oc',1); % surge height cyan circles
        end
        
        EDS=climada_EDS_calc(entity,temp_hazard,'',0,2); % last 2: silent mode
        max_damage_at_centroid=max(max_damage_at_centroid,EDS.ED_at_centroid);
        hazard_TS.damage(event_i,1:length(EDS.ED_at_centroid))=EDS.ED_at_centroid; % store damage
        
        if check_mode
            LOCAL_circle_plot(hazard_TS.lon,hazard_TS.lat,...
                max_damage_at_centroid,max(entity.assets.Value)*params.damage_scale,20,'om',3); % surge magenta circles
            drawnow
        end
        
    end
    if check_mode,xlabel('wind [m/s] blue, surge [m] cyan, damage [USD]: wind red, surge magenta');end
    hazard_TS.annotation='assets [USD] green..blue, surge [m/s] cyan, damage [USD] magenta';
    hazard_TS.max_damage=max_damage_at_centroid'; % store max damage
    fprintf('max TS damage %g\n',max(hazard_TS.max_damage));
end

climada_global.tc.extratropical_transition=climada_global_transition; % reset

% save all the relevant information for nicer plot options
hazard.tc_track=tc_track; % also store tc_track to hazard
hazard.assets=entity.assets; % also store assets to hazard
hazard.focus_region=params.focus_region; % also add focus region
fprintf('saving animation data in %s\n',params.animation_data_file);
save(params.animation_data_file,'hazard','hazard_TS');

end % climada_event_damage_data_tc


% LOCAL functions

function LOCAL_circle_plot(lon,lat,values,max_value,circle_diam,circle_format,circle_linewidth)
% a simple (and fast) version to check
% see climada_circle_plot for a 'full' version
% 'or'
%
if ~exist('values','var'),return;end
if ~exist('max_value','var'),max_value=max(values);end
if ~exist('circle_diam','var'),circle_diam=10;end
if ~exist('circle_format','var'),circle_format='or';end
if ~exist('circle_linewidth','var'),circle_linewidth=1;end
%
minval=0.0;maxval=sqrt(abs(max_value)); % not minval=sqrt(abs(min(values)))
MarkerSizes=sqrt(abs(values-minval))/(maxval-minval)*circle_diam;
pos=find(isnan(MarkerSizes));
if ~isempty(pos),MarkerSizes(pos)=0;end;
pos=find(MarkerSizes<1);if ~isempty(pos),MarkerSizes(pos)=0;end;
ok_points_pos=find(MarkerSizes>0);
for ii=1:length(ok_points_pos)
    abs_ii=ok_points_pos(ii);
    plot(lon(abs_ii),lat(abs_ii),circle_format,'MarkerSize',...
        MarkerSizes(abs_ii),'LineWidth',circle_linewidth);
    hold on;
end
end % LOCAL_circle_plot
