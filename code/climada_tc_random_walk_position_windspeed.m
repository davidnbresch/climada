function tc_track_prob = climada_tc_random_walk_position_windspeed(tc_track , tc_track_save, ens_size, ens_amp, Maxangle,...
    check_plot, check_printplot)

% TC event set with probabilistic longitude, latitude and wind speed based
% on random walk
% NAME:
%   climada_tc_random_walk_position_windspeed
% PURPOSE:
%   given a tc_track structure, create ens_size WIND SPEED varied derived tracks based on
%   directed random walk
%   and generates ens_size LONGITUDE, LATITUDE varied based on directed
%   random walk
%   PARAMETERS for wind speed: distribution of initial wind speed v0 and
%   distribution of change in wind speed vi (mu and sigma) obtained by
%   function: [mu, sigma, A]   = climada_distribution_v0_vi('all');
%   PARAMETERS for longitude, latitude:
%   ens_amp0, ens_amp, Maxangle, etc.
%   previous step:  see climada_tc_read_unisys_database
%   next step:      see climada_tc_hazard_set
% CALLING SEQUENCE:
%   tc_track_prob = climada_tc_random_walk_position_windspeed(tc_track,
%   'tc_track_prob',
%   ens_size, ens_amp, Maxangle, check_plot, check_printplot);
% EXAMPLE:
%   tc_track_prob = climada_tc_random_walk_position_windspeed;
% INPUTS:
%   none, if tc_track empty prompted for
% OPTIONAL INPUT PARAMETERS:
%   tc_track: a structure with the track information for each cyclone i at
%       each node j, see climada_read_unisys_database for a detailed
%       description, wind speed in knots, nodes every six hours
%   ens_size: create ens_size varied derived tracks, default 9
% OUTPUTS:
%   same structure now including the ens_size times number of tracks
%   all the info from the original tracks is copied, only the WIND SPEED
%   differs
%   field category and season is added
% RESTRICTIONS:
% MODIFICATION HISTORY:
% Lea Mueller, 20110616
%-

% init global variables
global climada_global
if ~climada_init_vars, return; end

% check inputs, and set default values
if ~exist('tc_track'       , 'var'), tc_track      = []  ; end
if ~exist('tc_track_save'  , 'var'), tc_track_save = []  ; end
if ~exist('ens_size'       , 'var'), ens_size      = 9   ; end
if isempty(ens_size)               , ens_size      = 9   ; end

%amplitude of random walk wiggles in degree longitude for 'directed'
if ~exist('ens_amp'        , 'var'), ens_amp  = 0.2; end % .35; end
if isempty(ens_amp)                , ens_amp  = 0.2; end % .35; end

% maximum angle of variation, =pi is like undirected, pi/4 means one
% quadrant
if ~exist('Maxangle'       , 'var'), Maxangle = pi/4; end %pi/7; end
if isempty(Maxangle)               , Maxangle = pi/4; end %pi/7; end

if ~exist('check_plot'     , 'var'), check_plot      = 1  ; end
if ~exist('check_printplot', 'var'), check_printplot = 0  ; end

% prompt for tc_track if not given
if isempty(tc_track)
    tc_track             = [climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    tc_track_default     = [climada_global.data_dir filesep 'tc_tracks' filesep 'Select HISTORICAL tc track .mat'];
    [filename, pathname] = uigetfile(tc_track, 'Select HISTORICAL tc track:',tc_track_default);
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
    load(tc_track_file);
end

%% add season to historical tc tracks (field tc_track.season)
if ~isfield(tc_track,'season')
    [tc_track, seasons] = climada_tc_season(tc_track);
    fprintf('season to every tc track added \n')
end


%% WIND SPEED
%  compute mu and sigma (fitted normal distribution) in knots
[mu, sigma]         = climada_distribution_v0_vi(tc_track,'kn',0);

%  enhance variation of change in wind speed
% sigma(2)       = sigma(2) *enhance_sigma;
% if enhance_sigma>1
%     fprintf('------------------ \n');
%     fprintf('sigma of change in wind speed (kn) ENHANCED by factor %10.1f \n', enhance_sigma);
%     fprintf('new sigma = %10.2f \n', sigma(2));
%     fprintf('------------------ \n');
% end

track_count   = length(tc_track);
track_counter = 0;


%% COORDINATES
%  ensemble generation parameters
%  amplitude of max random starting point shift degree longitude
ens_amp0      = 0.5; %1.5;
% maximum latitudinal distance between consequent data points. if this
% distance is larger than max_lat_dist, the storm is not
% used (kind of second data cleaning)
max_lat_dist  = 10;


mu_v     = 0;
sigma_v  = 1;


fprintf('adding %i derived tracks to %i original storms \n', ens_size, track_count);
if climada_global.waitbar,h  = waitbar(0,'Processing ...');end
t0 = clock;

randn('seed',0)
rand ('seed',0)

% loop over all original tracks
for track_i = 1:track_count
    
    % update waitbar
    if climada_global.waitbar,waitbar(track_i/track_count,h);end
    track_counter = track_counter+1;
    nodes_count   = length(tc_track(track_i).MaxSustainedWind);
    
    %% WIND SPEED
    % generate probabilistic initial wind speed for ens_size probabilistic
    % tracks
    % v0 = tc_track(track_i).MaxSustainedWind(1) + sigma(1).*randn(ens_size, 1);
    % generate probabilistic change in wind speed for every node)
    %vi = mu(2) + sigma(2) .* randn(ens_size,nodes_count);
    vi  = mu_v  + sigma_v  .* randn(ens_size,nodes_count);
    % add up probabilistic changes in wind speed
    vi_cum   = cumsum(vi,2);
    %figure
    %plot(vi_cum')
    
    %% COORDINATES
    % generate random starting points for ensemble members: +- 0.75. mean 0
    % rand    : uniformly distributed random numbers between 0 and 1
    % rand-0.5: uniformly distributed random numbers between +- 0.5
    % x0, y0  : uniformly distributed random numbers between +- 0.5*1.5, +- 0.75
    x0 = ens_amp0 *( rand(ens_size,1)-0.5);
    y0 = ens_amp0 *( rand(ens_size,1)-0.5);
    
    % directed random walk (summed in dimension 2), how much differ the
    % derived from the original
    % uniformly distributed random numbers between +- Maxangle, mean 0
    x = 2*Maxangle*rand(ens_size,nodes_count) - Maxangle;
    y = 2*Maxangle*rand(ens_size,nodes_count) - Maxangle;
    % cumulate (cumsum in dimension 2)
    x = cumsum(x,2);
    y = cumsum(y,2);
    % apply sinus for x and y! (instead of cosinus for y)
    x = sin(x);
    y = sin(y);
    % multiply with amplitude of ensemble 0.35 and cumulated (in dimension
    % 2)
    x = cumsum( ens_amp * x, 2);
    y = cumsum( ens_amp * y, 2);
    
    % figure
    % plot(x','b')
    % hold on
    % plot(y','r')
    %all in one
    %x = cumsum( ens_amp *sin( cumsum( 2*Maxangle*rand(ens_size,nodes_count) - Maxangle, 2)  ),2);
    %y = cumsum( ens_amp *sin( cumsum( 2*Maxangle*rand(ens_size,nodes_count) - Maxangle, 2)  ),2);
    
    % add all the other vectors and arrays (copy)
    tc_track_prob(track_counter) = tc_track(track_i);
    
    %v_cum_ = bsxfun(@plus, vi_cum, tc_track(track_i).MaxSustainedWind);
    %v_cum_ = round(v_cum_ /5)*5;
    %figure
    %plot(tc_track(track_i).MaxSustainedWind,'ok-')
    %hold on
    %plot(v_cum_','b.-')
    %plot(v_cum_','b.')
    %v    = tc_track(track_i).MaxSustainedWind    + vi_cum(ens_i,:);
    % round to 5 kn
    %v    = round(v /5)*5;
    
    
    for ens_i = 1:ens_size
        track_counter = track_counter+1;
        % first copy from original historical track and then change wind
        % speed, longitude and latitude
        tc_track_prob(track_counter) = tc_track(track_i);
        
        %% WIND SPEED
        % sort so that first all positive changes, then all negative or
        % equal changes in wind speed
        %pos          = vi(ens_i,:) >  0;
        %neg          = vi(ens_i,:) <= 0;
        %vi_sort      = [vi(ens_i,pos) vi(ens_i,neg)];
        % % plot(vi_sort,'*r')
        % % plot(cumsum(vi(1,:)),'*-b')
        % % hold on
        % % plot(cumsum(vi_sort),'*-r')
        % sum up initial wind speed and following changes in wind speed
        %v   = v0(track_i) + vi_cum;
        %v   = tc_track(track_i).MaxSustainedWind(1) + vi_cum;
        v    = tc_track(track_i).MaxSustainedWind    + vi_cum(ens_i,:);
        % round to 5 kn
        %v    = round(v /5)*5;
        % plot for check
        % % track_i
        % % plot(v)
        % % hold on
        % % plot(v_,'k')
        % % plot(tc_track(track_i).MaxSustainedWind,'-r')
        % % xlim([0 nodes_count+1])
        % % ylim([0 130])
        % add probabilistic wind speed
        %tc_track_prob(track_counter).MaxSustainedWind = v;
        tc_track_prob(track_counter).MaxSustainedWind = tc_track(track_i).MaxSustainedWind;
        
        %% COORDINATES
        % add change in coordinates to the different starting points
        x_cum = x(ens_i,:)- x(ens_i,1) + x0(ens_i);
        y_cum = y(ens_i,:)- y(ens_i,1) + y0(ens_i);
        
        % fill in the derived track: add dlon/dlat
        tc_track_prob(track_counter).lon = tc_track(track_i).lon + x_cum;
        tc_track_prob(track_counter).lat = tc_track(track_i).lat + y_cum;
        % add probabilistic event flag
        tc_track_prob(track_counter).orig_event_flag = 0;
        % add probabilistic season
        tc_track_prob(track_counter).season          = tc_track(track_i).season*(ens_size+1) + ens_i;
        % new names: first derived ..._gen1
        tc_track_prob(track_counter).name            = [deblank(tc_track(track_i).name) '_gen' int2str(ens_i)];
        % new ID_no are decimals for derived tracks
        tc_track_prob(track_counter).ID_no           = tc_track(track_i).ID_no+ens_i/100;
    end
    %close
end
if climada_global.waitbar,close(h);end % dispose waitbar


%% decay of wind speed over land
% fprintf('probabilistic tc tracks decay in wind speed over land\n');
p_rel      = [];
tc_track_prob = climada_tc_track_wind_decay(tc_track_prob, p_rel, check_plot);

for t_i = 1:length(tc_track_prob)
    if isnan(tc_track_prob(t_i).MaxSustainedWind)
        fprintf('Not a number in wind speeds (tc_track %d)\n', t_i)
        tc_track_prob = [];
        return
    end
end


%% add category for each track
tc_track_prob = climada_tc_stormcategory(tc_track_prob);

t_elapsed     = etime(clock,t0);
fprintf('generating %i derived storms took %3.1f sec (%3.1f sec/track)\n',(ens_size+1)*track_count,t_elapsed,t_elapsed/ens_size);

tc_track = tc_track_prob;

if check_plot
    fprintf('preparing check plot ...\n');
    
    %set scale for figuresize
    max_lon = max([tc_track(:).lon]);
    min_lon = min([tc_track(:).lon]);
    max_lat = max([tc_track(:).lat]);
    min_lat = min([tc_track(:).lat]);
    scale   = max_lon - min_lon;
    %scale2  =(max_lon - min_lon)/...
    %         (min(max_lat,60) - max(min_lat,-50));
    scale2  =(max_lon - min_lon)/...
        (max_lat - min_lat);
    height = 0.5;
    if height*scale2 > 1.2; height = 1.2/scale2; end
    
    fig = climada_figuresize(height,height*scale2+0.15);
    climada_plot_world_borders(0.7,'United States (USA)');
    set(0, 'defaultlinelinewidth' ,0.5)
    hold on
    for track_i = 1:ens_size+1:length(tc_track)
        for ens_i = 1:ens_size
            h = plot(tc_track(track_i+ens_i).lon, tc_track(track_i+ens_i).lat,'-b');
        end
    end
    for track_i = 1:ens_size+1:length(tc_track)
        g = plot(tc_track(track_i).lon, tc_track(track_i).lat,'-r');
    end
    xlabel('Longitude')
    ylabel('Latitude')
    
    axis equal
    axis([min_lon-scale/30  max_lon+scale/30 ...
        min_lat-scale/30  max_lat+scale/30])
    %axis([min_lon-scale/30  max_lon+scale/30 ...
    %      max(min_lat,-50)-scale/30  min(max_lat,60)+scale/30])
    set(gca,'layer','top')
    titlestr = sprintf('%d original tracks (%d - %d), %d probabilistic tracks\n%s',...
        sum([tc_track(:).orig_event_flag]), tc_track(1).yyyy(1), tc_track(end).yyyy(end),...
        length(tc_track)-sum([tc_track(:).orig_event_flag]), strrep(tc_track_save,'_',' '));
    title(titlestr)
    
    legend([g h],'Original tracks','Derived tracks')
    if check_printplot
        %foldername  = ['\results\mozambique\tc_tracks\tracks_prob_' int2str((ens_size+1)*track_count) '.pdf'];
        foldername  = ['\results\tracks_prob_' int2str((ens_size+1)*track_count) '.pdf'];
        print(fig,'-dpdf',[climada_global.data_dir foldername])
        fprintf('FIGURE saved in folder %s \n', foldername);
    end
end

% % prompt for tc_track_save if not given
% if isempty(tc_track_save) % local GUI
%     tc_track_save = [climada_global.data_dir filesep 'tc_tracks' filesep 'Select name to save probabilistic tc_track_XXXX.mat'];
%     [filename, pathname] = uiputfile(tc_track_save, 'Save probabilistic tc track set as:');
%     if isequal(filename,0) || isequal(pathname,0)
%         return; % cancel
%     else
%         tc_track_save = filename;
%     end
% end

% fprintf('saving probabilistic tc track set as %s\n',tc_track_save);
% save([climada_global.data_dir filesep 'tc_tracks' filesep tc_track_save],'tc_track')


return