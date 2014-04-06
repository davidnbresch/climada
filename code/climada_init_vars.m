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
%-

global climada_global

% PARAMETERS
%

ok=1;

warning off MATLAB:divideByZero % avoid division by zero Warnings
warning off MATLAB:griddata:DuplicateDataPoints % avoid duplicate data points Warnings
warning off MATLAB:nonIntegerTruncatedInConversionToChar % alloe eg conversion of NaN to empty char
persistent climada_vars_initialised % used to communicate status of initialisation

if exist('reset_flag','var')
    if reset_flag==1
        % force re-init
        climada_vars_initialised=[];
    end
end

if length(climada_vars_initialised)<1 % initialise and check only first time called

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
    if ~exist(climada_global.data_dir,'dir')
        fprintf('WARNING: please create %s manually\n',climada_global.data_dir);
    end
    climada_global.system_dir=[climada_global.data_dir filesep 'system'];
    if ~exist(climada_global.system_dir,'dir')
        fprintf('WARNING: please create %s manually\n',climada_global.system_dir);
    end
    
    % the map border file as used by climada_plot_world_borders
    climada_global.map_border_file=[climada_global.system_dir filesep 'world_50m.gen'];

    % country-specific csv delimuter (to read and convert to Excel properly)
    climada_global.csv_delimiter=';';
    
    % tropical cyclone (TC) specific parameters
    climada_global.tc.default_min_TimeStep=1; % 1 hour
    
    % evaluation and NPV (net present value) specific parameters
    climada_global.present_reference_year=2014;
    climada_global.future_reference_year =2030;
    
    % standard return periods for DFC report
    climada_global.DFC_return_periods=[1 5 10 20 25 30 35 40 45 50 75 100 125 150 175 200 250 300 400 500 1000];
    
    % whether we show waitbars for progress (eg in climada_EDS-_calc), =1:yes, =0: no
    climada_global.waitbar=1;
    
    % create the root dir of additional
    climada_root_dir_additional = [fileparts(climada_global.root_dir) filesep 'climada_additional'];
    if exist(climada_root_dir_additional,'dir')  
        climada_global.additional_dir = climada_root_dir_additional;  
    end
    
    % the default spreadsheet type, either '.xls' (default) or '.ods'
    % the user can always select from 'All Files', the default is only
    % used to compose the default filename.
    climada_global.spreadsheet_ext='.xls'; % default '.xls'
    
    % whether the code checks for (possible) asset encoding issues and
    % re-encodes in case of doubt (might take time...)
    % =0: no double check, faster, user needs to know what he's calculating ;-)
    % =1: if ~all(diff(entity.assets.centroid_index) == 1) etc., re-encoded
    climada_global.re_check_encoding = 0; % default =0
    
    climada_vars_initialised=1; % indicate we have initialized all vars

end

return