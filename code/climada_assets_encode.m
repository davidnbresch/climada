function [assets,hazard] = climada_assets_encode(assets,hazard)
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
%       > prompted for if empty (promting for an entity, the assets within
%       are then taken - in this case, instead of assets, the entity is
%       returned in 'assets')
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   the encoded assets, means locations mapped to calculation centroids
%       new field assets.centroid_index added
%       NOTE: in case an entity instead of assets was passed on input, the
%       output is also the entity
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091227
% David N. Bresch, david.bresch@gmail.com, 20100107, revised, changed from entity.assets to assets
% David N. Bresch, david.bresch@gmail.com, 20141127, allows for assets OR entity as input
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('assets','var'),assets=[];end
if ~exist('hazard','var'),hazard=[];end

% PARAMETERS
%
% whether we print all encoded centroids (=1) or not (=0), rather to TEST
verbose=0; % default =0

% prompt for assets (entity) if not given
if isempty(assets) % local GUI
    entity_file=[climada_global.data_dir filesep 'entities' filesep '*.mat'];
    [filename, pathname] = uigetfile(entity_file, 'Select entity to re-encode:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_file=fullfile(pathname,filename);
        load(entity_file) % loads entity
        assets=entity; % see below, entity_passed_on_input
    end
end

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

if isfield(assets,'assets') % an entity instead of assets passed
    entity_passed_on_input=1;
    entity=assets; % store
    assets=assets.assets; % assign
else
    entity_passed_on_input=0;
end

% start encoding
n_centroids=length(assets.Value);

if climada_global.waitbar,h = waitbar(0,sprintf('Encoding %i records...',n_centroids));end

for centroid_i=1:n_centroids
    if climada_global.waitbar,waitbar(centroid_i/n_centroids,h);end
    
    dist_m=climada_geo_distance(assets.Longitude(centroid_i),assets.Latitude(centroid_i),hazard.lon,hazard.lat);
    [min_dist,min_dist_index] = min(dist_m);
    assets.centroid_index(centroid_i)=min_dist_index;
    if verbose,fprintf('%f/%f --> %f/%f\n',assets.Longitude(centroid_i),assets.Latitude(centroid_i),hazard.lon(min_dist_index),hazard.lat(min_dist_index));end
end % centroid_i
if climada_global.waitbar,close(h);end % close waitbar

assets.hazard.filename=hazard.filename;
assets.hazard.comment=hazard.comment;

if entity_passed_on_input
    entity=rmfield(entity,'assets');
    entity.assets=assets; % assign re-encoded assets
    % and pass on output:
    assets=entity;
end

return