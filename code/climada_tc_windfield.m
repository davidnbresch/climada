function gust = climada_tc_windfield(tc_track,centroids,~,silent_mode,~)
% TC windfield calculation
% MODULE:
%   core
% NAME:
%   climada_tc_windfield
% PURPOSE:
%   given a TC track (lat/lon,CentralPressure,MaxSustainedWind), calculate
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
%   [gust,res]=climada_tc_windfield(tc_track,centroids,~,silent_mode,~)
% EXAMPLE:
%   tc_track=climada_tc_track_load('TEST_tracks.atl_hist');
%   tc_track=climada_tc_equal_timestep(tc_track);
%   centroids=climada_centroids_load('USFL_MiamiDadeBrowardPalmBeach');
%   gust=climada_tc_windfield(tc_track(68),centroids); % Andrew, 1992
%   climada_color_plot(gust,centroids.lon,centroids.lat);
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
%       Note: if length(tc_track.lon)=2 (i.e. two nodes) and
%       silent_mode=-1, only use first node in order to return one single
%       step windfield.  
% OUTPUTS:
%   gust: the windfield [m/s] at all centroids, NOT sparse for speedup
%       i.e. convert like hazard.intensity()=sparse(res.gust)...
% RESTRICTIONS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20090728
% David N. Bresch, david.bresch@gmail.com, 20150103, not faster than climada_tc_windfield any more
% David N. Bresch, david.bresch@gmail.com, 20150819, climada_global.centroids_dir introduced
% David N. Bresch, david.bresch@gmail.com, 20160529, about 20% faster than climada_tc_windfield_slow
% David N. Bresch, david.bresch@gmail.com, 20160529, only gust returned, even faster
% David N. Bresch, david.bresch@gmail.com, 20161205, Rmax parameters moved to PARAMETERS section
% David N. Bresch, david.bresch@gmail.com, 20161225, Celerity fixed (dipole)
% David N. Bresch, david.bresch@gmail.com, 20161226, further speedup, all to arrays, no struct in main loop
% David N. Bresch, david.bresch@gmail.com, 20170103, special case silent_mode=-1 for single node
%-

gust = []; % init output

global climada_global

% for SPEEDUP, we assume init_vars to have been executed
%if ~climada_init_vars, return; end
if ~exist('tc_track' ,'var'), tc_track       = []; end
if ~exist('centroids','var'), centroids      = []; end
if ~exist('silent_mode','var'), silent_mode  =  1; end

% PARAMETERS
%
% Radius of max wind (in km), latitudes at which range applies
R_min=30;R_max=75; % km
R_lat_min=24;R_lat_max=42;
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

gust=centroids.lon*0; % init with zeros

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

cos_tc_track_lat  = cos(tc_track.lat/180*pi); % calculate once for speedup
diff_tc_track_lon = diff(tc_track.lon);
diff_tc_track_lat = diff(tc_track.lat);
if ~isfield(tc_track,'Celerity') % forward speed (=celerity, km/h)
    % calculate degree distance between nodes  
    ddx                   = diff_tc_track_lon.*cos_tc_track_lat(2:end);
    dd                    = sqrt(diff_tc_track_lat.^2+ddx.^2)*111.1; % approx. conversion into km
    tc_track.Celerity     = dd./tc_track.TimeStep(1:length(dd)); % avoid troubles with TimeStep sometimes being one longer
    %tc_track.Celerity     = [tc_track.Celerity(1) tc_track.Celerity]; % until 20161226
    tc_track.Celerity     = [tc_track.Celerity tc_track.Celerity(end)];
    tc_track.CelerityUnit = 'km/h';
end

node_dx=[diff_tc_track_lon diff_tc_track_lon(end)];
node_dy=[diff_tc_track_lat diff_tc_track_lat(end)];
node_len=sqrt(node_dx.^2+node_dy.^2); % length of track forward vector
% rotate track forward vector 90 degrees clockwise, i.e.
% x2=x* cos(a)+y*sin(a), with a=pi/2,cos(a)=0,sin(a)=1
% y2=x*-sin(a)+Y*cos(a), therefore
node_tmp=node_dx;node_dx=node_dy;node_dy=-node_tmp;
        
% keep only windy nodes
pos = find(tc_track.MaxSustainedWind > (wind_threshold*3.6)); % cut-off in km/h
if length(tc_track.lon)==2 && silent_mode==-1,pos=pos(1:end-1);end % ignore last node if single step
if ~isempty(pos) % and no struct, as arrays are faster
    tc_track_lon              = tc_track.lon(pos);
    tc_track_lat              = tc_track.lat(pos);
    tc_track_MaxSustainedWind = tc_track.MaxSustainedWind(pos);
    tc_track_Celerity         = tc_track.Celerity(pos);
    cos_tc_track_lat          = cos_tc_track_lat(pos);
    tc_track_node_dx          = node_dx(pos);
    tc_track_node_dy          = node_dy(pos);
    tc_track_node_len         = node_len(pos);
else
    return % no wind
end

n_centroids = length(centroids.lon);

if isfield(centroids,'distance2coast_km')
    % treat only centrois closer than coastal_range_km to coast for speedup
    % coastal range both inland and offshore
    valid_centroid_pos=find(centroids.distance2coast_km<coastal_range_km);
    local_lon=centroids.lon(valid_centroid_pos); % for parfor
    local_lat=centroids.lat(valid_centroid_pos); % for parfor
else
    valid_centroid_pos=1:n_centroids;
    local_lon=centroids.lon; % for parfor
    local_lat=centroids.lat; % for parfor
end

n_valid_centroids=length(valid_centroid_pos);
local_gust=valid_centroid_pos*0; % init

%t0=clock; % TIMING
for centroid_i=1:n_valid_centroids % now loop over all valid centroids
    %parfor centroid_i=1:n_valid_centroids % works with PARFOR, but not faster
    
    % find closest node (these two lines MOST TIME CONSUMING)
    dd=((tc_track_lon-local_lon(centroid_i)).*cos_tc_track_lat).^2+(tc_track_lat-local_lat(centroid_i)).^2; % in km^2
    [~,pos] = min(dd);
    
    node_i  = pos(1); % take first if more than one
    D = sqrt(dd(node_i))*111.12; % now in km
    
    % avoid indexing, slight speedup
    node_lat = tc_track_lat(node_i);
    node_lon = tc_track_lon(node_i);
    node_dx  = tc_track_node_dx(node_i);
    node_dy  = tc_track_node_dy(node_i);
    node_len = tc_track_node_len(node_i);
    
    % until 20161205, hard-wired
    %R = 30; % radius of max wind (in km)
    %if abs(node_lat) > 42
    %    R = 75;
    %elseif abs(node_lat) > 24
    %    R = 30+2.5*(abs(node_lat)-24);
    %end
    
    % since 20161205, with parameters
    R = R_min; % radius of max wind (in km)
    if abs(node_lat) > R_lat_max
        R = R_max;
    elseif abs(node_lat) > R_lat_min
        R = R_min+(R_max-R_min)/(R_lat_max-R_lat_min)*(abs(node_lat)-R_lat_min);
    end
    
    %if D<10*R % close enough to have an impact
    if D<5*R % focus on the radius that really has an impact
        
        % calculate angular field to add translational wind
        % -------------------------------------------------
        
        % figure which side of track, hence add/subtract translational wind
        
        % we use the scalar product of the track forward vector and the vector
        % towards each centroid to figure the angle between and hence whether
        % the translational wind needs to be added (on the right side of the
        % track for Northern hemisphere) and to which extent (100% exactly 90
        % to the right of the track, zero in front of the track)
        
        % the vector towards each centroid
        centroids_dlon=local_lon(centroid_i)-node_lon; % vector from center
        centroids_dlat=local_lat(centroid_i)-node_lat;
        centroids_len=sqrt(centroids_dlon.^2+centroids_dlat.^2); % length
        
        % scalar product, a*b=|a|*|b|*cos(phi), phi angle between vectors
        cos_phi=(centroids_dlon*node_dx+centroids_dlat*node_dy)/centroids_len/node_len;
        if node_lat<0;cos_phi=-cos_phi;end % southern hemisphere
        
        % calculate vtrans wind field array assuming that
        % - effect of Celerity decreases with distance from eye (r_normed)
        % - Celerity is added 100% to the right of the track, 0% in front etc. (cos_phi)
        r_normed=R/D;
        r_normed(r_normed>1)=1;
        T = tc_track_Celerity(node_i)*r_normed*cos_phi;
        
        M = tc_track_MaxSustainedWind(node_i);
        
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
        
        % Please note the special case if max_wind_at_bullseye=1
        % For generation of fully probabilistic sets (max_wind_at_bullseye=1),
        % the windfield calculation is speeded up by only treating the node
        % closest to the centroid. In case the centroid sits within the eye
        % of the hurricane at one timestep, it is very likely (almost
        % certain) it will sooner or later experience the max wind, hence
        % the code does indeed assign the maximum wind (eyewall) to these
        % centroids, instead of a low value.
        % max_wind_at_bullseye=0 is used for single time-step windfields,
        % e.g. for animations.
        if D<=R && max_wind_at_bullseye
            S = min(M, M+2*T*D/R); % in the inner core
        elseif D<10*R % in the outer core
            S = max( (M-abs(T))*( R^1.5 * exp( 1-R^1.5/D^1.5 )/D^1.5) + T, 0);
        else
            S = 0; % well, see also check before, hence never reached
        end % D<10*R
        
        local_gust(centroid_i) = max((S/3.6)*1.27,0); % local_gust now in m/s, peak gust
        %local_gust(centroid_i) = max((S/3.6)*1.00,0); % local_gust now in m/s 20161225
        
    end % D<5*R
    
end % centroid_ii

gust(valid_centroid_pos)=local_gust; % store into all valid centroids

%res.time=etime(clock,t0); % TIMING

end % climada_tc_windfield