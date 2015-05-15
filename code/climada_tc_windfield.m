function res=climada_tc_windfield(tc_track,centroids,equal_timestep,silent_mode,check_plot)
% TC windfield calculation
% NAME:
%   climada_tc_windfield
% PURPOSE:
%   given a TC track (lat/lon,CentralPressure,MaxSustainedWind), calculate
%   the wind field at locations (=centroids)
%
%   If centroids.distance2coast_km exists, the hazard intensity is only
%   calculated in the coastal_range_km (usually 300km, see PARAMETERS) -
%   this speeds up calculation for large countries considerably. To switch
%   this feature off, just centroids=rmfield(centroids,'distance2coast_km')
%   prior to passing centroids to climada_tc_windfield
%
%   mainly called from: see climada_tc_hazard_set
% CALLING SEQUENCE:
%   climada_tc_windfield(tc_track,centroids,equal_timestep,silent_mode)
% EXAMPLE:
%   climada_tc_windfield
%   plot windfield:
%   climada_tc_windfield(tc_track(1411), centroids,1,1,1)
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
%       If centroids.distance2coast_km exists, the hazard intensity is only
%       calculated in the coastal_range_km (usually 300km, see PARAMETERS) -
%       this speeds up calculation for large countries considerably. To switch
%       this feature off, just centroids=rmfield(centroids,'distance2coast_km')
%       prior to passing centroids to climada_tc_windfield.
%       Some other fields of centroids are also appended to res struct
% OPTIONAL INPUT PARAMETERS:
%   equal_timestep: if set=1 (default), first interpolate the track to a common
%       timestep, if set=0, no equalization of TC track data (not recommended)
%       BUT: for speedup, run climada_tc_equal_timestep for ALL tracks
%       prior to calling climada_tc_windfield (see e.g. climada_tc_hazard_set)
%       and then set equal_timestep=0 in calling climada_tc_windfield
%   silent_mode: if =1, do not write to stdout unless severe warning
%       If silent_mode=-1, use step-by-step detailed windfield, i.e. reduce
%       wind to zero at center of the eye (not recommended for
%       probabilistic, since hit/miss issue with closest node, see variable
%       max_wind_at_bullseye in code).
%   check_plot: disabled, see code, commented out for speedup
% OUTPUTS:
%   res: the output strcuture, with fields
%       gust(i): the windfield [m/s] at all centroids i
%       lat(i): the latitude of the centroids i
%       lon(i): the longitude of the centroids i
%       Some other fields of centroids are also appended to res struct
% RESTRICTIONS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20090728
% David N. Bresch, david.bresch@gmail.com, 20141227, centroids.distance2coast_km treatment added
% David N. Bresch, david.bresch@gmail.com, 20150124, wind_threshold=15 (was 0), coastal_range_km=375 (was 300)
% David N. Bresch, david.bresch@gmail.com, 20150315, back to real Holland for single timestep
% David N. Bresch, david.bresch@gmail.com, 20150319, eye 'filled' for probabilistic windfields
% David N. Bresch, david.bresch@gmail.com, 20150515, optional plot debugged (usually commented out, starting line 333)
%-

res = []; % init output

global climada_global
if ~climada_init_vars, return; end

if ~exist('tc_track'      , 'var'),  return; end
if ~exist('centroids'      , 'var'), return; end
if ~exist('equal_timestep', 'var'), equal_timestep = 1; end
if ~exist('silent_mode'   , 'var'), silent_mode    = 0; end
%if ~exist('check_plot'    , 'var'), check_plot     = 0; end % check_plot commented out for speedup

% PARAMETERS
%
% threshold above which we calculate the windfield
wind_threshold=15; % in m/s, default=0 until 20150124
%
% treat the extratropical transition celerity exceeding vmax problem
% an issue e.g. for Northern US, where this should be set=1
treat_extratropical_transition=0; % default=0, since non-standard iro Holland
%
% for speed, up only process centroids within a coastal range (on/offshore)
coastal_range_km=375; % in km, 300 until 20150124, 5*75=375 (see D<5*R below)
%

max_wind_at_bullseye=1; % =1 for probabilistic set, see remark down in code
if silent_mode==-1,max_wind_at_bullseye=0;silent_mode=1;end % =0 only for single timestep

% if check_plot
% to store original track for plotting, see below
%     tc_track_ori = tc_track;
% end

if equal_timestep
    if ~silent_mode,...
            fprintf('NOTE: tc_track refined (%i hour timestep) prior to windfield calculation\n',climada_global.tc.default_min_TimeStep);end
    tc_track=climada_tc_equal_timestep(tc_track); % make equal timesteps
end

% calculate MaxSustainedWind if only CentralPressure given
if ~isfield(tc_track,'MaxSustainedWind') && isfield(tc_track,'CentralPressure')
    tc_track.MaxSustainedWind=tc_track.CentralPressure*0; % init
end

% check validity of MaxSustainedWind
if isfield(tc_track,'MaxSustainedWind')
    tc_track.MaxSustainedWind(isnan(tc_track.MaxSustainedWind))=0; % NaN --> 0
end

switch tc_track.MaxSustainedWindUnit % to convert to km/h
    case 'kn'
        tc_track.MaxSustainedWind = tc_track.MaxSustainedWind*1.15*1.61;
    case 'kt'
        tc_track.MaxSustainedWind = tc_track.MaxSustainedWind*1.15*1.61;
    case 'mph'
        tc_track.MaxSustainedWind = tc_track.MaxSustainedWind/0.62137;
    case 'm/s'
        tc_track.MaxSustainedWind = tc_track.MaxSustainedWind*3.6;
    otherwise
        % already km/h
end;
tc_track.MaxSustainedWindUnit = 'km/h'; % after conversion

% calculate MaxSustainedWind if only CentralPressure given
zero_wind_pos = find(tc_track.MaxSustainedWind==0);
if ~isempty(zero_wind_pos)
    if ~silent_mode,fprintf('calculating MaxSustainedWind (%i of %i nodes) ...\n',length(zero_wind_pos),length(tc_track.MaxSustainedWind));end
    % hard-wired fit parameters, see climada_bom_check_Pwind_relation to get
    % these P-values (that's why they are NOT in the Parameter section above)
    P1=-0.0000709379; % all P-values to result in km/h windspeed
    P2=0.1952888100;
    P3=-180.5843850867;
    P4=56284.046256966;
    tc_track.MaxSustainedWind(zero_wind_pos)=...
        P1*tc_track.CentralPressure(zero_wind_pos).^3+...
        P2*tc_track.CentralPressure(zero_wind_pos).^2+...
        P3*tc_track.CentralPressure(zero_wind_pos)+P4;
    invalid_pos=find(tc_track.CentralPressure<700); % treat bad pressure data
    if ~isempty(invalid_pos),tc_track.MaxSustainedWind(invalid_pos)=0;end;
    filled_pos=find(tc_track.CentralPressure>=1013); % treat where pressure shows no wind
    if ~isempty(filled_pos),tc_track.MaxSustainedWind(filled_pos)=0;end;
    
    tc_track.zero_MaxSustainedWind_pos=zero_wind_pos; % to store
end % length(zero_wind_pos)>0

if isfield(tc_track,'Celerity')
    switch tc_track.CelerityUnit % to convert to km/h
        case 'kn'
            tc_track.Celerity=tc_track.Celerity*1.15*1.61;
        case 'kt'
            tc_track.Celerity=tc_track.Celerity*1.15*1.61;
        case 'mph'
            tc_track.Celerity=tc_track.Celerity/0.62137;
        case 'm/s'
            tc_track.Celerity=tc_track.Celerity*3.6;
        otherwise
            % already km/h
    end;
    tc_track.CelerityUnit='km/h'; % after conversion
end

% calculate forward speed (=celerity, km/h) if not given
if ~isfield(tc_track,'Celerity')
    % calculate km distance between nodes
    dd = 111.1*sqrt( (tc_track.lat(2:end)-tc_track.lat(1:end-1)).^2 + ...
        ((tc_track.lon(2:end)-tc_track.lon(1:end-1)).*cos((0.5*tc_track.lat(1:end-1)+0.5*tc_track.lat(2:end))/180*pi)).^2 );
    %dd_in_miles=dd*0.62137; % just if needed
    tc_track.Celerity          = dd./tc_track.TimeStep(1:length(dd)); % avoid troubles with TimeStep sometimes being one longer
    tc_track.Celerity(2:end+1) = tc_track.Celerity;
    tc_track.Celerity(1)       = tc_track.Celerity(2);
end

% Azimuth - always recalculate to avoid bad troubles (interpolating over North... other meaning of directions)
% calculate km distance between nodes
ddx                       = (tc_track.lon(2:end)-tc_track.lon(1:end-1)).*cos((0.5*tc_track.lat(2:end)+0.5*tc_track.lat(1:end-1))/180*pi);
ddy                       = (tc_track.lat(2:end)-tc_track.lat(1:end-1));
tc_track.Azimuth          = atan2(ddy,ddx)*180/pi; % in degree
tc_track.Azimuth          = mod(-tc_track.Azimuth+90,360); % convert wind such that N is 0, E is 90, S is 180, W is 270
tc_track.Azimuth(2:end+1) = tc_track.Azimuth;
tc_track.Azimuth(1)       = tc_track.Azimuth(2);

% %%to check Azimuth
% subplot(2,1,1);
% plot(tc_track.lon,tc_track.lat,'-r');
% plot(tc_track.lon,tc_track.lat,'xr');
% subplot(2,1,2)
% plot(tc_track.Azimuth);title('calculated Azimuth');ylabel('degree (N=0, E=90)');
% return

% keep only windy nodes
pos = find(tc_track.MaxSustainedWind > (wind_threshold*3.6)); % cut-off in km/h
if ~isempty(pos)
    tc_track.lon              = tc_track.lon(pos);
    tc_track.lat              = tc_track.lat(pos);
    tc_track.MaxSustainedWind = tc_track.MaxSustainedWind(pos);
    tc_track.Celerity         = tc_track.Celerity(pos);
    tc_track.Azimuth          = tc_track.Azimuth(pos);
end

cos_tc_track_lat = cos(tc_track.lat/180*pi);
centroid_count   = length(centroids.lat);
res.gust         = zeros(1,centroid_count);
res.node_Azimuth = zeros(1,centroid_count);
res.node_lat     = zeros(1,centroid_count);
res.node_lon     = zeros(1,centroid_count);

res.lat = centroids.lat;
res.lon = centroids.lon;

% add further fields (for climada use)
if isfield(centroids,'centroid_ID'),res.ID          = centroids.centroid_ID; end
if isfield(centroids,'elevation_m'),res.elevation_m = centroids.elevation_m; end

if isfield(centroids,'distance2coast_km')
    % treat only centrois closer than coastal_range_km to coast for speedup
    % coastal range both inland and offshore
    valid_centroid_pos=find(centroids.distance2coast_km<coastal_range_km);
    res.distance2coast_km=centroids.distance2coast_km;
else
    valid_centroid_pos=1:length(centroids.lat);
end

centroid_count=length(valid_centroid_pos);
tic;
for centroid_ii=1:centroid_count % now loop over all valid centroids
    
    centroid_i=valid_centroid_pos(centroid_ii);
    
    % find closest node
    dd=((tc_track.lon-res.lon(centroid_i)).*cos_tc_track_lat).^2+(tc_track.lat-res.lat(centroid_i)).^2; % in km^2
    
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
        ddx          = (res.lon(centroid_i)-node_lon)*cos(node_lat/180*pi);
        ddy          = (res.lat(centroid_i)-node_lat);
        node_Azimuth = atan2(ddy,ddx)*180/pi; % in degree
        node_Azimuth = mod(-node_Azimuth+90,360); % convert wind such that N is 0, E is 90, S is 180, W is 270
        res.node_Azimuth(centroid_i) = node_Azimuth; % to store
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
        
        % end your code here
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        res.gust(centroid_i) = max((S/3.6)*1.27,0); % G now in m/s, peak gust
        
    end % D<5*R
    
end % centroid_ii

title_str = [tc_track.name ', ' datestr(tc_track.datenum(1))];
if ~silent_mode,fprintf('%f secs for %s windfield\n',toc,deblank(title_str));end


%--------------
% FIGURE
%--------------
% if check_plot % usually whole section commented out for speedup
%     if sum(res.gust)==0
%         fprintf('zero windfield, no plot\n')
%     else
%         fprintf('preparing footprint plot\n')
%         
%         %scale figure according to range of longitude and latitude
%         scale  = max(centroids.lon) - min(centroids.lon);
%         scale2 =(max(centroids.lon) - min(centroids.lon))/...
%             (min(max(centroids.lat),60)-max(min(centroids.lat),-50));
%         height = 0.5;
%         if height*scale2 > 1.2; height = 1.2/scale2; end
%         fig = climada_figuresize(height,height*scale2+0.15);
%         
%         % create gridded values
%         [X, Y, gridded_VALUE] = climada_gridded_VALUE(res.gust, centroids);
%         gridded_max       = max(max(gridded_VALUE));
%         gridded_max_round = 90;
%         
%         contourf(X, Y, full(gridded_VALUE),...
%             0:10:gridded_max_round,'edgecolor','none')
%         hold on
%         climada_plot_world_borders(0.7)
%         climada_plot_tc_track_stormcategory(tc_track_ori);
%         
%         plot(centroids.lon, centroids.lat, '+r','MarkerSize',0.8,'linewidth',0.1)
%         
%         axis equal
%         axis([min(centroids.lon)-scale/30  max(centroids.lon)+scale/30 ...
%             max(min(centroids.lat),-50)-scale/30  min(max(centroids.lat),60)+scale/30])
%         
%         caxis([0 gridded_max_round])
%         
%         cmap_=...
%             [1.0000    1.0000    1.0000;
%             0.8100    0.8100    0.8100;
%             0.6300    0.6300    0.6300;
%             1.0000    0.8000    0.2000;
%             0.9420    0.6667    0.1600;
%             0.8839    0.5333    0.1200;
%             0.8259    0.4000    0.0800;
%             0.7678    0.2667    0.0400;
%             0.7098    0.1333         0];
%         
%         colormap(cmap_)
%         
%         colorbartick           = [0:10:round(gridded_max)];% gridded_max_round round(gridded_max)
%         colorbarticklabel      = num2cell(colorbartick);
%         colorbarticklabel{end} = [num2str(gridded_max,'%10.2f') 'max'];
%         colorbarticklabel{end} = [int2str(gridded_max)          'max'];
%         t = colorbar('YTick',colorbartick,'yticklabel',colorbarticklabel);
%         set(get(t,'ylabel'),'String', 'Wind speed (m s^{-1})','fontsize',8);
%         xlabel('Longitude','fontsize',8)
%         ylabel('Latitude','fontsize',8)
%         
%         title(title_str,'interpreter','none','fontsize',8)
%         
%         set(gca,'fontsize',8)
%         
%     end % non-zero gusts
%     
% end % check plot

end % climada_tc_windfield

