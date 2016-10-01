function climada_tc_windfield_animation(tc_track,centroids,aggregation,check_avi)                                
% plot animation of windfield for a specific historical or
% probabilistic storm
% to find a specific windstorm use
% climada_plot_probabilistic_wind_speed_map
% NAME:
%   climada_tc_windfield_animation
% PURPOSE:
%   plot animation of windfield for a specific historical or
%   probabilistic storm, plot is produced every aggregation time step
%   (minimum 1 hour or more)
% CALLING SEQUENCE:
%   climada_tc_windfield_animation(tc_track       ,...
%                                  centroids      ,...
%                                  aggregation    ,...
%                                  check_printplot)
% EXAMPLE:
%   climada_tc_windfield_animation(tc_track_prob(1226), centroids, 1, 6)
% INPUTS:
%	tc_track:           just one tc_track, tc_track_prob(1)
%   centroids:          centroid mat file
% OPTIONAL INPUT PARAMETERS:
%   aggregation:        desired timestep for plots (minimum one plot per
%   hour, can be one plot for 6 hours or more)
%   check_avi:         if set to 1 will save animation as avi-file
% OUTPUTS:
%   plot of windfield (footprint) for every aggreagation step
%   (minimum 1 hour) for one specific storm track
% MODIFICATION HISTORY:
% Lea Mueller, 20110603
% David N. Bresch, david.bresch@gmail.com, 20150819, climada_global.centroids_dir
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables
if ~exist('tc_track'       ,'var'), tc_track        = []; end
if ~exist('centroids'      ,'var'), centroids       = []; end
if ~exist('aggregation'    ,'var'), aggregation     = []; end
if ~exist('check_avi'      ,'var'), check_avi       = []; end
if isempty(aggregation)           , aggregation     = 6 ; end

%% prompt for tc_track if not given
if isempty(tc_track)
    %load ([climada_global.data_dir
    %'\tc_tracks\tc_tracks_mozambique_1978_2011_southwestindian_cleaned_6h'])
    tc_track = [climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    [filename, pathname] = uigetfile(tc_track, 'Select PROBABILISTIC TC track set:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        tc_track = fullfile(pathname,filename);
    end
end
% load the tc track set, if a filename has been passed
if ~isstruct(tc_track)
    tc_track_file = tc_track;
    tc_track      = [];
    vars = whos('-file', tc_track_file);
    load(tc_track_file);
    if ~strcmp(vars.name,'tc_track')
        tc_track = eval(vars.name);
        clear (vars.name)
    end
    prompt   ='Type specific No. of track to print windfield [e.g. 1, 10, 34, 1011]:';
    name     =' No. of track';
    defaultanswer = {'1011'};
    answer = inputdlg(prompt,name,1,defaultanswer);
    track_no = str2num(answer{1});
    tc_track = tc_track(track_no);
end

%% prompt for centroids if not given
if isempty(centroids)
    centroids            = [climada_global.centroids_dir filesep '*.mat'];
    [filename, pathname] = uigetfile(centroids, 'Select centroids:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        centroids = fullfile(pathname,filename);
    end
end
% load the centroids, if a filename has been passed
if ~isstruct(centroids)
    centroids_file = centroids;
    centroids      = [];
    vars = whos('-file', centroids_file);
    load(centroids_file);
    if ~strcmp(vars.name,'centroids')
        centroids = eval(vars.name);
        clear (vars.name)
    end
end

%---------------------------
%% Calculations
%---------------------------
% wind field for every hour (for every node from tc_track)
% equal timestep within this routine
% [res min_node_pos dist_node] = climada_tc_windfield_timestep(tc_track,centroids,1); 

%equal 1h timestep
tc_track_1h  = climada_tc_equal_timestep(tc_track); 
a            = length(tc_track_1h.lon);
% and restructure to required time aggregation level
aggregation_count = floor(a/aggregation);
tc_track          = tc_track_1h;
tc_track.TimeStep = ones(1,aggregation_count)*aggregation;
tc_track.lon      = tc_track.lon(1:aggregation:end);
tc_track.lat      = tc_track.lat(1:aggregation:end);
tc_track.MaxSustainedWind = tc_track.MaxSustainedWind(1:aggregation:end);
tc_track.CentralPressure  = tc_track.CentralPressure(1:aggregation:end);
tc_track.yyyy             = tc_track.yyyy(1:aggregation:end);
tc_track.mm               = tc_track.mm(1:aggregation:end);
tc_track.dd               = tc_track.dd(1:aggregation:end);
tc_track.hh               = tc_track.hh(1:aggregation:end);
tc_track.datenum          = tc_track.datenum(1:aggregation:end);

fprintf('Calculating windfield for required timestep (takes some time with a lot of centroids)...')
equal_timestep = 0;
res  = climada_tc_windfield_timestep(tc_track,centroids,equal_timestep); 
res.gust_aggr = res.gust;
fprintf(' done.\n')
stormdate = tc_track.datenum(1);
stormname = tc_track.name;
stormname(stormname == '_') = ' ';


% aggregate wind field for specific hours (unit remains mm/s)
% [a b]             = size(res.gust);
% aggregation_count = floor(a/aggregation);
% if aggregation > 1
%     for i = 1:aggregation_count
%         res.gust_aggr(i,:) = mean(res.gust((i-1)*aggregation+1:i*aggregation,:));
%     end
% else
%     res.gust_aggr = res.gust;
% end


%---------------------------
%% FIGURE
%---------------------------
replay    = 1;

%scale figure according to range of longitude and latitude
scale  = max(centroids.lon) - min(centroids.lon);
scale2 =(max(centroids.lon) - min(centroids.lon))/...
        (min(max(centroids.lat),60)-max(min(centroids.lat),-50));
height = 0.5;
if height*scale2 > 1.2; height = 1.2/scale2; end
fig = climada_figuresize(height,height*scale2+0.15);
set(fig,'Color',[1 1 1])

%world border and tc_track
climada_plot_world_borders(0.7)
hold on
climada_plot_tc_track_stormcategory(tc_track);

% centroids
% plot(centroids.lon, centroids.lat, '+r','MarkerSize',0.8,'linewidth',0.1)
  
% scale for specific extract of world map
axis equal
axis([min(centroids.lon)-scale/30  max(centroids.lon)+scale/30 ...
      max(min(centroids.lat),-50)-scale/30  min(max(centroids.lat),60)+scale/30])
  
% colormap, constant color range
cmap_= [1.0000    1.0000    1.0000;
        0.8100    0.8100    0.8100;
        0.6300    0.6300    0.6300;
        1.0000    0.8000    0.2000;
        0.9420    0.6667    0.1600;
        0.8839    0.5333    0.1200;
        0.8259    0.4000    0.0800;
        0.7678    0.2667    0.0400;
        0.7098    0.1333         0];
    
colormap(cmap_)
% load ([climada_global.system_dir filesep 'colormap_gray_red_90'])
% colormap(gray_red)
max_wind = 90;
caxis([0 max_wind])
  
% colorbar
t = colorbar('YTick',[0:10:max_wind]);
% colorbartick           = [0:10:gridded_max_round round(gridded_max)];
% colorbarticklabel      = num2cell(colorbartick);
% colorbarticklabel{end} = [num2str(gridded_max,'%10.2f') 'max'];
% colorbarticklabel{end} = [int2str(gridded_max)          'max'];
% colorbar('YTick',colorbartick,'yticklabel',colorbarticklabel)
set(get(t,'ylabel'),'String', 'Wind speed (m s^{-1})','fontsize',8);
xlabel('Longitude','fontsize',8)
ylabel('Latitude','fontsize',8)

while replay == 1
    for agg_i = 1:aggregation_count
        [X, Y, gridded_VALUE] = climada_gridded_VALUE(full(res.gust_aggr(agg_i,:)), centroids);
        if sum(gridded_VALUE(:)>1)>0
            [c,h] = contourf(X, Y, full(gridded_VALUE),[0:10:max_wind],'linecolor','none');
            climada_plot_tc_track_stormcategory(tc_track);
            plot(centroids.lon(1), centroids.lat(1), '+r','MarkerSize',0.8,'linewidth',0.1)
            climada_plot_world_borders(0.7, '', '', 1)
            drawnow
            time_ = stormdate + (agg_i-1)*aggregation/24;
            title([stormname ', '  datestr(time_,'dd-mmm-yy HHh')],'fontsize',8)
            
            set(gca,'fontsize',8) 
            if check_avi
                F   = getframe(fig);
                mov = addframe(mov,F);
            else
                pause(0.002)    
            end
            %if agg_i<aggregation_count
                delete(h)
            %end        
        end
    end
    if check_avi
        mov = close(mov);
        check_avi = [];
    end

    %% relevant final foot print
    %  find maximum wind speed at every centroid
    c = max(res.gust)';
    [X, Y, gridded_VALUE] = climada_gridded_VALUE(full(c), centroids);
    if sum(gridded_VALUE(:)>1)>0
        [c, h]                = contourf(X, Y, full(gridded_VALUE),[0:10:max_wind],'linecolor','none');
        climada_plot_tc_track_stormcategory(tc_track);
    else
        time_ = stormdate;
    end
    plot(centroids.lon(1), centroids.lat(1), '+r','MarkerSize',0.8,'linewidth',0.1)
    climada_plot_world_borders(0.8, '', '', 1)
    title([stormname ', '  datestr(time_,'dd-mmm-yy HHh')])

    %% ask for replay
    if isempty(check_avi) || check_avi == 0 
        if sum(gridded_VALUE(:)>1)>0 
            choice = questdlg('Choose your next step?','Replay and or save as animation?','replay','save as animation.avi','exit','replay');
            switch choice
                case 'replay'
                    delete(h)
                    replay    = 1;
                    check_avi = [];
                case 'save as animation.avi'
                    delete(h)
                    check_avi = 1;
                    filename = [filesep 'results' filesep 'windfield_animation_' stormname '_' int2str(aggregation) 'h.avi'];
                    mov      = avifile([climada_global.data_dir filename],'compression','none','fps',2,'quality',100);
                    fprintf('movie saved in \n %s\n', filename)
                case 'exit'
                    %close
                    return
            end
        else
            return
        end
    else
        pause(2)    
        delete(h)
    end
end % replay == 1
    

return

% %% edit and save colormap
% colormapeditor
% %change node pointers, etc...
% gray_blue = get(gcf,'Colormap'); 
% save([climada_global.data_dir '\results\mozambique\colormap_gray_blue_rate'],'gray_blue')
