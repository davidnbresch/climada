function hazard = climada_tc_hazard_set(tc_track, hazard_set_file, centroids)
% climada TC hazard event set generate
% NAME:
%   climada_tc_hazard_set
% PURPOSE:
%   generate a tc (tropical cyclone) hazard event set
%   previous: likely climada_random_walk
%   next: diverse
% CALLING SEQUENCE:
%   res=climada_tc_hazard_set(tc_track,hazard_set_file)
% EXAMPLE:
%   res=climada_tc_hazard_set(tc_track)
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   tc_track: a TC track structure, or a filename of a saved one
%       details: see e.g. climada_tc_random_walk
%       > promted for if not given
%   hazard_set_file: the name and path of the hazard set file
%       > promted for if not given
%   centroids: the variable grid centroids (see climada_centroids_read)
%       a structure with
%           Longitude(1,:): the longitudes   
%           Latitude(1,:): the latitudes   
%           centroid_ID(1,:): a unique ID for each centroid, simplest: 1:length(Longitude)
%       or a .mat-file which contains a centroids struct (saved by
%       climada_centroids_read) or the filename of an Excel file (the original
%       input to climada_centroids_read) which holds the centroids, in
%       which case climada_centroids_read is called.
%       > promted for .mat or .xls filename if not given
%       NOTE: if you then select Cancel, a regular default grid is used, see hard-wired definition in code
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
%       matrix_density: the density of the sparse array hazard.arr
%       windfield_comment: a free comment, not in all hazard event sets
%       filename: the filename of the hazard event set (if passed as a
%           struct, this is often useful)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20090729
% David N. Bresch, david.bresch@gmail.com, 20130506, centroids filename handling improved
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
hazard_reference_year = climada_global.present_reference_year; % default for present hazard is normally 2010

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
        hazard_set_file = fullfile(pathname,filename);
    end
else
    %%hazard_set_file = [climada_global.data_dir filesep 'hazards' filesep hazard_set_file];
end

% prompt for centroids if not given
if isempty(centroids) % local GUI
    centroids_default    = [climada_global.system_dir filesep '*.mat'];
    %%[filename, pathname] = uigetfile(centroids_default,'Select centroids:');
    [filename, pathname] = uigetfile({'*.mat;*.xls'},'Select centroids (.mat or .xls):',centroids_default);    
    if isequal(filename,0) || isequal(pathname,0)
        % TEST centroids
        fprintf('WARNING: Special mode, TEST centroids grid created in %s\n',mfilename);
        ii=0;
        for lon_i=-100:1:-50
            for lat_i=20:1:50
                ii=ii+1;
                centroids.Longitude(ii)=lon_i;        
                centroids.Latitude(ii)=lat_i;
            end
        end
        centroids.centroid_ID=1:length(centroids.Longitude);
    else
        centroids_file=fullfile(pathname,filename);
        [fP,fN,fE]=fileparts(centroids_file);
        if strcmp(fE,'.xls')
            fprintf('reading centroids from %s\n',centroids_file);
            centroids=climada_centroids_read(centroids_file);
        else
            centroids=centroids_file;
        end
        
    end
end
    
if ~isstruct(centroids) % load, if filename given
    centroids_file=centroids;centroids=[];
    fprintf('centroids read from %s\n',centroids_file);
    load(centroids_file); % contains centrois as a variable
end


min_year   = tc_track(1).yyyy(1);
max_year   = tc_track(end).yyyy(end);
orig_years = max_year - min_year+1;
% fill the hazard structure
hazard.reference_year   = hazard_reference_year;
hazard.lon              = centroids.Longitude;
hazard.lat              = centroids.Latitude;
hazard.centroid_ID      = centroids.centroid_ID;
hazard.orig_years       = orig_years;
hazard.orig_event_count = 0; % init
hazard.event_count      = length(tc_track);
hazard.event_ID         = 1:hazard.event_count;
hazard.orig_event_flag  = zeros(1,hazard.event_count);

% allocate the hazard array (sparse, to manage memory)
hazard.arr = spalloc(hazard.event_count,length(hazard.lon),...
                     ceil(hazard.event_count*length(hazard.lon)*hazard_arr_density));

t0       = clock;
msgstr   = sprintf('processing %i tracks',length(tc_track));
fprintf('%s (updating waitbar with estimation of time remaining every 100th track)\n',msgstr);
h        = waitbar(0,msgstr);
mod_step = 10; % first time estimate after 10 tracks, then every 100
for track_i=1:length(tc_track)
    
    % calculate wind for every centroids, equal timestep within this routine  
    res                             = climada_tc_windfield(tc_track(track_i),centroids,1,1,check_plot); 
    %res                             = climada_tc_windfield_fast(tc_track(track_i),centroids,1,1,check_plot);
    hazard.arr(track_i,:)           = res.gust;
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
    
    if mod(track_i,mod_step)==0
        mod_step          = 100;
        t_elapsed_track   = etime(clock,t0)/track_i;
        tracks_remaining  = length(tc_track)-track_i;
        t_projected_track = t_elapsed_track*tracks_remaining;
        msgstr            = sprintf('est. %3.2f min left (%i/%i tracks)',t_projected_track/60, track_i, length(tc_track));
        waitbar(track_i/length(tc_track),h,msgstr); % update waitbar
    end

end %track_i
close(h); % dispose waitbar

t_elapsed = etime(clock,t0);
msgstr    = sprintf('generating %i windfields took %3.2f min (%3.2f sec/event)',length(tc_track),t_elapsed/60,t_elapsed/length(tc_track));
fprintf('%s\n',msgstr);



% number of derived tracks per original one
ens_size        = hazard.event_count/hazard.orig_event_count-1; 
event_frequency = 1/(orig_years*(ens_size+1));

% not transposed, just regular
hazard.frequency         = ones(1,hazard.event_count)*event_frequency; 
hazard.matrix_density    = nnz(hazard.arr)/numel(hazard.arr);
hazard.windfield_comment = msgstr;
hazard.peril_ID          = 'TC';
hazard.filename          = hazard_set_file;
hazard.comment           = sprintf('TCNA hazard event set, generated %s',datestr(now));
hazard.date              = datestr(now);

fprintf('saving hazard set in .../data/hazards folder as %s\n',hazard_set_file);
save(hazard_set_file,'hazard')


return