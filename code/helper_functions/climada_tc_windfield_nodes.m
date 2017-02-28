function [gust_i,gust_j,gust_v,gust_n,n_nodes,n_centroids] = climada_tc_windfield_nodes(tc_track,centroids,wind_threshold,arr_density,return_max)
% TC windfield calculation
% MODULE:
%   core
% NAME:
%   climada_tc_windfield_nodes
% PURPOSE:
%   stripped-down version of climada_tc_windfield, see climada_tc_windfield
%   treats extratropical transition. NO argument check for speedup.
%
%   Key difference: this code does return the single-step windfields for
%   each node of the track, i.e. gust is of dimension n_nodes x n_centroids
%   (while climada_tc_windfield just returns the max gust over all nodes).
%
%   The code returns i,j,v to construct a sparse array (see OUTPUTS).
%
%   to TEST this code, uncomment all the TEST section at the beginning and
%   the end of the code. There is a switch in the PARAMETERS section, in
%   order to allow easy on/off during TESTs. But commenting all TEST out
%   makes the code slightly faster in fully operational mode (very
%   millisecond counts if called millions of times...).
%
%   Do NOT use this code except wehn calling from climada_event_damage_data_tc
% CALLING SEQUENCE:
%   [gust_i,gust_j,gust_v,gust_n,n_nodes,n_centroids]=climada_tc_windfield_nodes(tc_track,centroids,wind_threshold,arr_density,return_max)
% EXAMPLE:
%   see climada_event_damage_data_tc, in essence
%   [gust_i,gust_j,gust_v,gust_n,n_nodes,n_centroids]=climada_tc_windfield_nodes(tc_track,centroids,15,0.01,0)
%   gust=sparse(gust_i,gust_j,gust_v,n_nodes,n_centroids);
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
%   wind_threshold: threshold above which we calculate the windfield,
%       best set to 15 [m/s]. For speedup, we do no default setting or
%       the like here.
%   arr_density: the density of the sparse array, i.. to estimate the
%       non-zero elements, a good starting value is 0.01, but it depends on the
%       geographical scope and density of centroids vis-a-vis the extent of the
%       wind field.
%   return_max: if =1, return only the maximum windspeed at each centroid.
%       Default=0, to return windspeed for all nodes (i.a. all times)
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   gust_i: i-index of non-zero gust elements, empty if no node had any
%       wind above wind_threshold at any centroid
%   gust_j: j-index of non-zero gust elements
%   gust_v: value of non-zero gust elements, gust windfield in [m/s] at
%       node gust_i for centroid gust_j
%   gust_n: the number of elements in gust_i,gust_j and gust_v each
%       =length(gust_i), but faster to pass on
%   n_nodes: number of nodes
%   n_centroids: number of centroids
%   -> convert output to sparse array by:
%      gust=sparse(gust_i,gust_j,gust_v,n_nodes,n_centroids);
% RESTRICTIONS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20170225, copy from climada_tc_windfield
% David N. Bresch, david.bresch@gmail.com, 20170227, massive speedup, explicit construction of sparse array
% David N. Bresch, david.bresch@gmail.com, 20170228, further speedup, return i,j,v of sparse array
%-

% init output
gust_i=[];gust_j=[];gust_v=[];gust_n=0; % init output

% PARAMETERS
%
% Radius of max wind (in km), latitudes at which range applies
R_min=30;R_max=75; % km
R_lat_min=24;R_lat_max=42;
%
TEST=0;


% TEST, uncomment all below
if TEST==1
    wind_threshold=15;
    arr_density=.1;
    tc_track=climada_tc_read_unisys_database('nio');tc_track=tc_track(173);tc_track.name='Sidr';
    tc_track.MaxSustainedWind(end-1)=80;tc_track.MaxSustainedWind(end)=40;
    entity=climada_entity_load('BGD_Bangladesh');
    centroids.lon=entity.assets.lon; % redefine
    centroids.lat=entity.assets.lat;
    %tc_track=climada_tc_equal_timestep(tc_track,1/3);return_max=1; % to TEST footprint
    return_max=0;
end % TEST

if ~isfield(tc_track,'Celerity')
    % add fields Celerity, node_dx, node_dy and node_len for speedup
    tc_track.cos_lat  = cos(tc_track.lat/180*pi); % calculate once for speedup
    diff_tc_track_lon = diff(tc_track.lon);
    diff_tc_track_lat = diff(tc_track.lat);
    % calculate degree distance between nodes
    ddx                   = diff_tc_track_lon.*tc_track.cos_lat(2:end);
    dd                    = sqrt(diff_tc_track_lat.^2+ddx.^2)*111.1; % approx. conversion into km
    tc_track.Celerity     = dd./tc_track.TimeStep(1:length(dd)); % avoid troubles with TimeStep sometimes being one longer
    %tc_track.Celerity     = [tc_track.Celerity(1) tc_track.Celerity]; % until 20161226
    tc_track.Celerity     = [tc_track.Celerity tc_track.Celerity(end)];
    tc_track.CelerityUnit = 'km/h';
    node_dx=[diff_tc_track_lon diff_tc_track_lon(end)];
    node_dy=[diff_tc_track_lat diff_tc_track_lat(end)];
    tc_track.node_len=sqrt(node_dx.^2+node_dy.^2); % length of track forward vector
    % rotate track forward vector 90 degrees clockwise, i.e.
    % x2=x* cos(a)+y*sin(a), with a=pi/2,cos(a)=0,sin(a)=1
    % y2=x*-sin(a)+Y*cos(a), therefore
    tc_track.node_dx=node_dy;tc_track.node_dy=-node_dx;
end
switch tc_track.MaxSustainedWindUnit % convert to km/h
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

if ~isfield(tc_track,'min_node'),tc_track.min_node=1;tc_track.max_node=length(tc_track.lon);end
tc_track.n_steps=tc_track.max_node-tc_track.min_node+1;

n_nodes     = tc_track.n_steps;
n_centroids = length(centroids.lon);

% keep only windy nodes
windy_node=tc_track.MaxSustainedWind > (wind_threshold*3.6); % cut-off in km/h

if sum(windy_node)==0,return;end

if return_max,max_gust=zeros(1,n_centroids);end

guess_nnz=ceil(n_nodes*n_centroids*arr_density);
gust_i=zeros(1,guess_nnz);gust_j=zeros(1,guess_nnz);gust_v=zeros(1,guess_nnz); % init

% no struct, as arrays are faster
tc_track_lon              = tc_track.lon;
tc_track_lat              = tc_track.lat;
tc_track_MaxSustainedWind = tc_track.MaxSustainedWind;
tc_track_Celerity         = tc_track.Celerity;
cos_tc_track_lat          = tc_track.cos_lat;
tc_track_node_dx          = tc_track.node_dx;
tc_track_node_dy          = tc_track.node_dy;
tc_track_node_len         = tc_track.node_len;

% restrict to a region around the track, since windfield does anyway not extend further
tmalo=max(tc_track_lon)+5;
tmala=max(tc_track_lat)+5;
tmilo=min(tc_track_lon)-5;
tmila=min(tc_track_lat)-5;
valid_centroid_pos=find((centroids.lon>tmilo & centroids.lon<tmalo) & (centroids.lat>tmila & centroids.lat<tmala));
local_lon=centroids.lon(valid_centroid_pos); % for parfor
local_lat=centroids.lat(valid_centroid_pos); % for parfor

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
        
        S = S/3.6*1.27; % local_gust now in m/s, peak gust
        
        nze=S>0; % NEW
        if ~isempty(nze)
            nnze=sum(nze); % number of non-zero elements
            gust_i(1,gust_n+1:gust_n+nnze)=node_i-tc_track.min_node+1;
            gust_j(1,gust_n+1:gust_n+nnze)=valid_centroid_pos(nze);
            gust_v(1,gust_n+1:gust_n+nnze)=S(nze);
            gust_n=gust_n+nnze; % number of filled in elements
            if return_max,max_gust(valid_centroid_pos(nze))=max(max_gust(valid_centroid_pos(nze)),S(nze));end
        end % ~isempty(nze)
        
    end % windy_node(node_i)
    
end % node_i

if return_max
    nze=max_gust>0;
    if ~isempty(nze)
        gust_j=valid_centroid_pos(nze);
        gust_i=gust_j*0+1;
        gust_v=max_gust(nze);
        n_nodes=1;
    else
        gust_i=[];
    end
else
    gust_i=gust_i(1:gust_n);
    gust_j=gust_j(1:gust_n);
    gust_v=gust_v(1:gust_n);
end % return_max

if TEST==1
    if gust_n>0
        fprintf('TEST: plotting\n');
        gust=sparse(gust_i,gust_j,gust_v,n_nodes,n_centroids);
        climada_color_plot(gust(end,:),centroids.lon,centroids.lat);
        title('TEST - windfield TC Sidr after landfall in Bangladesh')
    else
        fprintf('no centroid with gust windspeed above %i\n',wind_threshold);
    end
end % TEST==1

end % climada_tc_windfield_viz