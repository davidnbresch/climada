function hazard = climada_tc_hazard_set_exercise(tc_track, hazard_set_file, centroids)
% climada TC hazard event set generate
% NAME:
%   climada_tc_hazard_set_exercise
% PURPOSE:
%   generate a tc (tropical cyclone) hazard event set
%
%   previous: likely climada_random_walk
%   next: diverse
%
%   NOTE: code for demonstration purposes (e.g. lecture), see 
%   climada_tc_windfield for the operational code
%
% CALLING SEQUENCE:
%   res=climada_tc_hazard_set_exercise(tc_track,hazard_set_file)
% EXAMPLE:
%   res=climada_tc_hazard_set_exercise(tc_track)
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   tc_track: a TC track structure, or a filename of a saved one
%       details: see e.g. climada_tc_random_walk
%       > promted for if not given
%   hazard_set_file: the name of the hazard set file
%       > promted for if not given
%   centroids: the variable grid centroids (see climada_centroids_read)
%       a structure with
%           Longitude(1,:): the longitudes   
%           Latitude(1,:): the latitudes   
%           centroid_ID(1,:): a unique ID for each centroid, simplest: 1:length(Longitude)
%       or a file which contains the struct (saved after climada_centroids_read)
%       if you select Cancel, a regular default grid is used, see hard-wired definition in code
% OUTPUTS:
%   hazard: a struct, the hazard event set, more for tests, since the
%       hazard set is stored as hazard_set_file, see code
%       lon(centroid_i): the longitude of each centroid
%       lat(centroid_i): the latitude of each centroid
%       centroid_ID(centroid_i): a unique ID for each centroid
%       peril_ID: just an ID identifying the peril, e.g. 'TC' for
%       tropical cyclone or 'ET' for extratropical cyclone
%       comment: a free comment, normally containing the time the hazard
%           event set has been generated
%       orig_years: the original years the set is based upon
%       orig_event_count: the original events
%       event_count: the total number of events in the set, including all
%           probabilistic ones, hence event_count>=orig_event_count
%       orig_event_flag(event_i): a flag for each event, whether it's an original
%           (1) or probabilistic (0) one
%       event_ID: a unique ID for each event
%       date: the creation date of the set
%       arr(event_i,centroid_i),sparse: the hazard intensity of event_i at
%           centroid_i
%       frequency(event_i): the frequency of each event
%       matrix_density: the density of the sparse array hazard.intensity
%       windfield_comment: a free comment, not in all hazard event sets
%       filename: the filename of the hazard event set (if passed as a
%           struct, this is often useful)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20090729
% David N. Bresch, david.bresch@gmail.com, 20120404 copy from climada_tc_hazard_set
%-

hazard=[]; % init

% init global variables
global climada_global
if ~climada_init_vars,return;end

% check inputs
if ~exist('tc_track','var'),tc_track=[];end
if ~exist('hazard_set_file','var'),hazard_set_file=[];end
if ~exist('centroids','var'),centroids=[];end

% PARAMETERS
%
check_plot=0; % only for few tracks, please
%
% since we store the hazard as sparse array, we need an a-priory estimation
% of it's density
hazard_arr_density=0.03; % 3% sparse hazard array density (estimated)
%
% define the reference year for this hazard set
hazard_reference_year=climada_global.present_reference_year; % default for present hazard is normally 2010

% prompt for tc_track if not given
if isempty(tc_track) % local GUI
    tc_track             = [climada_global.data_dir filesep 'tc_tracks' filesep '*.mat'];
    tc_track_default     = [climada_global.data_dir filesep 'tc_tracks' filesep 'Select tc track .mat'];
    [filename, pathname] = uigetfile(tc_track, 'Select tc track set:',tc_track_default);
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        tc_track=fullfile(pathname,filename);
    end
end
if ~isstruct(tc_track) % load, if filename given
    tc_track_file=tc_track;tc_track=[];
    load(tc_track_file);
    vars = whos('-file', tc_track_file);
    load(tc_track_file);
    if ~strcmp(vars.name,'tc_track')
        tc_track = eval(vars.name);
        clear (vars.name)
    end
end

% prompt for hazard_set_file if not given
if isempty(hazard_set_file) % local GUI
    hazard_set_file      = [climada_global.data_dir filesep 'hazards' filesep 'TCXX_hazard.mat'];
    hazard_set_default   = [climada_global.data_dir filesep 'hazards' filesep 'Save in TCXX_hazard .mat'];
    [filename, pathname] = uiputfile(hazard_set_file, 'Save TC hazard set as:',hazard_set_default);
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard_set_file=fullfile(pathname,filename);
    end
end

% prompt for centroids if not given
if isempty(centroids) % local GUI
    centroids            = [climada_global.data_dir filesep 'system' filesep '*.mat'];
    centroids_default    = [climada_global.system_dir filesep 'Select centroids .mat'];
    [filename, pathname] = uigetfile(centroids, 'Select centroids:',centroids_default);
    if isequal(filename,0) || isequal(pathname,0)
        % TEST centroids
        ii=0;
        for lon_i=-100:1:-50
            for lat_i=20:1:50
                ii=ii+1;
                centroids.lon(ii)=lon_i;        
                centroids.lat(ii)=lat_i;
            end
        end
        centroids.centroid_ID=1:length(centroids.lon);
        %return; % cancel
    else
        centroids=fullfile(pathname,filename);
    end
end
if ~isstruct(centroids) % load, if filename given
    centroids_file=centroids;centroids=[];
    load(centroids_file);
end

min_year=tc_track(1).yyyy(1);
max_year=tc_track(end).yyyy(end);
orig_years=max_year-min_year+1;

hazard.lon=centroids.lon;
hazard.lat=centroids.lat;
hazard.centroid_ID=centroids.centroid_ID;
hazard.peril_ID='TC';
hazard.comment=sprintf('TCNA hazard event set, generated %s',datestr(now));
hazard.orig_years=orig_years;
hazard.event_count=length(tc_track);
hazard.event_ID=1:hazard.event_count;
hazard.date=datestr(now);
hazard.orig_event_count=0; % init
hazard.orig_event_flag=zeros(1,hazard.event_count);

% allocate the hazard array (sparse, to manage memory)
hazard.intensity = spalloc(hazard.event_count,length(hazard.lon),...
    ceil(hazard.event_count*length(hazard.lon)*hazard_arr_density));

t0 = clock;
msgstr=sprintf('processing %i tracks',length(tc_track));
fprintf('%s (updating waitbar with estimation of time remaining every 100th track)\n',msgstr);
if climada_global.waitbar,h = waitbar(0,msgstr);end
mod_step=10; % first time estimate after 10 tracks, then every 100
for track_i=1:length(tc_track)
    
    % calculate wind for every centroids
    res                             = climada_tc_windfield_exercise(tc_track(track_i),centroids,1,1,check_plot); % equal timestep within this routine    
    hazard.intensity(track_i,:)           = sparse(res.gust); % fill hazard array
    hazard.orig_event_count         = hazard.orig_event_count+tc_track(track_i).orig_event_flag;
    hazard.orig_event_flag(track_i) = tc_track(track_i).orig_event_flag;
    
    % if check_plot
    %     values = res.gust;
    %     values(values==0) = NaN; % suppress zero values
    %     caxis_range       = [];
    %     climada_color_plot(values,res.lon,res.lat,'none',tc_track(track_i).name,[],[],[],[],caxis_range);hold on;
    %     plot(tc_track(track_i).lon,tc_track(track_i).lat,'xk');hold on;
    %     set(gcf,'Color',[1 1 1]);
    % end
    
    if mod(track_i,mod_step)==0 && climada_global.waitbar
        mod_step=100;
        t_elapsed_track=etime(clock,t0)/track_i;
        tracks_remaining=length(tc_track)-track_i;
        t_projected_track=t_elapsed_track*tracks_remaining;
        msgstr=sprintf('est. %i seconds left (%i tracks)',ceil(t_projected_track),tracks_remaining);
        waitbar(track_i/length(tc_track),h,msgstr); % update waitbar
    end

end %track_i
if climada_global.waitbar,close(h);end % dispose waitbar

t_elapsed=etime(clock,t0);
msgstr=sprintf('generating %i windfields took %f sec (%f sec/event)\n',length(tc_track),t_elapsed,t_elapsed/length(tc_track));
fprintf('%s\n',msgstr);

% number of derived tracks per original one
ens_size        = hazard.event_count/hazard.orig_event_count-1; 
event_frequency = 1/(orig_years*(ens_size+1));

% not transposed, just regular
hazard.frequency         = ones(1,hazard.event_count)*event_frequency; 
hazard.matrix_density    = nnz(hazard.intensity)/numel(hazard.intensity);
hazard.windfield_comment = msgstr;
hazard.filename          = hazard_set_file;
hazard.reference_year    = hazard_reference_year;

fprintf('saving hazard set as %s\n',hazard_set_file);
save(hazard_set_file,'hazard')

return