function [hazard,hazard_TS]=climada_event_damage_data_tc(tc_track,entity,animation_data_file,add_surge,check_mode,focus_region)
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
%   Instead of uisng a track from any of the ../data/tc_tracks databases,
%   you might also just download a single track from
%   weather.unisys.com/hurricane (click trough to a single track, then
%   save the 'tracking information' as .dat file, i.e. right click and save
%   as...) and then load with tc_track=climada_tc_read_unisys_track (in
%   contrast to climada_tc_read_unisys_database, this reads one single
%   track from a single track .dat file).
%
%   The code asks for a tc track and an entity and produces all the
%   step-by-step data to produce a damage animation. Instead of single
%   events, the resulting hazard event set contains single time steps of
%   the one event and the corresponding damage is also stored as a field
%   into hazard (hazard.damage). For ease of use, the tc_track and the
%   assets are also stored to hazard.
%
%   The code determines the plot area based on entity (but since there can be
%   more than one ocean basin's tracks hitting the centroids, the user has
%   to select the track file). See variable focus_region in case you'd like
%   to hard-wire the region (see PARAMETERS in code).
%
%   prior calls: none necessarily, consider climada_tc_track_info to obtain
%   information about all tracks in an ocean basin
%   next call: climada_event_damage_animation
% CALLING SEQUENCE:
%   [hazard,hazard_TS]=climada_event_damage_data_tc(tc_track,entity,animation_data_file,add_surge,check_mode)
% EXAMPLE:
%   % save a single track file from weather.unisys.com/hurricane as .dat
%   tc_track=climada_tc_read_unisys_track % read the single track file
%   hazard=climada_event_damage_data_tc(tc_track,[],'',0,1); % prompts for entity, check
%   hazard=climada_event_damage_data_tc(tc_track,[],'',0,0); % prompts for entity, high-res
%   climada_event_damage_data_tc([],[],'',1); % TC and TS, check mode
%
%   [hazard,hazard_TS]=climada_event_damage_data_tc([],[],'',1); % TC and TS, check mode
%   [hazard,hazard_TS]=climada_event_damage_data_tc([],[],'',0,0); % no TS, no plots
% INPUTS:
%   tc_track: a tc_track structure, as returned by
%       climada_tc_read_unisys_database or climada_tc_read_unisys_tc_track
%       > promted for if not given
%       Note: if a tc_track struct is passed, the user is prompted for the
%       specific single track (a plot shows all tracks to select from)
%   entity: a climada entity, see climada_entity_read (skip hazard set
%       selection to encode to) or climada_entity_load
%       > promted for if not given
%       Note: for speedup, consider creating an entity covering only the
%       region you'd like to focus on, e.g. avoid full contiguous US if
%       you'd like to animate a TC hitting Floriday, i.e consider
%       entity=climada_nightlight_entity('USA','Florida')
%   animation_data_file: the file where animation data is stored (not the
%       animation itself). If not provided, set to ../results/animation_data.mat
% OPTIONAL INPUT PARAMETERS:
%   add_surge: whether we also treat surge (TS) =1) or not (=0, default)
%   check_mode: =1: show plots, use 1h timestep
%       =0: no plots, 6 min timestep (the best option to generate the data
%       pretty fast)
%       =2: (default) show plots, use 2h timestep (fast check)
%       <0: set timestep=check_mode and omit any plots (expert use)
%   focus_region: the region we're going to show [minlon maxlon minlat maxlat]
%       default=[], automatically determined by area of entity lat/lon
%       SPECIAL: if =1, use the region around the tc_track, NOT around the entity
% OUTPUTS:
%   hazard_plus: a hazard structure (as usual) with additional fields:
%       tc_track_node(i): the node i (tc_track.lon(i)...) for which the other
%       fields (like hazard.intensity(i,:)..) are valid
%       tc_track: the TC track (see climada_tc_read_unisys_database for
%           description of fields)
%       damage: the same dimension as intensity, the damage at each
%           centroid for each timestep of the tc track
%       max_damage: the maximum damage at each centroid (useful to scale or
%           normalize, can also be calculated as =full(max(hazard.damage,[],1));
%   hazard_TS: in case add_surge=1, otherwise empty. Does contain the same
%       additional fields tc_track, tc_track_node, damage and max_damage.
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150117, intial
% David N. Bresch, david.bresch@gmail.com, 20150118, TS added
% David N. Bresch, david.bresch@gmail.com, 20150120, check_mode added
% David N. Bresch, david.bresch@gmail.com, 20150128, climada_tc_track_nodes
% David N. Bresch, david.bresch@gmail.com, 20150220, focus_region added
%-

hazard=[]; % init output
hazard_TS=[]; % init output
close all % TEST

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('tc_track','var'),tc_track=[];end
if ~exist('entity','var'),entity=[];end
if ~exist('animation_data_file','var'),animation_data_file=[];end
if ~exist('add_surge','var'),add_surge=0;end
if ~exist('check_mode','var'),check_mode=2;end
if ~exist('focus_region','var'),focus_region=[];end
if ~exist('tc_track_mat','var'),tc_track_mat='';end

% PARAMETERS
%
% whether we show single steps (=0, default) or the footprint (=1)
show_footprint=0; % default=0
%
% the timestep (in hours or fractions thereof) between nodes
tc_track_timestep=0.1; % 0.1 means 6 min, good movie resolution, used if check_mode=0;
if check_mode==1,tc_track_timestep=1;end % 1h for checks
if check_mode==2,tc_track_timestep=2;end % 2h for fast checks
if check_mode<0,tc_track_timestep=abs(check_mode);check_mode=0;end % expert
%
% the scale for plots, such that max_damage=max(entity.assets.Value)*damage_scale
damage_scale=1/100;
%
% the range (in degree) around the tc_track (to show a bit a wider area in plots)
dX=1;dY=1; % default=1
%
% the rect to plot (default is track's full coverage, =[], in which case it is automatically determined)
focus_region=[]; % default=[], [minlon maxlon minlat maxlat]
%-- for Salvador, lea, 20150220
% focus_region = [-91.5 -86 12 15.5];
%------------------------------------------

% label track nodes along track
label_track_nodes=0; % default=0
%
% a grid to show windfield (as the entity might only contain points on land)
grid_add=1; % default=1, =0 if centroids cover eg water points already
grid_delta=0.2; % grid spacing in degree, default=1
%
% the nodes we're interested in
min_node=[];max_node=[]; % by default empty, automatically determined
%
% % TEST for atl (Katrina)
% tc_track_file=[climada_global.data_dir filesep 'tc_tracks' filesep 'TEST_tracks.atl.txt'];
% [tc_track,tc_track_mat]=climada_tc_read_unisys_database(tc_track_file);
% tc_track=tc_track(84); % Katrina
% entity_file=[climada_global.data_dir filesep 'entities' filesep 'demo_today.mat'];
% entity=climada_entity_load(entity_file);
%
%
% % TEST for nio (Sidr)
% tc_track_file=[climada_global.data_dir filesep 'tc_tracks' filesep 'tracks.nio.txt'];
% [tc_track,tc_track_mat]=climada_tc_read_unisys_database(tc_track_file);
% tc_track=tc_track(173); % Sidr
% entity_file=[climada_global.data_dir filesep 'entities' filesep 'BGD_Bangladesh_entity.mat'];
% entity=climada_entity_load(entity_file);
% add_surge=0;
%
% the file to store all information for nicer animation plots
% currently set to a default, but could also be prompted for (see below)
if isempty(animation_data_file),animation_data_file=[climada_global.data_dir filesep 'results' filesep 'animation_data.mat'];end

% prompt for inputs, if not provided:
if isempty(tc_track),[tc_track,tc_track_mat]=climada_tc_read_unisys_database;end % get tc_track
if isempty(entity),entity=climada_entity_load;end                                % get entity
if isempty(entity),return;end                                                    % Cancel pressed
% if isempty(animation_data_file)                                                  % get output filename
%     animation_data_file=[climada_global.data_dir filesep 'results' filesep 'animation_data.mat'];
%     [filename, pathname] = uiputfile(animation_data_file, 'Save animation data as:');
%     if isequal(filename,0) || isequal(pathname,0)
%         return; % cancel
%     else
%         animation_data_file=fullfile(pathname,filename);
%     end
% end

focus_track_region=0;
if ~isempty(focus_region)
    if focus_region(1)==1,focus_track_region=1;focus_region=[];end
end
if isempty(focus_region) % define the focus region based on entity
    focus_region(1)=min(entity.assets.lon)-dX;
    focus_region(2)=max(entity.assets.lon)+dX;
    focus_region(3)=min(entity.assets.lat)-dY;
    focus_region(4)=max(entity.assets.lat)+dY;
    focus_track_region=0;
end

if length(tc_track)>1
    
    % obtain tc_track nodes
    tc_track_nodes=climada_tc_track_nodes(tc_track_mat);
    if isempty(tc_track_mat)
        tc_track_mat = [climada_global.data_dir filesep 'tc_tracks' filesep 'unknown_tracks'];
    end
    % figure which tracks are in the focus region
    [fP,fN]=fileparts(tc_track_mat);
    fN=strrep(fN,'_proc','');
    tc_track_nodes_file=[fP filesep fN '_nodes.mat'];
    
    if ~exist(tc_track_nodes_file,'file')
        tc_track_nodes.lon=[];
        tc_track_nodes.lat=[];
        tc_track_nodes.track_no=[];
        fprintf('collecting all nodes for %i TC tracks\n',length(tc_track));
        for track_i=1:length(tc_track)
            tc_track_nodes.lon=[tc_track_nodes.lon tc_track(track_i).lon];
            tc_track_nodes.lat=[tc_track_nodes.lat tc_track(track_i).lat];
            tc_track_nodes.track_no=[tc_track_nodes.track_no (tc_track(track_i).lat)*0+track_i];
        end % track_i
        fprintf('saving TC track nodes as %s\n',tc_track_nodes_file);
        save(tc_track_nodes_file,'tc_track_nodes');
    else
        load(tc_track_nodes_file);
    end
    
    % check for track nodes within focus_region
    edges_x = [focus_region(1),focus_region(1),focus_region(2),focus_region(2),focus_region(1)];
    edges_y = [focus_region(3),focus_region(4),focus_region(4),focus_region(3),focus_region(3)];
    
    in_track_poly = inpolygon(tc_track_nodes.lon,tc_track_nodes.lat,edges_x,edges_y);
    focus_region_track_no=unique(tc_track_nodes.track_no(in_track_poly));
    
    tc_track=climada_tc_stormcategory(tc_track); % add storm category

    fprintf('iiii: name          yyyymmdd  category (only tracks within the area)\n'); % header

    for track_ii=1:length(focus_region_track_no)
        track_i=focus_region_track_no(track_ii);
        plot(tc_track(track_i).lon,tc_track(track_i).lat,'-r');hold on
        for node_i=1:5:length(tc_track(track_i).lon) % lebel the track
            text(tc_track(track_i).lon(node_i),tc_track(track_i).lat(node_i),sprintf('%i',track_i),'FontSize',9,'Color','r');
        end

        fprintf('%4.4i: %s (%4.4i%2.2i%2.2i) %i\n',track_i,...
            char(tc_track(track_i).name),...
            tc_track(track_i).yyyy(1),tc_track(track_i).mm(1),tc_track(track_i).dd(1),...
            max(tc_track(track_i).category));
    end % track_i
    axis equal
    axis(focus_region);
    climada_plot_world_borders(1,'','',1);
    drawnow
    
    % ask for selection
    prompt={'Enter the tc track number to animate:'};
    name='Input for tc track animation';
    numlines=1;
    defaultanswer={'1'};
    answer=inputdlg(prompt,name,numlines,defaultanswer);
    if ~isempty(answer)
        track_i=answer{1};
        track_i=str2double(track_i);
        fprintf('tc_track(%i) selected\n',track_i);
    else
        return
    end
else
    track_i=1;
end

tc_track=tc_track(track_i);

if focus_track_region==1
    % we focus on the whole track rather than the entity region
    focus_region(1)=min(tc_track.lon)-dX;
    focus_region(2)=max(tc_track.lon)+dX;
    focus_region(3)=min(tc_track.lat)-dY;
    focus_region(4)=max(tc_track.lat)+dY;
end

tc_track=climada_tc_equal_timestep(tc_track,tc_track_timestep);

% prepare entity and centroids
centroids.lon=entity.assets.lon;
centroids.lat=entity.assets.lat;

if grid_add
    if isempty(focus_region)
        grid_region=[min(tc_track.lon) max(tc_track.lon) min(tc_track.lat) max(tc_track.lat)];
    else
        grid_region=focus_region;
    end
    for i=grid_region(1):grid_delta:grid_region(2)
        for j=grid_region(3):grid_delta:grid_region(4)
            centroids.lon(end+1)=i;
            centroids.lat(end+1)=j;
        end
    end
end
centroids.centroid_ID=1:length(centroids.lon);

if check_mode
    % plot overview and get decent plot region (o cover whole track)
    plot(tc_track.lon,tc_track.lat,'-g');hold on
    set(gcf,'Color',[1 1 1]) % white background
    axis equal
    axis(focus_region);
    climada_plot_world_borders(1,'','',1);
end

d_nodes=ceil(10/tc_track_timestep); % 10 if track in hours, 100 if track in 6 min
if isempty(max_node) || isempty(min_node)
    % check for track nodes within focus_region
    edges_x = [focus_region(1),focus_region(1),focus_region(2),focus_region(2),focus_region(1)];
    edges_y = [focus_region(3),focus_region(4),focus_region(4),focus_region(3),focus_region(3)];
    in_track_poly = inpolygon(tc_track.lon,tc_track.lat,edges_x,edges_y);
    node_no=1:length(tc_track.lon);
    node_no=node_no(in_track_poly);
    if isempty(max_node),max_node=min(max(node_no)+d_nodes,length(tc_track.lon));end
    if isempty(min_node),min_node=max(min(node_no)-d_nodes,2);end
end
min_node=max(min_node,2); % avoid 1 since windfield needs at least two nodes

n_steps=max_node-min_node+1;

% init hazard structure
hazard.lon=centroids.lon;
hazard.lat=centroids.lat;
hazard.centroid_ID=centroids.centroid_ID;
hazard.peril_ID='TC';
hazard.orig_years=1;
hazard.event_count=n_steps;
hazard.event_ID=1:hazard.event_count;
hazard.date=datestr(now);
hazard.orig_event_count=hazard.event_count;
hazard.orig_event_flag=hazard.event_ID*0+1;
hazard.frequency=(hazard.event_ID*0+1); % all once
hazard.filename=mfilename;
hazard.reference_year=climada_global.present_reference_year;
hazard.comment=sprintf('special hazard event set for animation plots, generated by %s',mfilename);
% allocate the hazard array (sparse, to manage memory)
hazard_arr_density=0.1;
hazard.intensity = spalloc(hazard.event_count,length(hazard.lon),...
    ceil(hazard.event_count*length(hazard.lon)*hazard_arr_density));
hazard.tc_track_node=zeros(1,hazard.event_count); % special, to store tc_track node
hazard.damage=hazard.intensity;
max_damage_at_centroid=[]; % init
hazard.units='m/s';


%entity=climada_assets_encode(entity,hazard); % to be on the safe side, lea, 20150131
% previous line not needed, since we create hazard.lat/lon from entity.lat/lon
entity.assets.centroid_index = 1:length(entity.assets.lon);

% for-loop progress to stdout
t0       = clock;
msgstr   = sprintf('processing %i steps (%i..%i)',n_steps,min_node,max_node);
mod_step = 2; % first time estimate after 2 steps, then every 10th
fprintf('%s\n',msgstr);
format_str='%s';

%for step_i=2:length(tc_track.lon)
for step_i=min_node:max_node
    if show_footprint
        step0=1;
    else
        step0=max(1,step_i-1);
    end
    tc_track_segment.MaxSustainedWindUnit=tc_track.MaxSustainedWindUnit;
    tc_track_segment.CentralPressureUnit =tc_track.CentralPressureUnit;
    tc_track_segment.TimeStep=tc_track.TimeStep(step0:step_i);
    tc_track_segment.lon=tc_track.lon(step0:step_i);
    tc_track_segment.lat=tc_track.lat(step0:step_i);
    tc_track_segment.MaxSustainedWind=tc_track.MaxSustainedWind(step0:step_i);
    tc_track_segment.CentralPressure=tc_track.CentralPressure(step0:step_i);
    tc_track_segment.name=tc_track.name;
    tc_track_segment.datenum=tc_track.datenum(step0:step_i);
    if check_mode
        plot(tc_track_segment.lon,tc_track_segment.lat,'xg');hold on
        if label_track_nodes,text(tc_track_segment.lon(end),tc_track_segment.lat(end),sprintf('%i',step_i),'FontSize',9,'Color','g');end
    end
    res=climada_tc_windfield(tc_track_segment,centroids,0,1,0);
    
    hazard.intensity(step_i-min_node+1,:)=res.gust;
    hazard.tc_track_node(step_i-min_node+1)=step_i;
    
    if check_mode
        % plot intensity
        LOCAL_circle_plot(hazard.lon,hazard.lat,...
            hazard.intensity(step_i-min_node+1,:),100,20,'ob',1); % wind speed blue circles
    end
    
    % calculate damage
    temp_hazard=hazard;temp_hazard.intensity(1:step_i-min_node,:)=0; % we only need present step for damage
    EDS=climada_EDS_calc(entity,temp_hazard,'',0,1); % last 1: silent mode
    if isempty(max_damage_at_centroid)
        max_damage_at_centroid=EDS.ED_at_centroid;
    else
        max_damage_at_centroid=max(max_damage_at_centroid,EDS.ED_at_centroid);
    end

    hazard.damage(step_i-min_node+1,1:length(EDS.ED_at_centroid))=EDS.ED_at_centroid'; % store damage
        
    if check_mode
        LOCAL_circle_plot(hazard.lon,hazard.lat,max_damage_at_centroid,...
            max(entity.assets.Value)*damage_scale,20,'or',3); % damage red circles
        title(sprintf('%s %s',strrep(char(tc_track_segment.name),'_',' '),datestr(tc_track_segment.datenum(end))));
        drawnow
    end
    
    % the progress management
    if mod(step_i,mod_step)==0
        mod_step          = 10;
        t_elapsed_event   = etime(clock,t0)/(step_i-min_node+1);
        events_remaining  = n_steps-(step_i-min_node+1);
        t_projected_sec   = t_elapsed_event*events_remaining;
        msgstr = sprintf('est. %3.0f sec left (%i/%i nodes)',t_projected_sec,   step_i-min_node+1,n_steps);
        fprintf(format_str,msgstr); % write progress to stdout
        format_str=[repmat('\b',1,length(msgstr)) '%s']; % back to begin of line
    end
    
end % step_i
fprintf(format_str,''); % move carriage to begin of line
if check_mode,xlabel('wind [m/s] blue, damage [USD] red');end
hazard.max_damage=max_damage_at_centroid'; % store max damage
hazard.matrix_density=nnz(hazard.intensity)/numel(hazard.intensity);


if add_surge
    % add TS (tropical cyclone surge)
    hazard_TS=tc_surge_hazard_create(hazard,'NO_SAVE');
    
    % calculate TS damage
    hazard_TS.damage=hazard_TS.intensity*0; % init
    max_damage_at_centroid=[];
    for step_i=1:length(hazard_TS.event_ID)
        temp_hazard=hazard_TS;
        temp_hazard.intensity(1:step_i-1,:)  =0; % we only need present step
        temp_hazard.intensity(step_i+1:end,:)=0; % we only need present step
        
        if check_mode
            hold on
            LOCAL_circle_plot(hazard_TS.lon,hazard_TS.lat,...
                full(temp_hazard.intensity(step_i,:)),10,20,'oc',1); % surge height cyan circles
        end
        
        EDS=climada_EDS_calc(entity,temp_hazard,'',0,1); % last 1: silent mode
        if isempty(max_damage_at_centroid)
            max_damage_at_centroid=EDS.ED_at_centroid;
        else
            max_damage_at_centroid=max(max_damage_at_centroid,EDS.ED_at_centroid);
        end
        hazard_TS.damage(step_i,1:length(EDS.ED_at_centroid))=EDS.ED_at_centroid; % store damage
        
        if check_mode
            LOCAL_circle_plot(hazard_TS.lon,hazard_TS.lat,...
                max_damage_at_centroid,max(entity.assets.Value)*damage_scale,20,'om',3); % surge magenta circles
            drawnow
        end
        
    end
    if check_mode,xlabel('wind [m/s] blue, surge [m] cyan, damage [USD]: wind red, surge magenta');end
    hazard_TS.max_damage=max_damage_at_centroid'; % store max damage
    hazard_TS.tc_track=tc_track; % also store tc_track to hazard
    hazard_TS.assets=entity.assets; % also store assets to hazard
    hazard_TS.tc_track_node=hazard.tc_track_node;
    hazard_TS.focus_region=focus_region;
end

% save all the relevant information for nicer plot options
hazard.tc_track=tc_track; % also store tc_track to hazard
hazard.assets=entity.assets; % also store assets to hazard
hazard.focus_region=focus_region; % also add focus region
fprintf('saving animation data in %s\n',animation_data_file);
save(animation_data_file,'hazard','hazard_TS');

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
