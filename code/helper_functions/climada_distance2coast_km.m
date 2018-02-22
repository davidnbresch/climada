function [distance_km,lon,lat,onLand]=climada_distance2coast_km(lon,lat,check_plot,force_beyond_1000km,check_inpolygon,onLand)
% climada distance km coast
% NAME:
%   climada_distance2coast
% PURPOSE:
%   calculate distance to coast in km (approx.)
%
%   NOTE: this code listens to climada_global.parfor for substantial
%   speedup, about n workers faster
%
%   NOTE: for speedup, max distance is 1'000km, i.e. distances larger than
%   approx 1'000km are set to 1'000km (speeds up by st least factor ten). See the
%   try/catch statement to switch to calculation of all distances (even
%   beyond 1'000 km)
%
%   Run climada_shaperead('SYSTEM_COASTLINE') in case the coastline does
%   not exist (requires the climada module country_risk from
%   https://github.com/davidnbresch/climada_module_country_risk
% CALLING SEQUENCE:
%   distance_km=climada_distance2coast_km(lon,lat,check_plot)
% EXAMPLE:
%   distance_km=climada_distance2coast_km(lon,lat)
% INPUTS:
%   lon: vector of longitues
%   lat: vector of latitudes
% OPTIONAL INPUT PARAMETERS:
%   check_plot: =1: show circle plot for check (default=0). Works only for
%       less than 50'000 points, if you want to plot more, use check_plot=2
%   force_beyond_1000km: =1 to claculate all distances precisely, even for
%       points >1000km from coast (default=0)
%   check_inpolygon: if=1, set distance negative if inside the polygon (i.e. on land)
%       if=2, set distance negative if outside the polygon (i.e. on sea)
%       if=3, set distance to 0 if outside the polygon (i.e. on sea) 
%       if check_inpolygon<0, only the points closer than
%       abs(check_inpolygon) [km] are checked and returned (see oputput
%       arguments lon lat in this case. This options speeds up the
%       inpolygon search substantially.
%       (default =0)
%       (slow for large data if no onLand vector is provided!)
%   onLand: vector of on-land mask (1= on land, 0 = on sea), same length as
%       lon & lat. This significantly speeds up inpolygon
% OUTPUTS:
%   distance_km: distance to coast in km for each lat/lon
%   lon and lat: same as on input, except for check_inpolygon<0, whre only
%       the points closer than abs(check_inpolygon) [km] are returned
%   onLand: same as on input, NaN if not provided and not computed.
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141225, initial
% David N. Bresch, david.bresch@gmail.com, 20150514, progress indication for more than 1000 points added
% David N. Bresch, david.bresch@gmail.com, 20150514, speedup factor ten or more implemented
% David N. Bresch, david.bresch@gmail.com, 20150515, check_inpolygon implemented
% David N. Bresch, david.bresch@gmail.com, 20170208, parfor implemented
% David N. Bresch, david.bresch@gmail.com, 20171230, climada_progress2stdout and enabled for multiple shapes
% Samuel Eberenz, eberenz@posteo.eu, 20180209, add inpolygon options to exclude points on sea and possible input onLand
%-

distance_km=[];

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('lon','var'),return;end
if ~exist('lat','var'),return;end
if ~exist('check_plot','var'),check_plot=0;end
if ~exist('force_beyond_1000km','var'),force_beyond_1000km=0;end
if ~exist('check_inpolygon','var'),check_inpolygon=0;end

% locate the module's data
%module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% PARAMETERS


% check for the map_shape_file
if ~exist(climada_global.coastline_file,'file')
    % try to re-create it
    shapes=climada_shaperead('SYSTEM_COASTLINE');
end

if ~exist(climada_global.coastline_file,'file')
    % it does definitely not exist
    fprintf('ERROR %s: file with coastline information not found: %s\n',mfilename,climada_global.coastline_file);
    fprintf(' - consider installing climada module country_risk from\n');
    fprintf(['   <a href="https://github.com/davidnbresch/climada_module_country_risk">'...
        'climada_module_country_risk</a> from Github.\n'])
    return
end

load(climada_global.coastline_file) % contains coastline as 'Point'

cos_lat=cos(lat./180.*pi);
distance_km=cos_lat*0+1e12; % init with big value
distance_km_tmp=distance_km;

n_shapes=length(shapes);
n_points=length(cos_lat);
n_shapes_n_points=n_shapes*n_points;

% progress to stdout
if ~climada_global.parfor && length(cos_lat)>1000,climada_progress2stdout;end % init, see terminate below
t0            = clock;

for shape_i=1:n_shapes
    % usually one shape, but this way, it would work for multiple ones,
    % e.g. if shapes would be rather 'Line' than 'Point'
    
    if force_beyond_1000km
        eff_shp_X=shapes(shape_i).X;
        eff_shp_Y=shapes(shape_i).Y;
    else
        try
            % restrict shapes to vicinity (i.e. distances larger than 1'000 km do not matter
            minlon=min(lon);maxlon=max(lon);
            minlat=min(lat);maxlat=max(lat);
            eff_pos=find(shapes(shape_i).X>minlon-10 & shapes(shape_i).X<maxlon+10 & ...
                shapes(shape_i).Y>minlat-10 & shapes(shape_i).Y<maxlat+10);
            
            eff_shp_X=shapes(shape_i).X(eff_pos);
            eff_shp_Y=shapes(shape_i).Y(eff_pos);
        catch
            fprintf('Warning: restriction to <1000km for speedup failed\n');
            eff_shp_X=shapes(shape_i).X;
            eff_shp_Y=shapes(shape_i).Y;
        end % try to restrict
        
    end % force_beyond_1000km
    
    if climada_global.parfor
        
        parfor point_i=1:n_points
            distance_km(point_i)=min(( (eff_shp_X-lon(point_i)).*cos_lat(point_i) ).^2 + (eff_shp_Y-lat(point_i)).^2);
        end % point_i
        
    else
        
        for point_i=1:n_points
            
            % next line eats up almost all time
            %dist2=min(( (eff_shp_X-lon(point_i)).*cos_lat(point_i) ).^2 + (eff_shp_Y-lat(point_i)).^2);
            %distance_km(point_i)=min(distance_km(point_i),dist2);
            distance_km(point_i)=min(( (eff_shp_X-lon(point_i)).*cos_lat(point_i) ).^2 + (eff_shp_Y-lat(point_i)).^2);
            
            n_points_proc     = point_i+(shape_i-1)*point_i;
            climada_progress2stdout(n_points_proc,n_shapes_n_points,10000,'points'); % update
            
        end % point_i
        
    end % parfor
    
    if abs(check_inpolygon)>0 % differentiate between sea and land
        
        if check_inpolygon<0 % special case, only keep points within abs(check_inpolygon) range
            check_dist=(abs(check_inpolygon)/111.12)^2; % convert, see conversion below
            pos=find(distance_km<=check_dist);
            distance_km=distance_km(pos);
            lon=lon(pos);lat=lat(pos);
        end
        if ~(exist('onLand','var') && length(onLand)==length(lon))
            fprintf('\n onLand not provided or in the wrong format:\n Running inpolygon. This can take a while...\n');
            onLand=inpolygon(lon,lat,shapes(shape_i).X,shapes(shape_i).Y); %inpolygon, slow
        end
        onLand = boolean(onLand);
        distance_km(onLand)=-distance_km(onLand); % set points on land negative...
        switch abs(check_inpolygon)
            case 2 % invert to make points on sea negative
                distance_km=-distance_km;
            case 3 % invert and set points on sea to 0
                distance_km=-distance_km;
                distance_km(distance_km<0)=0;           
        end         
    end 

    distance_km_tmp=min(distance_km_tmp,distance_km); % keep shortest distance
    
end % shape_i

distance_km=distance_km_tmp; clear distance_km_tmp % using _tmp for lisibility

if ~climada_global.parfor && length(cos_lat)>1000,climada_progress2stdout(0);end % terminate

distance_km=sign(distance_km).*sqrt(abs(distance_km))*111.12; % convert to km (approx.)

if check_plot
    fprintf('time elapsed %f sec\n',etime(clock,t0));
    if n_shapes_n_points > 50000 && check_plot<2
        fprintf('LOTS of points to plot - do you really want this? If yes, use check_plot=2\n');
        return
    end
    climada_circle_plot(distance_km,lon,lat)
end
if ~exist('onLand','var'), onLand = NaN.*lon;
end % climada_distance2coast_km