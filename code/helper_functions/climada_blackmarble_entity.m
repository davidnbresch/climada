function entity=climada_blackmarble_entity(admin0_name,admin1_name,parameters)
% country admin0 admin1 entity high resolution
% MODULE:
%   core
% NAME:
%	climada_blackmarble_entity
% PURPOSE:
%   Construct an entity file based on high-resolution (0.5km!) night light
%   data of 2016.
%
%   NOTE: this code really belongs to the country risk module, but we moved
%   it to the core module to allow for easy generation of admin0 (country)
%   entities at 10km resolution. See
%   https://github.com/davidnbresch/climada_module_country_risk for details. 
%
%   Reads an image file with nightlight density and matches it to the local
%   geography, then scales to proxy for asset values.
%
%   Prompts for country (admin0) and state/province (admin1, optional),
%   obtains the high-resolution (or mid-resolution) night lights for this
%   area and constrains the active centroids (with values>0) to the
%   selected country or admin1 (see input parameter selections) plus a
%   surrounding buffer and saves the entity, optionally adding distance to
%   coast (in km) and elevation (in m) for each centroid, too.
%
%   The original nightlight intensities are first scaled to the range
%   [0..1], then transformed using a polynomial (see
%   parameters.nightlight_transform_poly), then scaled such that all values
%   sum to to one (normalized).
%
%   If admin0 (whole country) is selected, the values are scaled to sum up
%   to GDP*(income_group+1) as a good proxy for the 'real' asset value (see
%   code climada_entity_value_GDP_adjust_one). 
%
%   If admin1,is requested, no automatic scaling or allocation of GDP to
%   centroids is performed.
%
%   The niglight image is not stored within the climada structure. It can
%   be created using blackmarble_read.m
%   The original data needs to be aquired from 
%   https://earthobservatory.nasa.gov/Features/NightLights/page3.php
%
%   Programmer's remark: The code deals with a lot of admin stuff to get
%   the nightlight file, the admin0 and admin1 names etc. Key code sections
%   are marked with ***********
%
%   Note: the code uses climada_inpolygon instead of inpolygon.
%
%   See also older version like climada_nightlight_entity,
%   climada_create_GDP_entity and climada_hybrid_entity. 
%   See also climada_nightlight2cdf to store as netCDF (e.g. for isimip)
%   See climada_nightlight_global_entity to generate a global entity with
%       all countries scaled etc.
% CALLING SEQUENCE:
%   entity=climada_blackmarble_entity(admin0_name,admin1_name,parameters)
% EXAMPLE:
%   entity=climada_blackmarble_entity('Italy'); % good for test, as shape of Italy is well-known
%   climada_entity_plot(entity,[],1); % visual check
%   parameters=climada_blackmarble_entity('parameters') % return all default parameters
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   admin0_name: the country name, either full or ISO3
%       > If empty, a list dialog lets the user select (default)
%       Instead of explicit country names, one can also use ISO3 country
%       codes (like DEU, CHE). Note that the entity filename will use the
%       full country name, but ISO3 is stored in entity.assets.admin0_ISO3
%       See parameter selections, especially if you want to select a whole
%       country.
%       If you leave admin1_name empty, a country will be processed. Set
%       admin1_name='ask' in case you'd like to be prompted for admin1.
%       Also useful if a img_filename is passed in parameters
%       and thus if admin0_name is defined, the respective country is cut out.
%       If ='parameters' or 'params', return all default parameters
%   admin1_name: if passed on, do not prompt for admin1 name, ='ask' to prompt for
%       > If empty together with admin0_name, a list dialog lets the user select (default)
%       Most useful for subsequent calls, i.e. once one knows the exact
%       admin1 name. Also useful if a img_filename is passed in parameters
%       and thus if admin1_name is defined, the respective admin1 is cut out.
%       NOTE: Still an issue with some characters, i.e. Zrich does not work
%       if entered as admin1_name, please use the admin1_code, also shown
%       behind the | in the list dialog, e.g. for Zurich, the call hence is
%       entity=climada_nightlight_entity('CHE','CHE-176'). Note that the
%       admin1_name is kept as on input, i.e. 'CHE-176' in the example, not
%       'Zrich'.
%   parameters: a structure to pass on parameters, with fields as
%       (run parameters=climada_nightlight_entity('parameters') to obtain
%       all default values)
%       resolution_km: the resuting resolution, either =1 or =10
%           It is often advisable to first TEST with resolution=10 for
%           speed reasons. If a fully country is selected, default=10, else
%           =1 for admin1
%       restrict_Values_to_country: whether we restrict the values to
%           within the country (=1, default) or not (=0, faster, but less useful)
%       grid_spacing_multiplier: the spacing of regular grid outside of the
%           area requested. Default=5, hence approx every 5th point as outer
%           grid.
%       nightlight_transform_poly: the polynomial coefficients to transform
%           the nightlight intensity (usually in the range 0..60) to proxy
%           asset values. Evaluated using polyval, i.e.
%           value=polyval(parameters.nightlight_transform_poly,nightlight_intensity)
%           Default=[0 1 0 0], which means Value=nightlight_intensity^2
%           After this Values are normalized to sum up to 1.
%           Note that if a whole country is requested, Values are then
%           scaled to sum up to GDP*(income_group+1).
%       scale_GDP: wheter we scale up asset values based on a country's 
%           estimated total asset value (=1, default) or not (=0). 
%           Note: this sets parameters.nightlight_transform_poly=[0 0 0 0]
%           if not provided otherwise)
%       value_threshold: if empty or =0, all centroids (also those with zero
%           value) are kept in the entity (default). If set to a value,
%           only centroids with entity.Value>value_threshold are kept (note
%           that this way, one can specify an asset value threshold, reduce
%           the number of points to be dealt with).
%           One might often want to avoid all truly tero points, i.e. 
%       add_distance2coast_km: if =1, add distance to coast, default=0
%       add_elevation_m: if =1, add elevation, default=0
%       img_filename: the filename of an image with night light density, as
%           created using the GUI at http://maps.ngdc.noaa.gov/viewers/dmsp_gcv4/
%           and select Satellite F18, 2010, avg_lights_x_pct, then 'Download
%           data' and enter the coordinates
%           The filename has to be of form A_B_C_D_{|E_F}*..lzw.tiff with A,B,C and D
%           the min lon, min lat, max lon and max lat (integer), like
%           87_20_94_27_F182010.v4c.avg_lights_x_pct.lzw.tiff and E and F the
%           country (admin0) and state/province (admin1) name, like
%           -88_24_-79_32_United States of America_Florida_high_res.avg_lights.lzw.tiff
%
%           If empty (eg run the code without any argument), it prompts for country
%           and admin1 name and constructs the URL to get the corresponding
%           tile from the nightlight data, e.g. a string such as:
%           http://mapserver.ngdc.noaa.gov/cgi-bin/public/gcv4/F182010.v4c.
%               avg_lights_x_pct.lzw.tif?request=GetCoverage&service=WCS&
%               version=1.0.0&COVERAGE=F182010.v4c.avg_lights_x_pct.lzw.tif&
%               crs=EPSG:4326&format=geotiff&resx=0.0083333333&resy=0.0083333333&
%               bbox=-88,24,-79,32
%
%           ='ASK' prompt for an image file (without first asking for country
%           where one has to press 'Cancel') to get the to filename prompt
%       save_entity: whether we save the entity (=1, default) or nor (=0).
%       entity_filename: the filename to save the entity to, default is a
%           long one with ISO3, country name, admin1 name, geo coord and
%           resolution. Not used if save_entity=0
%       check_plot: if =1: plot nightlight data with admin0 (countries)
%           superimposed, if=2 also admin1 (country states/provinces)
%           =0: no plot (default). If=3, plot the resulting asset Values
%       verbose: whether we printf progress to stdout (=1, default) or not (=0)
% OUTPUTS:
%   entity: a full climada entity, see climada_entity_read, plus the fields
%       entity.assets.distance2coast_km(i): distance to coast in km (both on-
%           and offshore) for each centroid
%       entity.assets.elevation_m(i): elevation in m for each centroid,
%           negatove for ocean depth (needs climada module etopo, just skips
%           this if module not installed)
%       entity.assets.admin0_name: country name
%       entity.assets.admin0_ISO3: country ISO3 code
%       entity.assets.admin1_name: state/province name (if restricted to
%           admin1)
%       entity.assets.admin1_code: state/province code (if restricted to
%           admin1)
%       entity.assets.nightlight_transform_poly: the polynomial
%           coefficients that have been used to transform the nightlight
%           intensity.
%       entity.assets.isgridpoint: =1 for the regular grid added 'around'
%           the assets, =0 for the 'true' asset centroids
%       see e.g. climada_entity_plot to check
% RESTRICTIONS:
% MODIFICATION HISTORY:
% david.bresch@gmail.com, 20171103, major part copied from climada_nightlight_entity.m
% thomas.roeoesli@usys.ethz.ch, 20171114, initial
% Dario Stocker & Samuel Eberenz, eberenz@posteo.eu, 20180209, add switch parameters.scale_GDP

entity=[]; % init

% import/setup global variables
global climada_global
if ~climada_init_vars,return;end;

% check for arguments
if ~exist('admin0_name','var'),admin0_name=''; end
if ~exist('admin1_name','var'),admin1_name=''; end
if ~exist('parameters','var'),parameters=struct;end

% locate the country risk module's data (only needed for high-res 1x1km, as
% 10x10km is part of standard core climada)
module_data_dir=[fileparts(fileparts(which('centroids_generate_hazard_sets'))) filesep 'data'];

% check for some parameter fields we need
if ~isfield(parameters,'resolution_km'),parameters.resolution_km=[];end
if ~isfield(parameters,'nightlight_transform_poly'),parameters.nightlight_transform_poly=[];end
if ~isfield(parameters,'restrict_Values_to_country'),parameters.restrict_Values_to_country=[];end
if ~isfield(parameters,'grid_spacing_multiplier'),parameters.grid_spacing_multiplier=[];end
if ~isfield(parameters,'img_filename'),parameters.img_filename='';end
if ~isfield(parameters,'save_entity'),parameters.save_entity=[];end
if ~isfield(parameters,'entity_filename'),parameters.entity_filename='';end
if ~isfield(parameters,'value_threshold'),parameters.value_threshold=[];end
if ~isfield(parameters,'scale_GDP'),parameters.scale_GDP=[];end
if ~isfield(parameters,'add_distance2coast_km'),parameters.add_distance2coast_km=[];end
if ~isfield(parameters,'add_elevation_m'),parameters.add_elevation_m=[];end
if ~isfield(parameters,'check_plot'),parameters.check_plot=[];end
if ~isfield(parameters,'verbose'),parameters.verbose=[];end

% set default values (see header for details)
%if isempty(parameters.nightlight_transform_poly),parameters.nightlight_transform_poly=[1 0 0 0];end % until 20170119

if isempty(parameters.restrict_Values_to_country),parameters.restrict_Values_to_country=1;end
if isempty(parameters.grid_spacing_multiplier),parameters.grid_spacing_multiplier=5;end
if isempty(parameters.save_entity),parameters.save_entity=1;end
if isempty(parameters.value_threshold),parameters.value_threshold=0;end
if isempty(parameters.scale_GDP),parameters.scale_GDP=1;end
if isempty(parameters.add_distance2coast_km),parameters.add_distance2coast_km=0;end
if isempty(parameters.add_elevation_m),parameters.add_elevation_m=0;end
if isempty(parameters.check_plot),parameters.check_plot=0;end
if isempty(parameters.verbose),parameters.verbose=1;end
if isempty(parameters.nightlight_transform_poly)
    if parameters.scale_GDP, parameters.nightlight_transform_poly=[0 1 0 0]; % default GDP
    else, parameters.nightlight_transform_poly=[0 0 0 0];end % default pure night light
end

% PARAMETERS
%
% the file with the full (whole earth) 1x1km nightlights
% see http://ngdc.noaa.gov/eog/dmsp/downloadV4composites.html#AVSLCFC3
% and the detailed instructions where to obtain in the file
% F182012.v4c_web.stable_lights.avg_vis.txt in the module's data dir.
full_img_filename=[module_data_dir filesep 'BlackMarble_2016_geo_gray.mat'];
% min_South=-65; % degree, defined on the webpage above
% max_North= 75; % defined on the webpage above
%
% low resolution file (approx. 10x10km): start with default file in core module

% Note: you might check whether the same min_South and max_North apply
%
% admin0 and admin1 shape files (in climada module country_risk):
admin0_shape_file=climada_global.map_border_file; % as we use the admin0 as in next line as default anyway
%admin0_shape_file=[module_data_dir filesep 'ne_10m_admin_0_countries' filesep 'ne_10m_admin_0_countries.shp'];
admin1_shape_file=[module_data_dir filesep 'ne_10m_admin_1_states_provinces' filesep 'ne_10m_admin_1_states_provinces.shp'];
%
% base entity file, such that we do not need to construct the entity from scratch
entity_file=[climada_global.entities_dir filesep 'entity_template' climada_global.spreadsheet_ext];
%
% whether we select admin0 or admin1 (see parameter selections)
select_admin0=0; % default=0, to select admin1
if isempty(admin1_name),select_admin0=1;end
if strcmpi(admin1_name,'ask'),select_admin0=0;admin1_name='';end

% if isempty(parameters.resolution_km)
%     if select_admin0
%         parameters.resolution_km=10; % default for admin0
%     else
%         parameters.resolution_km=1; % default for admin1
%     end
% end

if strcmpi(admin0_name,'parameters') || strcmpi(admin0_name,'params'),...
        entity=parameters;return;end % special case, return the full parameters strcture

% if parameters.resolution_km==10,full_img_filename=low_img_filename;end

% if parameters.verbose,fprintf('resolution %ix%i km\n',parameters.resolution_km,parameters.resolution_km);end

% read admin0 (country) shape file (we need this in any case)
admin0_shapes=climada_shaperead(admin0_shape_file);
admin1_shapes=[]; % init

selection_admin0_shape_i=[]; % init
selection_admin1_shape_i=[]; % init

% check for full global night light image being locally available
if ~exist(full_img_filename,'file')
    fprintf(['nightlight file "' full_img_filename '" does not exist. Use function "blackmarble_read.m" to create it.']);
    return
end

bbox=[]; % init

if ~isempty(admin0_name) % check for valid name, othwerwise set to empty
    [~,admin0_name]=climada_country_name(admin0_name);
end
    

if isempty(admin0_name)

    % generate the list of countries
    admin0_name_list={};admin0_code_list={};
    for shape_i=1:length(admin0_shapes)
        admin0_name_list{shape_i}=admin0_shapes(shape_i).NAME;
        admin0_code_list{shape_i}=admin0_shapes(shape_i).ADM0_A3;
    end % shape_i

    [liststr,sort_index] = sort(admin0_name_list);

    % prompt for a country name
    [selection] = listdlg('PromptString','Select one country (Cncl -> img):',...
        'ListString',liststr,'SelectionMode','Single');
    pause(0.1)
    if ~isempty(selection)
        admin0_name = admin0_name_list{sort_index(selection)};
        admin0_code = admin0_code_list{sort_index(selection)};
    else
        parameters.img_filename='ASK'; % Cancel pressed, later prompt for filename
    end

end % isempty(admin0_name)


[admin0_name,admin0_code]=climada_country_name(admin0_name);
% find the country in the shape file
admin0_shape_i=0;
for shape_i=1:length(admin0_shapes)
    if strcmp(admin0_shapes(shape_i).NAME,admin0_name)
        admin0_shape_i=shape_i;
    elseif strcmp(admin0_shapes(shape_i).ADM0_A3,admin0_code) % country code (2nd, since safer)
        admin0_shape_i=shape_i;
    end
end % shape_i
selection_admin0_shape_i=admin0_shape_i;

if select_admin0

    % prepare parameters for www call to fetch the tile of the global map
    % bbox=[minlon minlat maxlon maxlat]
    bbox(1)=floor(min(admin0_shapes(selection_admin0_shape_i).X));
    bbox(3)=ceil( max(admin0_shapes(selection_admin0_shape_i).X));
    bbox(2)=floor(min(admin0_shapes(selection_admin0_shape_i).Y));
    bbox(4)=ceil( max(admin0_shapes(selection_admin0_shape_i).Y));
    admin1_name='';

else

    % add (country states/provinces)
    if parameters.verbose,fprintf('processing admin1 shapes ...\n');end % prompt, since takes a bit of time...
    if isempty(admin1_shapes),admin1_shapes=climada_shaperead(admin1_shape_file);end % read admin1 shape file
    % figure which shapes within the country we need
    admin1_shape_i=0;next_admin1=1; % init
    for shape_i=1:length(admin1_shapes)
        for country_i=1:length(admin0_shape_i)
            %if strcmp(admin0_shapes(admin0_shape_i(country_i)).NAME,admin1_shapes(shape_i).admin)
            if strcmp(admin0_shapes(admin0_shape_i(country_i)).ADM0_A3,admin1_shapes(shape_i).adm0_a3) % safer
                admin1_shape_i(next_admin1)=shape_i;
                next_admin1=next_admin1+1;
            end
        end % country_i
    end % shape_i

    if isempty(admin1_name)

        % plot admin0 (country) shape(s)
        for admin0_i=1:length(admin0_shape_i)
            shape_i=admin0_shape_i(admin0_i);
            plot(admin0_shapes(shape_i).X,admin0_shapes(shape_i).Y,'-r','LineWidth',2);
            hold on; axis equal
        end % country_i
        set(gcf,'Color',[1 1 1]) % whithe figure background

        % plot admin1 (country states/provinces) shapes
        admin1_name_list={};
        admin1_name_code_list={};
        for admin1_i=1:length(admin1_shape_i)
            shape_i=admin1_shape_i(admin1_i);
            plot_X=admin1_shapes(shape_i).X;
            plot_Y=admin1_shapes(shape_i).Y;
            if strcmp(admin1_shapes(shape_i).name,'Alaska')
                % SPECIAL case for Alaska (to avoid badly shaped map)
                pos=find(plot_X>100);
                plot_X(pos)=plot_X(pos)-360;
            end
            plot(plot_X,plot_Y,'-r','LineWidth',1);
            text(admin1_shapes(shape_i).longitude,admin1_shapes(shape_i).latitude,admin1_shapes(shape_i).name);
            admin1_name_list{admin1_i}=admin1_shapes(shape_i).name; % compile list of admin1 names
            admin1_name_code_list{admin1_i}=[admin1_shapes(shape_i).name ...
                ' | ' admin1_shapes(shape_i).adm1_code]; % with code
        end % admin1_i

        [liststr,sort_index] = sort(admin1_name_code_list);

        % show list dialog to select admin1 (now easy as names shown on plot)
        [selection,ok] = listdlg('PromptString','Select admin1:',...
            'ListString',liststr,'SelectionMode','Single');
        if ~ok,return;end
        pause(0.1)
        if ~isempty(selection)
            admin1_name = admin1_name_list{sort_index(selection)};
            selection_admin1_shape_i=admin1_shape_i(sort_index(selection));
        else
            return
        end % ~isempty(selection)

    else

        for shape_i=1:length(admin1_shapes)
            if strcmp(admin1_shapes(shape_i).adm0_a3,admin0_code)
                if strcmp(admin1_shapes(shape_i).name,admin1_name)
                    %fprintf('%s|%s|\n',admin1_shapes(shape_i).name,admin1_name);
                    selection_admin1_shape_i=shape_i;
                elseif strcmp(admin1_shapes(shape_i).adm1_code,admin1_name) % also allow for code
                    selection_admin1_shape_i=shape_i;
                end % admin1_name
            end % admin0_code
        end % shape_i

    end % isempty(admin1_name)

    if isempty(selection_admin1_shape_i)
        admin1_name
        fprintf('Error: %s not found, consider using admin1_code, run once without specifying admin1 to see list of codes\n',char(admin1_name));
        return
    end

    % prepare parameters for www call to fetch the tile of the global map
    bbox(1)=floor(admin1_shapes(selection_admin1_shape_i).BoundingBox(1));
    bbox(3)=ceil(admin1_shapes(selection_admin1_shape_i).BoundingBox(2));
    bbox(2)=floor(admin1_shapes(selection_admin1_shape_i).BoundingBox(3));
    bbox(4)=ceil(admin1_shapes(selection_admin1_shape_i).BoundingBox(4));

end % select_admin0

% make sure at least 2 deg in each direction
if abs(bbox(3)-bbox(1))<2,bbox(1)=bbox(1)-1;bbox(3)=bbox(3)+1;end
if abs(bbox(4)-bbox(2))<2,bbox(2)=bbox(2)-1;bbox(4)=bbox(4)+1;end
% prepare parameters for www call to fetch the tile of the global map
bbox_file_pref=sprintf('%i_%i_%i_%i_',bbox);


%%% Get the nightlight intensity data from the file
% loads Blackmarble file as a matfile object
BM = matfile(full_img_filename); 
blackmarble_lat = BM.blackmarble_lat; %only a function
blackmarble_lon = BM.blackmarble_lon; %only a function
blackmarble_ind = BM.blackmarble_ind; %only a function
try
    extraction_ind = blackmarble_ind(bbox(2), bbox(4), bbox(1), bbox(3));% bbox=[minlon minlat maxlon maxlat] define indizes for extraction
catch
    error('ERROR: you are using a old version of matlab with a different behaviour of the function  + (plus). Please update MATLAB to a newer version.');
end
nightlight_intensity = BM.nightlight_intensity; % creates the actual values using BM (matfile object)
VALUES = double(nightlight_intensity(extraction_ind)); % copy needed box of nightlight intensity to VALUES and transform to double
clear nightlight_intensity
X = blackmarble_lon(extraction_ind); % creates the coordinates for the needed box
Y = blackmarble_lat(extraction_ind); % creates the coordinates for the needed box


    
% instead of bbox, the plotting further down needs another order
img_area=[bbox(1) bbox(3) bbox(2) bbox(4)]; % [minlon maxlon minlat maxlat]


% consistency check, returns both, interprets both name and ISO3
[admin0_name,admin0_ISO3] = climada_country_name(admin0_name); % get full name

% some double-checks (for the special case where an parameters.img_filename and
% admin0_name and admin1_name are passed)
if isempty(selection_admin0_shape_i) && ~isempty(admin0_name)
    for shape_i=1:length(admin0_shapes)
        %fprintf('|%s|%s|\n',admin0_shapes(shape_i).NAME,admin0_name)
        if strcmp(admin0_shapes(shape_i).NAME,admin0_name)
            selection_admin0_shape_i=shape_i;
        elseif strcmp(admin0_shapes(shape_i).ADM0_A3,admin0_ISO3) % ISO3 country code
            selection_admin0_shape_i=shape_i;
        end
    end % shape_i
end
if isempty(selection_admin1_shape_i) && ~isempty(admin1_name)
    if isempty(admin1_shapes),admin1_shapes=climada_shaperead(admin1_shape_file);end % read admin1 shape file
    for shape_i=1:length(admin1_shapes)
        %fprintf('|%s|%s|\n',admin1_shapes(shape_i).name,admin1_name)
        if strcmp(admin1_shapes(shape_i).name,admin1_name)
            selection_admin1_shape_i=shape_i;
        elseif strcmp(admin1_shapes(shape_i).adm1_code,admin1_name) % code
            selection_admin1_shape_i=shape_i;
        end
    end % shape_i
end

if isempty(parameters.entity_filename) % define default entity filename
    if isempty(admin1_name) % country
        parameters.entity_filename=sprintf('%s_%s',      admin0_ISO3,admin0_name);
        %parameters.entity_filename=sprintf('%s_%s_%i_%i_%i_%i',...
        %    admin0_ISO3,strrep(admin0_name,' ',''),bbox); % until 20160930
    else % state/province
        parameters.entity_filename=sprintf('%s_%s_%s_%s',admin0_ISO3,admin0_name,...
            admin1_shapes(selection_admin1_shape_i).name,...
            admin1_shapes(selection_admin1_shape_i).adm1_code);
        %parameters.entity_filename=sprintf('%s_%s_%s_%s_%i_%i_%i_%i',...
        %    admin0_ISO3,strrep(admin0_name,' ',''),...
        %    strrep(admin1_shapes(selection_admin1_shape_i).name,' ',''),...
        %    admin1_shapes(selection_admin1_shape_i).adm1_code,bbox); % until 20160930
    end
    if parameters.resolution_km==10
        parameters.entity_filename=[parameters.entity_filename '_blackmarble10x10'];
    else
        parameters.entity_filename=[parameters.entity_filename '_blackmarble'];
    end
    parameters.entity_filename=strrep(parameters.entity_filename,'.','');
    parameters.entity_filename=strrep(parameters.entity_filename,' ','');
    parameters.entity_filename=strrep(parameters.entity_filename,',','');
end

% parameters.entity_filename: complete path, if missing
[fP,fN,fE]=fileparts(parameters.entity_filename);
if isempty(fP),fP=climada_global.entities_dir;end
if isempty(fE),fE='.mat';end
parameters.entity_filename=[fP filesep fN fE];

%[X,Y]=meshgrid(xx,yy); % construct regular grid

% convert to daouble (from uint8)
%VALUES=double(img);

% figure which admin0 (country) shapes we need
% done before check_plot, as used below again
x=[bbox(1) bbox(1) bbox(3) bbox(3) (bbox(1)+bbox(3))/2];
y=[bbox(2) bbox(4) bbox(2) bbox(4) (bbox(2)+bbox(4))/2];
admin0_shape_i=0;next_admin0=1; % init
for shape_i=1:length(admin0_shapes)
%     if climada_global.octave_mode
%         % Octave's inpolygon can not deal with NaNs
%         ok_pos=~isnan(admin0_shapes(shape_i).X);
%         admin0_shapes(shape_i).X=admin0_shapes(shape_i).X(ok_pos);
%         admin0_shapes(shape_i).Y=admin0_shapes(shape_i).Y(ok_pos);
%     end
    country_hit=climada_inpolygon(x,y,admin0_shapes(shape_i).X,admin0_shapes(shape_i).Y);
    if sum(country_hit)>0
        admin0_shape_i(next_admin0)=shape_i;
        next_admin0=next_admin0+1;
    end
end % shape_i
if ~isempty(selection_admin0_shape_i),...
        admin0_shape_i(next_admin0)=selection_admin0_shape_i;end % to be safe

if parameters.check_plot
    % plot the image (kind of 'georeferenced')
    pcolor(X,Y,VALUES);
    shading flat
    axis(img_area)
    hold on
    set(gcf,'Color',[1 1 1]) % whithe figure background
    
    % plot admin0 (country) shapes
    for admin0_i=1:length(admin0_shape_i)
        shape_i=admin0_shape_i(admin0_i);
        plot(admin0_shapes(shape_i).X,admin0_shapes(shape_i).Y,'-r','LineWidth',2);
    end % country_i
    
    if parameters.check_plot>1
        if parameters.verbose,fprintf('adding admin1 shapes to plot ...\n');end
        % figure which admin1 (country states/provinces) shapes we need
        if isempty(admin1_shapes),admin1_shapes=climada_shaperead(admin1_shape_file);end % read admin1 shape file
        admin1_shape_i=0;next_admin1=1; % init
        for shape_i=1:length(admin1_shapes)
            for country_i=1:length(admin0_shape_i)
                if strcmp(admin0_shapes(admin0_shape_i(country_i)).NAME,admin1_shapes(shape_i).admin)
                    admin1_shape_i(next_admin1)=shape_i;
                    next_admin1=next_admin1+1;
                end
            end % country_i
        end % shape_i
        
        % plot admin1 (country states/provinces) shapes
        for admin1_i=1:length(admin1_shape_i)
            shape_i=admin1_shape_i(admin1_i);
            plot(admin1_shapes(shape_i).X,admin1_shapes(shape_i).Y,'-r','LineWidth',1);
        end % country_i
    end % check_plot>1
end % check_plot

if exist(entity_file,'file')
    entity=climada_entity_read(entity_file,'SKIP'); % read the empty entity
    if isfield(entity,'assets'),entity=rmfield(entity,'assets');end
else
    fprintf('WARNING: base entity %s not found, entity just entity.assets\n',entity_file);
end

entity.assets.comment=sprintf('generated by %s at %s',mfilename,datestr(now));
entity.assets.filename=parameters.img_filename;
if ~isempty(selection_admin1_shape_i),
    entity.assets.ADM0_A3=admin0_shapes(selection_admin0_shape_i).ADM0_A3;end
entity.assets.lon=X(:)';
entity.assets.lat=Y(:)';
VALUES_1D=VALUES(:); % one dimension

% generate regular grid (to also find inpoly for it)
grid_spacing1=0.01*parameters.grid_spacing_multiplier; % about 5km grid
if parameters.resolution_km==10,grid_spacing1=0.1*parameters.grid_spacing_multiplier;end % about 50km for moderate
if parameters.value_threshold>0,grid_spacing1=10;end % add only a few points (faster then suppressing grid)
if parameters.verbose,fprintf('adding inner regular %2.2f degree grid ...',grid_spacing1);end
[grid1_lon,grid1_lat] = meshgrid(min(entity.assets.lon):grid_spacing1:max(entity.assets.lon),...
    min(entity.assets.lat):grid_spacing1:max(entity.assets.lat));
n_elements=numel(grid1_lon);
grid1_lon=reshape(grid1_lon,1,n_elements);grid1_lat=reshape(grid1_lat,1,n_elements); % convert to vector
if parameters.verbose,fprintf(' done\n');end

if parameters.restrict_Values_to_country % reduce to assets within the country or admin1
    entity.assets.Value=entity.assets.lon*0; % init
    if isempty(selection_admin0_shape_i) % find center country
        
        % find center of centroids
        center_lon=mean(entity.assets.lon);
        center_lat=mean(entity.assets.lat);
        
        % find the country in the shape file
        admin0_shape_i=0;
        for shape_i=1:length(admin0_shapes)
            admin_hit=climada_inpolygon(center_lon,center_lat,...
                admin0_shapes(shape_i).X,admin0_shapes(shape_i).Y);
            if sum(admin_hit)>0,admin0_shape_i=shape_i;end
        end % shape_i
        selection_admin0_shape_i=admin0_shape_i(1);
        
    end
    if isempty(selection_admin1_shape_i)
        if parameters.verbose,fprintf('restricting %i assets to country %s (can take some time) ... ',...
            length(VALUES_1D),admin0_shapes(selection_admin0_shape_i).NAME);end
%         if climada_global.octave_mode
%             % Octave's inpolygon can not deal with NaNs
%             ok_pos=~isnan(admin0_shapes(selection_admin0_shape_i).X);
%             admin0_shapes(selection_admin0_shape_i).X=admin0_shapes(selection_admin0_shape_i).X(ok_pos);
%             admin0_shapes(selection_admin0_shape_i).Y=admin0_shapes(selection_admin0_shape_i).Y(ok_pos);
%         end
        admin_hit=climada_inpolygon(entity.assets.lon,entity.assets.lat,...
            admin0_shapes(selection_admin0_shape_i).X,admin0_shapes(selection_admin0_shape_i).Y);
        grid1_hit=climada_inpolygon(grid1_lon,grid1_lat,...
            admin0_shapes(selection_admin0_shape_i).X,admin0_shapes(selection_admin0_shape_i).Y);
    else
        if parameters.verbose,fprintf('restricting %i assets to admin1 %s (%s) (can take some time) ... ',...
            length(VALUES_1D),admin1_shapes(selection_admin1_shape_i).name,...
            admin1_shapes(selection_admin1_shape_i).adm1_code);
        end
%         if climada_global.octave_mode
%             % Octave's inpolygon can not deal with NaNs
%             ok_pos=~isnan(admin1_shapes(selection_admin1_shape_i).X);
%             admin1_shapes(selection_admin1_shape_i).X=admin1_shapes(selection_admin1_shape_i).X(ok_pos);
%             admin1_shapes(selection_admin1_shape_i).Y=admin1_shapes(selection_admin1_shape_i).Y(ok_pos);
%         end
        admin_hit=climada_inpolygon(entity.assets.lon,entity.assets.lat,...
            admin1_shapes(selection_admin1_shape_i).X,admin1_shapes(selection_admin1_shape_i).Y);
        grid1_hit=climada_inpolygon(grid1_lon,grid1_lat,...
            admin1_shapes(selection_admin1_shape_i).X,admin1_shapes(selection_admin1_shape_i).Y);
    end
    if parameters.verbose,fprintf('%i centroids within\n',sum(admin_hit));end
    if sum(admin_hit)>0
        entity.assets.Value(admin_hit)=VALUES_1D(admin_hit)';
        
        % now, get rid of all other fields outside of admin_hit in high res
        centroids_inside=entity.assets.lon*0; % to start with
        centroids_inside(admin_hit)=1;        % set all inside =1
        inside_pos=find(centroids_inside);    % find all inside absolute
        
        entity.assets.lon=entity.assets.lon(inside_pos); % restrict
        entity.assets.lat=entity.assets.lat(inside_pos);
        entity.assets.Value=entity.assets.Value(inside_pos);
        
        % append regular grid
        grid1_lon(grid1_hit)=[]; % remove all grid inside
        grid1_lat(grid1_hit)=[];
        entity.assets.lon   =[entity.assets.lon   grid1_lon]; % append
        entity.assets.lat   =[entity.assets.lat   grid1_lat]; % append
        entity.assets.Value =[entity.assets.Value grid1_lon*0]; % append
        entity.assets.isgridpoint=logical(entity.assets.lon*0); % init
        entity.assets.isgridpoint(end-length(grid1_lon)+1:end)=1; % indicate grid point
        % one can check with:
        %climada_circle_plot(entity.assets.isgridpoint,entity.assets.lon,entity.assets.lat);
    end
else
    entity.assets.Value=VALUES_1D';
end % params.restrict_Values_to_country

entity.assets.DamageFunID=entity.assets.Value*0+1;
entity.assets.reference_year=climada_global.present_reference_year;

if sum(parameters.nightlight_transform_poly)>0 && max(entity.assets.Value)>0
    entity.assets.Value=entity.assets.Value/max(entity.assets.Value); % normalize to range [0..1]
    entity.assets.Value = polyval(parameters.nightlight_transform_poly,entity.assets.Value); % ***********
    entity.assets.Value=entity.assets.Value/sum(entity.assets.Value); % normalize to sum=1
    entity.assets.nightlight_transform_poly=parameters.nightlight_transform_poly;
    entity.assets.comment='nightlights transformed using polynomial, then normalized to 1';
    if parameters.verbose,fprintf('%s\n',entity.assets.comment);end
end % parameters.nightlight_transform_poly

entity.assets.admin0_name=admin0_name;
entity.assets.admin0_ISO3=admin0_shapes(selection_admin0_shape_i).ADM0_A3;
if ~isempty(selection_admin1_shape_i)
    entity.assets.admin1_name=admin1_shapes(selection_admin1_shape_i).name;
    entity.assets.admin1_code=admin1_shapes(selection_admin1_shape_i).adm1_code;
end

% for consistency, update Deductible and Cover
entity.assets.Deductible=entity.assets.Value*0;
entity.assets.Cover=entity.assets.Value;


if parameters.scale_GDP && select_admin0 && parameters.restrict_Values_to_country % only one country
    % following lines added GDP and population info from shapefile, but outdated
%     entity.assets.GDP_from_shapefile=admin0_shapes(selection_admin0_shape_i).GDP_MD_EST*1e6; % USD
%     entity.assets.population_from_shapefile=admin0_shapes(selection_admin0_shape_i).POP_EST;
%     if parameters.verbose,fprintf('Note: GDP %g, Population %i (from shapefile, just for info)\n',entity.assets.GDP_from_shapefile,entity.assets.population_from_shapefile);end
    
    % Scale up asset values based on a country's estimated total asset value
    entity=climada_entity_value_GDP_adjust_one(entity,parameters.verbose); % ***********
end

if parameters.value_threshold>0
    valid_pos=find(entity.assets.Value>parameters.value_threshold);
    fprintf('keeping only %i (%2.2f%%) centroids with Value > %f\n',...
        length(valid_pos),length(valid_pos)/length(entity.assets.Value)*100,parameters.value_threshold);
    entity.assets.lon=entity.assets.lon(valid_pos);
    entity.assets.lat=entity.assets.lat(valid_pos);
    entity.assets.Value=entity.assets.Value(valid_pos);
    entity.assets.DamageFunID=entity.assets.DamageFunID(valid_pos);
    entity.assets.Deductible=entity.assets.Deductible(valid_pos);
    entity.assets.Cover=entity.assets.Cover(valid_pos);             
end % parameters.value_threshold>=0

if parameters.add_distance2coast_km
    % add distance to coast
    if parameters.verbose,fprintf('adding distance to coast [km] (might take some time) ...\n');end
    entity.assets.distance2coast_km=climada_distance2coast_km(entity.assets.lon,entity.assets.lat,parameters.check_plot);
end

if parameters.add_elevation_m
    % add elevation
    if ~exist('etopo_get','file')
        % safety to inform the user in case he misses the ETOPO module
        fprintf('Note: no elevation added (no etopo_get function found)\n Please download from github and install the climada elevation_models module\n https://github.com/davidnbresch/climada_module_elevation_models\n');
    else
        if parameters.verbose,fprintf('adding elevation [m] (might take some time) ...\n');end
        entity.assets.elevation_m=etopo_elevation_m(entity.assets.lon,entity.assets.lat,parameters.check_plot);
    end % add elevation
end

% make sure we have all fields and they are 'correct'
entity.assets = climada_assets_complete(entity.assets); 

% set value unit to 'NLX' for night light if not scaled with GDP, where X indicates highest polynomial degree:
if ~parameters.scale_GDP, entity.assets.Value_unit = repmat({sprintf('NL%i',...
        find(parameters.nightlight_transform_poly>0, 1, 'last' ))},size(entity.assets.Value)); end

if parameters.save_entity
    if parameters.verbose,fprintf('saving entity as %s\n',parameters.entity_filename);end
    entity.assets.filename=parameters.entity_filename;
    save(parameters.entity_filename,'entity');
    if parameters.verbose,fprintf('consider encoding entity to a particular hazard, see climada_assets_encode\n');end
end

if parameters.check_plot>2
    hold on
    climada_entity_plot(entity);
    hold off;drawnow
end

end % climada_nightlight_entity
