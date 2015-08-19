function centroids = climada_centroids_read(centroids_filename, centroids_save_file, visualize, add_regular_grid)
% climada measures read import
% NAME:
%   climada_centroids_read
% PURPOSE:
%   read the Excel file with the list of measures
% CALLING SEQUENCE:
%   centroids = climada_centroids_read(centroids_filename)
% EXAMPLE:
%   centroids = climada_centroids_read
%   centroids = climada_centroids_read('','',1) % to plot
% INPUTS:
%   centroids_filename: the filename of the Excel file with the centroids
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   centroids_save_file: filename for saving of centroids in
%       ...\climada\system\... (default is Excel filename with ext .mat)
%       'NO_SAVE' to suppress saving centroids
%       'PROMPT' to prompt for via file dialog
%   visualize: whether we plot the centroids on a map (=1) or not (=0, default)
%   add_regular_grid: add a regular grid for plotting purposes (default=1)
% OUTPUTS:
%   centroids: a structure, with 
%       Longitude  (1,:): the longitudes   
%       Latitude   (1,:): the latitudes   
%       centroid_ID(1,:): a unique ID for each centroid, simplest: 1:length(Longitude)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091229
% Lea Mueller, 20110718
% David N. Bresch, david.bresch@gmail.com, 20120505, cleanup
% David N. Bresch, david.bresch@gmail.com, 20150819, climada_global.centroids_dir and add_regular_grid as input parameter
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

centroids = [];

% poor man's version to check arguments
if ~exist('centroids_filename','var'),  centroids_filename = []; end
if ~exist('centroids_save_file','var'), centroids_save_file= []; end
if ~exist('visualize','var'),           visualize          = 0 ; end
if ~exist('add_regular_grid','var'),    add_regular_grid   = 1 ; end

% PARAMETERS
%
grid_extent     = 5; % how many degrees extended grid
grid_resolution = 1; % regular grids resolution in degree

% prompt for centroids_filename if not given
if isempty(centroids_filename) % local GUI
    centroids_filename=[climada_global.centroids_dir filesep '*.xls'];
    [filename, pathname] = uigetfile(centroids_filename, 'Select centroids file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        centroids_filename=fullfile(pathname,filename);
    end
end

% complete path, if missing
[fP,fN,fE]=fileparts(centroids_filename);
if isempty(fP),centroids_filename=[climada_global.centroids_dir filesep fN fE];end

centroids  = climada_xlsread('no',centroids_filename,'centroids');

if isfield(centroids,'Longitude'),centroids.lon=centroids.Longitude;centroids=rmfield(centroids,'Longitude');end
if isfield(centroids,'Latitude'), centroids.lat=centroids.Latitude; centroids=rmfield(centroids,'Latitude');end

if ~isfield(centroids,'lon'),fprintf('ERROR: Longitude (or lon) needed\n');end
if ~isfield(centroids,'lat'),fprintf('ERROR: Latitude (or lat) needed\n');end
if ~isfield(centroids,'centroid_ID')
    fprintf('WARNING: centroid_ID added\n');
    centroids.centroid_ID=1:length(centroids.lon);
end

if add_regular_grid
    % now, add a coarse grid around, such that the windfields are nicely displayed
    
    minlon = min(centroids.lon);
    maxlon = max(centroids.lon);
    minlat = min(centroids.lat);
    maxlat = max(centroids.lat);
    
    fprintf('adding regular grid [%2.0f - %2.0f x %2.0f - %2.0f] ... ',...
        minlon-grid_extent,maxlon+grid_extent,minlat-grid_extent,maxlat+grid_extent);
    
    ii=length(centroids.lon);
    for lon_i=minlon-grid_extent:grid_resolution:maxlon+grid_extent
        for lat_i=minlat-grid_extent:grid_resolution:maxlat+grid_extent
            ii=ii+1;
            centroids.lon  (ii) = lon_i;
            centroids.lat   (ii) = lat_i;
            centroids.centroid_ID(ii) = centroids.centroid_ID(ii-1)+1;
            if isfield(centroids,'VALUE'),centroids.VALUE(ii)=0;end
        end
    end
    fprintf('done\n');
end

% up to 20130318, vectors were transposed, no need to do so
% centroids.lon=centroids.lon';
% centroids.lat=centroids.lat';
% centroids.centroid_ID=centroids.centroid_ID';
% if isfield(centroids,'VALUE'),centroids.VALUE=centroids.VALUE';end

if visualize
    climada_circle_plot(centroids.VALUE,centroids.lon,centroids.lat)
    set(gca,'PlotBoxAspectRatio',[(maxlat-minlat)/(maxlon-minlon) 1 1],'layer','top')
    xlabel('Longitude'); ylabel('Latitude')
end

[fP,fN]=fileparts(centroids_filename);
if isempty(centroids_save_file) % local GUI
    centroids_save_file = [climada_global.system_dir filesep fN '.mat'];
end

if strcmp(centroids_save_file,'PROMPT')
    % prompt for centroids_save_file if not given
    centroids_save_file = [climada_global.system_dir filesep fN '.mat'];
    [filename, pathname] = uiputfile(centroids_save_file, 'Save centroids as:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        centroids_save_file=fullfile(pathname,filename);
    end
elseif strcmp(centroids_save_file,'NO_SAVE')
    % no need to save centroids
    return
end

fprintf('saving centroids as %s\n',centroids_save_file);
save(centroids_save_file,'centroids');

return
