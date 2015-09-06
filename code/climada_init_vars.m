function ok=climada_init_vars(reset_flag)
% init variables global
% NAME:
%	climada_init_vars
% PURPOSE:
%	initialize path and filenames
%
% CALLING SEQUENCE:
%	ok=climada_init_vars(reset_flag)
% EXAMPLE:
%	ok=climada_init_vars;
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   reset_flag: if set to 1, forced re-init
% OUTPUTS:
%	ok: =1 if no troubles, 0 else
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20120430
% David N. Bresch, david.bresch@gmail.com, 20130316, EDS->EDS...
% David N. Bresch, david.bresch@gmail.com, 20130623, re_check_encoding
% Lea Mueller, muellele@gmail.com, 20140211, start year set to 2014
% David N. Bresch, david.bresch@gmail.com, 20141018, switch to modules instead of climada_additional
% David N. Bresch, david.bresch@gmail.com, 20141225, climada_global.coastline_file added
% David N. Bresch, david.bresch@gmail.com, 20141226, update to be in line with manual
% David N. Bresch, david.bresch@gmail.com, 20141231, octave compatibility
% David N. Bresch, david.bresch@gmail.com, 20150126, csv_delimiter depends on computer
% David N. Bresch, david.bresch@gmail.com, 20150203, climada_lonlat_cleanup
% David N. Bresch, david.bresch@gmail.com, 20150211, global_CAGR added
% Lea Mueller, muellele@gmail.com, 20150728, add project directory,i.e. now set to San Salvador
% Lea Mueller, muellele@gmail.com, 20150728, set waitbar to 0
% David N. Bresch, david.bresch@gmail.com, 20150805, project_dir NOT possible to set here, set to default data dir
% David N. Bresch, david.bresch@gmail.com, 20150805, climada_demo_gui parameters set here
% David N. Bresch, david.bresch@gmail.com, 20150807, climada_global.tc.extratropical_transition
% David N. Bresch, david.bresch@gmail.com, 20150819, climada_global.centroids_dir introduced
% Lea Mueller, muellele@gmail.com, 20150831, introduce climada_global.Value_unit
% David N. Bresch, david.bresch@gmail.com, 20150906, climada_global.font_scale

global climada_global

% PARAMETERS
%

ok=1;

persistent climada_vars_initialised % used to communicate status of initialisation

if exist('reset_flag','var')
    if reset_flag==1
        climada_vars_initialised=[]; % force re-init
    end
end

if length(climada_vars_initialised)<1 % initialise and check only first time called
    
    %warning off MATLAB:divideByZero % avoid division by zero Warnings OLD removed 20141016
    warning off MATLAB:griddata:DuplicateDataPoints % avoid duplicate data points Warnings
    warning off MATLAB:nonIntegerTruncatedInConversionToChar % alloe eg conversion of NaN to empty char
    
    % first, check some MATLAB version specifics
    % ------------------------------------------
    
    climada_LOCAL_ROOT_DIR=getenv('climada_LOCAL_ROOT_DIR'); % get operating system's environment variable
    climada_LOCAL_ROOT_DIR=strrep(climada_LOCAL_ROOT_DIR,'"','');
    
    if exist(climada_LOCAL_ROOT_DIR,'dir')
        % if the environment variable exists, it overrides all other settings
        climada_global.root_dir=climada_LOCAL_ROOT_DIR;
        fprintf('local root dir %s (from environment variable climada_LOCAL_ROOT_DIR)\n',climada_global.root_dir);
    else
        
        % directory settings
        % -------------------
        
        % next code bit to access already defined root directory (by startup.m)
        if ~exist('climada_global','var')
            climada_global.root_dir='';
        elseif ~isfield(climada_global,'root_dir')
            climada_global.root_dir='';
        end
        
        if ~exist(climada_global.root_dir,'dir')
            climada_global.root_dir=['C:' filesep 'Documents and Settings' filesep 'All Users' filesep 'Documents' filesep 'climada'];
        end
        
        if ~exist(climada_global.root_dir,'dir')
            climada_global.root_dir=['D:' filesep 'Data' filesep 'climada'];
        end
        
    end % climada_LOCAL_ROOT_DIR
    
    % set and check the directory tree
    % --------------------------------
    
    climada_global.data_dir=[climada_global.root_dir filesep 'data'];
    alternative_data_dir=[fileparts(climada_global.root_dir) filesep 'climada_data'];
    if exist(alternative_data_dir,'dir')
        fprintf('\nNOTE: switched to data dir %s\n',alternative_data_dir);
        climada_global.data_dir=alternative_data_dir;
    end
    if ~exist(climada_global.data_dir,'dir')
        fprintf('WARNING: please create %s manually\n',climada_global.data_dir);
    end
    climada_global.system_dir=[climada_global.data_dir filesep 'system'];
    if ~exist(climada_global.system_dir,'dir')
        fprintf('WARNING: please create %s manually\n',climada_global.system_dir);
    end
    climada_global.centroids_dir=[climada_global.data_dir filesep 'centroids']; % added 20150819
    if ~exist(climada_global.centroids_dir,'dir')
        fprintf('WARNING: please create %s manually\n',climada_global.centroids_dir);
        climada_global.centroids_dir=climada_global.system_dir;
        fprintf('--> ad interim centroids in system folder (backward compatibility, too)\n');
    end
    % the map border file as used by climada_plot_world_borders
    % (see the short documentation in climada_global.system_dir/admin0.txt)
    climada_global.map_border_file=[climada_global.system_dir filesep 'admin0.mat'];
    %climada_global.map_border_file=[climada_global.system_dir filesep 'world_50m.gen']; % until 20141210
    
    % the global coastline file
    % (see the short documentation in climada_global.system_dir/coastline.txt)
    climada_global.coastline_file=[climada_global.system_dir filesep 'coastline.mat'];
    
    % the default spreadsheet type, either '.xls' (default) or '.ods'
    % the user can always select from 'All Files', the default is only
    % used to compose the default filename.
    climada_global.spreadsheet_ext='.xls'; % default '.xls'
    
    % country-specific csv delimiter (to read and convert to Excel properly)
    climada_global.csv_delimiter=';'; % ';' default
    if strfind(computer,'MAC'),climada_global.csv_delimiter=',';end
    
    % tropical cyclone (TC) specific parameters
    climada_global.tc.default_min_TimeStep=1; % 1 hour, see climada_tc_equal_timestep
    % the file extension of the raw TC track data files, see centroids_generate_hazard_sets
    % '.txt' for UNISYS files (http://weather.unisys.com/hurricane/index.html)
    % '.nc' for netCDF files
    climada_global.tc.default_raw_data_ext='.txt'; % default '.txt'
    % in climada_tc_windfield, treat the extratropical transition celerity
    % exceeding vmax problem an issue e.g. for Northern US, where this should be set=1 
    climada_global.tc.extratropical_transition=0; % default =0 (original Holland)
    
    % define asset value units (e.g. USD or people)
    climada_global.Value_unit = 'USD';
    
    % evaluation and NPV (net present value) specific parameters
    climada_global.present_reference_year = 2014; % yyyy
    climada_global.future_reference_year  = 2030; % yyyy
    % time dependence of impacts (1 for linear, default)
    % >1 concave (eg 2: cubic), <1 for convex (eg 1/2: like quare root)
    % concave means: damage increases slowly first (see climada_measures_impact)
    climada_global.impact_time_dependence = 1; % 1 for linear
    % define the default global compound annual growth rate (CAGR)
    climada_global.global_CAGR=0.02; % default 0.02 for 2%
    
    % standard return periods for DFC report
    climada_global.DFC_return_periods=[1 5 10 20 25 30 35 40 45 50 75 100 125 150 175 200 250 300 400 500 1000];
    
    % whether we show waitbars for progress (eg in climada_EDS_calc), =1:yes, =0: no
    climada_global.waitbar=0;
    
    % whether we store the damage (=1) at each centroid for each event (an EDS
    % for each centroid). Heavy memory, see climada_EDS_calc; therefore: default=0
    % please note that ED_at_centroid is always calculated (only a vector
    % length number of centroids)
    climada_global.EDS_at_centroid=0; % default=0
    
    % whether the code checks for (possible) asset encoding issues and
    % re-encodes in case of doubt (might take time...)
    % =0: no double check, faster, user needs to know what he's calculating ;-)
    % =1: if ~all(diff(entity.assets.centroid_index) == 1) etc., re-encoded
    climada_global.re_check_encoding = 0; % default =0
    
    % set some parameters for climada_demo_gui (allows users to make use of
    % the GUI for their own purpose, i.e. other entity...) 
    climada_global.demo_gui.entity_excel_file     =[climada_global.data_dir filesep 'entities' filesep 'demo_today.xls'];
    climada_global.demo_gui.hazard_present        =[climada_global.data_dir filesep 'hazards' filesep 'TCNA_today_small.mat'];
    climada_global.demo_gui.hazard_moderate_change=[climada_global.data_dir filesep 'hazards' filesep 'TCNA_2030med_small.mat'];
    climada_global.demo_gui.hazard_high_change    =[climada_global.data_dir filesep 'hazards' filesep 'TCNA_2030high_small.mat'];

    % set project directory, the user can this way store some data in his
    % own folders, outside of core climada (e.g. no automatic sync with GitHub)
    climada_global.project_dir = climada_global.data_dir;
    
    % to scale (some) fonts in plots, usefule to create eg ppt visuals
    % (larger fonts than on the screen for expert users)
    climada_global.font_scale=1; % integer only, please, default=1, useful for ppt is 2 or 3
    
    climada_vars_initialised=1; % indicate we have initialized all vars
    
    % whether we run on Octave
    climada_global.octave_mode=0; % default=0
    
    % last but not least, check for Octave (instead of MATLAB)
    if climada_octave
        climada_global.octave_mode=1;
        fprintf('Note: running on Octave\n')
    end
    
    % !!!!!!!!!!!!!!!!!!!!!!!!!
    % a temporary cleanup item (to be removed summer 2015 latest)
    cleanup_check_file=[climada_global.system_dir filesep 'climada_lonlat_cleanup_done.txt'];
    if ~exist(cleanup_check_file,'file')
        if climada_lonlat_cleanup
            fid=fopen(cleanup_check_file,'w');
            fprintf(fid,'climada_lonlat_cleanup run at %s\n',datestr(now));
            fclose(fid);
        end
    else
        fprintf('OK: migrated to lon/lat instead of Longitude/Latitude\n');
    end
    
    % !!!!!!!!!!!!!!!!!!!!!!!!!
    % a temporary cleanup item (to be removed winter 2015 latest)
    cleanup_check_file=[climada_global.system_dir filesep 'climada_centroids_cleanup_done.txt'];
    if ~exist(cleanup_check_file,'file')
        if climada_centroids_cleanup
            fid=fopen(cleanup_check_file,'w');
            fprintf(fid,'climada_centroids_cleanup run at %s\n',datestr(now));
            fclose(fid);
        end
    else
        fprintf('OK: centroids moved into own folder (out of system)\n');
    end
    % !!!!!!!!!!!!!!!!!!!!!!!!!
    
end

return