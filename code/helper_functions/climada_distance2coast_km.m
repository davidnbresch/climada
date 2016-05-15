function distance_km=climada_distance2coast_km(lon,lat,check_plot,force_beyond_1000km)
% climada distance km coast
% NAME:
%   climada_distance2coast
% PURPOSE:
%   calculate distance to coast in km (approx.)
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
%   check_plot: =1: show circle plot for check (default=0)
%   force_beyond_1000km: =1 to claculate all distances precisely, even for
%       points >1000km from coast (default=0)
% OUTPUTS:
%   distance_km: distance to coast in km for each lat/lon
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141225, initial
% David N. Bresch, david.bresch@gmail.com, 20150514, progress indication for more than 1000 points added
% David N. Bresch, david.bresch@gmail.com, 20150514, speedup factor ten implemented
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
distance_km=cos_lat*0+1e10; % init with large value

% progress to stdout
t0            = clock;
if length(cos_lat)>1000
    mod_step  = 100; % first time estimate after 100 points processed
    format_str= '%s';
else
    mod_step=-1;
end

n_shapes=length(shapes);
n_points=length(cos_lat);
nn=n_shapes*n_points;n_i=0;
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
    
    for ll_i=1:n_points
        
        % next line eats up almost all time
        dist2=min(( (eff_shp_X-lon(ll_i)).*cos_lat(ll_i) ).^2 + (eff_shp_Y-lat(ll_i)).^2);
        
        distance_km(ll_i)=min(distance_km(ll_i),dist2);
        
        if mod_step>0 % the progress management
            n_i=n_i+1;
            if mod(n_i,mod_step)==0
                if mod_step==100
                    mod_step=1000; % 2nd time 1000
                else
                    mod_step=10000; % later
                end
                
                t_elapsed_point   = etime(clock,t0)/n_i;
                points_remaining  = nn-n_i;
                t_projected_sec   = t_elapsed_point*points_remaining;
                if t_projected_sec<60
                    msgstr = sprintf('est. %3.0f sec left (%i/%i points)',t_projected_sec,   n_i,nn);
                else
                    msgstr = sprintf('est. %3.1f min left (%i/%i points)',t_projected_sec/60,n_i,nn);
                end
                fprintf(format_str,msgstr); % write progress to stdout
                format_str=[repmat('\b',1,length(msgstr)) '%s']; % back to begin of line
            end
        end % mod_step>0
        
    end % ll_i
    
end % shape_i

if mod_step>0,fprintf(format_str,'');end % move carriage to begin of line

distance_km=sqrt(distance_km)*111.12; % convert to km (approx.)

if check_plot
    fprintf('time elapsed %f sec\n',etime(clock,t0));
    climada_circle_plot(distance_km,lon,lat)
end

end % climada_distance2coast_km