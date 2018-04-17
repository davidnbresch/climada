function entityORassets = climada_assets_encode(entityORassets,hazard,max_encoding_distance_m,speed_up)
% climada assets encode
% NAME:
%   climada_assets_encode
% PURPOSE:
%   encode an entity (an already read assets file)
%   eoncoding means: map read data points to calculation centroids of
%   hazard event set
%   
%   Accepts both entity or assets as well as hazard or centroids as input,
%   output i therefore either entity (if entity on input) or assets (if
%   assets on input)
%
%   normally called from: climada_entity_read
%   see also: climada_assets_encode_check
% CALLING SEQUENCE:
%   entityORassets=climada_assets_encode(entityORassets,hazard,max_encoding_distance_m,speed_up)
% EXAMPLES:
%   assets=climada_assets_encode(climada_entity_load)
%   entity=climada_assets_encode(entity,hazard,45000); % high performance due to smaller encoding distance
%   entity=climada_assets_encode(entity,hazard,[],3); % high performance by maximum speed_up
% INPUTS:
%   entityORassets: an assets structure (such as entity.assets), see
%       climada_entity_read. Or just the full entity (with assets in entity.assets)
%       > prompted for if empty (promting for an entity, the assets within
%       are then taken - in this case, instead of assets, the entity is
%       returned in 'assets')
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a
%       struct) or a centroid struct (as returned by climada_centroids_load or
%       climada_centroids_read). hazard needs to have fields hazard.lon and
%       hazard.lat, centroids fields centroids.lon and centroids.lat  
%       > promted for if not given (select either a hazard event set or a
%       centroids .mat file)
%       if set to 'SKIP', do not encode, return original assets (used for
%       special cases, where this way no need for if statements prior to
%       calling climada_assets_encode)
%       SPECIAL: centroids with centroid_ID<0 (in either hazard.centroid_ID
%       or centroids.centroid_ID) are not used in encoding.
%       (this way the user can e.g. temporarily 'disable' centroids prior
%       to passing them to climada_assets_encode by simply setting their
%       centroid_ID=-1)
%       NOTE: if isfield(centroids,'peril_ID') and FL some special rules apply
% OPTIONAL INPUT PARAMETERS:
%   max_encoding_distance_m: the maximum distance to encode an asset
%       location to a centroid (in meters, e.g. 1e5 for 100km). Default
%       is climada_global.max_encoding_distance_m, or, if there is a field
%       hazard.max_encoding_distance_m.
%   speed_up: speed up encoding by using bounding boxes:
%       >0: entities are binned in geographical
%       bounding boxes of size 3x3 to 6x6 degree (depending on max. encoding distance)
%       and encoded box by box. centroids are restricted to larger boxes containing the boundary boxes 
%       with a buffer to account for assets close to the boxes' boundaries.
%       = 1: buffer= 1.1*max_encoding_distance (default). For further speed-up, you can reduce
%       max_encoding_distance_m to a sensitive value.
%       >1: faster than 1, using smaller buffers. This can lead to minor
%           errors:
%       =2: faster. centroid boxes only buffer=0.55*max_encoding_distance larger than
%           asset boxes, pretty save for evenly gridded assets and centroids.
%       >=3: buffer=0, fastest. This will most certainly omit some assets close
%           to the boxes' boundaries.
%       =0 for encoding without bounding boxes (~10 to 15 times slower,
%           should produce same results as =1, default until 20180416)
%           (no speed_up is used for small samples of less than 500 assets)
% OUTPUTS:
%   the encoded assets, means locations mapped to calculation centroids
%       new field assets.centroid_index added
%       NOTE: in case an entity instead of assets was passed on input, the
%       output is also the entity
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091227
% David N. Bresch, david.bresch@gmail.com, 20100107, revised, changed from entity.assets to assets
% David N. Bresch, david.bresch@gmail.com, 20141127, allows for assets OR entity as input
% David N. Bresch, david.bresch@gmail.com, 20141127, allows for hazard OR centroids as input
% Lea Mueller, muellele@gmail.com, 20150511, only for unique lon/lat values, essential speedup
% David N. Bresch, david.bresch@gmail.com, 20150610, Lea's speedup fixed
% Lea Mueller, muellele@gmail.com, 20150617, speedup works for both dimensions of entity.lats and .lons (1xn and nx1)
% David N. Bresch, david.bresch@gmail.com, 20150618, Lea's speedup fixed 2nd time (line 134)
% Lea Mueller, muellele@gmail.com, 20150805, define a maximum distance to hazard, otherwise centroid_index is set to 0 and no damage wil be calculated (see climada_EDS_calc)             
% David N. Bresch, david.bresch@gmail.com, 20150825, bug-fix to use centroids instead of hazard
% Lea Mueller, muellele@gmail.com, 20150915, set max_encoding_distance_m as input variable
% Lea Mueller, muellele@gmail.com, 20150916, add max_distance in waitbar text
% David N. Bresch, david.bresch@gmail.com, 20160606, max_distance_to_hazard renamed to max_encoding_distance_m and speedup
% David N. Bresch, david.bresch@gmail.com, 20161120, (waitbar) comments removed
% David N. Bresch, david.bresch@gmail.com, 20170228, progress to stdout fewer times
% Samuel Eberenz, eberenz@posteo.eu, 20180416, add option speed_up for use of bounding boxes
% Samuel Eberenz, eberenz@posteo.eu, 20180417, debug, speed_up: include buffer and speed_up options 1 to 3
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('entityORassets','var'),entityORassets=[];end
if ~exist('hazard','var'),hazard=[];end
if ~exist('max_encoding_distance_m','var'),max_encoding_distance_m=[];end
if ~exist('speed_up','var'),speed_up=[];end

% PARAMETERS
%

% prompt for assets (entity) if not given
if isempty(entityORassets) % local GUI
    entity_file=[climada_global.entities_dir filesep '*.mat'];
    [filename, pathname] = uigetfile(entity_file, 'Select entity to re-encode:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_file=fullfile(pathname,filename);
        load(entity_file) % loads entity
        entityORassets=entity; % see below, entity_passed_on_input
    end
end

% prompt for hazard if not given
if ischar(hazard),if strcmp(hazard,'SKIP'),return;end;end % special case, see e.g. climad_entity_read

hazard=climada_hazard_load(hazard);

if isempty(hazard) % user pressed Cancel when prompted for or hazard does not exist
    fprintf('Note: assets not encoded\n');
    return
end 

if isempty(max_encoding_distance_m)
    if isfield(hazard,'max_encoding_distance_m')
        % hazard set contains a max diatance
        max_encoding_distance_m=hazard.max_encoding_distance_m;
    else
    max_encoding_distance_m = climada_global.max_encoding_distance_m; %max_encoding_distance_m = 10^6; 
    end
end

if isempty(speed_up),speed_up=1;end
if speed_up>1
    warning('speed_up > 1: Some assets might not be encoded.')
end

% figure whether we got an entity OR assets as input
if isfield(entityORassets,'assets') % an entity instead of assets passed
    entity_passed_on_input=1;
    entity=entityORassets; % store full entity
    assets=entity.assets; % assign
else
    entity_passed_on_input=0;
    assets=entityORassets;
end
% now, assets contain assets indeed

if isfield(hazard,'intensity')
    % hazard does indeed contain a hazard structure
    % hence we do not need all fields
    centroids.lon=hazard.lon;
    centroids.lat=hazard.lat;
    centroids.peril_ID=hazard.peril_ID;
    if isfield(hazard,'filename'),centroids.filename = hazard.filename;end
    if isfield(hazard,'comment'), centroids.comment  = hazard.comment;end
else
    % hazard does contain centroids
    centroids=hazard; clear hazard
end
% now, centroids are centroids indeed

% omit flagged centroids (those with centroid_ID<0)
if isfield(centroids,'centroid_ID')
    centroids.lon=centroids.lon(centroids.centroid_ID>0);
    centroids.lat=centroids.lat(centroids.centroid_ID>0);
end


% check lat lon dimension (1xn or nx1), now the concatenations works for both dimensions
[lon_i,lon_j] = size(assets.lon);
% find unique lat lons
if lon_j == 1 % was lon_i
    [~,indx, indx2] = unique([assets.lon assets.lat],'rows');
elseif lon_i == 1 % was lon_j
    [~,indx, indx2] = unique([assets.lon;assets.lat]','rows');
else
    fprintf('Please check the dimensions of assets.lon and assets.lat.\n')
    return
end

% start encoding
n_assets              = length(indx);
if ~speed_up && n_assets>5000
    disp('Consider option speed_up=1 for faster encoding.')
end

assets.centroid_index = zeros(size(assets.Value)); % init

fprintf('encoding %i assets (max distance %d m) ...\n',n_assets,max_encoding_distance_m);

cos_centroids_lat = cos(centroids.lat/180*pi); % calculate once for speedup

climada_progress2stdout    % init, see terminate below

if speed_up && n_assets>500 % speed up by using this routine, encoding box by box.
                    % set buffer for overlaping centroids box,
                    % to avoid non-encoded assets close to boundaries of
                    % boxes. (The centroid box contains the asset box)
    if speed_up==1 % 1: save not to miss any assets within max_encoding max_encoding_distance_m (default)
            buffer = 1.1*max_encoding_distance_m/(111.12*1000); % converting m to degree
        elseif speed_up==2 % 2: faster, smaller overlap, save for regular grids if max encoding distace is set properly
            buffer = .55*max_encoding_distance_m/(111.12*1000); 
        elseif speed_up>=3 % 3: fastest, no overlap, will most certainly miss a few assets.
            buffer = 0;
    end
    % set optimal degree lon x lat box_size:
    if max_encoding_distance_m > 75000
        box_size = 6; % ~6x6 optimal performance for large encoding distances, tested for n_assets = 8'000
    elseif max_encoding_distance_m > 25000
        box_size = 4; % 4x4 optimal performance for ~50000m, tested for n_assets = 8'000 & 150'000
    else
        box_size = 3; % 3x3 degrees for small encoding distances, performance not tested.
    end
    % set bounding boxes for assets, rounded according to box_size:
    lon_box=floor(min(assets.lon)*1/box_size)*box_size:box_size:ceil(max(assets.lon)*1/box_size)*box_size;
    lat_box=floor(min(assets.lat)*1/box_size)*box_size:box_size:ceil(max(assets.lat)*1/box_size)*box_size;
    
    cos_max_lat = cos(max(abs(assets.lat))/180*pi);
    assets_count=0;

    for box_i=1:length(lon_box)-1 % begin double loop through all populated bounding boxes
        if box_i==length(lon_box)-1 % find indices for box in longitude
            lon_dummy_assets=assets.lon(indx)>=lon_box(box_i) &...
                      assets.lon(indx)<=lon_box(box_i+1);
            lon_dummy_centroids=centroids.lon>=(lon_box(box_i)-buffer/cos_max_lat) &... % lon min
                centroids.lon<=(lon_box(box_i+1)+buffer/cos_max_lat); % lon max                  
        else
            lon_dummy_assets=assets.lon(indx)>=lon_box(box_i) &...
                      assets.lon(indx)< lon_box(box_i+1);
            lon_dummy_centroids=centroids.lon>=(lon_box(box_i)-buffer/cos_max_lat) &... % lon min
                centroids.lon<(lon_box(box_i+1)+buffer/cos_max_lat); % lon max
        end
        for box_j=1:length(lat_box)-1
             % find indices for box in latitude
            asset_box_indx = find(lon_dummy_assets &...
                    assets.lat(indx)>=lat_box(box_j) & ...
                    assets.lat(indx)<=lat_box(box_j+1));
         
            if isempty(asset_box_indx),continue;
            else,assets_count=assets_count+length(asset_box_indx);end 
            
            centroid_box_indx = find(lon_dummy_centroids & ...
                centroids.lat>=(lat_box(box_j  )- buffer) & ... % lat min
                centroids.lat<=(lat_box(box_j+1)+ buffer)); % lat max
            
            if isempty(centroid_box_indx)
                assets.centroid_index(asset_box_indx)=0;
                continue;
            end
            % loop through assets in bounding box:
            for asset_box_i = 1:length(asset_box_indx)
                    dd=((centroids.lon(centroid_box_indx)-assets.lon(indx(asset_box_indx(asset_box_i)))).*...
                        cos_centroids_lat(centroid_box_indx)).^2+...
                        (centroids.lat(centroid_box_indx)-assets.lat(indx(asset_box_indx(asset_box_i)))).^2; % in km^2
                    [min_dist,min_dist_index]    = min(dd);
                    min_dist=sqrt(min_dist)*111.12*1000; % to km, then to m
                    % set closest hazard position to zero if hazard is too far away from asset (depends on peril ID)
                    if min_dist>max_encoding_distance_m
                        min_dist_index = 0;
                    else
                        min_dist_index = centroid_box_indx(min_dist_index);
                    end
                    %indx3                        = find(indx2 == asset_i); until 20160606
                    indx3                        = indx2 == asset_box_indx(asset_box_i);
                    assets.centroid_index(indx3) = min_dist_index;

                    mod_step=10000;
                    if assets_count<10000,mod_step=1000;end
                    if assets_count<1000,mod_step=100;end
                    climada_progress2stdout(min(assets_count,n_assets),n_assets,mod_step,'assets'); % update
            end            
        end
    clear lon_dummy_*
    end
else
    % default encoding processes without bounding boxes
    % (default till 20180416). activate by setting speed_up=0.
    for asset_i=1:n_assets

        % we used climada_geo_distance before (slower, since cos(lat) calculated each time)
        dd=((centroids.lon-assets.lon(indx(asset_i))).*cos_centroids_lat).^2+(centroids.lat-assets.lat(indx(asset_i))).^2; % in km^2
        [min_dist,min_dist_index]    = min(dd);
        min_dist=sqrt(min_dist)*111.12*1000; % to km, then to m
        % set closest hazard position to zero if hazard is too far away from asset (depends on peril ID)
        if min_dist>max_encoding_distance_m
            min_dist_index = 0;
        end
        %indx3                        = find(indx2 == asset_i); until 20160606
        indx3                        = indx2 == asset_i;
        assets.centroid_index(indx3) = min_dist_index;

        mod_step=10000;
        if asset_i<10000,mod_step=1000;end
        if asset_i<1000,mod_step=100;end
        climada_progress2stdout(asset_i,n_assets,mod_step,'assets'); % update

    end % asset_i
end
climada_progress2stdout(0) % terminate

assets.hazard.filename = 'assets encode'; % default
assets.hazard.comment  = 'assets encode'; % default
if isfield(centroids,'filename'),assets.hazard.filename = centroids.filename;end
if isfield(centroids,'comment' ),assets.hazard.comment  = centroids.comment;end

if entity_passed_on_input
    entity         = rmfield(entity,'assets'); % delete input
    entity.assets  = assets; % assign re-encoded assets
    % and pass on output:
    entityORassets = entity; % return entity as output
else
    entityORassets = assets; % return assets as output
end

end % climada_assets_encode