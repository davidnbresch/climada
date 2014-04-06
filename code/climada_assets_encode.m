function [assets hazard] = climada_assets_encode(assets,hazard)
% climada assets encode
% NAME:
%   climada_assets_encode
% PURPOSE:
%   encode an entity (an already read assets file)
%   eoncoding means: map read data points to calculation centroids of
%   hazard event set
%
%   normally called from: climada_entity_read
% CALLING SEQUENCE:
%   assets=climada_assets_encode(assets,hazard)
% EXAMPLE:
%   assets=climada_assets_encode(assets,hazard)
% INPUTS:
%   assets: a read assets structure, see climada_entity_read
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   the encoded assets, means locations mapped to calculation centroids
%   new field assets.centroid_index added
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091227
% David N. Bresch, david.bresch@gmail.com, 20100107 revised, changed from entity.assets to assets
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('assets','var'),return;end
if ~exist('hazard','var'),hazard=[];end

% PARAMETERS
%
% whether we print all encoded centroids (=1) or not (=0), rather to TEST
verbose=0; % default =0

% prompt for hazard if not given
if isempty(hazard) % local GUI
    hazard=[climada_global.data_dir filesep 'hazards' filesep '*.mat'];
    %%hazard=[climada_global.data_dir filesep 'hazards' filesep 'Select hazard event set to encode to.mat']; % LEA
    [filename, pathname] = uigetfile(hazard, 'Select hazard event set to encode to:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard=fullfile(pathname,filename);
    end
end

% load the hazard, if a filename has been passed
if ~isstruct(hazard)
    hazard_file=hazard;hazard=[];
    load(hazard_file);
end

% start encoding
n_centroids=length(assets.Value);

h = waitbar(0,sprintf('Encoding %i records...',n_centroids));

for centroid_i=1:n_centroids
    waitbar(centroid_i/n_centroids,h)
    
    dist_m=climada_geo_distance(assets.Longitude(centroid_i),assets.Latitude(centroid_i),hazard.lon,hazard.lat);
    [min_dist,min_dist_index] = min(dist_m);
    assets.centroid_index(centroid_i)=min_dist_index;
    if verbose,fprintf('%f/%f --> %f/%f\n',assets.Longitude(centroid_i),assets.Latitude(centroid_i),hazard.lon(min_dist_index),hazard.lat(min_dist_index));end
end % centroid_i
close(h) % close waitbar

assets.hazard.filename=hazard.filename;
assets.hazard.comment=hazard.comment;

return