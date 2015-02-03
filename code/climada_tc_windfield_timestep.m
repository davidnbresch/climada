function res = climada_tc_windfield_timestep(tc_track, centroids, equal_timestep)
% TC windfield calculation for every timestep
% NAME:
%   climada_tc_windfield_timestep
% PURPOSE:
%   given a TC track (lat/lon,CentralPressure,MaxSustainedWind), calculate
%   the wind field at locations (=centroids) for every timestep and display
%   it in a loop
% CALLING SEQUENCE:
%   climada_tc_windfield_timestep(tc_track, centroids, equal_timestep)
% EXAMPLE:
%   climada_tc_windfield_timestep
% INPUTS:
%   tc_track: a structure with the track information:
%       tc_track.lat
%       tc_track.lon
%       tc_track.MaxSustainedWind: maximum sustained wind speed (one-minute)
%       tc_track.MaxSustainedWindUnit as 'kn', 'mph', 'm/s' or 'km/h'
%       tc_track.CentralPressure: optional
%       tc_track.Celerity: translational (forward speed) of the hurricane.
%           optional, calculated from lat/lon if missing
%       tc_track.TimeStep: optional, only needed if Celerity needs to be
%           calculated, 6h assumed as default
%       tc_track.Azimuth: the forward moving angle, calculated if not given
%           to ensure consistency, it is even suggested not to pass Azimuth
%       tc_track.yyyy: 4-digit year, optional
%       tc_track.mm: month, optional
%       tc_track.dd: day, optional
%       tc_track.ID_no: unique ID, optional
%       tc_track.name: name, optional
%       tc_track.SaffSimp: Saffir-Simpson intensity, optional
%   centroids: a structure with the centroids information
%       centroids.lat: the latitude of the centroids
%       centroids.lon: the longitude of the centroids
% OPTIONAL INPUT PARAMETERS:
%   equal_timestep: if set=1 (default), first interpolate the track to a common
%       timestep, if set=0, no equalization of TC track data (not
%       recommended)
% OUTPUTS:
%   res.gust: the windfield [m/s] at all centroids
%       the single-character variables refer to the Pioneer offering circular
%       that's why we kept these short names (so one can copy the OC for
%       documentation)
%   res.lat: the latitude of the centroids
%   res.lon: the longitude of the centroids
% RESTRICTIONS:
% MODIFICATION HISTORY:
% Lea Mueller, 20110721
%-

res = []; % init output

if ~exist('tc_track'      , 'var'), return;             end
if ~exist('centroids'     , 'var'), return;             end
if ~exist('equal_timestep', 'var'), equal_timestep = 1; end

% PARAMETERS

% threshold above which we calculate the windfield
% in m/s, default = 0
wind_threshold = 0; 

% treat the extratropical transition celerity exceeding vmax problem
% default=0, since non-standard iro Holland
treat_extratropical_transition = 0;

% whether we plot the windfield (more for debugging this code)
% (you rather plot the output of this routine in your own code than setting this flag, for speed reasons)
% default=0 
check_plot = 0; 
tc_track_ori = tc_track;

% make equal timesteps
if equal_timestep
    tc_track = climada_tc_equal_timestep(tc_track); 
end

% calculate MaxSustainedWind if only CentralPressure given
if ~isfield(tc_track,'MaxSustainedWind') && isfield(tc_track,'CentralPressure')
    tc_track.MaxSustainedWind = tc_track.CentralPressure*0; % init
end

% check validity of MaxSustainedWind
if isfield(tc_track,'MaxSustainedWind')
    tc_track.MaxSustainedWind(isnan(tc_track.MaxSustainedWind))=0; % NaN --> 0
end

% to convert to km/h
switch tc_track.MaxSustainedWindUnit 
    case 'kn'
        tc_track.MaxSustainedWind=tc_track.MaxSustainedWind*1.15*1.61;
    case 'kt'
        tc_track.MaxSustainedWind=tc_track.MaxSustainedWind*1.15*1.61;
    case 'mph'
        tc_track.MaxSustainedWind=tc_track.MaxSustainedWind/0.62137;
    case 'm/s'
        tc_track.MaxSustainedWind=tc_track.MaxSustainedWind*3.6;
    otherwise
        % already km/h
end;
% after conversion
tc_track.MaxSustainedWindUnit='km/h'; 

% calculate MaxSustainedWind if only CentralPressure given
zero_wind_pos=find(tc_track.MaxSustainedWind==0);
if length(zero_wind_pos)>0
    if ~silent_mode,fprintf('calculating MaxSustainedWind (%i of %i nodes) ...\n',length(zero_wind_pos),length(tc_track.MaxSustainedWind));end
    % hard-wired fit parameters, see climada_bom_check_Pwind_relation to get
    % these P-values (that's why they are NOT in the Parameter section above)
    % all P-values to result in km/h windspeed
    P1 = -0.0000709379; 
    P2 =  0.1952888100;
    P3 = -180.5843850867;
    P4 = 56284.046256966;
    tc_track.MaxSustainedWind(zero_wind_pos) = ...
            P1*tc_track.CentralPressure(zero_wind_pos).^3+...
            P2*tc_track.CentralPressure(zero_wind_pos).^2+...
            P3*tc_track.CentralPressure(zero_wind_pos)+P4;
    % treat bad pressure data
    invalid_pos = find(tc_track.CentralPressure<700); 
    if length(invalid_pos)>0,tc_track.MaxSustainedWind(invalid_pos)=0;end;
    % treat where pressure shows no wind
    filled_pos  = find(tc_track.CentralPressure>=1013); 
    if length(filled_pos)>0,tc_track.MaxSustainedWind(filled_pos)=0;end;
    
    % to store
    tc_track.zero_MaxSustainedWind_pos = zero_wind_pos; 
end % length(zero_wind_pos)>0

% to convert to km/h
if isfield(tc_track,'Celerity')
    switch tc_track.CelerityUnit 
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
    % after conversion
    tc_track.CelerityUnit = 'km/h'; 
end

% Azimuth - always recalculate to avoid bad troubles (interpolating over North... other meaning of directions)
% calculate km distance between nodes
ddx                       = diff(tc_track.lon).*cos( (tc_track.lat(2:end)-0.5*diff(tc_track.lat)) /180*pi);
ddy                       = diff(tc_track.lat);
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

% calculate forward speed (=celerity, km/h) if not given
if ~isfield(tc_track,'Celerity')
    % calculate km distance between nodes
    dd = 111.1 * sqrt(  ddy.^2 + ddx .^2 );
    %dd_in_miles=dd*0.62137; % just if needed
    tc_track.Celerity          = dd./tc_track.TimeStep(1:length(dd)); % avoid troubles with TimeStep sometimes being one longer
    tc_track.Celerity          = [tc_track.Celerity(1) tc_track.Celerity];
end

% keep only windy nodes
pos = find(tc_track.MaxSustainedWind > (wind_threshold*3.6)); % cut-off in km/h
if length(pos) > 0
    tc_track.lon              = tc_track.lon(pos);
    tc_track.lat              = tc_track.lat(pos);
    tc_track.MaxSustainedWind = tc_track.MaxSustainedWind(pos);
    tc_track.Celerity         = tc_track.Celerity(pos);
    tc_track.Azimuth          = tc_track.Azimuth(pos);
end

cos_tc_track_lat = cos(tc_track.lat/180*pi);
centroid_count   = length(centroids.lat);
res.gust         = spalloc(centroid_count,1,ceil(centroid_count*0.1));

% % radius of max wind (km)
R_min = 30; 
R_max = 75;
tc_track.R                = ones(1,length(tc_track.lon))*R_min;
trop_lat                  = abs(tc_track.lat) > 24;
tc_track.R(trop_lat)      = tc_track.R(trop_lat)+2.5*(tc_track.lat(trop_lat)-24);
extratrop_lat             = abs(tc_track.lat) > 42;
tc_track.R(extratrop_lat) = R_max;

node_count       = length(tc_track.lon);
cos_tc_track_lat = cos(tc_track.lat/180*pi);
res.gust         = sparse(node_count,centroid_count);

% add further fields (for climada use)
if isfield(centroids,'OBJECTID')   , res.OBJECTID = centroids.OBJECTID;    end
if isfield(centroids,'centroid_ID'), res.ID       = centroids.centroid_ID; end

[c_i c_j] = size(centroids.lat);
if c_i == 1
    res.lat = centroids.lat';
    res.lon = centroids.lon';
else
    res.lat = centroids.lat;
    res.lon = centroids.lon;
end

% find closest track node to every centroid, and calculate distance in km
C_lonlat = [res.lon res.lat]; %[centroids.lon centroids.lat]; 
C_coslat = cos(res.lat/180*pi); %cos(centroids.lat/180*pi);
[t_i t_j] = size(tc_track.lon);
if t_i == 1
    T_lonlat = [tc_track.lon' tc_track.lat'];
else
    T_lonlat = [tc_track.lon  tc_track.lat];
end
% cos_tc_track_lat = cos(tc_track.lat/180*pi);

%loop over all track nodes
for node_i =1:node_count % now loop over all track nodes
    % node_i = 225;
    
    % in degree, close enough to have an impact
    R = tc_track.R(node_i);
    impact_radius = 10*R/111.12;
    
    % find centroids within plus minus 10*R km of node_i
    % logical vector of centroids length, containing 1 if centroid is
    % within impact radius of node, otherwise 0
    close_enough = res.lon > (tc_track.lon(node_i) - impact_radius) & ...
                   res.lon < (tc_track.lon(node_i) + impact_radius) & ...
                   res.lat > (tc_track.lat(node_i) - impact_radius) & ...
                   res.lat < (tc_track.lat(node_i) + impact_radius);
     
    if any(close_enough)
        %fprintf('%i centroids within plus minus 5? of node %i \n',sum(inreach(:)),node_i)
        
        % calculate distance to centroids
        % cos_tc_track_lat
        C_lonlat_ = C_lonlat(close_enough,:);
        C_coslat_ = C_coslat(close_enough,:);
        
        % calculate distance from single track node to all centroids that
        % are close enough (distance in km)
        dd = bsxfun(@minus, C_lonlat_, T_lonlat(node_i,:));
        dd(:,1) = dd(:,1).*C_coslat_; 
        D = sqrt(sum(dd.^2,2)) * 111.12; 
        %D  = sqrt((dd(:,1).*C_coslat_).^2 + dd(:,2).^2)*111.12; 

        % calculate angle to centroids to determine left/right of track
        node_Azimuth = atan2(dd(:,2),dd(:,1))*180/pi; % in degree       
        % convert wind such that N is 0, E is 90, S is 180, W is 270
        node_Azimuth = mod(-node_Azimuth+90,360); 
        % to store
        %res.node_Azimuth(node_i,inreach) = node_Azimuth; 
        
        M            = tc_track.MaxSustainedWind(node_i);

        % calculate T for every centroid withing +- 5? (inreach)
        right       = mod(node_Azimuth-tc_track.Azimuth(node_i)+360,360)<180;
        if any(right)
            T(right ,1) =  tc_track.Celerity(node_i);
        end
        if any(~right)
            T(~right,1) = -tc_track.Celerity(node_i);
        end
        % switch sign for Southern Hemisphere
        if tc_track.lat(node_i)<0
            T = -T;
        end 
           

        % if treat_extratropical_transition
        %     % special to avoid unrealistic celerity after extratropical transition
        %     max_T_fact=0.0;
        %     T_fact=1.0; % init
        %     if abs(node_lat) > 35, T_fact=1.0+(max_T_fact-1.0)*(abs(node_lat)-35)/(42-35);end;
        %     if abs(node_lat) > 42, T_fact=max_T_fact; end;
        %     T=sign(T)*min(abs(T),abs(M)); % first, T never exceeds M
        %     T=T*T_fact; % reduce T influence by latitude
        % end;
        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % in the inner core      
        inner = D <= R;
        outer = D > R & D <  10*R;
        none  = D >= 10*R;
        S     = [];
        if any(inner)
            S(inner,1) = min(M, M+2*T(inner).*D(inner)/R); 
        end
        if any(outer)
            S(outer,1) = max(    ( M - abs(T(outer)) )  .* ...
                                 R^1.5 ./ D(outer).^1.5 .* ...
                                 exp( 1-R^1.5./D(outer).^1.5 ) ...
                               + T(outer),...
                             0);
        end
        S(none,1) = 0;
        
        % gust now in m/s, peak gust    
        res.gust(node_i,close_enough) = max((S/3.6)*1.27,0); 
        
        %end %D<10*R
    end %any(inreach)
end %node_i

return


