function centroids=climada_centroids_load(centroids)
% climada
% NAME:
%   climada_centroids_load
% PURPOSE:
%   load previously saved centroids (just to avoid typing long paths and
%   filenames in the cmd window)
%   Works also if the file contains an entity.
%
%   Previous call: climada_centroids_read
% CALLING SEQUENCE:
%   centroids_out=climada_centroids_load(centroids_file)
% EXAMPLE:
%   centroids_out=climada_centroids_load(centroids_file)
% INPUTS:
%   entity: the filename (and path, optional) of a previously saved centroids
%       structure. If no path provided, default path ../data/centroids is used
%       (and name can be without extension .mat or even without _entity.mat)
%       > promted for if empty
%       OR: a centroids structure, in which cas it is just returned (to allow
%       calling climada_centroids_load anytime, see e.g. climada_EDS_calc)
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   centroids_out: a struct, see e.g. climada_centroids_read for details
% MODIFICATION HISTORY:
% david.bresch@gmail.com, 20130719
% david.bresch@gmail.com, 20150804, allow for name without path on input
% david.bresch@gmail.com, 20150817, climada_global.centroids_dir
% david.bresch@gmail.com, 20160516, allow for filename without _centroids
% david.bresch@gmail.com, 20160528, fix for .mat extension
% david.bresch@gmail.com, 20160703, same full flexibility as climada_entity_load
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('centroids','var'),centroids=[];end

% if already a complete hazard, return
if isstruct(centroids)
    
    if isfield(centroids,'assets')
        % centroids contains in fact an entity
        entity=centroids; centroids=[]; % silly switch, but fastest
        centroids.lat =entity.assets.lat;
        centroids.lon=entity.assets.lon;
        centroids.centroid_ID=1:length(entity.assets.lon);
        % treat optional fields
        if isfield(entity.assets,'distance2coast_km'),centroids.distance2coast_km=entity.assets.distance2coast_km;end
        if isfield(entity.assets,'elevation_m'),centroids.elevation_m=entity.assets.elevation_m;end
        if isfield(entity.assets,'country_name'),centroids.country_name=entity.assets.country_name;end
        if isfield(entity.assets,'admin0_name'),centroids.admin0_name=entity.assets.admin0_name;end
        if isfield(entity.assets,'admin0_ISO3'),centroids.admin0_ISO3=entity.assets.admin0_ISO3;end
        if isfield(entity.assets,'admin1_name'),centroids.admin1_name=entity.assets.admin1_name;end
        if isfield(entity.assets,'admin1_code'),centroids.admin1_code=entity.assets.admin1_code;end
        clear entity
    end

    return % already a hazard
else
    centroids_file=centroids;centroids=[];
    % from now on, centroids_file is the input and centroids will be output
end

% prompt for centroids_file if not given
if isempty(centroids_file) % local GUI
    centroids_file=[climada_global.centroids_dir filesep '*.mat'];
    [filename, pathname] = uigetfile(centroids_file, 'Load centroids:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        centroids_file=fullfile(pathname,filename);
    end
end

% complete path, if missing
[fP,fN,fE]=fileparts(centroids_file);
if isempty(fP),fP=[climada_global.data_dir filesep 'centroids'];end
if isempty(fE),fE='.mat';end
centroids_file=[fP filesep fN fE];
if ~exist(centroids_file,'file')
    [fP,fN,fE]=fileparts(centroids_file);
    fN=[fN '_centroids']; % append _entity
    centroids_file=[fP filesep fN fE];
end

try
    load(centroids_file) % contains centroids
    
    centroids.filename=centroids_file;
    
    if exist('entity','var') % the file contains an entity, not centroids
        centroids.lat=entity.assets.lat;
        centroids.lon=entity.assets.lon;
        centroids.centroid_ID=1:length(centroids.lon);
        if isfield(entity.assets,'admin0_name'),centroids.admin0_name=entity.assets.admin0_name;end
        if isfield(entity.assets,'admin0_ISO3'),centroids.admin0_ISO3=entity.assets.admin0_ISO3;end
        if isfield(entity.assets,'admin1_name'),centroids.admin1_name=entity.assets.admin1_name;end
    end
    
catch
    fprintf('Error: file not found (%s, or other error)\n',centroids_file);
    centroids=[];
end % try

end % climada_centroids_load