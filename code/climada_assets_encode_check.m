function climada_assets_encode_check(assets)
% climada assets encode
% NAME:
%   climada_assets_encode_check
% PURPOSE:
%   check an encoded assets or entity structure, i.e. whether the
%   coordinates in the structure map well to the hazard centroids
%
%   eoncoding means: map read data points to calculation centroids of
%   hazard event set, see climada_assets_encode
% CALLING SEQUENCE:
%   assets=climada_assets_encode_check(assets)
% EXAMPLE:
%   climada_assets_encode_check(climada_entity_load)
% INPUTS:
%   assets: a read assets OR an entity structure, see climada_entity_read
%       > prompted for if empty (promting for an entity, the assets within
%       are then taken)
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   a plot, showing the encoding
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141219, initial
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('assets','var'),assets=[];end

% PARAMETERS
%
% marker size for asset and centroid locations
MarkerSize=5; % default=5

% prompt for assets (entity) if not given
if isempty(assets) % local GUI
    entity_file=[climada_global.data_dir filesep 'entities' filesep '*.mat'];
    [filename, pathname] = uigetfile(entity_file, 'Select entity to check:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_file=fullfile(pathname,filename);
        load(entity_file) % loads entity
        assets=entity; % see below, entity_passed_on_input
    end
end

if isfield(assets,'assets') % an entity instead of assets passed
    entity=assets; % store
    assets=assets.assets; % assign
end

if ~isfield(entity.assets,'hazard')
    fprintf('Note: entity not encoded yet, aborted. Consider climada_assets_encode\n');
    return
end

if ~exist(entity.assets.hazard.filename,'file')
    fprintf('Error: hazard not found, aborted (%s)\n',entity.assets.hazard.filename);
    return
end

load(entity.assets.hazard.filename)

n_assets=length(assets.Longitude);

plot(entity.assets.Longitude,entity.assets.Latitude,'or','MarkerSize',MarkerSize);
hold on
axis equal
plot(hazard.lon,hazard.lat,'xb','MarkerSize',MarkerSize);
legend({'assets','centroids'})
for asset_i=1:n_assets
    plot([entity.assets.Longitude(asset_i) hazard.lon(entity.assets.centroid_index(asset_i))],...
        [entity.assets.Latitude(asset_i) hazard.lat(entity.assets.centroid_index(asset_i))],'-g');
end % asset_i

climada_plot_world_borders(2,'','',1);

end