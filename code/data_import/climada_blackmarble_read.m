function nightlight_intensity=climada_blackmarble_read(source_folder,save_flag,retain_res)
% MODULE:
%   core
% NAME:
%	climada_blackmarble_read
% PURPOSE:
%   this script imports the data from the files of the blackmarble nightlight
%   product and converts them to 30 arc-sec resolution (for usage with LitPopulation).
%   Please download the "Full Resolution (500m) By Region - 2016 Grayscale" files first:
%   https://earthobservatory.nasa.gov/Features/NightLights/page3.php.
% CALLING SEQUENCE:
%   [LitPopulation, gpw_index, gpw_lat, gpw_lon] = climada_LitPopulation_import
%   nightlight_intensity=climada_blackmarble_read(source_folder,save_flag)
% EXAMPLE:
%   nightlight_intensity=climada_blackmarble_read
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   source_folder: path were the BM Tiff files are saved. Prompted if invalid
%       or empty.
%   save_flag: if set =1 (default), the BM data is saved to the country risk module
%       data folder.
%   retain_res: if set =1, the resolution of the data is not converted and
%       retained at 15 arc-sec (like the input data).
% OUTPUTS:
%   nightlight_inensity: The nightlight intensity per pixel in a column
%   vector. Scale: 0 (no light) to 255 (brightest). 30 arc-sec resolution ~1km
%   (or 15 arc-sec ~0.5km if retain_res switch is used).
% RESTRICTIONS:
% MODIFICATION HISTORY:
% Thomas R??sli, thomas.roeoesli@usys.ethz.ch, init
% Dario Stocker, dario.stocker@gmail.ch, 2018, adjustment to cater for incorporation into LitPopulation routine
% Dario Stocker, dario.stocker@gmail.ch, 20180406, add option retain_res
% 

%% check folder and file names

bm_filenames = {'BlackMarble_2016_A1_geo_gray.tif', ...
    'BlackMarble_2016_A2_geo_gray.tif', ...
    'BlackMarble_2016_B1_geo_gray.tif', ...
    'BlackMarble_2016_B2_geo_gray.tif', ... 
    'BlackMarble_2016_C1_geo_gray.tif', ...
    'BlackMarble_2016_C2_geo_gray.tif', ...
    'BlackMarble_2016_D1_geo_gray.tif', ...
    'BlackMarble_2016_D2_geo_gray.tif'};


if ~exist('source_folder','var'),source_folder=[];end
if ~exist('save_flag','var'),save_flag=1;end
if ~exist('retain_res','var'),retain_res=0;end

bm_exist=0;
for i=1:length(bm_filenames)
    if exist([source_folder filesep bm_filenames{i}],'file')
        bm_exist=bm_exist+1;
    end
end

if bm_exist~=8
[source_folder] = uigetdir([], 'Please select the folder containing the Blackmarble raw data');
    if isequal(source_folder,0)
        error('No folder chosen. Operation aborted.');
    else
        if strcmp(source_folder(length(source_folder):length(source_folder)),filesep)==1
            source_folder=source_folder(1:(length(source_folder)-1));
        end
    end
    
    bm_exist=0;
    for i=1:length(bm_filenames)
        if exist([source_folder filesep bm_filenames{i}],'file')
            bm_exist=bm_exist+1;
        end
    end
    
    if bm_exist~=8
        error('The chosen folder does not contain (all) BM files. Please download them first.');
    end
    
end


%% data import
fprintf('Attempting to read BM data from source images')

for file_i = [1 3 5 7] % files A1, B1, C1, D1
    
    % first file
    fprintf('.')
    [tile_1, ~, ~] = geotiffread([source_folder filesep bm_filenames{file_i}]); % read file X1
    
    if all(all(tile_1(:,:,3)==tile_1(:,:,2))) && all(all(tile_1(:,:,3)==tile_1(:,:,1))) % make it smaller
        tile_1 = tile_1(:,:,1);
    end
    
    if retain_res~=1
        tile_1_temp = imresize(double(tile_1), 0.5, 'bilinear');
    else
        tile_1_temp = tile_1;
    end
        
    clearvars tile_1;
    fprintf('.')
    
    % second file
    [tile_2, ~, ~] = geotiffread([source_folder filesep bm_filenames{file_i+1}]); % read file X2
    tile_2 = tile_2(:,:,1);
    
    if retain_res~=1
        tile_2_temp = imresize(double(tile_2), 0.5, 'bilinear');
    else
        tile_2_temp = tile_2;
    end
    
    clearvars tile_2;
    fprintf('.')

    % join files
    if retain_res~=1
        tiles_redim=sparse(reshape([tile_1_temp; tile_2_temp],[(numel(tile_1_temp)+numel(tile_2_temp)) 1]));
        clearvars tile_1_temp tile_2_temp;
    else
        tiles_redim=reshape([tile_1_temp; tile_2_temp],[(numel(tile_1_temp)+numel(tile_2_temp)) 1]);
        clearvars tile_1_temp tile_2_temp;
    end

    % add files to nightlight_intensity
    if file_i==1
        nightlight_intensity= [tiles_redim];
        clearvars tiles_redim;
    else
        nightlight_intensity= [nightlight_intensity; tiles_redim];
        clearvars tiles_redim;
    end
end

fprintf('.\n')

clearvars tile_*;

if retain_res==1
    target_res=15;
    eval(['blackmarble_lon = @(x)(-180+((1/', num2str(3600/target_res), ')/2)+((1/', num2str(3600/target_res), ')*floor((double(x)-1)/', num2str(180*(3600/target_res)), ')));']);
    eval(['blackmarble_lat = @(x)(90-((1/', num2str(3600/target_res), ')/2)-(1/', num2str(3600/target_res), ')*(mod(double(x)-1,', num2str(180*(3600/target_res)), ')));']);
    eval(['blackmarble_ind = @(lat_min,lat_max,lon_min,lon_max)(uint32(interp1([1 2], [linspace((((min([(floor(((max([lon_min-(((1/', num2str(3600/target_res), ')/2)) -180]))-(-180))/(1/', num2str(3600/target_res), '))+1) ', num2str(360*(3600/target_res)), ']))-1)*(180/(1/', num2str(3600/target_res), '))+(max([(ceil((90-(min([lat_max+(((1/', num2str(3600/target_res), ')/2)) 90])))/(1/', num2str(3600/target_res), '))) 1]))), (((max([(ceil(((min([lon_max+(((1/', num2str(3600/target_res), ')/2)) 180]))-(-180))/(1/', num2str(3600/target_res), '))) 1]))-1)*(180/(1/', num2str(3600/target_res), '))+(max([(ceil((90-(min([lat_max+(((1/', num2str(3600/target_res), ')/2)) 90])))/(1/', num2str(3600/target_res), '))) 1]))), ((max([(ceil(((min([lon_max+(((1/', num2str(3600/target_res), ')/2)) 180]))-(-180))/(1/', num2str(3600/target_res), '))) 1]))-(min([(floor(((max([lon_min-(((1/', num2str(3600/target_res), ')/2)) -180]))-(-180))/(1/', num2str(3600/target_res), '))+1) ', num2str(360*(3600/target_res)), ']))+1)); linspace((((min([(floor(((max([lon_min-(((1/', num2str(3600/target_res), ')/2)) -180]))-(-180))/(1/', num2str(3600/target_res), '))+1) ', num2str(360*(3600/target_res)), ']))-1)*(180/(1/', num2str(3600/target_res), '))+(min([(ceil((90-(max([lat_min-(((1/', num2str(3600/target_res), ')/2)) -90])))/(1/', num2str(3600/target_res), '))) ', num2str(180*(3600/target_res)), ']))), (((max([(ceil(((min([lon_max+(((1/', num2str(3600/target_res), ')/2)) 180]))-(-180))/(1/', num2str(3600/target_res), '))) 1]))-1)*(180/(1/', num2str(3600/target_res), '))+(min([(ceil((90-(max([lat_min-(((1/', num2str(3600/target_res), ')/2)) -90])))/(1/', num2str(3600/target_res), '))) ', num2str(180*(3600/target_res)), ']))), ((max([(ceil(((min([lon_max+(((1/', num2str(3600/target_res), ')/2)) 180]))-(-180))/(1/', num2str(3600/target_res), '))) 1]))-(min([(floor(((max([lon_min-(((1/', num2str(3600/target_res), ')/2)) -180]))-(-180))/(1/', num2str(3600/target_res), '))+1) ', num2str(360*(3600/target_res)), ']))+1))], linspace(1, 2, ((min([(ceil((90-(max([lat_min-(((1/', num2str(3600/target_res), ')/2)) -90])))/(1/', num2str(3600/target_res), '))) ', num2str(180*(3600/target_res)), ']))-(max([(ceil((90-(min([lat_max+(((1/', num2str(3600/target_res), ')/2)) 90])))/(1/', num2str(3600/target_res), '))) 1]))+1)))));']);
end

fprintf('BM images imported\n');

%% save the file to climada_data
if save_flag==1
    module_data_dir=[fileparts(fileparts(which('centroids_generate_hazard_sets'))) filesep 'data'];
    if retain_res ~=1
        save([module_data_dir filesep 'BlackMarble_2016_geo_gray_30arcsec.mat'],'nightlight_intensity','-v7.3');
    else
        save([module_data_dir filesep 'BlackMarble_2016_geo_gray_15arcsec.mat'],'nightlight_intensity','blackmarble_lat','blackmarble_lon','blackmarble_ind','-v7.3');
    end
end

end