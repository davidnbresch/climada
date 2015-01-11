function [shapes,whole_world_borders]=climada_shaperead(shape_filename,mat_save_flag,create_world_borders,force_reread,silent_mode)
% climada
% NAME:
%   climada_shaperead
% PURPOSE:
%   read a shape file and return shapes structure. See shaperead (likely in
%   mapping toolbox)
%
%   See climada module country_risk for e.g. a global admin0 (country) and
%   admin1 (state/prvince) shape file.
%
%   Note that this code requires the mapping toolbox, that's why the binary
%   version of the admin0 shapes is stored as ../data/system/admin0.mat
%
%   Stores a .mat binary file with shapes for subsequent fast access
% CALLING SEQUENCE:
%   shapes=climada_shaperead(shape_filename,mat_save_flag,create_world_borders,force_reread,silent_mode);
% EXAMPLE:
%   shapes=climada_shaperead(shape_filename);
%   shapes=climada_shaperead('SYSTEM_ADMIN0');    % re-create ../data/system/admin0.mat
%   shapes=climada_shaperead('SYSTEM_COASTLINE'); % re-create ../data/system/coastline.mat
% INPUTS:
%   shape_filename: filename (with path) of a shapefile
%       > promted for if not given
%
%       Special case: if set to 'SYSTEM_ADMIN0', the core climada
%       admin0.mat file is re-created (requires country_risk module).
%       Note that in this case, country names are unified, see
%       reference_ISO3_country_name in PARAMETERS in code)
%       Note that in this case, some shapes are reduced to the comestic
%       part of the countries, namely for France, Netherlands, Norway, New
%       Zealand, Portugal, Russia and United States (see special_shape in
%       PARAMETERS in code and also see SYSTEM_ADMIN0 flag in code)
%
%       Special case: if set to 'SYSTEM_COASTLINE', the core climada
%       coastline.mat file is re-created (requires country_risk module).
%       The coastline is saved as one large 'Point' structure, in order to
%       speed up calculations in climada_distance2coast_km
%       That's currently the key use of the coastline. Since segments are
%       still separated by NaN, one can use plot(shapes.X,shapes.Y,'-r') to
%       show the coastline as line. In order to get the original shapes,
%       one needs to read the source .shp file again (see PARAMETERS in
%       code and also see SYSTEM_ADMIN0 flag in code, since the source file
%       is defined relative to the country_risk module and hence done only
%       if requested).
% OPTIONAL INPUT PARAMETERS:
%   mat_save_flag: =1: do save as .mat file (default)
%       =0: do not save as .mat file
%   create_world_borders: =1: create whole_world_borders which contains all
%       shapes in one structure for fast (global) plotting (no loop needed)
%       =0: do not do so (default)
%       See code, currently DISABLED, since it doubles the size of the .mat
%       file but plotting world borders only takes 0.35 sec compared to 0.25
%       sec. But kept in code (commented, as this might matter for even
%       higher border shape resolution)
%   force_reread: =1 force re-reading the original shape file
%       =0: use the .mat file if existing
%   silent_mode: =1, do not print anything,
%       =0: print shape filename (default)
% OUTPUTS:
%   shapes: a shapes structure, containing one element for each non-null
%       geographic feature in the shapefile. shapes is a "mapstruct" geographic
%       data structure array and combines coordinates/geometry, expressed in
%       terms of map X and Y, with non-spatial feature attributes.
%   whole_world_borders: a simpler structure with all shapes in one for
%       fast plotting, see e.g. climada_plot_world_borders (only genersted
%       if create_world_borders=1). DISABLED, see above.
%       In case you need whole_world_borders, add the following lines to
%       your code:
%           load(climada_global.map_border_file);
%           whole_world_borders.lon = [];
%           whole_world_borders.lat = [];
%           for i=1:length(shapes)
%               whole_world_borders.lon = [whole_world_borders.lon; shapes(i).X'];
%               whole_world_borders.lat = [whole_world_borders.lat; shapes(i).Y'];
%           end
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141211, initial
% David N. Bresch, david.bresch@gmail.com, 20141212, SYSTEM_ADMIN0 added
% David N. Bresch, david.bresch@gmail.com, 20141221, restriction to domestic for SYSTEM_ADMIN0
% David N. Bresch, david.bresch@gmail.com, 20141225, SYSTEM_COASTLINE added
%-

shapes=[]; % init output
whole_world_borders=[]; % init, see special admin0 section below

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('shape_filename','var'),shape_filename='';end
if ~exist('mat_save_flag','var'),mat_save_flag=1;end % default=1
if ~exist('create_world_borders','var'),create_world_borders=0;end % default=0
if ~exist('force_reread','var'),force_reread=0;end % default=0
if ~exist('silent_mode','var'),silent_mode=0;end % default=0

% PARAMETERS
%
% special treatement for SYSTEM_ADMIN0
%
% the consolidated reference country names as in the Excel file ../data/system/admin0.xls
% see tab 'combined' and column 'transfer for climada_shaperead'
reference_ISO3_country_name={
    'ABW','Aruba'
    'AFG','Afghanistan'
    'AGO','Angola'
    'AIA','Anguilla'
    'ALB','Albania'
    'ALD','Aland'
    'AND','Andorra'
    'ARE','United Arab Emirates'
    'ARG','Argentina'
    'ARM','Armenia'
    'ASM','American Samoa'
    'ATA','Antarctica'
    'ATC','Ashmore and Cartier Islands'
    'ATF','French Southern and Antarctic Lands '
    'ATG','Antigua and Barbuda'
    'AUS','Australia'
    'AUT','Austria'
    'AZE','Azerbaijan'
    'BDI','Burundi'
    'BEL','Belgium'
    'BEN','Benin'
    'BFA','Burkina Faso'
    'BGD','Bangladesh'
    'BGR','Bulgaria'
    'BHR','Bahrain'
    'BHS','Bahamas'
    'BIH','Bosnia and Herzegovina'
    'BJN','Bajo Nuevo Bank (Petrel Islands)'
    'BLM','St-Barthelemy'
    'BLR','Belarus'
    'BLZ','Belize'
    'BMU','Bermuda'
    'BOL','Bolivia'
    'BRA','Brazil'
    'BRB','Barbados'
    'BRN','Brunei'
    'BTN','Bhutan'
    'BWA','Botswana'
    'CAF','Central African Republic'
    'CAN','Canada'
    'CHE','Switzerland'
    'CHL','Chile'
    'CHN','China'
    'CIV','Cote dIvoire'
    'CLP','Clipperton Island'
    'CMR','Cameroon'
    'CNM','Cyprus UN Buffer Zone'
    'COD','Democratic Republic of the Congo'
    'COG','Congo'
    'COK','Cook Islands'
    'COL','Colombia'
    'COM','Comoros'
    'CPV','Cape Verde'
    'CRI','Costa Rica'
    'CSI','Coral Sea Islands'
    'CUB','Cuba'
    'CUW','Curacao'
    'CYM','Cayman Islands'
    'CYN','North Cyprus'
    'CYP','Cyprus'
    'CZE','Czech Republic'
    'DEU','Germany'
    'DJI','Djibouti'
    'DMA','Dominica'
    'DNK','Denmark'
    'DOM','Dominican Republic'
    'DZA','Algeria'
    'ECU','Ecuador'
    'EGY','Egypt'
    'ERI','Eritrea'
    'ESB','Dhekelia'
    'ESP','Spain'
    'EST','Estonia'
    'ETH','Ethiopia'
    'FIN','Finland'
    'FJI','Fiji'
    'FLK','Falkland Islands'
    'FRA','France'
    'FRO','Faeroe Islands'
    'FSM','Micronesia'
    'GAB','Gabon'
    'GBR','United Kingdom'
    'GEO','Georgia'
    'GGY','Guernsey'
    'GHA','Ghana'
    'GIB','Gibraltar'
    'GIN','Guinea'
    'GMB','Gambia'
    'GNB','Guinea-Bissau'
    'GNQ','Equatorial Guinea'
    'GRC','Greece'
    'GRD','Grenada'
    'GRL','Greenland'
    'GTM','Guatemala'
    'GUM','Guam'
    'GUY','Guyana'
    'HKG','Hong Kong'
    'HMD','Heard Island and McDonald Islands '
    'HND','Honduras'
    'HRV','Croatia'
    'HTI','Haiti'
    'HUN','Hungary'
    'IDN','Indonesia'
    'IMN','Isle of Man'
    'IND','India'
    'IOA','Indian Ocean Territory'
    'IOT','British Indian Ocean Territory'
    'IRL','Ireland'
    'IRN','Iran'
    'IRQ','Iraq'
    'ISL','Iceland'
    'ISR','Israel'
    'ITA','Italy'
    'JAM','Jamaica'
    'JEY','Jersey'
    'JOR','Jordan'
    'JPN','Japan'
    'KAB','Baikonur'
    'KAS','Siachen Glacier'
    'KAZ','Kazakhstan'
    'KEN','Kenya'
    'KGZ','Kyrgyzstan'
    'KHM','Cambodia'
    'KIR','Kiribati'
    'KNA','Saint Kitts and Nevis'
    'KOR','Korea'
    'KOS','Kosovo'
    'KWT','Kuwait'
    'LAO','Laos'
    'LBN','Lebanon'
    'LBR','Liberia'
    'LBY','Libya'
    'LCA','Saint Lucia'
    'LIE','Liechtenstein'
    'LKA','Sri Lanka'
    'LSO','Lesotho'
    'LTU','Lithuania'
    'LUX','Luxembourg'
    'LVA','Latvia'
    'MAC','Macao'
    'MAF','Saint Martin'
    'MAR','Morocco'
    'MCO','Monaco'
    'MDA','Moldova'
    'MDG','Madagascar'
    'MDV','Maldives'
    'MEX','Mexico'
    'MHL','Marshall Islands'
    'MKD','Macedonia'
    'MLI','Mali'
    'MLT','Malta'
    'MMR','Myanmar'
    'MNE','Montenegro'
    'MNG','Mongolia'
    'MNP','Northern Mariana Islands'
    'MOZ','Mozambique'
    'MRT','Mauritania'
    'MSR','Montserrat'
    'MUS','Mauritius'
    'MWI','Malawi'
    'MYS','Malaysia'
    'NAM','Namibia'
    'NCL','New Caledonia'
    'NER','Niger'
    'NFK','Norfolk Island'
    'NGA','Nigeria'
    'NIC','Nicaragua'
    'NIU','Niue'
    'NLD','Netherlands'
    'NOR','Norway'
    'NPL','Nepal'
    'NRU','Nauru'
    'NZL','New Zealand'
    'OMN','Oman'
    'PAK','Pakistan'
    'PAN','Panama'
    'PCN','Pitcairn Islands'
    'PER','Peru'
    'PGA','Spratly Islands'
    'PHL','Philippines'
    'PLW','Palau'
    'PNG','Papua New Guinea'
    'POL','Poland'
    'PRI','Puerto Rico'
    'PRK','North Korea'
    'PRT','Portugal'
    'PRY','Paraguay'
    'PSX','Palestine'
    'PYF','French Polynesia'
    'QAT','Qatar'
    'ROU','Romania'
    'RUS','Russia'
    'RWA','Rwanda'
    'SAH','Western Sahara'
    'SAU','Saudi Arabia'
    'SCR','Scarborough Reef'
    'SDN','Sudan'
    'SDS','South Sudan'
    'SEN','Senegal'
    'SER','Serranilla Bank'
    'SGP','Singapore'
    'SGS','South Georgia and South Sandwich Islands'
    'SHN','Saint Helena'
    'SLB','Solomon Islands'
    'SLE','Sierra Leone'
    'SLV','El Salvador'
    'SMR','San Marino'
    'SOL','Somaliland'
    'SOM','Somalia'
    'SPM','Saint Pierre and Miquelon'
    'SRB','Serbia'
    'STP','Sao Tome and Principe'
    'SUR','Suriname'
    'SVK','Slovakia'
    'SVN','Slovenia'
    'SWE','Sweden'
    'SWZ','Swaziland'
    'SXM','Sint Maarten'
    'SYC','Seychelles'
    'SYR','Syria'
    'TCA','Turks and Caicos Islands'
    'TCD','Chad'
    'TGO','Togo'
    'THA','Thailand'
    'TJK','Tajikistan'
    'TKM','Turkmenistan'
    'TLS','Timor-Leste'
    'TON','Tonga'
    'TTO','Trinidad and Tobago'
    'TUN','Tunisia'
    'TUR','Turkey'
    'TUV','Tuvalu'
    'TWN','Taiwan'
    'TZA','Tanzania'
    'UGA','Uganda'
    'UKR','Ukraine'
    'UMI','US Minor Outlying Islands'
    'URY','Uruguay'
    'USA','United States'
    'USG','USNB Guantanamo Bay'
    'UZB','Uzbekistan'
    'VAT','Vatican'
    'VCT','Saint Vincent and the Grenadines'
    'VEN','Venezuela'
    'VGB','British Virgin Islands'
    'VIR','US Virgin Islands'
    'VNM','Vietnam'
    'VUT','Vanuatu'
    'WLF','Wallis and Futuna Islands'
    'WSB','Akrotiri'
    'WSM','Samoa'
    'YEM','Yemen'
    'ZAF','South Africa'
    'ZMB','Zambia'
    'ZWE','Zimbabwe'
    };
%
% special treatement for SYSTEM_ADMIN0
% special treatment for some countries wth overseas territories
% the shapes(i).X will contain the core or domestic shape, not including
% all overseas territories (all shapes are back up in X_ALL and Y_ALL)
% if no seleciton (e.g. in one direction), use X=[-91 91], Y=[-181 181]
% set special_shape=[]; to suppress any restriction
special_shape(1).NAME='France';
special_shape(1).X_range=[-20 20]; % the X range of domestic France
special_shape(1).Y_range=[30 70];  % the Y range of domestic France
special_shape(2).NAME='Netherlands';
special_shape(2).X_range=[0 20];
special_shape(2).Y_range=[50 70];
special_shape(3).NAME='Norway';
special_shape(3).X_range=[0 181];
special_shape(3).Y_range=[50 91];
special_shape(4).NAME='New Zealand';
special_shape(4).X_range=[150 181];
special_shape(4).Y_range=[-91 91];
special_shape(5).NAME='Portugal';
special_shape(5).X_range=[-12 10];
special_shape(5).Y_range=[-91 91];
special_shape(6).NAME='Russia';
special_shape(6).X_range=[0 181];
special_shape(6).Y_range=[-91 91];
special_shape(7).NAME='United States';
special_shape(7).X_range=[-150 50];
special_shape(7).Y_range=[20 50];
%


% prompt for shape_filename if not given
if isempty(shape_filename) % local GUI
    shape_filename=[climada_global.system_dir filesep '*.shp'];
    [filename, pathname] = uigetfile(shape_filename, 'Select shape file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        shape_filename=fullfile(pathname,filename);
    end
end

if strcmp(shape_filename,'SYSTEM_ADMIN0') % Special case
    SYSTEM_ADMIN0=1;
    % The shape_filename used to create the admin0.mat file (the code later
    % moves the ne_10m_admin_0_countries.mat after creation to core climada
    % ../system/admin0.mat)
    if isempty(which('country_risk_calc'))
        fprintf('ERROR %s: file with admin0 shape information not found: ne_10m_admin_0_countries.shp\n',mfilename);
        fprintf(' - consider installing climada module country_risk from\n');
        fprintf('   https://github.com/davidnbresch/climada_module_country_risk\n');
        return
    end
    country_risk_module_data_dir=[fileparts(fileparts(which('country_risk_calc'))) filesep 'data'];
    shape_filename=[country_risk_module_data_dir ...
        filesep 'ne_10m_admin_0_countries' filesep 'ne_10m_admin_0_countries.shp'] % no ; to show hard-wired
    fprintf('Note: %s, special case, system admin0.mat file re-created\n',mfilename);
    force_reread=1;
else
    SYSTEM_ADMIN0=0; % default
end

if strcmp(shape_filename,'SYSTEM_COASTLINE') % Special case
    SYSTEM_COASTLINE=1;
    % The shape_filename used to create the admin0.mat file (the code later
    % moves the ne_10m_admin_0_countries.mat after creation to core climada
    % ../system/admin0.mat)
    if isempty(which('country_risk_calc'))
        fprintf('ERROR %s: file with coastline information not found: ne_10m_coastline.shp\n',mfilename);
        fprintf(' - consider installing climada module country_risk from\n');
        fprintf('   https://github.com/davidnbresch/climada_module_country_risk\n');
        return
    end
    country_risk_module_data_dir=[fileparts(fileparts(which('country_risk_calc'))) filesep 'data'];
    shape_filename=[country_risk_module_data_dir ...
        filesep 'ne_10m_coastline' filesep 'ne_10m_coastline.shp'] % no ; to show hard-wired
    fprintf('Note: %s, special case, system coastline.mat file re-created\n',mfilename);
    force_reread=1;
else
    SYSTEM_COASTLINE=0; % default
end

[fP,fN] = fileparts(char(shape_filename)); % to be on the safe side
shape_mat_filename=[fP filesep fN '.mat'];

if climada_check_matfile(shape_filename,shape_mat_filename) && ~force_reread
    % there is a .mat file more recent than the original shape file, load it
    load(shape_mat_filename) % contains struct named 'shapes'
    
    % see comment to create_world_borders below
    %     if isempty(whole_world_borders) && create_world_borders
    %         [shapes,whole_world_borders]=climada_shaperead(shape_filename,mat_save_flag,create_world_borders,1);
    %     end
    
else
    
    % read shape file
    if ~silent_mode,fprintf('reading shapes from %s\n',shape_filename);end
    shapes=shaperead(shape_filename);
    
    % get rid of non-ASCII portions of UTF characters
    % following code bit does NOT work, since ? is not 'seen'
    % only works as strrep('Saint-Barth??lemy','?','?') on command window
    %     field_names = fieldnames(shapes);
    %     for field_i=1:length(field_names)
    %         if ischar(field_names{field_i})
    %             fprintf('treating %s\n',field_names{field_i});
    %             for shape_i=1:length(shapes)
    %                 shapes(shape_i).(field_names{field_i})=strrep(shapes(shape_i).(field_names{field_i}),'?','?');
    %             end % shape_i
    %         end
    %     end % field_i
    
    % following switched OFF, since it doubles the size of the .mat file
    % but plotting world borders only takes 0.4 sec compared to 0.25 sec.
    % -> see climada module GDP_entity and climada_load_world_borders
    %
    %     if create_world_borders
    %
    %         % create whole_world_borders which contains all shapes in one
    %         % structure for fast (global) plotting (no loop needed). See e.g.
    %         % climada_plot_world_borders
    %
    %         if ~strcmp(shapes(1).Geometry,'Line'),fprintf('WARNING: shapes might not contain lines\n');end
    %
    %         % store also in one contiguous list (for plot speedup)
    %         whole_world_borders.lon = [];
    %         whole_world_borders.lat = [];
    %         for i=1:length(shapes)
    %             whole_world_borders.lon = [whole_world_borders.lon; shapes(i).X']; % NaN at end already there
    %             whole_world_borders.lat = [whole_world_borders.lat; shapes(i).Y']; % NaN at end already there
    %         end
    %     else
    %         whole_world_borders=[];
    %     end
    %
    % see also commented line in if mat_save_flag below
    
    if SYSTEM_ADMIN0
        
        % Special case: the core climada ..data/system/admin0.mat file is re-created
        % (requires country_risk module). Note that in this case, country
        % names are unified, see reference_ISO3_country_name in PARAMETERS
        % in code). Note that in this case, some shapes are reduced to the
        % comestic part of the countries, namely for France, Netherlands,
        % Norway, New Zealand, Portugal, Russia and United States (see
        % special_shape in PARAMETERS in code)
        
        if isfield(shapes(1),'ADM0_A3') && isfield(shapes(1),'NAME')
            fprintf('Note: %s: matching country names to consolidated reference ones\n',mfilename)
            % SPECIAL case to replace country names by consolidated reference ones
            % See also the Excel file ../data/system/admin0.xls
            match_count=0; % init
            for shape_i=1:length(shapes)
                plot(shapes(shape_i).X,shapes(shape_i).Y,'-k');hold on;
                match_pos=strcmp(reference_ISO3_country_name(:,1),shapes(shape_i).ADM0_A3); % match ISO3
                if sum(match_pos)>0
                    % replace name
                    shapes(shape_i).NAME=reference_ISO3_country_name{match_pos,2};
                    match_count=match_count+1;
                else
                    fprintf('%s (%s) not matched\n',shapes(shape_i).NAME,shapes(shape_i).ADM0_A3)
                end
            end % shape_i
            fprintf('%i of %i country names matched\n',match_count,length(shapes));
        end
        
        if ~isempty(special_shape)
            fprintf('Note: %s: restricting shapes to domestic: ',mfilename)
            % SPECIAL treatment for some countries wth overseas territories
            for special_shape_i=1:length(special_shape)
                match_shape_i=[];
                for shape_i=1:length(shapes) % find country
                    if strcmp(shapes(shape_i).NAME,special_shape(special_shape_i).NAME)
                        match_shape_i=shape_i;
                    end
                end
                if ~isempty(match_shape_i)
                    isnan_pos=find(isnan(shapes(match_shape_i).X)); % find sub-shapes
                    i1=1;X_dom=[];Y_dom=[]; % init
                    X_range=special_shape(special_shape_i).X_range;
                    Y_range=special_shape(special_shape_i).Y_range;
                    for isnan_pos_i=1:length(isnan_pos)
                        i2=isnan_pos(isnan_pos_i);
                        X=shapes(match_shape_i).X(i1:i2);
                        Y=shapes(match_shape_i).Y(i1:i2);
                        if (min(X)>X_range(1) && max(X)<X_range(2)) && (min(Y)>Y_range(1) && max(Y)<Y_range(2))
                            plot(shapes(match_shape_i).X(i1:i2),shapes(match_shape_i).Y(i1:i2),'-r')
                            hold on;
                            X_dom=[X_dom shapes(match_shape_i).X(i1:i2)];
                            Y_dom=[Y_dom shapes(match_shape_i).Y(i1:i2)];
                        end
                        i1=i2;
                        
                        % k = waitforbuttonpress % for TEST one shape added at a time
                        
                    end % isnan_pos_i
                    plot(X_dom,Y_dom,'-g')
                    
                    fprintf('%s, ',special_shape(special_shape_i).NAME);
                    shapes(match_shape_i).X_ALL=shapes(match_shape_i).X;
                    shapes(match_shape_i).X=X_dom;
                    shapes(match_shape_i).Y_ALL=shapes(match_shape_i).Y;
                    shapes(match_shape_i).Y=Y_dom;
                    
                end % ~isempty(match_shape_i)
            end % special_shape_i
            fprintf('\n');
        end % special_shape
        
    elseif SYSTEM_COASTLINE
        
        % Special case: the core climada ..data/system/coastline.mat file is re-created
        % (requires country_risk module). Convert the 'Line' segment shapes
        % to one large 'Point' shape to speed up calculations, see e.g.
        % climada_distance2coast_km
        
        fprintf('Note: %s: converting ''Line'' coastline to ''Point'' shape\n',mfilename)
        X=[];Y=[];
        for shape_i=1:length(shapes)
            X=[X shapes(shape_i).X];
            Y=[Y shapes(shape_i).Y];
        end % shape_i
        
        clear shapes
        shapes.Geometry='Point';
        shapes.X=X;
        shapes.Y=Y;
        
        fprintf('coastline saved in %s (Geometry=''Point'')\n',climada_global.coastline_file)
        save(climada_global.coastline_file,'shapes');
        mat_save_flag=0;
        
        % plot(shapes.X,shapes.Y,'.r') % for checkplot
        
    end % SYSTEM_ADMIN0 or SYSTEM_COASTLINE
    
    if mat_save_flag
        % save as .mat for fast re-load
        if ~silent_mode,fprintf('shapes saved in %s\n',shape_mat_filename);end
        save(shape_mat_filename,'shapes');
        %         save(shape_mat_filename,'shapes','whole_world_borders');
        
        if SYSTEM_ADMIN0
            % copy the file as default admin0.mat file to core climada ..data/system/admin0.mat
            fprintf('copying %s to %s...',shape_mat_filename,climada_global.map_border_file)
            [SUCCESS,MESSAGE] = copyfile(shape_mat_filename,climada_global.map_border_file);
            if SUCCESS
                fprintf('done\n')
            else
                fprintf('ERROR: %s\n',MESSAGE)
            end
        end
        
    end % mat_save_flag
    
end % climada_check_matfile

return