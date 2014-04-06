

function climada_plot_probabilistic_wind_speed_map(tc_track, track_req)


% plot historical tc track (Longitude, Latitude) in world map according to
% saffir-simpson hurrican scale. Add plot of probabilistic generated sister
% storms. Historical tracks has black lines around markers to identify as
% original track.
% NAME:
%   climada_plot_probabilistic_wind_speed_map
% PURPOSE:
%   analyse visuallly historical tc track and its generated probabilistic
%   sister storms. Check Longitude, Latitude and wind speed category
%   (saffir-simpson hurricane scale) 
% CALLING SEQUENCE:
%   climada_plot_probabilistic_wind_speed_map(tc_track)
% EXAMPLE:
%   climada_plot_probabilistic_wind_speed_map
% INPUTS:
%   tc_track: probabilistic tc track set (random walk of wind speed, 
%   longitude and latitude), wind speed in knots, nodes every six hours, if
%   not given, prompted for
% OPTIONAL INPUT PARAMETERS:
%   track_req:  number of specific historical track to be displayed with
%   its probabilistic sister storms, prompts for input 
%   p:          to print figure
%   x:          to exit
%   41:         or any other track number. will be rounded to the nearest 
%               historical track.
%   enter:      to continue.
% OUTPUTS:
%   figure, printout of figure if requested
% RESTRICTIONS:
% MODIFICATION HISTORY:
% Lea Mueller, 20110628
%-


global climada_global
if ~climada_init_vars, return; end
if ~exist('tc_track'  , 'var'), tc_track  = []; end
if ~exist('track_req' , 'var'), track_req = []; end

% if isempty(tc_track)
%     load ([climada_global.data_dir '\tc_tracks\tc_tracks_mozambique_1978_2011_southwestindian_prob_V_4480'])
%     tc_track = tc_track_prob; clear tc_track_prob
%     fprintf('\n***tc_track_prob loaded, 4480 tracks, south western Indian Ocean*** \n')                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
% end

% prompt for probabilistic tc_track if not given
if isempty(tc_track)
    %load ([climada_global.data_dir
    %'\tc_tracks\tc_tracks_mozambique_1978_2011_southwestindian_cleaned_6h'])
    tc_track = [climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    [filename, pathname] = uigetfile(tc_track, 'Select PROBABILISTIC tc track set:');
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
end

no_hist      = sum([tc_track.orig_event_flag]);
no_generated = length(tc_track)/no_hist;
ens_size     = no_generated-1;

%check if track_req is a historical track, round to nearest historial track
if track_req
    track_req = round((track_req-1)/(ens_size+1))*(ens_size+1)+1;
end

% longitude, latitude range
lon = [tc_track(:).lon];
lat = [tc_track(:).lat];

if min(lon)>0;    x_min   = ceil(min(lon)/10)*10;        else    x_min   = floor(min(lon)/10)*10;end
if max(lon)>0;    x_max   = ceil(max(lon)/10)*10;        else    x_max   = floor(max(lon)/10)*10;end

if min(lat)>0;    y_min   = ceil(min(lat)/10)*10;        else    y_min   = floor(min(lat)/10)*10;end
if max(lat)>0;    y_max   = ceil(max(lat)/10)*10; 
                  y_range = [y_min-10 min(y_max+10,80)]; else    y_max   = floor(max(lat)/10)*10;
                                                                 y_range = [y_min-10 max(y_max+10,-60)];end

x_range = [x_min-30 x_max+30];
%y_range = [y_min-10 min(y_max+10,80)];

scale  = max(lon)-min(lon);
scale2 =(max(lon)-min(lon))/(min(max(lat),60)-max(min(lat),-50));



%% analyze probabilistic wind speed, compare with random walk for coordinates

height = 0.5;
if height*scale2 > 1.2; height = 1.2/scale2; end
fig = climada_figuresize(height,height*scale2);

climada_plot_world_borders(0.7,'United States (USA)');
hold on
axis([min(lon)-scale/30  max(lon)+scale/30 ...
      max(min(lat),-50)-scale/30  min(max(lat),60)+scale/30])
axis equal
axis([min(lon)-scale/30  max(lon)+scale/30 ...
      max(min(lat),-50)-scale/30  min(max(lat),60)+scale/30])
xlabel('Longitude')
ylabel('Latitude')
track_count = length(tc_track);
for track_i = 1:ens_size+1:track_count
    if track_req
        track_i   = track_req;
        track_req = [];
    end
    h=[];
    for gen_i = 0:ens_size
        h(:,gen_i+1) = climada_plot_tc_track_stormcategory(tc_track(track_i+gen_i),8,[]);
    end
    %h(:,gen_i+1) = climada_plot_tc_track_stormcategory(tc_track(track_i),8,[]);
    %g           = plot(tc_track(track_i).lon,tc_track(track_i).lat,'.k','markersize',5);
    g            = plot(tc_track(track_i).lon,tc_track(track_i).lat,'ok','markersize',3,'linewidth',0.7);
    title(['Historical track ' int2str(track_i) ' and its ' [int2str(ens_size)] ' probabilistic sister storms'])
    
    %%add legend, makes it quite slow
    %climada_plot_tc_track_stormcategory(0,8,1);
    %pause
    print_reply = input('to print press p otherwise enter or choose a specific historical track No. \nTo end press x. [p, enter, 41, x]: ', 's');
    if str2double(print_reply)>0
        track_req = str2double(print_reply);
        %go to nearest historical track
        track_req = round((track_req-1)/(ens_size+1))*(ens_size+1)+1;
    elseif strcmp(print_reply,'p')
        filename = [filesep 'results' filesep 'tc_track_' int2str(track_i) '_prob.pdf'];
        print(fig,'-dpdf',[climada_global.data_dir filename])
        fprintf('figure saved in %s \n', filename) 
    elseif strcmp(print_reply,'x')
        close
        return
    end
    delete(h)
    delete(g)
end   