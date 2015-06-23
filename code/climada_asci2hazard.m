function hazard = climada_asci2hazard(asci_file, row_count, utm_transformation)
% climada_asci2hazard
% MODULE:
%   climada core
% NAME:
%   climada_asci2hazard
% PURPOSE:
%   read hazard event asci files and transform to climada hazard structure, 
%   asci files can be saved in climada/data/hazard/external_model_output or 
%   climada/data/hazard/myfolder and named asci_filename1.asc, asci_filename2.asc,...
%   Please manually add the following fields: .peril_ID, .units, .comment, 
%   .orig_years, .frequency, .yyyy and .datenum. Default: Every event is set to one year, starting
%   with 1-Jan-0001, 1-Jan-0002,...
% CALLING SEQUENCE:
%   hazard=climada_asci2hazard(asci_file)
% EXAMPLE:
%   hazard=climada_asci2hazard
% INPUTS: 
% OPTIONAL INPUT PARAMETERS:
%   asci_file: prompted for if not given. Asci file is delimited by tabs
%   (\t) and has 6 rows of information (ncols, nrows, xllcorner, yllcorner,
%   cellsize, NODATA_value).
%   utm_transformation: special case 'barisal' and 'salvador' to enable
%   local coordinate system transformation to utm lat lon coordinates.
% OUTPUTS: hazard
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150313, init
% Lea Mueller, muellele@gmail.com, 20150326, changes for generalisation
% Lea Mueller, muellele@gmail.com, 20150511, row_count input added, 10 if empty
% Lea Mueller, muellele@gmail.com, 20150617, utm_tranformation added, to
%              specific for barisal coordinate transformation and salvador
% Lea Mueller, muellele@gmail.com, 20150623, bugfix if not tranfomration needed
%-

hazard = []; %init

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('asci_file','var'),asci_file=[];end
if ~exist('row_count','var'),row_count=[];end
if ~exist('utm_transformation','var'),utm_transformation='';end

if isempty(row_count),row_count=10;end
%check row_count for your specific asci-file
row_count = 6;



%% prompt for asci file if not given
if isempty(asci_file) % local GUI
    % check if preset foldet "external_model_output" exists
    asci_file=[climada_global.data_dir filesep 'hazards' filesep 'external_model_output' filesep];
    if ~exist(asci_file, 'dir')      
        asci_file=[climada_global.data_dir filesep 'hazards' filesep];
    end
    % add asci-extension
    asci_file= [asci_file '*.asc'];
    % ask for asci-filename
    [filename, pathname] = uigetfile(asci_file, 'Select asci (raster hazard event from external model):');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        asci_file=fullfile(pathname,filename);
    end
end 

% for barisal (flood asci file)
% --------------
% climada_global.data_dir = '\\CHRB1065.CORP.GWPNET.COM\homes\X\S3BXXW\Documents\lea\climada_git\climada_data';
% asci_file = [climada_global.data_dir filesep 'hazards' filesep 'Flood_Barisal' filesep 'today' filesep 'MaxInundationDepths1983.asc'];


%% read information (number of rows, columsn, xllcorner and yllcorner, etc)
row_counter = 0;
fid=fopen(asci_file,'r');
for i = 1:row_count
    line=fgetl(fid);
    if length(line)>0
       [token, remain] = strtok(line,' ');
       if ~isempty(remain)
           if strfind(token,'ncols'       ); ncols        = str2num(remain);end
           if strfind(token,'nrows'       ); nrows        = str2num(remain);end
           if strfind(token,'xllcorner'   ); xllcorner    = str2num(remain);end
           if strfind(token,'yllcorner'   ); yllcorner    = str2num(remain);end
           if strfind(token,'cellsize'    ); cellsize     = str2num(remain);end
           if strfind(token,'NODATA_value'); NODATA_value = str2num(remain);end
           row_counter = row_counter+1;
       end
    end
end
fclose(fid);


%% read asci-file
delimiter = '';
% delimiter = ' ';
% delimiter = '\t';

%% ------always to be checked manually if flipud is needed or not ------
% event_grid = dlmread(asci_file,delimiter,row_count,0);
event_grid = flipud(dlmread(asci_file,delimiter,row_count,0));
fprintf('Data was flipped upside down, please check if this is correct.\n')


%% check that size matches
if ncols~=size(event_grid,2);fprintf('Number of columns do not correspond, please check. \\n Hint: check number of header rows.\n');return;end
if nrows~=size(event_grid,1);fprintf('Number of rows do not correspond, please check. \\n Hint: check number of header rows.\\n');return;end

% set nodata values to 0
event_grid(event_grid==NODATA_value) = 0;

% %calculate lat lon corners
% xllcorner = 530285.438;
% yllcorner = 504276.750;
% cellsize  = 100.0;

switch utm_transformation
    case 'barisal'
        % only for Barisal: transformation of UTM to lat lon coordinates (including shift)
        [lon_min, lat_min] = utm2ll_shift(xllcorner, yllcorner);
        [lon_max, lat_max] = utm2ll_shift(xllcorner+cellsize*ncols, yllcorner+cellsize*nrows);
        
    case 'salvador'
        % only for El Salvador: transformation of UTM to lat lon coordinates
        [lon_min, lat_min] = utm2ll_salvador(xllcorner, yllcorner);
        [lon_max, lat_max] = utm2ll_salvador(xllcorner+cellsize*ncols, yllcorner+cellsize*nrows);  
    % original conversion from UTM to lat lon
    % [lon_min, lat_min] = btm2ll(xllcorner, yllcorner);
    % [lon_max, lat_max] = btm2ll(xllcorner+cellsize*ncols, yllcorner+cellsize*nrows); 
    
    case '' % without transformation
        lon_min = xllcorner;
        lat_min = yllcorner;
        lon_max = xllcorner+cellsize*ncols;
        lat_max = yllcorner+cellsize*nrows;
end



% create meshgrid
[X, Y ] = meshgrid(linspace(lon_min,lon_max,ncols), ...
                   linspace(lat_min,lat_max,nrows));
                
%% test figure                
% figure
% contourf(X,Y,flood_grid)
% hold on
% climada_plot_world_borders('', '', '', 1);
% cmap = climada_colormap('FL');
% colormap(cmap)
% colorbar
% % caxis([])


%% get folder name and get number of asci files/events
[pathstr,name,ext] = fileparts(asci_file);
start_no  = name(isstrprop(name,'digit'));
name_only = name(~isstrprop(name,'digit'));


files_in_folder = ls(pathstr);
read_index = zeros(1,size(files_in_folder,1));
for i = 1:size(files_in_folder,1)
    filename_i = files_in_folder(i,:);
    filename_i = filename_i(~isstrprop(filename_i,'digit'));
    if strfind(filename_i,[name_only ext]) & strfind(filename_i,'.asc') & isempty(strfind(filename_i,'.xml'))
        read_index(i) = 1;
    end
end
no_event   = sum(read_index);


%% transform to hazard-structure
% load TC example and use as template for asci-hazard
% load([climada_global.modules_dir filesep 'barisal_demo' filesep 'data' filesep 'hazards' filesep 'Barisal_BCC_hazard_TC.mat'])
hazard_example_file = [climada_global.data_dir filesep 'hazards' filesep 'TCNA_today_small.mat'];
if exist(hazard_example_file,'file')
    load(hazard_example_file)
else
    fprintf('No hazard example found to be loaded. \n')
end
hazard_ex = hazard;

% overwrite template hazard with flood information
hazard.lon = reshape(X,1,ncols*nrows);
hazard.lat = reshape(Y,1,ncols*nrows);  
hazard.centroid_ID      = 1:numel(hazard.lon);
hazard.orig_years       = no_event;
hazard.orig_event_count = no_event;
hazard.event_count      = no_event;
hazard.event_ID         = 1:no_event;
hazard.orig_event_flag  = ones(1,no_event);
hazard.yyyy             = ones(1,no_event);
hazard.mm               = ones(1,no_event);
hazard.dd               = ones(1,no_event);
hazard.intensity        = sparse(no_event,numel(hazard.lon));
hazard.name             = cell(1,no_event);
hazard.frequency        = ones(1,no_event)/no_event;
hazard.peril_ID         = 'FL';
hazard.comment          = 'modelled by W+B';
hazard.date             = datestr(now);
hazard.units            = 'm';
hazard.orig_yearset     = [];

% filename   = 'MaxInundationDepths';
% year_start = 1983;
year_start = 0;
read_index = find(read_index);
counter    = 0;
% transform flood heights to hazard intensity
for e_i = read_index; 
    % read flood asci file
    counter            = counter+1;
    filename           = files_in_folder(e_i,:);
    [~,name,ext]       = fileparts(filename);
    fprintf('Read %s\n',[name ext]);
    event_grid         = flipud(dlmread(fullfile(pathstr,filename),delimiter,row_count,0));
    %NODATA_value       = -9999;
    event_grid(event_grid==NODATA_value) = 0;
    event_grid(isnan(event_grid)) = 0;

    % write hazard intensity into structure
    hazard.intensity(counter ,:) = reshape(event_grid,1,ncols*nrows);
    hazard.name{1,counter}       = name;
    hazard.yyyy(1,counter)       = year_start+counter;
    hazard.datenum(1,counter)    = datenum(hazard.yyyy(counter),1,1);
    
end
fprintf('Total: %d events\n------------\n',counter)

fprintf('Please check hazard data fields \n\t-.peril_ID \n\t-.units \n\t-.comment \n\t-.orig_years \n\t-.frequency \n\t-.yyyy \n\t-.datenum\n\tDefault: every event is set to one year, starting with 1-Jan-0001, 1-Jan-0002,...\n')


%save in climada/data/hazard
% hazard_filename = [climada_global.data_dir filesep 'hazards' filesep 'BCC_hazard_FL.mat'];
hazard_filename = [pathstr filesep 'hazard_' name '.mat'];
save(hazard_filename, 'hazard')
fprintf('saved hazard in %s\n',hazard_filename);


%%





    



