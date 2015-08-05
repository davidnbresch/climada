function res=climada_event_damage_animation(animation_data_file,animation_mp4_file,schematic_tag,show_plots,focus_region)
% climada template
% MODULE:
%   module name
% NAME:
%   climada_event_damage_animation
% PURPOSE:
%   Animation of event damage - as an .mp4 movie
%   This code does the visualization (rendering), see e.g.
%   climada_event_damage_data_tc to calculate all the data. As one often
%   needs to play with visualization parameters, the process is split.
%
%   An animation of the tropical cylclon track hitting the assets as
%   defined in entity
%
%   The code determines the plot area based on entity (but since there can be
%   more than one ocean basin's tracks hitting the centroids, the user has
%   to select the track file).
%
%   Note that this code does not (yet) run in Octave, as video support is
%   limited (see <http://octave.sf.net/video/>) and the present code uses
%   latest MATLAB videowriter (better performance than avifile...).
%
%   prior calls: climada_event_damage_data_tc or similar to prepare the
%   event damage information
% CALLING SEQUENCE:
%   res=climada_event_damage_animation(animation_data_file,animation_mp4_file)
% EXAMPLE:
%   res=climada_event_damage_animation; % prompt for
% INPUTS:
%   animation_data_file: the data file (.mat) with hazard set which
%       includes event damage information, see e.g. climada_event_damage_data_tc
%       > promted for if not given
%   animation_mp4_file: the filename of the resulting .mp4 movie
%       > promted for if not given (if cancel pressed, the movie frames are
%       not written to file - useful for test)
% OPTIONAL INPUT PARAMETERS:
%   schematic_tag: set to 1 if schematic plot (no colorbar, indicative
%       colorscale). if set to 0, e.g. tc wind color scale is yellow
%       (20-30 m/s), orange (30-40 m/s), dark orange (40-50 m/s), etc...
%   show_plots: =1, show single plots (frames) during animation creation,
%       =0 do not show (default)
%   focus_region: the region we're going to show [minlon maxlon minlat maxlat]
%       if empty, automatically determined by area of entity lat/lon, i.e.
%       hazard.assets.lat/lon
%       Default: use the region as stored in hazard.focus_region
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150118, initial
% David N. Bresch, david.bresch@gmail.com, 20150119, hazard translucent, entity blue, damage red
% Lea Mueller, muellele@gmail.com, 20150202, schematic tag, exponential circle size for assets
% David N. Bresch, david.bresch@gmail.com, 20150220, show_plots added
% David N. Bresch, david.bresch@gmail.com, 20150220, focus_region added
% David N. Bresch, david.bresch@gmail.com, 20150318, save as text debugged
% David N. Bresch, david.bresch@gmail.com, 20150804, switched from 'Uncompressed AVI' to 'MPEG-4' (no AVI coded on Mac)
%-

res=[]; % init output
close all % not really necessary, but speeds things up

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('animation_data_file','var'),animation_data_file = '';end
if ~exist('animation_mp4_file','var'), animation_mp4_file  = '';end
if ~exist('schematic_tag','var'),      schematic_tag       = [];end
if ~exist('show_plots','var'),         show_plots          =  0;end
if ~exist('focus_region','var'),       focus_region        = [];end
if isempty(schematic_tag), schematic_tag = 1; end

% PARAMETERS
%
% the scale for plots, such that max_damage=max(entity.assets.Value)*damage_scale
damage_scale=1/3; % defaul =1/2
%
% the rect to plot (default is are as in hazard.lon/lat, =[], in which case it is automatically determined)
focus_region = []; % default=[], [minlon maxlon minlat maxlat]
% for Salvador, lea, 20150220
% focus_region = [-91.5 -86 12 15.5];
%

% % load colormap
% colormap_file=[climada_global.data_dir filesep 'system' filesep 'colormap_gray_blue.mat'];
% if exist(colormap_file,'file'),load(colormap_file);end
%
% intensity plot parameters
npoints=199;
interp_method='linear';
%
% damage plot parameters
circle_diam=16; %5; % default=20
circle_format='or';
circle_linewidth=3;
asset_color  = [199 21 133 ]/255; %mediumvioletred
asset_color2 = [255 130 171]/255; %palevioletred 1
% asset_color = [255 97 3 ]/255; %cadmiumorange
% asset_color = [250 128 114 ]/255; %salmon

% the range (in degree) around the tc_track (to show a bit a wider area in plots)
%dX=1;dY=1; % default=1
dX=0;dY=0; % default=1
%
% TEST
%animation_data_file=[climada_global.data_dir filesep 'results' filesep 'animation_data.mat'];
%animation_mp4_file =[climada_global.data_dir filesep 'results' filesep 'animation_movie.mp4'];
%

% prompt for animation_data_file if not given
if isempty(animation_data_file) % local GUI
    animation_data_file=[climada_global.data_dir filesep 'results' filesep 'animation_data.mat'];
    [filename, pathname] = uigetfile(animation_data_file, 'Select animation data file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
        fprintf('Consider running climada_event_damage_data_tc to generate the animation data file\n');
    else
        animation_data_file=fullfile(pathname,filename);
    end
end

% prompt for animation_mp4_file if not given
make_mp4=1;
if isempty(animation_mp4_file) % local GUI
    %animation_mp4_file =[climada_global.data_dir filesep 'results' filesep 'animation_movie.avi'];
    animation_mp4_file =[climada_global.data_dir filesep 'results' filesep 'animation_movie.mp4'];
    [filename, pathname] = uiputfile(animation_mp4_file, 'Save animation as:');
    if isequal(filename,0) || isequal(pathname,0)
        make_mp4=0;
        animation_mp4_file='';
    else
        animation_mp4_file=fullfile(pathname,filename);
    end
end

load(animation_data_file);

if ~isempty(hazard_TS)
    fprintf('animation data also for TS\n');
    %hazard=hazard_TS;
end

if show_plots,fig_visible='on';else fig_visible='off';end
fig_handle = figure('Name','animation','visible',fig_visible,'Color',[1 1 1],'Position',[430 20 920 650]);

c_ax = []; %init
if schematic_tag
    % create schematic colormap (gray red)
    [cmap,c_ax]= climada_colormap('schematic');
    %if exist([climada_global.system_dir filesep 'colormap_gray_red.mat'],'file')
        %load([climada_global.system_dir filesep 'colormap_gray_red'])
        %cmap = gray_red;
        %%colormap(cmap)        
    %end
else
    % color range for hazard intensity
    [cmap,c_ax]= climada_colormap(hazard.peril_ID);
    cmap = brighten(cmap,0.2);
end
if isempty (c_ax)
    c_ax = [0 full(max(max(hazard.intensity)))];
end

intensity_units=[char(hazard.peril_ID) ' intensity'];
if isfield(hazard,'units'),intensity_units=[intensity_units ' [' hazard.units ']'];end

if isempty(focus_region) % define the focus region based on entity
    if isfield(hazard,'focus_region')
        focus_region=hazard.focus_region;
    else
        focus_region(1)=min(hazard.assets.lon)-dX;
        focus_region(2)=max(hazard.assets.lon)+dX;
        focus_region(3)=min(hazard.assets.lat)-dY;
        focus_region(4)=max(hazard.assets.lat)+dY;
        focus_region(4)=focus_region(4) + diff(focus_region(3:4))*0.2;
    end
end

n_steps=hazard.event_count;

t0       = clock;
msgstr   = sprintf('processing %i steps',n_steps);
mod_step = 2; % first time estimate after 10 events, then every 100
fprintf('%s\n',msgstr);
format_str='%s';

% define grid
npoints=abs(npoints); % force positive
xx=linspace(min(hazard.lon)-dX, max(hazard.lon)+dX, npoints);
yy=linspace(min(hazard.lat)-dY, max(hazard.lat)+dY, npoints);
[X,Y]=meshgrid(xx,yy); % construct regular grid

damage_min_value=full(min(min(hazard.damage(hazard.damage>0))));
damage_max_value=full(max(max(hazard.damage)))*damage_scale;
max_damage_str=sprintf('%g',damage_max_value);

% Prepare the new file
if make_mp4
    %mov = avifile(animation_mp4_file,'compression','none','fps',2,'quality',100);end
    %vidObj = VideoWriter(animation_mp4_file,'Uncompressed AVI'); % 'Archival', 'Indexed AVI'
    vidObj = VideoWriter(animation_mp4_file,'MPEG-4');
    open(vidObj);
end

max_damage_at_centroid=[]; % init

% start loop    
for step_i=1:n_steps
    
    hold off

    % prepare legend entries
    h = [];
    h(1) = plot(1,1,'ob','MarkerSize',circle_diam-2,'LineWidth',circle_linewidth-1);
    hold on
    h(2) = plot(1,2,'o','MarkerSize',circle_diam-2,'LineWidth',2,...
        'markeredgecolor',asset_color,'markerfacecolor',asset_color2);
    legend(h,'Asset value (relative to circle size)','Damaged asset','location','northeast');
    %legend('boxoff')

    % plot assets
    % -----------  
    asset_values = hazard.assets.Value;
    values       = log10(asset_values);
    values(isinf(values)) = 0;
    values(isnan(values)) = 0;
    min_value = min(values(values>0));
    max_value = max(values);
    diam_ = [1:1:circle_diam];
    MarkerSizes = interp1(linspace(min_value, max_value,numel(diam_)),[1:1:circle_diam],values,'linear');
    %MarkerSizes=(abs(values-min_value))/(max_value-min_value)*circle_diam;    
    MarkerSizes(isnan(MarkerSizes))=0;
    MarkerSizes(MarkerSizes<1)=0;
    ok_points_pos = find(MarkerSizes>0);
    for ii=1:length(ok_points_pos)
        i = ok_points_pos(ii);
        plot(hazard.assets.lon(i),hazard.assets.lat(i),'ob','MarkerSize',...
            MarkerSizes(i),'LineWidth',1);hold on;
    end

    % plot hazard intensity
    % ---------------------
    int_values = full(hazard.intensity(step_i,:));
    %int_values(int_values<10)=NaN; % mask low intensities
    gridded_VALUE = griddata(hazard.lon,hazard.lat,int_values,X,Y,interp_method); % interpolate to grid 'linear'
    pcolor(X,Y,gridded_VALUE);
    %p = pcolor(X,Y,gridded_VALUE);
    colormap(cmap)
    
    
    % set figure properties
    hold on;shading flat;axis equal
    caxis(c_ax);axis off
    climada_plot_world_borders(1);
    axis(focus_region);
    if ~schematic_tag
        colorbar;
    end

    if isfield(hazard,'tc_track') % add some track information
        if isfield(hazard,'tc_track_node') % title
            node_i=hazard.tc_track_node(step_i);
            title_str=sprintf('%s %s',strrep(char(hazard.tc_track.name),'_',' '),datestr(hazard.tc_track.datenum(node_i),'dd-mmm-yyyy HH:MM'));
            %plot(hazard.tc_track.lon(1:node_i),hazard.tc_track.lat(1:node_i),'-b','LineWidth',2);
        else
            title_str=sprintf('%s',strrep(char(hazard.tc_track.name),'_',' '));
        end
    end

    
    % plot damage
    % -----------
    %values = hazard.assets.Value;
    if isempty(max_damage_at_centroid)
        max_damage_at_centroid=full(hazard.damage(step_i,:));
    else
        max_damage_at_centroid=max(max_damage_at_centroid,full(hazard.damage(step_i,:)));
    end
    damage_values = max_damage_at_centroid;
    damage_values = damage_values(hazard.assets.centroid_index);
    %------- for Salvador, lea, 20150220
    damage_values = damage_values/100;
    %damage_values(damage_values<1000) = 0;
    %-------------------
    
    %MarkerSizes=sqrt(abs(values-damage_min_value))/sqrt(damage_max_value-damage_min_value)*circle_diam;
    %MarkerSizes=sqrt(abs(values-min_value))/sqrt(max_value-min_value)*circle_diam;
    %MarkerSizes=(abs(values-min_value))/(max_value-min_value)*circle_diam;    
    %MarkerSizes(isnan(MarkerSizes))=0;
    %MarkerSizes(MarkerSizes<1)=0;
    % Salvador
    ok_points_pos= find(MarkerSizes>1 & damage_values>10);
    
    %ok_points_pos= find(MarkerSizes>0 & damage_values>0);
    for ii=1:length(ok_points_pos)
        i=ok_points_pos(ii);
        plot(hazard.assets.lon(i),hazard.assets.lat(i),circle_format,'MarkerSize',MarkerSizes(i)-1,...
            'LineWidth',1,'markeredgecolor',asset_color,'markerfacecolor',asset_color2);
        
        %plot(hazard.assets.lon(i),hazard.assets.lat(i),circle_format,'MarkerSize',MarkerSizes(i),...
        %    'LineWidth',2,'markeredgecolor',asset_color,'markerfacecolor',asset_color2);
        
        %plot(hazard.lon(i),hazard.lat(i),circle_format,'MarkerSize',...
        %    MarkerSizes(i),'LineWidth',circle_linewidth,'markerfacecolor','r');
    end
    
    title(title_str,'FontSize',9);
    % bottom_label_str=['color:' intensity_units ', damage: red circles (max ' max_damage_str ')'];
    % xlabel(bottom_label_str,'FontSize',9);
    
    %drawnow
        
    if make_mp4
        %currFrame   = getframe(gcf);
        currFrame   = getframe(fig_handle);
        %%mov = addframe(mov,currFrame);
        writeVideo(vidObj,currFrame);
        %currFrame   = getframe(fig);
        %writeVideo(vidObj,fig);
        %mov = addframe(mov,fig);
    end
    
    % the progress management
    if mod(step_i,mod_step)==0
        mod_step          = 10;
        t_elapsed_event   = etime(clock,t0)/step_i;
        steps_remaining  = n_steps-step_i;
        t_projected_sec   = t_elapsed_event*steps_remaining;
        msgstr = sprintf('est. %3.0f sec left (%i/%i events)',t_projected_sec,   step_i,n_steps);
        fprintf(format_str,msgstr); % write progress to stdout
        format_str=[repmat('\b',1,length(msgstr)) '%s']; % back to begin of line
    end
    
end % step_i
fprintf(format_str,''); % move carriage to begin of line

if make_mp4
    %mov = close(mov);
    close(vidObj);
    fprintf('movie saved in %s\n', animation_mp4_file)
end

if ~show_plots,delete(fig_handle);end

end % climada_event_damage_animation