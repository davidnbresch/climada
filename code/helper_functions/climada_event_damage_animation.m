function res=climada_event_damage_animation(animation_data_file,params)
% climada event animation movie
% MODULE:
%   core
% NAME:
%   climada_event_damage_animation
% PURPOSE:
%   Animation of event damage - as an .mp4 movie
%
%   This code does the visualization (rendering), see e.g.
%   climada_event_damage_data_tc to calculate all the data first. You might
%   also consider to write your own version of climada_event_damage_data_tc
%   (e.g for another peril than TC).
%
%   As one often needs to play with visualization parameters, the process is split.
%   Threrefor call climada_event_damage_animation without any argument to return the
%   default parameters (same as calling climada_event_damage_animation('params')
%
%   Note that this code does not (yet) run in Octave, as video support is
%   limited (see <http://octave.sf.net/video/>) and the present code uses
%   latest MATLAB videowriter (better performance than avifile...).
%
%   Soemtimes, it is faster to edit fields in hazard instead of re-running
%   climada_event_damage_data_tc, like: for i=1:length(hazard.event_name),...
%   hazard.event_name{i}=strrep(hazard.event_name{i},'NNN 1200706','Sidr');end
%   (obviously, you first load and then save animation_data.mat)
%
%   prior calls: climada_event_damage_data_tc or similar to prepare the
%       event damage information
%
%   NOTE: please consider to rename and edit/tune your local version
% CALLING SEQUENCE:
%   climada_event_damage_animation(animation_data_file,params)
% EXAMPLE:
%   climada_event_damage_animation
%   climada_event_damage_animation('ask'); % prompt for both input data and output animation filename
%
%   params=climada_event_damage_animation('params') % return default parameters
%   climada_event_damage_animation('colors') % check color maps
% INPUTS:
%   animation_data_file: the data file (.mat) with hazard set which
%       includes event damage information, see e.g. climada_event_damage_data_tc
%       If specified without path, searched for in ../results and extension .mat
%       If empty, use the default file, i.e. ../results/animation_data.mat
%       If ='ask', prompt for
%       If ='params', return all default parameters in res, abort
%       If ='colors', check color maps, abort
%       If ='check', run three frames about 70% into the animation to
%       briefly check
% OPTIONAL INPUT PARAMETERS:
%   params: a structure with fields:
%    animation_mp4_file: the filename of the resulting .mp4 movie
%       If specified without path, stored in ../results with extension
%       according to VideoWriter (see params.video_profile)
%       If empty, use default ../results/animation_movie.mp4 (or other ext)
%       If ='ask', prompt for (if cancel pressed, the movie frames are
%       not written to file - useful for test)
%    focus_region: the region we're going to show [minlon maxlon minlat maxlat]
%       if empty, automatically determined by area of entity lat/lon, i.e.
%       hazard.assets.lat/lon
%       Default: use the region as stored in hazard.focus_region
%    FontSize: the size for legend and title, default=18 (good readability
%       on animation)
%    asset_markersize: the size of the 'dots' to plot entity and damage,
%       default=5
%    npoints: the resolution of the hazard intensity plot (since
%       re-gridded), default =599 points (the higher the more time consuming)
%    schematic_tag: if =1, use (old) schematic intensity colortable, default=0
%    Position: the figure position, as in figure
%       =[1 5 1310 1100] screen at home
%       =[1 5 2560 1340] screen in the office
%    frame_start: frame to start with (default=1). Sometimes useful to
%       shorten animation without re-generating animation_data.mat
%    frame_end: last frame to process (default=last frame on animation_data.mat)
%    jump_step: the steps to jump (in order to first check, e.g. only show
%       every 5th frame by setting jump_step=5, default=1 (all steps).
%    plot_tc_track: show tc track as a black dotted line (default=, no plot).
%       the value of plot_tc_track is the MarkerSize of the dots, use e.g.=5
%    video_profile: the video profile (see help VideoWriter), default is ='MPEG-4'
%       if this fails, try ='Motion JPEG AVI'
%       If strcmpi(computer,'GLNXA64') the code uses 'Motion JPEG AVI' as
%       default already
%    check_colors: if =1, check color maps, then abort, default=0
% OUTPUTS:
%   the .mp4 animation file in res.animation_mp4_file
%   res: the parameter structure params as used (helpful to obtain all default
%       values, see animation_data_file='params')
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150118, initial
% David N. Bresch, david.bresch@gmail.com, 20150119, hazard translucent, entity blue, damage red
% Lea Mueller, muellele@gmail.com, 20150202, schematic tag, exponential circle size for assets
% David N. Bresch, david.bresch@gmail.com, 20150220, show_plots added
% David N. Bresch, david.bresch@gmail.com, 20150220, focus_region added
% David N. Bresch, david.bresch@gmail.com, 20150318, save as text debugged
% David N. Bresch, david.bresch@gmail.com, 20150804, switched from 'Uncompressed AVI' to 'MPEG-4' (no AVI coded on Mac)
% David N. Bresch, david.bresch@gmail.com, 20150915, schematic_tag=2 implemented, i.e. asset distribution shown as in climada_entity_plot
% David N. Bresch, david.bresch@gmail.com, 20150916, speedup plotting map borders directly (avoid climada_plot_world_borders)
% David N. Bresch, david.bresch@gmail.com, 20160516, filenames without path allowed
% David N. Bresch, david.bresch@gmail.com, 20170103, params introduced, easier to introduce new features going forward, colorscale adjusted
% David N. Bresch, david.bresch@gmail.com, 20170104, clean up
% David N. Bresch, david.bresch@gmail.com, 20170105, frame_start, frame_end and plot_tc_track, video_profile
% David N. Bresch, david.bresch@gmail.com, 20170228, npoints in params, schematic_tag removed, lots of old stuff removed
% David N. Bresch, david.bresch@gmail.com, 20170301, 'check' option added
%-

res=[]; % init output, mainly used to return (default) parameters

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%if nargin==0,animation_data_file='params';end % to return params

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('animation_data_file','var'),animation_data_file = '';end
if ~exist('params','var'),             params=struct;end

% check for some parameter fields we need
if ~isfield(params,'animation_mp4_file'),params.animation_mp4_file='';end
if ~isfield(params,'schematic_tag'),params.schematic_tag=[];end
if ~isfield(params,'show_plots'),params.show_plots=[];end
if ~isfield(params,'focus_region'),params.focus_region=[];end
if ~isfield(params,'FontSize'),params.FontSize=[];end
if ~isfield(params,'asset_markersize'),params.asset_markersize=[];end
if ~isfield(params,'schematic_tag'),params.schematic_tag=[];end
if ~isfield(params,'damage_scale'),params.damage_scale=[];end
if ~isfield(params,'Position'),params.Position=[];end
if ~isfield(params,'jump_step'),params.jump_step=[];end
if ~isfield(params,'frame_start'),params.frame_start=[];end
if ~isfield(params,'frame_end'),params.frame_end=[];end
if ~isfield(params,'plot_tc_track'),params.plot_tc_track=[];end
if ~isfield(params,'video_profile'),params.video_profile=[];end
if ~isfield(params,'npoints'),params.npoints=[];end
if ~isfield(params,'check_colors'),params.check_colors=[];end

% PARAMETERS
%
animation_data_file_DEF=[climada_global.data_dir filesep 'results' filesep 'animation_data.mat'];
if isempty(animation_data_file),animation_data_file=animation_data_file_DEF;end
%
% set default values (see header for details)
if isempty(params.animation_mp4_file),params.animation_mp4_file=...
        [climada_global.data_dir filesep 'results' filesep 'animation_movie.mp4'];end
if isempty(params.show_plots),params.show_plots=0;end
if isempty(params.FontSize),params.FontSize=18;end
if isempty(params.asset_markersize),params.asset_markersize=1;end % was 5
if isempty(params.schematic_tag),params.schematic_tag=0;end
% the scale for plots, such that max_damage=max(entity.assets.Value)*damage_scale
if isempty(params.damage_scale),params.damage_scale=1/3;end
if isempty(params.Position),params.Position=[1 5 1310 1100];end % screen at home
%if isempty(params.Position),params.Position=[1 5 2560 1340];end % screen in the office
if isempty(params.jump_step),params.jump_step=1;end
if isempty(params.frame_start),params.frame_start=1;end
if isempty(params.plot_tc_track),params.plot_tc_track=1;end
if isempty(params.video_profile)
    if strcmpi(computer,'GLNXA64') % does not support mp4
        params.video_profile='Motion JPEG AVI'; % larger output
    else
        params.video_profile='MPEG-4'; % default, best compression
    end
end
if isempty(params.npoints),params.npoints=599;end % was 199
if isempty(params.check_colors),params.check_colors=0;end
%
windfieldFaceAlpha=0.7; % transparent
%
% intensity plot parameters
interp_method='linear';
%
% the range (in degree) around the tc_track (to show a bit a wider area in plots)
dX=0;dY=0; % default=1
%
% TEST
make_mp4=1; % default=1, set =0 for debugging (no movie file created, each frame shown on screen)
%
% assets coloring (used for solid colored assets, ignored for circles)
assets_cmap = makeColorMap([0 1 0], [0 0 1], 10);
%
% damage coloring (used for solid colored assets, ignored for circles)
damage_cmap = makeColorMap([.7 .7 0], [1 0 0], 10); % [Red Green Blue] [1 1 1] white, [0 0 0] black
% to test color maps:
%close all;figure,colormap(assets_cmap);colorbar;figure,colormap(damage_cmap);colorbar

if strcmpi(animation_data_file,'params'),res=params;return;end % special case, return the full params strcture
if strcmpi(animation_data_file,'colors'),
    params.check_colors=1; % special case, return the full params strcture
    animation_data_file=animation_data_file_DEF;
end 
if strcmpi(animation_data_file,'check')
    check_mode=1;
    animation_data_file=animation_data_file_DEF;
else
    check_mode=0;
end 

% prompt for animation_data_file if not given
if strcmpi(animation_data_file,'ask') % local GUI
    animation_data_file=[climada_global.data_dir filesep 'results' filesep 'animation_data.mat'];
    [filename, pathname] = uigetfile(animation_data_file, 'Select animation data file:');
    if isequal(filename,0) || isequal(pathname,0)
        fprintf('Consider running climada_event_damage_data_tc to generate the animation data file\n');
        return; % cancel
    else
        animation_data_file=fullfile(pathname,filename);
    end
end

% complete animation_data_file path, if missing
[fP,fN,fE]=fileparts(animation_data_file);
if isempty(fP),fP=[climada_global.data_dir filesep 'results'];end
if isempty(fE),fE='.mat';end
animation_data_file=[fP filesep fN fE];

% prompt for params.animation_mp4_file if not given
if strcmpi(params.animation_mp4_file,'ask') % local GUI
    params.animation_mp4_file =[climada_global.data_dir filesep 'results' filesep 'animation_movie.mp4'];
    [filename, pathname] = uiputfile(params.animation_mp4_file, 'Save animation as (Cancel: show frames on screen only):');
    if isequal(filename,0) || isequal(pathname,0)
        make_mp4=0;
        params.animation_mp4_file='';
    else
        params.animation_mp4_file=fullfile(pathname,filename);
    end
end

% complete params.animation_mp4_file path, if missing
[fP,fN,fE]=fileparts(params.animation_mp4_file);
if isempty(fP),fP=[climada_global.data_dir filesep 'results'];end
if isempty(fE),fE='.mp4';end
params.animation_mp4_file=[fP filesep fN fE];

load(animation_data_file);

if check_mode
    fprintf('SPECIAL check mode\n');
    n_frames=size(hazard.intensity,1);
    params.frame_start=ceil(0.75*n_frames);
    params.frame_end=params.frame_start+2;
    % sum up all damages up to this frame, in order to show a reasonable
    % image
    % hazard.damage(params.frame_start,:)=sum(hazard.damage(1:params.frame_start,:));
end

c_ax = []; %init
if params.schematic_tag
    % create schematic colormap (gray red)
    [hazard_cmap,c_ax]= climada_colormap('schematic');
    %if exist([climada_global.system_dir filesep 'colormap_gray_red.mat'],'file')
    %load([climada_global.system_dir filesep 'colormap_gray_red'])
    %hazard_cmap = gray_red;
    %%colormap(hazard_cmap)
    %end
else
    % color range for hazard intensity
    [hazard_cmap,c_ax]= climada_colormap(hazard.peril_ID);
    hazard_cmap = brighten(hazard_cmap,0.2);
end
if isempty(c_ax)
    c_ax = [0 full(max(max(hazard.intensity)))];
end

if params.check_colors
    % to test color maps:
    close all;
    figure('Name','assets'),colormap(assets_cmap);colorbar;title('assets');
    figure('Name','hazard'),colormap(hazard_cmap);colorbar;title('hazard');
    figure('Name','damage'),colormap(damage_cmap);colorbar;title('damage');
    fprintf('STOP: run again without ''colors''\n');
    return
end

if params.show_plots,fig_visible='on';else fig_visible='off';end
fig_handle = figure('Name','animation','visible',fig_visible,'Color',[1 1 1],'Position',params.Position);

intensity_units=[char(hazard.peril_ID) ' intensity'];
if isfield(hazard,'units'),intensity_units=[intensity_units ' [' hazard.units ']'];end

if isempty(params.focus_region) % define the focus region based on entity
    if isfield(hazard,'focus_region')
        params.focus_region=hazard.focus_region;
    else
        params.focus_region(1)=min(hazard.assets.lon)-dX;
        params.focus_region(2)=max(hazard.assets.lon)+dX;
        params.focus_region(3)=min(hazard.assets.lat)-dY;
        params.focus_region(4)=max(hazard.assets.lat)+dY;
        params.focus_region(4)=params.focus_region(4) + diff(params.focus_region(3:4))*0.2;
    end
end

if isempty(params.frame_end),params.frame_end=hazard.event_count;end
n_frames=params.frame_end-params.frame_start+1;
eff_n_frames=max(ceil(n_frames/params.jump_step),1);

% define grid
params.npoints=abs(params.npoints); % force positive
xx=linspace(min(hazard.lon)-dX, max(hazard.lon)+dX, params.npoints);
yy=linspace(min(hazard.lat)-dY, max(hazard.lat)+dY, params.npoints);
[X,Y]=meshgrid(xx,yy); % construct regular grid
[~,unique_pos]=unique(hazard.lon*10000+hazard.lat); % avoid duplicate entries

% prepare asset scales
asset_values = hazard.assets.Value;
asset_values = log10(asset_values);
asset_values(isinf(asset_values)) = 0;
asset_values(isnan(asset_values)) = 0;

% prepare damage scales
max_damage_at_centroid=[]; % init
max_damage_absolute=full(max(max(hazard.damage)));

% prepare country border (for substantila speedup)
shapes=climada_shaperead(climada_global.map_border_file,1,1); % reads .mat
border.X=[];for i=1:length(shapes),border.X=[border.X shapes(i).X];end
border.Y=[];for i=1:length(shapes),border.Y=[border.Y shapes(i).Y];end

% Prepare the new file
if make_mp4
    vidObj = VideoWriter(params.animation_mp4_file,params.video_profile);
    open(vidObj);
end

t0=clock;
if params.jump_step==1
    fprintf('processing %i frames (frame %i .. %i)\n',n_frames,params.frame_start,params.frame_end);
else
    fprintf('processing approx. %i frames (frame %i:%i:%i)\n',eff_n_frames,params.frame_start,params.jump_step,params.frame_end);
end

hazard_lon_uni=hazard.lon(unique_pos);
hazard_lat_uni=hazard.lat(unique_pos);

% start loop
climada_progress2stdout(-1,[],1) % init, see terminate below
for frame_i=params.frame_start:params.jump_step:params.frame_end
    
    hold off;clf % start with blank plot each time
    
    % plot assets
    % -----------
    plotclr(hazard.assets.lon,hazard.assets.lat,asset_values,...
        's',params.asset_markersize,0,0,max(asset_values)*1.05,assets_cmap,1,0);
    hold on
    
    % plot hazard intensity
    % ---------------------
    int_values = full(hazard.intensity(frame_i,:));
    %int_values(int_values<10)=NaN; % mask low intensities
    gridded_VALUE = griddata(hazard_lon_uni,hazard_lat_uni,int_values(unique_pos),X,Y,interp_method);
    gridded_VALUE(gridded_VALUE==0)=NaN; % mask zeros
    % alternatively the next line (since MATLAB suggested)
    %F = scatteredInterpolant(hazard.lon(unique_pos)',hazard.lat(unique_pos)',int_values(unique_pos)');gridded_VALUE = F(X,Y);
    pcolor_handle = pcolor(X,Y,gridded_VALUE);
    colormap(hazard_cmap)
    
    if windfieldFaceAlpha>0,set(pcolor_handle,'FaceAlpha',windfieldFaceAlpha);end % set transparency of windfield
    
    % plot TC track
    % -------------
    if isfield(hazard,'tc_track') && params.plot_tc_track
        track_i=hazard.tc_track_number(frame_i);
        for track_ii=hazard.tc_track_number(params.frame_start):track_i-1 % all previous tracks
            plot(hazard.tc_track(track_ii).lon,hazard.tc_track(track_ii).lat,'.k','MarkerSize',params.plot_tc_track);
            plot(hazard.tc_track(track_ii).lon,hazard.tc_track(track_ii).lat,'-k','LineWidth',1)
        end % track_ii
        tc_track_lon=hazard.tc_track(track_i).lon(1:hazard.tc_track_node(frame_i));
        tc_track_lat=hazard.tc_track(track_i).lat(1:hazard.tc_track_node(frame_i));
        plot(tc_track_lon,tc_track_lat,'.k','MarkerSize',params.plot_tc_track);
        plot(tc_track_lon,tc_track_lat,'-k','LineWidth',1);
    end % plot TC track
    
    % set figure properties
    shading flat;
    caxis(c_ax);axis off
    plot(border.X,border.Y,'-k')
    axis equal;axis(params.focus_region);
    if ~params.schematic_tag,colorbar;end
    
    title_str='';
    if isfield(hazard,'tc_track') % add some track information
        if isfield(hazard,'event_name')
            title_str=char(hazard.event_name{frame_i});
        elseif isfield(hazard,'tc_track_node') % title
            track_i=hazard.tc_track_track(frame_i);
            node_i=hazard.tc_track_node(frame_i);
            title_str=sprintf('%s %s',strrep(char(hazard.tc_track(track_i).name),'_',' '),...
                datestr(hazard.tc_track(track_i).datenum(node_i),'dd-mmm-yyyy HH:MM'));
        end
    end
    
    % plot damage
    % -----------
    if isempty(max_damage_at_centroid)
        %max_damage_at_centroid=full(hazard.damage(frame_i,:));
        max_damage_at_centroid=full(sum(hazard.damage(1:frame_i,:)));
    else
        max_damage_at_centroid=max(max_damage_at_centroid,full(hazard.damage(frame_i,:)));
    end
    damage_values = max_damage_at_centroid;
    
    ok_points_pos=find(damage_values>1);
    
    if ~isempty(ok_points_pos)
        % show log of damage, since otherwise no spread...
        plotclr(hazard.assets.lon(ok_points_pos),hazard.assets.lat(ok_points_pos),log(damage_values(ok_points_pos)),...
            's',params.asset_markersize,0,0,log(max_damage_absolute*1.05),damage_cmap,1,0);
    end
   
    title(title_str,'FontSize',params.FontSize);
    % bottom_label_str=['color:' intensity_units ', damage: red circles (max ' max_damage_str ')'];
    % xlabel(bottom_label_str,'FontSize',9);
    
    if params.show_plots,drawnow;end
    
    if make_mp4
        currFrame   = getframe(fig_handle);
        writeVideo(vidObj,currFrame);
    end
    
    if eff_n_frames>500,mod_step=100;else mod_step=50;end
    if eff_n_frames<100,mod_step=20;end
    if eff_n_frames<50,mod_step=10;end
    if eff_n_frames<20,mod_step=5;end
    eff_frame_i=max(ceil((frame_i-params.frame_start)/params.jump_step),1);
    if eff_frame_i<10,mod_step=2;end
    climada_progress2stdout(eff_frame_i,eff_n_frames,mod_step,'frames'); % update
    
end % frame_i
climada_progress2stdout(0) % terminate
fprintf('animation generation took %2.1f sec\n',etime(clock,t0));

if make_mp4
    close(vidObj);
    fprintf('movie saved in %s\n', params.animation_mp4_file)
end

if ~params.show_plots,delete(fig_handle);end

end % climada_event_damage_animation