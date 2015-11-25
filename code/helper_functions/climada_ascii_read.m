function output = climada_ascii_read(asci_file,save_file,check_plot,delim)
% climada_ascii_read
% MODULE:
%   climada core
% NAME:
%   climada_ascii_read
% PURPOSE:
%   read asci file and store as struct with the following fields: .lon,
%   .lat, .value, .comment
% CALLING SEQUENCE:
%   output = climada_ascii_read(asci_file,save_file,check_plot,delim)
% EXAMPLE:
%   output = climada_ascii_read(asci_file)
% INPUTS: 
% OPTIONAL INPUT PARAMETERS:
%   asci_file: prompted for if not given. Asci file is delimited by tabs
%   (\t) and has 6 rows of information (ncols, nrows, xllcorner, yllcorner,
%   cellsize, NODATA_value).
% OUTPUTS: output structure with fields .lon, .lat, .value, .comment
% MODIFICATION HISTORY:
% Gilles Stassen, gillesstassen@hotmail.com, 20150511, init
%-

output = []; %init

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('asci_file',  'var'),       asci_file=[];     end
if ~exist('delim',      'var'),       delim='';         end
if ~exist('save_flag',  'var'),       save_file='';     end
if ~exist('check_plot', 'var'),       check_plot=0;     end

% the module's data folder:
module_data_dir = [fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];
asci_dir        = [module_data_dir filesep];

% prompt for asci file if not given
if isempty(asci_file) % local GUI
    % check if preset foldet "external_model_output" exists
    %asci_dir=[climada_global.data_dir filesep 'hazards' filesep 'external_model_output' filesep];
    if ~exist(asci_dir, 'dir')      
        asci_dir=[climada_global.data_dir filesep];
    end
    % add asci-extension
    asci_dir= [asci_dir '*.asc'];
    % ask for asci-filename
    [fN, pN] = uigetfile(asci_dir, 'Select asci file:');
    if isequal(fN,0) || isequal(pN,0)
        return; % cancel
    else
        asci_file=fullfile(pN,fN);
    end
end 

[fP,fN,fE] = fileparts(asci_file);

% read information (number of rows, columsn, xllcorner and yllcorner, etc)
fprintf('reading %s asci file... ',fN)
row_count = 0;
fid=fopen(asci_file,'r');
for i = 1:10
    line=fgetl(fid);
    if length(line)>0
       [token, remain] = strtok(line,' ');
       if isempty(str2num(token)) && ~isempty(str2num(remain))
           if strfind(token,'ncols'       ); ncols        = str2num(remain);end
           if strfind(token,'nrows'       ); nrows        = str2num(remain);end
           if strfind(token,'xllcorner'   ); xllcorner    = str2num(remain);end
           if strfind(token,'yllcorner'   ); yllcorner    = str2num(remain);end
           if strfind(token,'cellsize'    ); cellsize     = str2num(remain);end
           if strfind(token,'NODATA_value'); NODATA_value = str2num(remain);end
           row_count = row_count+1;
       end
    end
end
fclose(fid);

% read asci-file
data_grid = flipud(dlmread(asci_file,delim,row_count,0));

fprintf('done\n')

% check that size matches
if ncols~=size(data_grid,2);fprintf('Number of columns do not correspond, please check.\n');return;end
if nrows~=size(data_grid,1);fprintf('Number of rows do not correspond, please check.\n');return;end

% set nodata values to 0
data_grid(data_grid==NODATA_value)  = NaN;
data_grid(isnan(data_grid))         = NaN;

lon_min = xllcorner; lat_min = yllcorner;
lon_max = xllcorner+cellsize*ncols; lat_max = yllcorner+cellsize*nrows;

% create meshgrid
[X, Y ] = meshgrid(linspace(lon_min,lon_max,ncols),linspace(lat_min,lat_max,nrows));
                
% figure    
if check_plot
    figure('color','w')
    imagesc(unique(X),unique(Y),data_grid);
    set(gca,'Ydir','normal')
    hold on
    colormap(bone)
    colorbar
end


% construct output
output.lon      = reshape(X,1,ncols*nrows);
output.lat      = reshape(Y,1,ncols*nrows);  
output.value    = zeros(1,numel(output.lon));
output.comment  = strrep(fN,'_',' ');


% write hazard intensity into structure
output.value(1,:) = reshape(data_grid,1,ncols*nrows);

if ~isempty(save_file)
    % save
    if save_file ==1;
        save_file = [fP filesep fN '.mat']; % auto save location
    end
    save(save_file, 'output')
    fprintf('saved .mat file in %s\n',save_file);
end

