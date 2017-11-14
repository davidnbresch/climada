%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% IMPORT BLACKMARBLE %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this script imports the data from the files of the blackmarble nightlight
% product. Please download the "Full Resolution (500m) By Region - 2016
% Grayscale" files first
% (https://earthobservatory.nasa.gov/Features/NightLights/page3.php). Then
% change the variable bm_folder in the script below to direct to the folder
% where you saved the files on your computer.

% Thomas R??sli, thomas.roeoesli@usys.ethz.ch, init

%% folder and file names
bm_folder = 'D:\Documents_DATA\Nasa_nightlight\';
bm_filenames = {'BlackMarble_2016_A1_geo_gray.tif', ...
    'BlackMarble_2016_A2_geo_gray.tif', ...
    'BlackMarble_2016_B1_geo_gray.tif', ...
    'BlackMarble_2016_B2_geo_gray.tif', ...
    'BlackMarble_2016_C1_geo_gray.tif', ...
    'BlackMarble_2016_C2_geo_gray.tif', ...
    'BlackMarble_2016_D1_geo_gray.tif', ...
    'BlackMarble_2016_D2_geo_gray.tif'};
%% data import
nightlight_intensity =  zeros(21600^2*8, 1, 'uint8');
% lat = zeros(21600^2*8, 1); lon = zeros(21600^2*8, 1); does not work because of memory, use function instead:
blackmarble_lat = @(x)(mod(x-1,21600*2)+1) * -0.0041666666666666666 + 89.997916666666669 + 0.0041666666666666666;
blackmarble_lon = @(x)(floor((x-1)/(21600*2))+1) * 0.0041666666666666666 - 179.99791666666667 - 0.0041666666666666666;
blackmarble_ind = @(lat_min, lat_max, lon_min, lon_max) ((floor((lon_min-(-179.99791666666667))/0.0041666666666666666)*(21600*2))...
    +(floor((-lat_max+(89.997916666666669 + 0.0041666666666666666))/0.0041666666666666666):ceil((-lat_min+89.997916666666669+ 0.0041666666666666666)/0.0041666666666666666))')...
    +((0:1:(ceil((lon_max-(-179.99791666666667- 0.0041666666666666666))/0.0041666666666666666)-floor((lon_min-(-179.99791666666667- 0.0041666666666666666))/0.0041666666666666666)))*...
    (21600*2));
for file_i = [1 3 5 7] % files A1, B1, C1, D1
    % read file
    [tile_1, refmat_1, bbox_1] = geotiffread([bm_folder bm_filenames{file_i}]); % read file X1
    [tile_2, refmat_2, bbox_2] = geotiffread([bm_folder bm_filenames{file_i+1}]); % read file X2
    if all(all(tile_1(:,:,3)==tile_1(:,:,2))) && all(all(tile_1(:,:,3)==tile_1(:,:,1))) % make it smaller
        tile_1 = tile_1(:,:,1);
        tile_2 = tile_2(:,:,1);
    end
    
    % create grid of coordinates
%     info = geotiffinfo([bm_folder bm_filenames{file_i}]);
%     [x,y] = pixcenters(info); %same as [x,y] = pixcenters(refmat,size(A,1),size(A,2));
%     [x,y] = meshgrid(x,y);
    % fill variables
    nightlight_intensity((21600^2*(file_i-1)+1):(21600^2*(file_i+1))) = reshape([tile_1; tile_2],[21600^2*2,1]);
%     lat((21600^2*(file_i-1)+1):(21600^2*(file_i))) = y(:); % does not work because of memory
%     lon((21600^2*(file_i-1)+1):(21600^2*(file_i))) = x(:);
end
%% save the file to climada_data
module_data_dir=[fileparts(fileparts(which('centroids_generate_hazard_sets'))) filesep 'data'];
save([module_data_dir filesep 'BlackMarble_2016_geo_gray.mat'],'nightlight_intensity','blackmarble_lat','blackmarble_lon','blackmarble_ind','-v7.3');
% plot a sample of the map
figure; plotclr(blackmarble_lon(1:1000:(21600^2*8)),blackmarble_lat(1:1000:(21600^2*8)),double(nightlight_intensity(1:1000:(21600^2*8))))
