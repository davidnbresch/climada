function [res,tc_track] = climada_tc_windfield_exercise(tc_track,centroids,~,silent_mode,~)
% TC windfield calculation
% NAME:
%   climada_tc_windfield_exercise
% PURPOSE:
%   the EXERCISE version of climada_tc_windfield, used for lecture course,
%   see www.iac.ethz.ch/edu/courses/master/modules/climate-risk.html
%
%   given a TC track (lat/lon,MaxSustainedWind), calculate
%   the wind field at locations (=centroids)
%
%   mainly called from: see climada_tc_hazard_set
%
%   Note: this code is optimized for speed, hence assumes that tc_track is
%   free of missing data, climada_tc_equal_timestep applied and
%   MaxSustainedWind calculated.
%
%   PARFOR: this code does run with parfor, but it seems not to be faster
%   at all (sine there seems to be lots of comms overhead to share tc_track
%   between parallel processes) - see climada_tc_hazard_set for another
%   PARFOR opportunity (we use it there, not here).
%
%   See climada_tc_windfield_slow in the tropical cyclone module 
%   (https://github.com/davidnbresch/climada_module_tropical_cyclone) 
%   for the old slow version (for backward compatibility).
%
% CALLING SEQUENCE:
%   [res,tc_track]=climada_tc_windfield_exercise(tc_track,centroids,~,silent_mode,~)
% EXAMPLE:
%   tc_track=climada_tc_track_load('TEST_tracks.atl_hist');
%   tc_track=climada_tc_equal_timestep(tc_track);
%   centroids=climada_centroids_load('USFL_MiamiDadeBrowardPalmBeach');
%   res=climada_tc_windfield_exercise(tc_track(68),centroids);
%   climada_color_plot(res.gust,res.lon,res.lat);
% INPUTS:
%   tc_track: a structure with the single track information (length(tc_track)!=1)
%       see e.g. climada_tc_read_unisys_tc_track
%       tc_track.Azimuth and/or tc_track.Celerity calculated, if not existing
%       but climada_tc_equal_timestep mist have been run and
%       tc_track.MaxSustainedWind must exist on input
%   centroids: a structure with the centroids information (see e.g.
%       climada_centroids_read):
%       centroids.lat: the latitude of the centroids
%       centroids.lon: the longitude of the centroids
% OPTIONAL INPUT PARAMETERS:
%   silent_mode: default=0, if =-1, use step-by-step detailed windfield,
%       i.e. reduce wind to zero at center of the eye (not recommended for
%       probabilistic, since hit/miss issue with closest node, see variable
%       max_wind_at_bullseye in code).  
% OUTPUTS:
%   res.gust: the windfield [m/s] at all centroids, NOT sparse for speedup
%       i.e. convert like hazard.intensity()=sparse(res.gust)...
%   res.lon: the longitude of the centroids (=centroids.lon)
%   res.lat: the latitude of the centroids (=centroids.lat)
%   res.time: the time (sec) windfield calculation used
%   tc_track: provided on output, to validate added fields, such as e.g.
%       Azimuth and Celerity
% RESTRICTIONS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20090728
% David N. Bresch, david.bresch@gmail.com, 20150103, not faster than climada_tc_windfield any more
% David N. Bresch, david.bresch@gmail.com, 20150819, climada_global.centroids_dir introduced
% David N. Bresch, david.bresch@gmail.com, 20160529, about 20% faster than climada_tc_windfield_slow
%-

res = []; % init output

global climada_global

% for SPEEDUP, we assume init_vars to have been executed
%if ~climada_init_vars, return; end
if ~exist('tc_track' ,'var'), tc_track       = []; end
if ~exist('centroids','var'), centroids      = []; end
if ~exist('silent_mode','var'), silent_mode  =  1; end

% PARAMETERS
%
% threshold above which we calculate the windfield
wind_threshold=15; % in m/s, default=0 until 20150124
%
% treat the extratropical transition celerity exceeding vmax problem
% an issue e.g. for Northern US, where this should be set=1
% (in climada_init_vars, default=0, since non-standard iro Holland)
treat_extratropical_transition=climada_global.tc.extratropical_transition;
%
% for speed, up only process centroids within a coastal range (on/offshore)
coastal_range_km=375; % in km, 300 until 20150124, 5*75=375 (see D<5*R below)

max_wind_at_bullseye=1; % =1 for probabilistic set, see remark down in code
if silent_mode==-1,max_wind_at_bullseye=0;end % =0 only for single timestep

if isempty(tc_track),return;end
if isempty(centroids),return;end

res.gust=centroids.lon*0; % init with zeros
res.lon=centroids.lon;
res.lat=centroids.lat;

% to convert to km/h
switch tc_track.MaxSustainedWindUnit
    case 'kn'
        tc_track.MaxSustainedWind = tc_track.MaxSustainedWind*1.8515; % =1.15*1.61
    case 'kt' % just old naming
        tc_track.MaxSustainedWind = tc_track.MaxSustainedWind*1.15*1.61;
    case 'mph'
        tc_track.MaxSustainedWind = tc_track.MaxSustainedWind/0.62137;
    case 'm/s'
        tc_track.MaxSustainedWind = tc_track.MaxSustainedWind*3.6;
    otherwise
        % already km/h
end
tc_track.MaxSustainedWindUnit = 'km/h'; % after conversion

if isfield(tc_track,'Celerity')
    switch tc_track.CelerityUnit % to convert to km/h
        case 'kn'
            tc_track.Celerity = tc_track.Celerity*1.15*1.61;
        case 'kt'
            tc_track.Celerity = tc_track.Celerity*1.15*1.61;
        case 'mph'
            tc_track.Celerity = tc_track.Celerity/0.62137;
        case 'm/s'
            tc_track.Celerity = tc_track.Celerity*3.6;
        otherwise
            % already km/h
    end;
    tc_track.CelerityUnit = 'km/h'; % after conversion
end

% calculate degree distance between nodes (used for both Azimuth and Celerity)
cos_tc_track_lat = cos(tc_track.lat/180*pi); % calculate once for speedup
%ddx                       = diff(tc_track.lon).*cos( (tc_track.lat(2:end)-0.5*diff(tc_track.lat)) /180*pi);
ddx                       = diff(tc_track.lon).*cos_tc_track_lat(2:end);
ddy                       = diff(tc_track.lat);

if ~isfield(tc_track,'Azimuth') % direction, N is 0, E is 90, S is 180, W is 270
    tc_track.Azimuth          = atan2(ddy,ddx)*180/pi; % in degree
    tc_track.Azimuth          = mod(-tc_track.Azimuth+90,360); % convert wind such that N is 0, E is 90, S is 180, W is 270
    tc_track.Azimuth          = [tc_track.Azimuth(1) tc_track.Azimuth];
    % %%to check Azimuth
    % subplot(2,1,1);
    % plot(tc_track.lon,tc_track.lat,'-r');
    % plot(tc_track.lon,tc_track.lat,'xr');
    % subplot(2,1,2)
    % plot(tc_track.Azimuth);title('calculated Azimuth');ylabel('degree (N=0, E=90)');
    % return
end % ~isfield(tc_track,'Azimuth')

if ~isfield(tc_track,'Celerity') % forward speed (=celerity, km/h)
    % calculate km distance between nodes
    dd = sqrt(  ddy.^2 + ddx .^2 ) * 111.1; % approx. conversion into km
    tc_track.Celerity          = dd./tc_track.TimeStep(1:length(dd)); % avoid troubles with TimeStep sometimes being one longer
    tc_track.Celerity          = [tc_track.Celerity(1) tc_track.Celerity];
    tc_track.CelerityUnit      = 'km/h';
end

% keep only windy nodes
pos = find(tc_track.MaxSustainedWind > (wind_threshold*3.6)); % cut-off in km/h
if ~isempty(pos)
    tc_track.lon              = tc_track.lon(pos);
    tc_track.lat              = tc_track.lat(pos);
    tc_track.MaxSustainedWind = tc_track.MaxSustainedWind(pos);
    tc_track.Celerity         = tc_track.Celerity(pos);
    tc_track.Azimuth          = tc_track.Azimuth(pos);
    cos_tc_track_lat          = cos_tc_track_lat(pos);
else
    return % no wind
end

n_centroids = length(centroids.lon);

if isfield(centroids,'distance2coast_km')
    % treat only centrois closer than coastal_range_km to coast for speedup
    % coastal range both inland and offshore
    valid_centroid_pos=find(centroids.distance2coast_km<coastal_range_km);
    local_lon=res.lon(valid_centroid_pos); % for parfor
    local_lat=res.lat(valid_centroid_pos); % for parfor
    %res.distance2coast_km=centroids.distance2coast_km;
else
    valid_centroid_pos=1:n_centroids;
    local_lon=res.lon; % for parfor
    local_lat=res.lat; % for parfor
end

n_valid_centroids=length(valid_centroid_pos);
local_gust=valid_centroid_pos*0; % init

t0=clock;
for centroid_i=1:n_valid_centroids % now loop over all valid centroids
%parfor centroid_i=1:n_valid_centroids % works with PARFOR, but not faster
        
    % find closest node (these two lines MOST TIME CONSUMING)
    dd=((tc_track.lon-local_lon(centroid_i)).*cos_tc_track_lat).^2+(tc_track.lat-local_lat(centroid_i)).^2; % in km^2
    [~,pos] = min(dd);
    
    node_i  = pos(1); % take first if more than one
    D = sqrt(dd(node_i))*111.12; % now in km
    
    node_lat = tc_track.lat(node_i);
    node_lon = tc_track.lon(node_i);
    
    R = 30; % radius of max wind (in km)
    if abs(node_lat) > 42
        R = 75;
    elseif abs(node_lat) > 24
        R = 30+2.5*(abs(node_lat)-24);
    end
    
    %if D<10*R % close enough to have an impact
    if D<5*R % focus on the radius that really has an impact
        
        % calculate angle to node to determine left/right of track
        ddx          = (local_lon(centroid_i)-node_lon)*cos(node_lat/180*pi);
        ddy          = (local_lat(centroid_i)-node_lat);
        node_Azimuth = atan2(ddy,ddx)*180/pi; % in degree
        node_Azimuth = mod(-node_Azimuth+90,360); % convert wind such that N is 0, E is 90, S is 180, W is 270
        %res.node_Azimuth(centroid_i) = node_Azimuth; % to store
        M            = tc_track.MaxSustainedWind(node_i);
        
        if mod(node_Azimuth-tc_track.Azimuth(node_i)+360,360)<180
            % right of track
            T =  tc_track.Celerity(node_i);
        else
            % left of track
            T = -tc_track.Celerity(node_i);
        end
        % switch sign for Southern Hemisphere
        if node_lat<0,T = -T;end
        
        if treat_extratropical_transition
            % special to avoid unrealistic celerity after extratropical transition
            max_T_fact=0.0;
            if abs(node_lat) > 42
                T_fact=max_T_fact;
            elseif abs(node_lat) > 35
                T_fact=1.0+(max_T_fact-1.0)*(abs(node_lat)-35)/(42-35);
            else
                T_fact=1.0;
            end
            T=sign(T)*min(abs(T),abs(M))*T_fact; % T never exceeds M
        end;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % start adding your code here
        
        
        
        % end your code here
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        local_gust(centroid_i) = max((S/3.6)*1.27,0); % local_gust now in m/s, peak gust
        
    end % D<5*R
    
end % centroid_ii

res.gust(valid_centroid_pos)=local_gust; % store into all valid centroids

res.time=etime(clock,t0);

end % climada_tc_windfield_exercise