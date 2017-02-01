function [tc_track,info]=climada_tc_track_info(tc_track,check_plot,boundary_rect,centroids,manual_select)
% climada tc track info
% MODULE:
%   core
% NAME:
%   climada_tc_track_info
% PURPOSE:
%   Prints information of tracks to stdout (name, date....) and shows
%   (nice) plots of historic (and probabilistic) tracks
%
%   Prior call: climada_tc_read_unisys_tc_track, climada_tc_track_quality_check
%   Possible subsequent call: hold on;climada_entity_plot
% CALLING SEQUENCE:
%   [tc_track,info]=climada_tc_track_info(tc_track)
% EXAMPLE:~
%   [~,info]=climada_tc_track_info('tracks.she_hist.mat',2,[140 180 -40 -10]); % historic
%   [~,info]=climada_tc_track_info('tracks.she_prob.mat',1,[140 180 -40 -10]); % also probabilistic
% INPUTS:
%   tc_track: a tc_track structure, as returned by
%       climada_tc_read_unisys_database or climada_tc_read_unisys_tc_track
%       > promted for (.mat) if not given
%       If a .mat filename is passed, the content is loaded
% OPTIONAL INPUT PARAMETERS:
%   check_plot: if =1, show checkplot (default),
%       =0 no plot, no print to stdout
%       =-1: check plot and print info to stdout (can be long)
%       =-99: only print info to stdout (can be long)
%       =2: only check plot and only historic events (to create the e.g.
%       the slide to show hist/prob, see boundary_rect also)
%   boundary_rect: the boundary to plot [minlon maxlon minlat maxlat]
%       default is whole globe
%   centroids: a structure with centroids.lon, centroids.lat
%       if provided, only show tracks intersecting centroids
%   manual_select: if =1, alow for user to define point(s) on the map to
%       select tracks in vicinity (press enter after clicking on the map)
%       Best use is to define a 'gate', i.e. two points on the left and
%       right of the track to select.
% OUTPUTS:
%   tc_track: the tc_track structure, restricted to centroids, if passed
%       and cleaned up, if check_plot=-99. Otherwise same as input tc_track
%   info contains some information, but to stdout is main purpose of this
%       routine
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150118, initial
% David N. Bresch, david.bresch@gmail.com, 20160515, check_plot and boundary_rect added
% David N. Bresch, david.bresch@gmail.com, 20160528, centroids and manual_select added
% David N. Bresch, david.bresch@gmail.com, 20170125, climada_tc_track_quality_check
%-

info=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('tc_track','var'),tc_track=[];end
if ~exist('check_plot','var'),check_plot=[];end
if ~exist('boundary_rect','var'),boundary_rect=[];end
if ~exist('centroids','var'),centroids=[];end
if ~exist('manual_select','var'),manual_select=[];end

% PARAMETERS
%
% color of land
country_color=[.7 .7 .7]; % light gray
%
% border around the area shown if based on centroids
dlim=1; % in degrees
%
if isempty(check_plot),check_plot=1;end
if isempty(manual_select),manual_select=0;end

% prompt for tc_track
tc_track_filename='';
if isempty(tc_track) % local GUI
    tc_track_filename=[climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    [filename, pathname] = uigetfile(tc_track_filename, 'Select tc_track file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        tc_track_filename=fullfile(pathname,filename);
    end
elseif ~isstruct(tc_track)
    tc_track_filename=tc_track; % assume filename passed
end

if ~isempty(tc_track_filename)
    % complete path, if missing
    [fP,fN,fE]=fileparts(tc_track_filename);
    if isempty(fP),fP=[climada_global.data_dir filesep 'tc_tracks'];end
    if isempty(fE),fE='.mat';end
    tc_track_filename=[fP filesep fN fE];
    load(tc_track_filename)
end

if isempty(tc_track),tc_track=climada_tc_read_unisys_database;end % get tc_track

if ~isfield(tc_track,'category')
    tc_track=climada_tc_stormcategory(tc_track); % add storm category
end

tc_track_number=1:length(tc_track);

if ~isempty(centroids)
    % restrict to tracks intersecting centroids
    boundary_rect=[min(centroids.lon)-dlim max(centroids.lon)+dlim min(centroids.lat)-dlim max(centroids.lat)+dlim];
    XV=[min(centroids.lon) min(centroids.lon) max(centroids.lon) max(centroids.lon)];
    YV=[min(centroids.lat) max(centroids.lat) max(centroids.lat) min(centroids.lat)];
    tracks_selected=1:length(tc_track);
    for track_i=1:length(tc_track)
        if sum(inpolygon(tc_track(track_i).lon,tc_track(track_i).lat,XV,YV))==0
            tracks_selected(track_i)=0; % remove
        end
    end % track_i
    tc_track=tc_track(tracks_selected>0);
    tc_track_number=tc_track_number(tracks_selected>0);
end % ~isempty(centroids)

if check_plot<0
    
    fprintf('iiii: name          yyyymmdd  category\n'); % header
    
    info=cell(1,length(tc_track)); % allocate
    
    for track_i=1:length(tc_track)
        info{track_i}=sprintf('%4.4i: %s (%4.4i%2.2i%2.2i) %i',tc_track_number(track_i),...
            char(tc_track(track_i).name),...
            tc_track(track_i).yyyy(1),tc_track(track_i).mm(1),tc_track(track_i).dd(1),...
            max(tc_track(track_i).category));
        fprintf('%s\n',char(info{track_i}));
    end % track_i
    
    if check_plot==-99,check_plot=0;end
    
end % check_plot<0

min_yyyy=1e6;max_yyyy=-1e6;

if abs(check_plot)
    
    % plot land and ocean in light blue
    climada_plot_world_borders(-1,'','',0,[],country_color);
    hold on
    
    % fastest two loops, first ploting probabilsitic tracks, then historic
    fprintf('plotting %i tracks,',length(tc_track))
    if check_plot==1
        fprintf(' probabilistic ...')
        for track_i=1:length(tc_track)
            if tc_track(track_i).orig_event_flag==0
                color_cat=min(max(tc_track(track_i).category,0),5);
                plot(tc_track(track_i).lon,tc_track(track_i).lat,'Color',[0 0 color_cat/7+2/7]);
                hold on
            end % probabilistic
        end % track_i
    end
    fprintf(' historic ...')
    for track_i=1:length(tc_track)
        min_yyyy=min(min_yyyy,min(tc_track(track_i).yyyy));
        max_yyyy=max(max_yyyy,max(tc_track(track_i).yyyy));
        if tc_track(track_i).orig_event_flag==1
            color_cat=min(max(tc_track(track_i).category,0),5);
            plot(tc_track(track_i).lon,tc_track(track_i).lat,'Color',[color_cat/7+2/7 0 0]);
            hold on
        end % historic
    end % track_i
    fprintf(' done\n')
    axis equal
    if ~isempty(boundary_rect),xlim(boundary_rect(1:2));ylim(boundary_rect(3:4));end
    if ~isempty(centroids),plot(centroids.lon,centroids.lat,'.r','MarkerSize',1);end
    hold off; drawnow
    xlabel('blue: probabilistic, red: historic');
    title(sprintf('%4.4i .. %4.4i',min_yyyy,max_yyyy));
    
    if manual_select==1
        fprintf('select point(s) on the map using the mouse, then press enter/return\n')
        [x,y] = ginput;
        % restrict to tracks close the selected point(s)
        if length(x)==1,x(2)=x(1)+0.01;y(2)=y(1)+0.01;end
        hold on;plot(x,y,'or');
        XV=[min(x) min(x) max(x) max(x)];
        YV=[min(y) max(y) max(y) min(y)];
        tracks_selected=1:length(tc_track);
        for track_i=1:length(tc_track)
            if sum(inpolygon(tc_track(track_i).lon,tc_track(track_i).lat,XV,YV))==0
                tracks_selected(track_i)=0; % remove
            end
        end % track_i
        tc_track=tc_track(tracks_selected>0);
        tc_track_number=tc_track_number(tracks_selected>0);
        
        for track_i=1:length(tc_track)
            plot(tc_track(track_i).lon,tc_track(track_i).lat,'Color','g');
            track_info=sprintf('%4.4i: %s (%4.4i%2.2i%2.2i) %i',tc_track_number(track_i),...
                char(tc_track(track_i).name),...
                tc_track(track_i).yyyy(1),tc_track(track_i).mm(1),tc_track(track_i).dd(1),...
                max(tc_track(track_i).category));
            fprintf('%s\n',track_info);
        end % track_i
        hold off; drawnow
        
    end % manual_select
    
end % check_plot

end % climada_tc_track_info