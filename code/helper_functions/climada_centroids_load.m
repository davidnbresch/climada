function centroids=climada_centroids_load(centroids_file)
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
%   centroids_file: the filename (with path, optional) of previously saved centroids, see
%       climada_centroids_read
%       Works also if the file contains an entity.
%       If no path provided, default path ../data/system is used (and name
%       can be without extension .mat and even without _centroids.mat)
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   centroids_out: a struct, see e.g. climada_centroids_read for details
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20130719
% David N. Bresch, david.bresch@gmail.com, 20150804, allow for name without path on input
% David N. Bresch, david.bresch@gmail.com, 20150817, climada_global.centroids_dir
% David N. Bresch, david.bresch@gmail.com, 20160516, allow for filename without _centroids
%-

centroids=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('centroids_file','var'),centroids_file=[];end

% PARAMETERS
%

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
if isempty(fP),centroids_file=[climada_global.centroids_dir filesep fN fE];end

if ~exist('centroids_file','file') % try also appending '_centroids'
    [fP,fN,fE]=fileparts(centroids_file);
    fN=[fN '_centroids'];
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