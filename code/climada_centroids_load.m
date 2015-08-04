function centroids_out=climada_centroids_load(centroids_file)
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
%       can be without extension .mat) 
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   centroids_out: a struct, see e.g. climada_centroids_read for details
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20130719
% David N. Bresch, david.bresch@gmail.com, 20150804, allow for name without path on input
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('centroids_file','var'),centroids_file=[];end

% PARAMETERS
%
% TEST
%%centroids_file=[climada_global.data_dir filesep 'system' filesep 'centroids_FortMyers.mat'];

% prompt for centroids_file if not given
if isempty(centroids_file) % local GUI
    centroids_file=[climada_global.data_dir filesep 'system' filesep '*.mat'];
    [filename, pathname] = uigetfile(centroids_file, 'Load centroids:');
    if isequal(filename,0) || isequal(pathname,0)
        centroids_out = []; return; % cancel
    else
        centroids_file=fullfile(pathname,filename);
    end
end

% complete path, if missing
[fP,fN,fE]=fileparts(centroids_file);
if isempty(fP),centroids_file=[climada_global.data_dir filesep 'system' filesep fN fE];end

load(centroids_file) % contains centroids

if exist('entity','var') % the file contains an entity, not centroids
    centroids.lat=entity.assets.lat;
    centroids.lon=entity.assets.lon;
    centroids.centroid_ID=1:length(centroids.lon);
    if isfield(entity.assets,'country_name'),centroids.country_name{1}=entity.assets.country_name;end
    if isfield(entity.assets,'admin0_name'),centroids.admin0_name{1}=entity.assets.admin0_name;end
    if isfield(entity.assets,'admin0_ISO3'),centroids.admin0_ISO3{1}=entity.assets.admin0_ISO3;end
    if isfield(entity.assets,'admin1_name'),centroids.admin1_name{1}=entity.assets.admin1_name;end
    clear entity
end

centroids_out=centroids;

return

