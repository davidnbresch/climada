function gust = climada_tc_windfield_viz(tc_track,centroids)
% TC windfield calculation
% MODULE:
%   core
% NAME:
%   climada_tc_windfield_viz
% PURPOSE:
%   stripped-down version of climada_tc_windfield, see climada_tc_windfield
%   treats extratropical transition, 
%   
%   Key difference: this code does return the single-step windfields for
%   each node of the track, i.e. gust is of dimension n_nodes x n_centroids
%   (while climada_tc_windfield just returns the max gust over all nodes)
%
%   Do NOT use this code except wehn calling from climada_event_damage_data_tc_viz
% CALLING SEQUENCE:
%   gust=climada_tc_windfield_viz(tc_track,centroids)
% EXAMPLE:
%   see climada_event_damage_data_tc_viz
% INPUTS:
%   tc_track: a structure with the single track information (length(tc_track)!=1)
%       see e.g. climada_tc_read_unisys_tc_track
%       tc_track.Azimuth and/or tc_track.Celerity calculated, if not existing
%       but climada_tc_equal_timestep mist have been run and
%       tc_track.MaxSustainedWind must exist on input
%    PLUS fields Celerity, cos_lat, node_dx, node_dy and node_len need to
%       exist (see climada_event_damage_data_tc_viz, for speedup resons)
%   centroids: a structure with the centroids information (see e.g.
%       climada_centroids_read):
%       centroids.lat: the latitude of the centroids
%       centroids.lon: the longitude of the centroids
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   gust(node_i,centroid_i): the windfield [m/s] at all centroids i for all
%       nodes i. NOT sparse for speedup i.e. convert like
%       hazard.intensity()=sparse(gust)...
% RESTRICTIONS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20170225, copy from climada_tc_windfield
%-

gust = []; % init output

% PARAMETERS
%
% Radius of max wind (in km), latitudes at which range applies
R_min=30;R_max=75; % km
R_lat_min=24;R_lat_max=42;
%
% threshold above which we calculate the windfield
%wind_threshold=15; % in m/s, default=0 until 20150124
wind_threshold=5; % in m/s, default=0 until 20150124
%
% for speed, up only process centroids within a coastal range (on/offshore)
%coastal_range_km=375; % in km, 300 until 20150124, 5*75=375 (see D<5*R below)
coastal_range_km=500; % in km, set to 500 for global animation, 20170225


n_centroids = length(centroids.lon);

%gust=zeros(tc_track.n_steps,n_centroids); % init
gust=spalloc(tc_track.n_steps,n_centroids,ceil(tc_track.n_steps*n_centroids*0.01)); % init

% keep only windy nodes
windy_node=tc_track.MaxSustainedWind > (wind_threshold*3.6); % cut-off in km/h
% no struct, as arrays are faster
tc_track_lon              = tc_track.lon;
tc_track_lat              = tc_track.lat;
tc_track_MaxSustainedWind = tc_track.MaxSustainedWind;
tc_track_Celerity         = tc_track.Celerity;
cos_tc_track_lat          = tc_track.cos_lat;
tc_track_node_dx          = tc_track.node_dx;
tc_track_node_dy          = tc_track.node_dy;
tc_track_node_len         = tc_track.node_len;

% restricxt to a region around the track, since windfield does anyway not
% extend further
tmalo=max(tc_track_lon)+5;
tmala=max(tc_track_lat)+5;
tmilo=min(tc_track_lon)-5;
tmila=min(tc_track_lat)-5;
valid_centroid_pos=find((centroids.lon>tmilo & centroids.lon<tmalo) & (centroids.lat>tmila & centroids.lat<tmala));
local_lon=centroids.lon(valid_centroid_pos); % for parfor
local_lat=centroids.lat(valid_centroid_pos); % for parfor

% if isfield(centroids,'distance2coast_km')
%     % treat only centrois closer than coastal_range_km to coast for speedup
%     % coastal range both inland and offshore
%     valid_centroid_pos=find(centroids.distance2coast_km<coastal_range_km);
%     local_lon=centroids.lon(valid_centroid_pos); % for parfor
%     local_lat=centroids.lat(valid_centroid_pos); % for parfor
% else
%     valid_centroid_pos=1:n_centroids;
%     local_lon=centroids.lon; % for parfor
%     local_lat=centroids.lat; % for parfor
% end

n_valid_centroids=length(valid_centroid_pos);

zero_vect=zeros(1,n_valid_centroids);
ones_vect=ones(1,n_valid_centroids);
    
for node_i=tc_track.min_node:tc_track.max_node
    
    % avoid indexing, slight speedup
    cos_lat  = cos_tc_track_lat(node_i);
    node_lat = tc_track_lat(node_i);
    node_lon = tc_track_lon(node_i);
    node_dx  = tc_track_node_dx(node_i);
    node_dy  = tc_track_node_dy(node_i);
    node_len = tc_track_node_len(node_i);
    
    R = R_min; % radius of max wind (in km)
    if abs(node_lat) > R_lat_max
        R = R_max;
    elseif abs(node_lat) > R_lat_min
        R = R_min+(R_max-R_min)/(R_lat_max-R_lat_min)*(abs(node_lat)-R_lat_min);
    end
    
    if windy_node(node_i)
        
        % distance to node
        %dd=((node_lon-local_lon(centroid_i))*cos_lat)^2+(node_lat-local_lat(centroid_i))^2; % in km^2
        dd=((node_lon-local_lon)*cos_lat).^2+(node_lat-local_lat).^2; % in km^2
        D = sqrt(dd)*111.12; % now in km
        
        % calculate angular field to add translational wind
        % -------------------------------------------------
        
        % figure which side of track, hence add/subtract translational wind
        
        % we use the scalar product of the track forward vector and the vector
        % towards each centroid to figure the angle between and hence whether
        % the translational wind needs to be added (on the right side of the
        % track for Northern hemisphere) and to which extent (100% exactly 90
        % to the right of the track, zero in front of the track)
        
        % the vector towards each centroid
        %centroids_dlon=local_lon(centroid_i)-node_lon; % vector from center
        centroids_dlon=local_lon-node_lon; % vector from center
        %centroids_dlat=local_lat(centroid_i)-node_lat;
        centroids_dlat=local_lat-node_lat;
        %centroids_len=sqrt(centroids_dlon^2+centroids_dlat^2); % length
        centroids_len=sqrt(centroids_dlon.^2+centroids_dlat.^2); % length
        
        % scalar product, a*b=|a|*|b|*cos(phi), phi angle between vectors
        %cos_phi=(centroids_dlon*node_dx+centroids_dlat*node_dy)/centroids_len/node_len;
        cos_phi=(centroids_dlon.*node_dx+centroids_dlat.*node_dy)./centroids_len/node_len;
        if node_lat<0;cos_phi=-cos_phi;end % southern hemisphere
        
        % calculate vtrans wind field array assuming that
        % - effect of Celerity decreases with distance from eye (r_normed)
        % - Celerity is added 100% to the right of the track, 0% in front etc. (cos_phi)
        r_normed=R./D;
        r_normed(r_normed>1)=1;
        T = tc_track_Celerity(node_i).*r_normed.*cos_phi;

        M = tc_track_MaxSustainedWind(node_i)*ones_vect;
        
        % special to avoid unrealistic celerity after extratropical transition
        max_T_fact=0.0;
        if abs(node_lat) > 42
            T_fact=max_T_fact;
        elseif abs(node_lat) > 35
            T_fact=1.0+(max_T_fact-1.0)*(abs(node_lat)-35)/(42-35);
        else
            T_fact=1.0;
        end
        T=sign(T).*min(abs(T),abs(M)).*T_fact; % T never exceeds M
        
        S=zero_vect; % init
        
        ocp=find(D<10*R); % in the outer core
        S(ocp) = max( (M(ocp)-abs(T(ocp))).*( R^1.5 * exp(1-R^1.5./D(ocp).^1.5 )./D(ocp).^1.5) + T(ocp), 0);
        % if one would like, for speedup, to omit the inner core
        % (see max_wind_at_bullseye in climada_tc_windfield)
        %icp=find(D<=R);    % in the inner core
        %S(icp) = min(M(icp), M(icp)+2.*T(icp).*D(icp)./R);
                
        S = max((S/3.6)*1.27,0); % local_gust now in m/s, peak gust
        
        gust(node_i-tc_track.min_node+1,valid_centroid_pos)=S; % store into all valid centroids
    end % windy_node(node_i)
    
end % for node_i=1:tc_track_tmp.n_steps

end % climada_tc_windfield_viz