function res=climada_event_damage_animation(animation_data_file,animation_avi_file)
% climada template
% MODULE:
%   module name
% NAME:
%   climada_event_damage_animation
% PURPOSE:
%   Animation of event damage - as an .avi movie
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
%   res=climada_event_damage_animation(animation_data_file,animation_avi_file)
% EXAMPLE:
%   res=climada_event_damage_animation; % prompt for
% INPUTS:
%   animation_data_file: the data file (.mat) with hazard set which
%       includes event damage information, see e.g. climada_event_damage_data_tc
%       > promted for if not given
%   animation_avi_file: the filename of the resulting .avi movie
%       > promted for if not given (if cancel pressed, the movie frames are
%       not written to file - useful for test)
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150118, initial
% David N. Bresch, david.bresch@gmail.com, 20150119, hazard translucent, entity blue, damage red
%-

res=[]; % init output
close all % not really necessary, but speeds things up

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('animation_data_file','var'),animation_data_file='';end
if ~exist('animation_avi_file','var'),animation_avi_file  ='';end


% PARAMETERS
%
% the scale for plots, such that max_damage=max(entity.assets.Value)*damage_scale
damage_scale=1/3; % defaul =1/2
%
% the rect to plot (default is are as in hazard.lon/lat, =[], in which case it is automatically determined)
focus_region=[]; % default=[], [minlon maxlon minlat maxlat]
%
% load colormap
colormap_file=[climada_global.data_dir filesep 'system' filesep 'colormap_gray_blue.mat'];
if exist(colormap_file,'file'),load(colormap_file);end
%
% intensity plot parameters
npoints=199;
interp_method='linear';
%
% damage plot parameters
circle_diam=5; % default=20
circle_format='or';
circle_linewidth=3;
%
% the range (in degree) around the tc_track (to show a bit a wider area in plots)
%dX=1;dY=1; % default=1
dX=0;dY=0; % default=1
%
% TEST
%animation_data_file=[climada_global.data_dir filesep 'results' filesep 'animation_data.mat'];
%animation_avi_file =[climada_global.data_dir filesep 'results' filesep 'animation_movie.avi'];
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

% prompt for animation_avi_file if not given
make_avi=1;
if isempty(animation_avi_file) % local GUI
    animation_avi_file =[climada_global.data_dir filesep 'results' filesep 'animation_movie.avi'];
    [filename, pathname] = uiputfile(animation_avi_file, 'Select animation data file:');
    if isequal(filename,0) || isequal(pathname,0)
        make_avi=0;
        animation_avi_file='';
    else
        animation_avi_file=fullfile(pathname,filename);
    end
end

load(animation_data_file);

if ~isempty(hazard_TS)
    fprintf('animation data also for TS\n');
    %hazard=hazard_TS;
end

% color range for hazard intensity
[cmap c_ax]= climada_colormap(hazard.peril_ID);
cmap = brighten(cmap,0.5);
if isempty (c_ax)
    c_ax = [0 full(max(max(hazard.intensity)))];
end
    
intensity_units=[char(hazard.peril_ID) ' intensity'];
if isfield(hazard,'units'),intensity_units=[intensity_units ' [' hazard.units ']'];end

if isempty(focus_region) % define the focus region based on entity
    focus_region(1)=min(hazard.assets.Longitude)-dX;
    focus_region(2)=max(hazard.assets.Longitude)+dX;
    focus_region(3)=min(hazard.assets.Latitude)-dY;
    focus_region(4)=max(hazard.assets.Latitude)+dY;
end

n_steps=hazard.event_count;

% template for-loop with waitbar or progress to stdout
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
if make_avi
    %mov = avifile(animation_avi_file,'compression','none','fps',2,'quality',100);end
    vidObj = VideoWriter(animation_avi_file,'Uncompressed AVI'); % 'Archival', 'Indexed AVI'
    open(vidObj);
end

max_damage_at_centroid=[]; % init
for step_i=1:n_steps
    
    hold off
    
    % plot assets
    % -----------
    values=hazard.assets.Value;
    min_value=min(values(values>0));
    max_value=max(values);
    MarkerSizes=(abs(values-min_value))/(max_value-min_value)*circle_diam;    
    MarkerSizes(isnan(MarkerSizes))=0;
    MarkerSizes(MarkerSizes<1)=0;
    ok_points_pos=find(MarkerSizes>0);
    for ii=1:length(ok_points_pos)
        i=ok_points_pos(ii);
        plot(hazard.assets.Longitude(i),hazard.assets.Latitude(i),'ob','MarkerSize',...
            MarkerSizes(i),'LineWidth',1);hold on;
    end
        
    % plot hazard intensity
    % ---------------------
    values=full(hazard.intensity(step_i,:));
    values(values<10)=NaN; % mask low intensities
    
    gridded_VALUE=griddata(hazard.lon,hazard.lat,values,X,Y,interp_method); % interpolate to grid 'linear'
    pcolor(X,Y,gridded_VALUE);
    colormap(cmap)
    hold on;shading flat;axis equal
    caxis(c_ax);axis off
    climada_plot_world_borders(1);
    axis(focus_region);
    colorbar;
    
    if isfield(hazard,'tc_track') % add some track information
        if isfield(hazard,'tc_track_node') % title
            node_i=hazard.tc_track_node(step_i);
            title_str=sprintf('%s %s',strrep(char(hazard.tc_track.name),'_',' '),datestr(hazard.tc_track.datenum(node_i),0));
%             plot(hazard.tc_track.lon(1:node_i),hazard.tc_track.lat(1:node_i),'-b','LineWidth',2);
        else
            title_str=sprintf('%s',strrep(char(hazard.tc_track.name),'_',' '));
        end
    end
    
    % plot damage
    % -----------
    if isempty(max_damage_at_centroid)
        max_damage_at_centroid=full(hazard.damage(step_i,:));
    else
        max_damage_at_centroid=max(max_damage_at_centroid,full(hazard.damage(step_i,:)));
    end
    values=max_damage_at_centroid;
    
    MarkerSizes=sqrt(abs(values-damage_min_value))/sqrt(damage_max_value-damage_min_value)*circle_diam;
    MarkerSizes(isnan(MarkerSizes))=0;
    MarkerSizes(MarkerSizes<1)=0;
    ok_points_pos=find(MarkerSizes>0);
    for ii=1:length(ok_points_pos)
        i=ok_points_pos(ii);
        plot(hazard.lon(i),hazard.lat(i),circle_format,'MarkerSize',...
            MarkerSizes(i),'LineWidth',circle_linewidth);
    end
    
    bottom_label_str=['color:' intensity_units ', damage: red circles (max ' max_damage_str ')'];
    title(title_str,'FontSize',9);
    xlabel(bottom_label_str,'FontSize',9);
    
    drawnow
    
    if make_avi
        currFrame   = getframe(gcf);
        %mov = addframe(mov,currFrame);
        writeVideo(vidObj,currFrame);
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

if make_avi
    %mov = close(mov);
    close(vidObj);
    fprintf('movie saved in %s\n', animation_avi_file)
end

end % climada_event_damage_animation