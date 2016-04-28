function assets = climada_tif2assets(tif_file,check_plot,verbose)
% climada_tif2assets
% MODULE:
%   climada code/helperfunctions
% NAME:
%   climada_tif2assets
% PURPOSE:
%   create climada assets structure from a tif-file, create .lon, .lat,
%   .Values as given in tif-file, transform transform tif-units to Values
%   with weights given in tif_file.tif_value and tif_file.asset_weights
% CALLING SEQUENCE:
%   assets = climada_tif2assets(tif_file,check_plot,verbose)
% EXAMPLE:
%   assets = climada_tif2assets
% INPUTS: 
% OPTIONAL INPUT PARAMETERS:
%   tif_file: a struct with the following fields, prompted for if not given
%   .filename: prompted for if not given. Tif_file is the filename, the file
%           contains raster data information.
%   .lon_lat_min_max: i.e. [99 100 2 3], define lon min, lon max, lat min, 
%           lat max for the gridded data. 
%   .lon_lat_min_max_selection: i.e. [99 99.5 2 2.5], define the subset of 
%           the data that you want with lon min, lon max, lat min, lat max
%   .NODATA_value: i.e. -9999, this data will be overwritten with 0
%   .tif_value: i.e. [0 1 2 3], values as given in tif-file
%   .asset_weights: i.e. [0 5 80 15]/100, these are the weights assigned to
%           the tif-file values, i.e. 5% for 1, 80% for 2 and 15 for 3.
%   check_plot: set to 1 to see a figure, default is 0
%   verbose: get fprint information in the command line, default is 0
% OUTPUTS: 
%   a climada assets structure, with fields .lon, .lat, .Value,
%       .Deductible, etc
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20160408, init
%-

assets = []; %init

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('tif_file','var'), tif_file = []; end
if ~exist('check_plot','var'), check_plot = 0; end
if ~exist('verbose','var'), verbose = 0; end

% make sure these two fields exist
if ~isfield(tif_file,'tif_value'), tif_file.tif_value = []; end
if ~isfield(tif_file,'asset_weights'), tif_file.asset_weights = []; end

% read tif
res = climada_tif_read(tif_file,check_plot,verbose);
if isempty(res), return, end

% init assets
assets.lon = []; assets.lat = []; assets.Value= [];
assets.Deductible = []; assets.Cover = []; assets.DamageFunID = [];
assets.Value_unit = []; assets.reference_year = []; 
assets.comment = []; assets.filename = [];

% fill asset fields
no_assets = numel(res.data);
% create mehsgrid
lon = res.lon; lat = res.lat; %init
if numel(res.lon) == 2 && any(size(res.lon) ~= size(res.data))
    [lon,lat] = meshgrid(linspace(res.lon(1), res.lon(2), size(res.data,2)), ...
                         linspace(res.lat(1), res.lat(2), size(res.data,1)));
end
assets.lon = lon(:); assets.lon = reshape(assets.lon,1,no_assets);
assets.lat = lat(:); assets.lat = reshape(assets.lat,1,no_assets);
assets.tif_Value = res.data(:); assets.tif_Value = reshape(assets.tif_Value,1,no_assets);

% transform tif-units to Values
% init
assets.Value = assets.tif_Value;
if ~isempty(tif_file.tif_value) && ~isempty(tif_file.asset_weights)
    % assign relative weights per tif_value, normally to sum up to 100%
    assets.Value = interp1(tif_file.tif_value,tif_file.asset_weights,assets.tif_Value);
    valid_assets = ismember(assets.tif_Value,tif_file.tif_value);
    assets.Value(~valid_assets) = 0;
    % unique(assets.Value) % just to check
end
assets = rmfield(assets,'tif_Value');

% save only Values greater than zero
is_positive = assets.Value>0;
assets.lon = assets.lon(is_positive); 
assets.lat = assets.lat(is_positive);
assets.Value = assets.Value(is_positive);

% fill other fields
assets.Deductible = assets.Value; assets.Cover = assets.Value;
assets.DamageFunID = ones(size(assets.Value));
Value_unit = 'USD'; 
if isfield(climada_global, 'Value_unit'), Value_unit = climada_global.Value_unit; end
assets.Value_unit = repmat({Value_unit},1,no_assets);
assets.reference_year = climada_global.present_reference_year;
    

    
if check_plot    
    if check_plot==1,climada_figuresize(0.4,0.6); end
    entity.assets = assets; 
    upper_limit_to_plot = 2*10^6;
    if numel(entity.assets.Value)>upper_limit_to_plot
        entity.assets.Value = entity.assets.Value(1:upper_limit_to_plot);
        entity.assets.lon = entity.assets.lon(1:upper_limit_to_plot);
        entity.assets.lat = entity.assets.lat(1:upper_limit_to_plot);
        fprintf('Assets contains %d locations. Due to performance reason we plot only the first %d.\n', numel(assets.Value), upper_limit_to_plot)
    end
    climada_map_plot(entity); 
end
     


