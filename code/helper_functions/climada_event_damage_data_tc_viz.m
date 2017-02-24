function [hazard,hazard_TS]=climada_event_damage_data_tc_viz(tc_track,entity,check_mode,params)
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
%
%   params.focus_region=[-180 180 -60 60];
%
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
if isempty(params.hazard_arr_density),    params.hazard_arr_density=0.1;end
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

if isfield(entity.assets,'centroids_file')
    if exist(entity.assets.centroids_file,'file')
    load(entity.assets.centroids_file)
    end
end
centroids.lon=entity.assets.lon; % redefine
centroids.lat=entity.assets.lat;
if isfield(centroids,'distance2coast_km')
    pos=find(centroids.distance2coast_km(1:length(centroids.lon))<200);
    %entity.assets=climada_subarray(entity.assets,pos);
    
    entity.assets.Value=entity.assets.Value(pos);
    entity.assets.Deductible=entity.assets.Deductible(pos);
    entity.assets.Cover=entity.assets.Cover(pos);
    entity.assets.DamageFunID=entity.assets.DamageFunID(pos);
    entity.assets.lon=entity.assets.lon(pos);
    entity.assets.lat=entity.assets.lat(pos);
end
entity.assets.centroid_index=1:length(entity.assets.lon);
entity.assets.hazard.filename='NO_SAVE';

if params.grid_add
    fprintf('adding regular grid ...');
    grid_region=params.focus_region;
    for i=grid_region(1):params.grid_delta:grid_region(2)
        for j=grid_region(3):params.grid_delta:grid_region(4)
            centroids.lon(end+1)=i;
            centroids.lat(end+1)=j;
        end
    end
    fprintf(' done\n');
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
n_events=0; % init

% prep loop over all tracks to figure nodes within frame (focus_region) etc.
n_tracks=length(tc_track);

n_sel=0; % init
N_i=1;
track_node_count_start=zeros(1,n_tracks+1); % init
% define rectangular area to search for track nodes within
edges_x = [params.focus_region(1),params.focus_region(1),params.focus_region(2),params.focus_region(2),params.focus_region(1)];
edges_y = [params.focus_region(3),params.focus_region(4),params.focus_region(4),params.focus_region(3),params.focus_region(3)];
d_nodes=ceil(10/params.tc_track_timestep); % 10 if track in hours, 100 if track in 6 min
fprintf('preprocessing %i tracks\n',n_tracks);
climada_progress2stdout    % init, see terminate below
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
        n_events=n_events+n_steps;
        n_sel=n_sel+1;
        tc_track_N(N_i)=tc_track_tmp; % as we added fields (min_node,max_node,n_steps)
        track_node_count_start(N_i+1)=track_node_count_start(N_i)+n_steps;
        N_i=N_i+1; % point to next
        if check_mode,plot(tc_track(track_i).lon,tc_track(track_i).lat,'-g');hold on;axis equal;end
    end
    
    climada_progress2stdout(track_i,n_tracks,10,'tracks'); % update
    
end % track_i (preprocessing)
climada_progress2stdout(0) % terminate

tc_track=tc_track_N; clear tc_track_N; % re-assign, clear
n_tracks=length(tc_track);
n_centroids=length(centroids.lon);
n_assets=length(entity.assets.lon);

fprintf('preprocessing (2) %i tracks\n',n_tracks);
hazard.tc_track_number=zeros(1,n_events);
hazard.tc_track_node=zeros(1,n_events);
hazard.tc_track_ID_no=zeros(1,n_events);
hazard.event_name=cell(1,n_events);
climada_progress2stdout    % init, see terminate below
for track_i=1:n_tracks
    min_node=tc_track(track_i).min_node;
    max_node=tc_track(track_i).max_node;
    for node_i=min_node:max_node
        
        hazard_i=track_node_count_start(track_i)+(node_i-min_node)+1;
        
        hazard.tc_track_number(hazard_i)=track_i;
        hazard.tc_track_node(hazard_i)=node_i;
        hazard.tc_track_ID_no(hazard_i)=tc_track(track_i).ID_no;
        hazard.event_name{hazard_i}=sprintf('%s %s',strrep(char(tc_track(track_i).name),'_',' '),...
            datestr(tc_track(track_i).datenum(node_i),'dd-mmm-yyyy HH:MM'));
    end % node_i
    climada_progress2stdout(track_i,n_tracks,10,'tracks'); % update
end % track_i (preprocessing 2)
climada_progress2stdout(0) % terminate

if check_mode
    axis(params.focus_region);
    climada_plot_world_borders(1,'','',1)
    set(gcf,'Color',[1 1 1]) % white background
end

% allocate the hazard array (sparse, to manage memory)
intensity = spalloc(n_events,n_centroids,...
    ceil(n_events*n_centroids*params.hazard_arr_density));
damage    = spalloc(n_steps,n_assets,...
    ceil(n_steps*n_assets*params.hazard_arr_density));
max_damage_at_centroid=zeros(1,n_assets);

% for-loop progress to stdout
if climada_global.parfor
    fprintf('processing total %i nodes of %i track(s) - parfor\n',n_events,n_tracks);
else
    fprintf('processing total %i nodes of %i track(s)\n',n_events,n_tracks);
    climada_progress2stdout    % init, see terminate below
end

for track_i=1:n_tracks
        
    e1=track_node_count_start(track_i);
    e2=track_node_count_start(track_i+1)-1;
    [intensity(e1:e2,:),damage(e1:e2,:)]=LOCAL_intens_dama(tc_track(track_i),centroids,entity,params.hazard_arr_density);

    if ~climada_global.parfor,climada_progress2stdout(track_i,n_tracks,1,'tracks');end % update
    
end % track_i
if ~climada_global.parfor,climada_progress2stdout(0);end % terminate
hazard.tc_track_number=tc_track_number;
hazard.tc_track_node=tc_track_node;
hazard.tc_track_ID_no=tc_track_ID_no;
hazard.event_name=event_name;

% complete hazard
hazard.event_ID=1:n_events; % now we know the total count, each node an event
hazard.orig_event_count=n_events;
hazard.orig_event_flag=hazard.event_ID*0+1;
hazard.frequency=hazard.event_ID*0+1; % all one
hazard.intensity=intensity;
hazard.damage=damage;

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

climada_global.tc.extratropical_transition=climada_global_transition; % reset

% save all the relevant information for nicer plot options
hazard.tc_track=tc_track; % also store tc_track to hazard
hazard.assets=entity.assets; % also store assets to hazard
hazard.focus_region=params.focus_region; % also add focus region
fprintf('saving animation data in %s\n',params.animation_data_file);
save(params.animation_data_file,'hazard','-v7.3');

end % climada_event_damage_data_tc


function [intensity,damage]=LOCAL_intens_dama(tc_track,centroids,entity,hazard_arr_density)

min_node=tc_track.min_node;
max_node=tc_track.max_node;
n_steps=max_node-min_node+1;
n_centroids=length(centroids.lon);

n_assets=length(entity.assets.lon);

intensity = spalloc(n_steps,n_centroids,...
    ceil(n_steps*n_centroids*hazard_arr_density));
damage    = spalloc(n_steps,n_assets,...
    ceil(n_steps*n_assets*hazard_arr_density));
tc_track_segment.MaxSustainedWindUnit=tc_track.MaxSustainedWindUnit;
tc_track_segment.CentralPressureUnit =tc_track.CentralPressureUnit;

% init hazard structure
hazard.lon=centroids.lon;
hazard.lat=centroids.lat;
hazard.centroid_ID=centroids.centroid_ID;
hazard.peril_ID='TC';
hazard.orig_years=1;
hazard.date='';
hazard.filename='';
hazard.reference_year=9999;
hazard.comment='';
hazard.frequency=1;
hazard.event_ID=1;
hazard.orig_event_flag=1;

for node_i=min_node:max_node
        
    node_0=max(1,node_i-1);
    
    tc_track_segment.TimeStep=tc_track.TimeStep(node_0:node_i);
    tc_track_segment.lon=tc_track.lon(node_0:node_i);
    tc_track_segment.lat=tc_track.lat(node_0:node_i);
    tc_track_segment.MaxSustainedWind=tc_track.MaxSustainedWind(node_0:node_i);
    tc_track_segment.CentralPressure=tc_track.CentralPressure(node_0:node_i);
    tc_track_segment.datenum=tc_track.datenum(node_0:node_i);
    
    % calculate windfield
    gust=climada_tc_windfield(tc_track_segment,centroids,0,-1,0);
    intensity(node_i,:)=gust;
    
    % calculate damage
    hazard.intensity=gust; % we only need present step for damage
    hazard.fraction=spones(hazard.intensity); % update fraction 100%
    EDS=climada_EDS_calc(entity,hazard,'',0,2); % last 2: silent mode
    damage(node_i,:)=EDS.ED_at_centroid'; % store damage
end % node_i

end % LOCAL_intens_dama