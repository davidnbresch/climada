function res = climada_tif_read(tif_file,check_plot,verbose)
% climada_tif_read
% MODULE:
%   climada code/data_import
% NAME:
%   climada_tif_read
% PURPOSE:
%   read a tif file (data and coordinates) and put into res.data, res.lon,
%   res.lat structure
%   tif file can be saved in climada/data/entities or any other folder that
%   you select throught he popup-window.
% CALLING SEQUENCE:
%   res = climada_tif_read(tif_file,check_plot,verbose)
% EXAMPLE:
%   res = climada_tif_read(tif_file,check_plot,verbose)
%   res = climada_tif_read
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
%   check_plot: set to 1 to see a figure, default is 0
%   verbose: get fprint information in the command line, default is 0
% OUTPUTS: 
%   res: a structure with 
%   .data: gridded data from tif-file
%   .lon: range of longitude (lon min and lon max)
%   .lat: range of latitude (lat min and lat max)
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20160408, init
%-

res.data = []; res.lon = []; res.lat = []; %init

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('tif_file','var'), tif_file = []; end
if ~exist('check_plot','var'), check_plot = 0; end
if ~exist('verbose','var'), verbose = 0; end

% init
if isempty(tif_file), tif_file.filename = []; tif_file.lon_lat_min_max = []; 
    tif_file.lon_lat_min_max_selection = []; tif_file.NODATA_value = []; end

if ~isfield(tif_file,'filename'), tif_file.filename = []; end
if ~isfield(tif_file,'lon_lat_min_max'), tif_file.lon_lat_min_max = []; end
if ~isfield(tif_file,'lon_lat_min_max_selection'), tif_file.lon_lat_min_max_selection = []; end
if ~isfield(tif_file,'NODATA_value'), tif_file.NODATA_value = []; end

%% prompt for tif file if not given
if isempty(tif_file.filename) % local GUI
    % check if preset foldet "external_model_output" exists
    tif_file.filename = [climada_global.data_dir filesep 'hazards' filesep 'external_model_output' filesep];
    if ~exist(tif_file.filename, 'dir')      
        tif_file.filename = [climada_global.data_dir filesep 'entities' filesep];
    end
    % add tif-extension
    tif_file.filename = [tif_file.filename '*.tif'];
    % ask for tif-filename
    [filename, pathname] = uigetfile(tif_file.filename, 'Select tif:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        tif_file.filename = fullfile(pathname,filename);
    end
end 

mat_file = strrep(tif_file.filename,'.tif','_.mat');
if exist(mat_file,'file')
    % load from previously saved .mat (binary) file
    if verbose,fprintf('Restoring %s\n',mat_file);end
    load(mat_file)
else    
    %% read the tif data
    % -------------------------------------
    if exist(tif_file.filename,'file'), res.data = imread(tif_file.filename); end
    if isempty(res.data), fprintf('ERROR: File not found.\n'); return, end

    %------always to be checked manually if flipud is needed or not ------ 
    res.data = flipud(res.data);
    fprintf('Data was flipped upside down, please check if this is correct.\n')
    
    % set filename
    res.tif_filename = tif_file.filename;
    [fP,fN] = fileparts(res.tif_filename);
    res.filename = [fP filesep fN '.mat'];
end

% set nodata values to 0
if ~isempty(tif_file.NODATA_value), res.data(res.data==tif_file.NODATA_value) = 0; end
% if ~isempty(tif_file.NODATA_value), res.data(res.data<=tif_file.NODATA_value) = 0; end 

% create coordinate range
if isempty(tif_file.lon_lat_min_max),tif_file.lon_lat_min_max = [1 size(res.data,2) 1 size(res.data,1)];end
res.lon = [tif_file.lon_lat_min_max(1) tif_file.lon_lat_min_max(2)];
res.lat = [tif_file.lon_lat_min_max(3) tif_file.lon_lat_min_max(4)];
% create coordinate meshgrid    
%[res.lon,res.lat] = meshgrid(linspace(lon_lat_min_max(1), lon_lat_min_max(2), size(res.data,2)), ...
%                             linspace(lon_lat_min_max(3), lon_lat_min_max(4), size(res.data,1)));

% % single precision to save space
% res.lon=single(res.lon);
% res.lat=single(res.lat);
% res.data=single(res.data);    

% select only specific lon/lat range
if isempty(tif_file.lon_lat_min_max_selection),tif_file.lon_lat_min_max_selection = tif_file.lon_lat_min_max; end
if any(tif_file.lon_lat_min_max_selection ~= tif_file.lon_lat_min_max)
    lon = linspace(tif_file.lon_lat_min_max(1), tif_file.lon_lat_min_max(2), size(res.data,2));
    lat = linspace(tif_file.lon_lat_min_max(3), tif_file.lon_lat_min_max(4), size(res.data,1));
    is_selected_lon = find(lon>=tif_file.lon_lat_min_max_selection(1) & lon<= tif_file.lon_lat_min_max_selection(2));
    is_selected_lat = find(lat>=tif_file.lon_lat_min_max_selection(3) & lat<= tif_file.lon_lat_min_max_selection(4));
    res.data = res.data(is_selected_lat,is_selected_lon);
    res.lon = [min(lon(is_selected_lon)) max(lon(is_selected_lon))];
    res.lat = [min(lat(is_selected_lat)) max(lat(is_selected_lat))];
end

if verbose,fprintf('Saving %s\n',res.filename);end
save(res.filename,'res'); % save as .mat (binary) file
    
    
if check_plot    
    if check_plot==1,climada_figuresize(0.4,0.6); end
    if check_plot>2,res.data(res.data>400)=NaN; end % safeguard
    imagesc([min(res.lon(:)) max(res.lon(:))],[min(res.lat(:)) max(res.lat(:))],res.data)
    %contourf(X,Y,flood_grid)
    set(gca,'YDir','normal')
    hold on
    unique_data = unique(res.data);
    cmap = jet(64);
    if numel(unique_data)<=20, cmap = jet(numel(unique_data)); cmap(1,:) = [1 1 1]; end
    colormap(cmap)
    colorbar;
    %caxis;
    
    if exist('climada_plot_world_borders','file'),climada_plot_world_borders;end
    axlim = [min(res.lon(:)) max(res.lon(:)) min(res.lat(:)) max(res.lat(:))];
    if exist('climada_figure_axis_limits_equal_for_lat_lon','file'),
        climada_figure_axis_limits_equal_for_lat_lon(axlim);
    else
        axis equal; axis(axlim);
    end
    if exist('climada_figure_scale_add','file'),climada_figure_scale_add;end
end



% 
% switch utm_transformation
%     case 'barisal'
%         % only for Barisal: transformation of UTM to lat lon coordinates (including shift)
%         [lon_min, lat_min] = utm2ll_shift(xllcorner, yllcorner);
%         [lon_max, lat_max] = utm2ll_shift(xllcorner+cellsize*ncols, yllcorner+cellsize*nrows);
%         
%     case 'salvador'
%         % special case for San Salvador, we get the lat/lon corners directly from
%         % Maxime and ignore the xllcorner, yllcorner in the asci-file
%         lon_min = -89.251;
%         lon_max = -89.163;
%         lat_min =  13.671;
%         lat_max =  13.702;
%     
%     case '' % without transformation
%         lon_min = xllcorner;
%         lat_min = yllcorner;
%         lon_max = xllcorner+cellsize*ncols;
%         lat_max = yllcorner+cellsize*nrows;
% end


%%





    



