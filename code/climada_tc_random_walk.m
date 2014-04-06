function tc_track_out=climada_tc_random_walk(tc_track,ens_size,ens_amp,Maxangle,check_plot)
% TC event set random walk probabilistic
% NAME:
%   climada_tc_random_walk
% PURPOSE:
%   given a tc_track structure, create ens_size varied derived tracks based on
%   directed random walk
%
%   NOTE see PARAMETER section to change parameters
%   (e.g. ens_amp0,ens_amp,Maxangle)
%
%   previous step: see climada_tc_read_unisys_database
%   next step: see climada_tc_hazard_set
% CALLING SEQUENCE:
%   tc_track=climada_tc_random_walk(tc_track,ens_size);
% EXAMPLE:
%   tc_track=climada_read_unisys_database;
%   tc_track=climada_tc_random_walk(tc_track);
% INPUTS:
%   tc_track: a structure with the track information for each cyclone i at
%       each node j, see climada_read_unisys_database for a detailed
%       description
% OPTIONAL INPUT PARAMETERS:
%   ens_size: create ens_size varied derived tracks, default 9 
%       (means for each original track, 9 daughter tracks are generated)
%   ens_amp: amplitude of random walk wiggles in degree longitude for
%       'directed', default 0.35. Be careful when changing, test with one track and plot, e.g.
%       climada_tc_random_walk(tc_track(1),9,ens_amp,[],1)
%   Maxangle: the angle the track direction can change for one timestep
%       default=pi/7. Be careful when changing, test with one track and plot, e.g.
%       climada_tc_random_walk(tc_track(1),9,[],Maxangle,1)
%   check_plot: whether we show a check plot (=1) or not (=0), default=0
% OUTPUTS:
%   same structure now including the ens_size times number of tracks
%   all the info from the original tracks is copied, only the lat, lon
%   differs
% RESTRICTIONS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20090728
% Markus Huber, markus.huber@env.ethz.ch, 20100412
% Omar Bellprat, mar.bellprat@env.ethz.ch, 20100412, Maxangle added as input
%-

% init global variables
global climada_global
if ~climada_init_vars,return;end

% check inputs
if ~exist('tc_track'  , 'var'), tc_track   = []; end
if ~exist('ens_size'  , 'var'), ens_size   = []; end
if ~exist('ens_amp'   , 'var'), ens_amp    = []; end
if ~exist('Maxangle'  , 'var'), Maxangle   = []; end
if ~exist('check_plot', 'var'), check_plot = []; end

% if isempty(tc_track),return;end
if isempty(tc_track)
    load ([climada_global.data_dir '\tc_tracks\tc_tracks_mozambique_1978_2011_southwestindian_cleaned_6h'])
end



% PARAMETERS
%
% whether we use the same seed each time we call this (=1) or a true new seed (=0)
% If =1, use always the same seed, in order to allow for reproduceability in exercises
force_seed_0=1; % default=1 (for lecture)
%
% the number of created tracks per original track
if isempty(ens_size), ens_size = 9; end % hint: max 100 (more takes really long...)
%
% ensemble generation parameters
ens_amp0 = 1.5; % amplitude of max random starting point shift degree longitude
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%omar & markus : ens_size -> ens_amp,  Maxangle default=pi/7;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(ens_amp),ens_amp=0.35;end % amplitude of random walk wiggles in degree longitude for 'directed'
if isempty(Maxangle),Maxangle=pi/7;end % maximum angle of variation, =pi is like undirected, pi/4 means one quadrant
% ens_amp0=2;  %original value
% ens_amp=0.1; %original value
% Maxangle=pi/8; %original value
%
max_lat_dist=10; % maximum latitudinal distance between consequent data points. if this
%distance is larger than max_lat_dist, the storm is not
%used (kind of second data cleaning)
% 
% whether we show a check plot
% ----------------------------
% be careful, consumes most CPU time, only use with test data
if isempty(check_plot),check_plot=0;end % whether we show a check plot (=1) or not (=0)

n_storms            = length(tc_track);
next_track_position = 0; % to store first one original track and then derived ones
ens_count           = 0; % init

% generate random starting points for ensemble members
if force_seed_0,rand('seed',0),end % always the same seed, in order to allow for reproduceability in exercises
x0 = ens_amp0*(rand(ens_size*n_storms,1)-0.5);   % rand: uniformly distributed random numbers
y0 = ens_amp0*(rand(ens_size*n_storms,1)-0.5);

fprintf('adding %i derived tracks to %i original storms\n',ens_size,n_storms);
h = waitbar(0,'Processing ...');               

t0 = clock;
for track_i=1:n_storms % loop over all original tracks

    if isempty(find(abs(diff(tc_track(track_i).lat))>max_lat_dist)==1)

        next_track_position = next_track_position+1; 
        
        waitbar(track_i/n_storms,h); % update waitbar
        
        % take lon/lat for the original track
        lon  = tc_track(track_i).lon;
        lat  = tc_track(track_i).lat;
        name = tc_track(track_i).name;
        ID   = tc_track(track_i).ID_no;
        N    = length(lon);
        
        % directed random walk
        %---------------------
        if force_seed_0,rand('seed',0),end % always the same seed, in order to allow for reproduceability in exercises
        x = cumsum( ens_amp *sin( cumsum( 2*Maxangle*rand(ens_size*N,1) -Maxangle)));
        y = cumsum( ens_amp *cos( cumsum( 2*Maxangle*rand(ens_size*N,1) -Maxangle)));
        
        % copy original track
        tc_track_out(next_track_position) = tc_track(track_i);
        
        for ii=0:ens_size-1  %loop over derived tracks
            
            ens_count           = ens_count+1;
                    
            % the derived track is in the following positions after the original one
            next_track_position = next_track_position+1;  
            
            % copy original track
            tc_track_out(next_track_position) = tc_track(track_i);

            % dx/dy: how much differ the derived from the original
            dx   = x(ii*N+1:(ii+1)*N,1) - x(ii*N+1,1);
            dy   = y(ii*N+1:(ii+1)*N,1) - y(ii*N+1,1);
            
            % add dx/dy to the different starting points
            dlon = dx'+x0((ii+1)*track_i);
            dlat = dy'+y0((ii+1)*track_i);
            
            %if check_plot,plot(lon+dlon,lat+dlat),hold on;end; % DEBUG only
            
            % fill in the derived track: add dlon/dlat
            tc_track_out(next_track_position).lon             = lon+dlon;
            tc_track_out(next_track_position).lat             = lat+dlat;
            tc_track_out(next_track_position).orig_event_flag = 0;
            tc_track_out(next_track_position).name            = [deblank(name) '_gen' num2str(ii+1)];   %new names: first derived ..._gen1
            tc_track_out(next_track_position).ID_no           = tc_track(track_i).ID_no+ii/100; % new ID_no are decimals for derived tracks
            tc_track_out(next_track_position).orig_event_flag = 0;

        end % for ii=0:ens_size-1  %loop over derived tracks  
    end % track_i
end %if isempty(find(abs(diff(tc_track(i).lat))>max_lat_dist)==1)

t_elapsed = etime(clock,t0);
fprintf('generating %i derived storms took %f sec (%f sec/track)\n',ens_count,t_elapsed,t_elapsed/ens_count);
close(h); % dispose waitbar

fprintf('HINT: for further use, save the generated tracks using the ''save'' command\n');

if check_plot
    fprintf('preparing check plot ...\n');
    figure
    plot(tc_track_out(1).lon,tc_track_out(1).lat,'-b');hold on;title('TC ensemble set')
    plot(tc_track(1).lon,tc_track(1).lat,'-r');hold on
    legend('derived tracks','original tracks');
    for i=2:length(tc_track_out);plot(tc_track_out(i).lon,tc_track_out(i).lat,'-b');hold on;end;title('TC ensemble set')
    for i=2:length(tc_track);plot(tc_track(i).lon,tc_track(i).lat,'-r');hold on;end;
    if exist('climada_plot_world_borders'),climada_plot_world_borders;end % plot coastline
    set(gcf,'Color',[1 1 1]); % background to white
end

return
