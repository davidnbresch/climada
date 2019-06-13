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
%   silent_mode: =1, do not print anything, do not show plots
%       =0: print shape filename and show plot for admin0 check (default)
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
% Lea Mueller, muellele@gmail.com, 20160229, add semicolon
% David N. Bresch, david.bresch@gmail.com, 20161007, missing (sub) countries searched for and added
% David N. Bresch, david.bresch@gmail.com, 20161008, sub country treatement moved to climada_admin0_fix
% David N. Bresch, david.bresch@gmail.com, 20190521, load(...,'shapes')
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
% special treatement for SYSTEM_ADMIN0, see below and climada_admin0_fix
% the consolidated reference country names have been moved to climada_admin0_fix
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
        fprintf([' - consider installing ' ...
            '<a href="https://github.com/davidnbresch/climada_module_country_risk">'...
            'climada_module_country_risk</a> from Github.\n'])
        return
    end
    country_risk_module_data_dir=[fileparts(fileparts(which('country_risk_calc'))) filesep 'data'];
    shape_filename=[country_risk_module_data_dir ...
        filesep 'ne_10m_admin_0_countries' filesep 'ne_10m_admin_0_countries.shp']; % no ; to show hard-wired
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
        filesep 'ne_10m_coastline' filesep 'ne_10m_coastline.shp']; % no ; to show hard-wired
    fprintf('Note: %s, special case, system coastline.mat file re-created\n',mfilename);
    force_reread=1;
else
    SYSTEM_COASTLINE=0; % default
end

[fP,fN] = fileparts(char(shape_filename)); % to be on the safe side
shape_mat_filename=[fP filesep fN '.mat'];

if climada_check_matfile(shape_filename,shape_mat_filename) && ~force_reread
    % there is a .mat file more recent than the original shape file, load it
    load(shape_mat_filename,'shapes') % contains struct named 'shapes'
    
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
        
        [shapes,admin0_info]=climada_admin0_fix(shapes,~silent_mode); % admin0_info saved to .mat below
             
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
        %save(shape_mat_filename,'shapes','whole_world_borders'); % OLD, see above
        
        if SYSTEM_ADMIN0
            save(shape_mat_filename,'shapes','admin0_info'); % add admin0_info
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