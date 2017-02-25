function hazard=climada_event_damage_data_tc_viz(tc_track,entity,check_mode,params)
% climada tc ts animation
% MODULE:
%   core
% NAME:
%   climada_event_damage_data_tc_viz
% PURPOSE:
%   The FAST version of climada_event_damage_data_tc. See also
%   climada_event_damage_data_tc for some special cases. The present
%   version of the code runs parallel of climada_global.parfor=1 for
%   (massive) speedup.
%
%   Animation of climada cyclone impact for illustration - this code
%   calculates all the data. See climada_event_damage_animation for nice
%   plots and movie generation.
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
%   Example for global (do NOT try this first ;-):
%   entity=climada_entity_load('GLB_isimip_entity'); % full globe
%   load([climada_global.data_dir filesep 'tc_tracks' filesep 'ibtracs' filesep 'ibtracs.mat']); % all track 1950..2016
%   params.show_all_tracks=1;params.focus_region=[-180 180 -60 60];
%   params.hazard_arr_density=0.001;
%   climada_event_damage_data_tc_viz(tc_track,entity,0,params);
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
%   hazard=climada_event_damage_data_tc_viz(tc_track,entity,check_mode,params)
% EXAMPLE:
%   tc_track=climada_tc_read_unisys_database('atl');tc_track=tc_track(1170);
%   entity=climada_entity_load('USA_UnitedStates_Florida');
%   hazard=climada_event_damage_data_tc_viz(tc_track,entity); % check
%   hazard=climada_event_damage_data_tc_viz(tc_track,entity,0); % high-res
%   climada_event_damage_animation % create the movie
%
%   params=climada_event_damage_data_tc_viz % return default parameters
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
%   show_all_tracks: show all tracks (default =1), or only the ones
%       affecting the focus region (=0)
%   damage_cumsum: if =1, store the cumulative damage, If=0, store the
%       momentaneous damage (for each step/node) - which case the
%       visiulaization needs to sum up (advantage if due to huge size,
%       chunks of data need to be processed).
% OUTPUTS:
%   hazard: a hazard structure (as usual) with additional fields:
%       tc_track_node(i): the node i (tc_track.lon(i)...) for which the other
%       tc_track: the TC track (see climada_tc_read_unisys_database for
%           description of fields)
%       max_damage: the maximum damage at each centroid (useful to scale or
%           normalize, can also be calculated as =full(max(hazard.damage,[],1));
%       in case of hazard=climada_event_damage_data_tc('params'), hazard
%       contains the default parameters
%
% 	HINT: for data to be directly used by other visualization projects, you
% 	need to consider the following fields:
%   hazard.intensity(time_i,centroid_i): the hazard intensity (here m/s
%       wind speed) for timestep_i at centroid i
%   hazard.damage(time_i,centroid_i): the (cumulative) damage (here in USD)
%       for timestep_i at centroid i. See params.damage_cumsum, default=0
%   hazard.lon(centroid_i): the longitude of centroid i
%   hazard.lat(centroid_i): the latitude of centroid i
%   hazard.event_name{time_i}: then name (with time stamp) of time step i
%   hazard.focus_region(4): the region for which the data is valid
%       [minlon maxlon minlat maxlat]
%   hazard.assets.Value(year_i,centroid_j): the asset Value (USD) for year i
%       at centroid j, if first dimension=1, constant/static assets values
%   hazard.assets.lon(centroid_j): the longitude of centroid j
%   hazard.assets.lat(centroid_j): the latitude of centroid j
%   hazard.assets.Values_yyyy(year_i): the actual year for year i (=1 if
%       constant/static assets value
%   hazard.assets.Value(year_i,centroid_j): the asset Value (USD) for year i
%       at centroid j, if first dimension=1, constant/static assets values
%   hazard.tc_track(track_i): the tropical cyclone track data, where:
%       hazard.tc_track(hazard.tc_track_number(time_i)).lon(hazard.tc_track_node(time_i))
%       hazard.tc_track(hazard.tc_track_number(time_i)).lat(hazard.tc_track_node(time_i))
%       is the longitude and latitude of the track node at time step i
%   hazard.tc_track_number(time_i): the track_i of time step i, i.e.
%       hazard.tc_track(hazard.tc_track_number(time_i)) is the track
%   hazard.tc_track_node(time_i): the track node of time step i, i.e.
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20170222, intial, started from climada_event_damage_data_tc_viz
% David N. Bresch, david.bresch@gmail.com, 20170224, massive speedup
% David N. Bresch, david.bresch@gmail.com, 20170225, clean up
%-

hazard=[]; % init output

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
if ~isfield(params,'show_all_tracks'),    params.show_all_tracks=[];end
if ~isfield(params,'damage_cumsum'),      params.damage_cumsum=[];end

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
if isempty(params.show_all_tracks),       params.show_all_tracks=0;end
if isempty(params.damage_cumsum),         params.damage_cumsum=0;end
%
% some overriders for check mode
if check_mode==1,params.tc_track_timestep=1;end % 1h for checks
if check_mode==2,params.tc_track_timestep=2;end % 2h for fast checks
%
% the range (in degree) around the tc_track (to show a bit a wider area in plots)
dX=1;dY=1; % default=1
%
% set global parameters (they are reset at the end)
climada_global_transition=climada_global.tc.extratropical_transition;
climada_global.tc.extratropical_transition=1;
climada_global_damage=climada_global.damage_at_centroid;
climada_global.damage_at_centroid=1;

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
    pos=find(centroids.distance2coast_km(1:length(centroids.lon))<500);
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
            centroids.lon(end+1)=i+params.grid_delta/10;
            centroids.lat(end+1)=j+params.grid_delta/10;
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
track_node_count_start=zeros(1,n_tracks+1);track_node_count_start(1)=1; % init
% define rectangular area to search for track nodes within
edges_x = [params.focus_region(1),params.focus_region(1),params.focus_region(2),params.focus_region(2),params.focus_region(1)];
edges_y = [params.focus_region(3),params.focus_region(4),params.focus_region(4),params.focus_region(3),params.focus_region(3)];
d_nodes=ceil(10/params.tc_track_timestep); % 10 if track in hours, 100 if track in 6 min
fprintf('checking %i tracks\n',n_tracks);
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
    
    % add fields Celerity, node_dx, node_dy and node_len for speedup in climada_tc_windfield_viz
    tc_track(track_i).cos_lat  = cos(tc_track(track_i).lat/180*pi); % calculate once for speedup
    diff_tc_track_lon = diff(tc_track(track_i).lon);
    diff_tc_track_lat = diff(tc_track(track_i).lat);
    % calculate degree distance between nodes
    ddx                   = diff_tc_track_lon.*tc_track(track_i).cos_lat(2:end);
    dd                    = sqrt(diff_tc_track_lat.^2+ddx.^2)*111.1; % approx. conversion into km
    tc_track(track_i).Celerity     = dd./tc_track(track_i).TimeStep(1:length(dd)); % avoid troubles with TimeStep sometimes being one longer
    %tc_track.Celerity     = [tc_track.Celerity(1) tc_track.Celerity]; % until 20161226
    tc_track(track_i).Celerity     = [tc_track(track_i).Celerity tc_track(track_i).Celerity(end)];
    tc_track(track_i).CelerityUnit = 'km/h';
    node_dx=[diff_tc_track_lon diff_tc_track_lon(end)];
    node_dy=[diff_tc_track_lat diff_tc_track_lat(end)];
    tc_track(track_i).node_len=sqrt(node_dx.^2+node_dy.^2); % length of track forward vector
    % rotate track forward vector 90 degrees clockwise, i.e.
    % x2=x* cos(a)+y*sin(a), with a=pi/2,cos(a)=0,sin(a)=1
    % y2=x*-sin(a)+Y*cos(a), therefore
    tc_track(track_i).node_dx=node_dy;tc_track(track_i).node_dy=-node_dx;
    
    % to convert to km/h
    switch tc_track(track_i).MaxSustainedWindUnit
        case 'kn'
            tc_track(track_i).MaxSustainedWind = tc_track(track_i).MaxSustainedWind*1.8515; % =1.15*1.61
        case 'kt' % just old naming
            tc_track(track_i).MaxSustainedWind = tc_track(track_i).MaxSustainedWind*1.15*1.61;
        case 'mph'
            tc_track(track_i).MaxSustainedWind = tc_track(track_i).MaxSustainedWind/0.62137;
        case 'm/s'
            tc_track(track_i).MaxSustainedWind = tc_track(track_i).MaxSustainedWind*3.6;
        otherwise
            % already km/h
    end
    tc_track(track_i).MaxSustainedWindUnit = 'km/h'; % after conversion
    
    tc_track_tmp=climada_tc_equal_timestep(tc_track(track_i),params.tc_track_timestep); % tc_track_tmp a bit ugly, but pragmatic
    
    if params.show_all_tracks
        tc_track_tmp.min_node=1;
        tc_track_tmp.max_node=length(tc_track_tmp.lon);
    else
        % check for track nodes within params.focus_region
        in_track_poly = inpolygon(tc_track_tmp.lon,tc_track_tmp.lat,edges_x,edges_y);
        node_no=1:length(tc_track_tmp.lon);
        node_no=node_no(in_track_poly);
        max_node=min(max(node_no)+d_nodes,length(tc_track_tmp.lon));
        min_node=max(min(node_no)-d_nodes,2); % never first node
        tc_track_tmp.min_node=min_node;
        tc_track_tmp.max_node=max_node;
    end % params.show_all_tracks
    n_steps=tc_track_tmp.max_node-tc_track_tmp.min_node+1;
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
    
    climada_progress2stdout(track_i,n_tracks,20,'tracks'); % update
    
end % track_i (preprocessing)
climada_progress2stdout(0) % terminate

tc_track=tc_track_N; clear tc_track_N; % re-assign, clear
n_tracks=length(tc_track);
n_centroids=length(centroids.lon);
n_assets=length(entity.assets.lon);

fprintf('preprocessing %i tracks\n',n_tracks);
hazard.tc_track_number=zeros(1,n_events);
hazard.tc_track_node=zeros(1,n_events);
hazard.tc_track_ID_no=zeros(1,n_events);
hazard.event_name=cell(1,n_events);
climada_progress2stdout    % init, see terminate below
for track_i=1:n_tracks
    min_node=tc_track(track_i).min_node;
    max_node=tc_track(track_i).max_node;
    for node_i=min_node:max_node
        
        hazard_i=track_node_count_start(track_i)+(node_i-min_node);
        
        hazard.tc_track_number(hazard_i)=track_i;
        hazard.tc_track_node(hazard_i)=node_i;
        hazard.tc_track_ID_no(hazard_i)=tc_track(track_i).ID_no;
        hazard.event_name{hazard_i}=sprintf('%s %s',strrep(char(tc_track(track_i).name),'_',' '),...
            datestr(tc_track(track_i).datenum(node_i),'dd-mmm-yyyy HH:MM'));
    end % node_i
    climada_progress2stdout(track_i,n_tracks,20,'tracks'); % update
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

t0=clock;
if climada_global.parfor
    fprintf('processing total %i nodes of %i track(s) - parfor\n',n_events,n_tracks);
    for track_i=1:n_tracks
        e1=track_node_count_start(track_i);
        e2=track_node_count_start(track_i+1)-1;
        intensity(e1:e2,:) = sparse(climada_tc_windfield_viz(tc_track(track_i),centroids));
    end %track_i
else
    fprintf('processing total %i nodes of %i track(s)\n',n_events,n_tracks);
    climada_progress2stdout(-1,[],1)
    for track_i=1:n_tracks
        e1=track_node_count_start(track_i);
        e2=track_node_count_start(track_i+1)-1;
        intensity(e1:e2,:) = sparse(climada_tc_windfield_viz(tc_track(track_i),centroids));
        climada_progress2stdout(track_i,n_tracks,2,'tracks'); % update
    end %track_i
    climada_progress2stdout(0) % terminate
end % climada_global.parfor

t_elapsed = etime(clock,t0);
hazard.comment = sprintf('%s: processing %i tracks took %3.2f min (%3.4f sec/event)',mfilename,n_tracks,t_elapsed/60,t_elapsed/n_tracks);
fprintf('%s\n',hazard.comment);

%hazard.intensity=sparse(intensity); % store into struct, sparse() to be safe
%clear intensity % free up memory

% init hazard structure
hazard.lon=centroids.lon;
hazard.lat=centroids.lat;
hazard.centroid_ID=centroids.centroid_ID;
hazard.peril_ID='TC';
hazard.date=datestr(now);
hazard.filename=mfilename;
if isfield(entity.assets,'reference_year')
    hazard.reference_year=entity.assets.reference_year;
else
    hazard.reference_year=9999;
end
hazard.event_ID        = 1:n_events;
hazard.event_count     = n_events;
hazard.orig_event_flag = ones(1,n_events);
hazard.orig_event_count=n_events;
hazard.orig_years = tc_track(end).yyyy(end)-tc_track(1).yyyy(1)+1;
%hazard.frequency  = 1/hazard.orig_years;
hazard.frequency  = hazard.event_ID*0+1; % all one

% damage calculation
% ------------------

% now for the damage calculation in junks, since too big an
% array for damage_at_centrroids for all in one
damage_junk_size=100;
damage_junk_start=(0:damage_junk_size:n_events)+1;
damage_junk_end  =[damage_junk_start(2:end)-1 n_events];
if damage_junk_end(end)<damage_junk_start(end)
    damage_junk_start=damage_junk_start(1:end-1);
    damage_junk_end=damage_junk_end(1:end-1);
end
n_junks=length(damage_junk_start);

damage    = spalloc(n_steps,n_assets,...
    ceil(n_steps*n_assets*params.hazard_arr_density));

local_hazard.peril_ID    = hazard.peril_ID;
local_hazard.event_ID    = hazard.event_ID(e1:e2);
local_hazard.centroid_ID = hazard.centroid_ID;

if climada_global.parfor
    fprintf('processing total %i EDSs (%i timesteps each) - parfor\n',n_junks,damage_junk_size);
    for junk_i=1:n_junks
        e1=damage_junk_start(junk_i);
        e2=damage_junk_end(junk_i);
        
        % junk of hazard structure
        
        local_hazard.frequency   = hazard.frequency(e1:e2);
        local_hazard.intensity   = intensity(e1:e2,:);
        local_hazard.fraction    = spones(local_hazard.intensity); % fraction 100%
        local_hazard.event_count = e2-e1+1;
        
        EDS=climada_EDS_calc(entity,local_hazard,'',0,2); % last=2 silent
        
        damage(e1:e2,:)=sparse(EDS.damage_at_centroid)';
    end % junk_i
else
    fprintf('processing total %i EDSs (%i timesteps each)\n',n_junks,damage_junk_size);
    climada_progress2stdout(-1,[],1)
    for junk_i=1:n_junks
        e1=damage_junk_start(junk_i);
        e2=damage_junk_end(junk_i);
        
        % junk of hazard structure
        
        local_hazard.frequency   = hazard.frequency(e1:e2);
        local_hazard.intensity   = intensity(e1:e2,:);
        local_hazard.fraction    = spones(local_hazard.intensity); % fraction 100%
        local_hazard.event_count = e2-e1+1;
        
        EDS=climada_EDS_calc(entity,local_hazard,'',0,2); % last=2 silent
        
        damage(e1:e2,:)=sparse(EDS.damage_at_centroid)';
        climada_progress2stdout(junk_i,n_junks,1,'EDSs'); % update
    end % junk_i
    climada_progress2stdout(0) % terminate
end % parfor

climada_global.tc.extratropical_transition=climada_global_transition; % reset
climada_global.damage_at_centroid=climada_global_damage; % reset

% complete hazard
% ---------------
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

% save the relevant TC track information for nicer plot options
for track_i=1:length(tc_track)
    hazard.tc_track(track_i).lon     = tc_track(track_i).lon;
    hazard.tc_track(track_i).lat     = tc_track(track_i).lat;
    hazard.tc_track(track_i).datenum = tc_track(track_i).datenum;
end % track_i
clear tc_track % also store tc_track to hazard

hazard.assets=entity.assets; % also store assets to hazard
hazard.focus_region=params.focus_region; % also add focus region

hazard.intensity  = intensity;clear intensity
if params.damage_cumsum
    hazard.damage = cumsum(damage,1);
else
    hazard.damage = damage;
end
clear damage
hazard.fraction   = spones(hazard.intensity); % fraction 100%

hazard.max_damage = max(hazard.damage,[],1); % store max damage
fprintf('max cumulated TC damage %g\n',full(max(hazard.max_damage)));

hazard.matrix_density=nnz(hazard.intensity)/numel(hazard.intensity);

fprintf('saving animation data in %s\n',params.animation_data_file);
save(params.animation_data_file,'hazard','-v7.3');

end % climada_event_damage_data_tc_viz