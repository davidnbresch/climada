function assets = climada_assets_read(assets_filename,hazard)
% climada assets read import
% NAME:
%   climada_assets_read
% PURPOSE:
%   read assets with Longitude (lon), Latitude (lat) and Values (the
%   mandatory fields, all other fields are automatically added if needed). 
%   See climada_entity_read for a comprehensive description of output fields.
%
%   climada_assets_complete and climada_assets_encode are automatically invoked.
%   usually called from climada_entity_read, see climada_entity_read for
%   more information.
%
%   The code invokes climada_spreadsheet_read to really read the data,
%   which implements .xls, .xlsx and .ods files. For .xls, the sheet names
%   are dynamically checked, for .ods, the sheet names are hard-wired (see
%   code), means for .ods, the sheet 'assets' needs to exist.
%
%   called from: climada_entity_read
% CALLING SEQUENCE:
%   assets = climada_assets_read(assets_filename,hazard)
% EXAMPLE:
%   assets = climada_assets_read;
% INPUTS:
%   assets_filename: the filename of the Excel (or .ods) file with the assets
%       If no path provided, default path ../data/entities is used
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       > promted for if not given (out of climada_assets_encode)
%       ='NOENCODE' or 'noencode': do not encode assets, see climada_assets_encode
% OUTPUTS:
%    assets: a structure, with
%           Latitude: the latitude of the values
%           Longitude: the longitude of the values
%           Value: the total insurable value
%           Deductible: the deductible
%           Cover: the cover
%           DamageFunID: the damagefunction curve ID
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151117, init from climada_entity_read to read only assets
% David Bresch, david.bresch@gmail.com, 20151119, bugfix for Octave to try/catch xlsinfo
% Lea Mueller, muellele@gmail.com, 20151127, add assets.region and assets.refence_year
% Lea Mueller, muellele@gmail.com, 20151207, return if already a complete assets structure as input
% Lea Mueller, muellele@gmail.com, 20151207, invoke climada_assets_category_ID
% david.bresch@gmail.com, 20160603, make sure we have 1xN arrays
% david.bresch@gmail.com, 20160916, see remark in code
% david.bresch@gmail.com, 20160917, Category treatment removed, since Category_ID new in Excel
% david.bresch@gmail.com, 20160917, Region_ID and Value_unit added, assets_save_file removed
% david.bresch@gmail.com, 20160918, climada_assets_complete added
% david.bresch@gmail.com, 20160919, assets.reference_year moved to climada_names_read
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

assets = [];

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('assets_filename','var'),assets_filename = [];end
if ~exist('hazard','var'),hazard=[];end

% PARAMETERS
%

% prompt for assets_filename if not given
if isempty(assets_filename) % local GUI
    assets_filename      = [climada_global.entities_dir filesep '*' climada_global.spreadsheet_ext];
    [filename, pathname] = uigetfile(assets_filename, 'Select assets file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        assets_filename = fullfile(pathname,filename);
    end
end

[fP,fN,fE] = fileparts(assets_filename);
if isempty(fE),fE=climada_global.spreadsheet_ext;end
if isempty(fP) % complete path, if missing
    assets_filename=[climada_global.entities_dir filesep fN fE];
end

if strcmp(fE,'.ods')
    % hard-wired sheet names for files of type .ods
    sheet_names = {'assets'};
else
    try
        % inquire sheet names from .xls
        [~,sheet_names] = xlsfinfo(assets_filename);
    catch
        sheet_names = {'assets'}; % fix for Octave, david.bresch@gmail.com, 20151119
    end
end

try
    % read assets
    % --------------------
    for sheet_i = 1:length(sheet_names) % loop over tab (sheet) names
        if strcmp(sheet_names{sheet_i},'assets')
            assets = climada_spreadsheet_read('no',assets_filename,'assets',1);
        end
    end % sheet_i
    if isempty(assets)
        fprintf('No sheet "assets" found, just reading the first sheet.\n')
        assets = climada_spreadsheet_read('no',assets_filename,1);
    end
    
catch ME
    fprintf('Error: no assets data read: %s\n',ME.message)
end

% rename .Longitude to .lon and .Latitude to .lat (and VulnCurveID to DamageFunID)
if isfield(assets,'Longitude'),assets.lon=assets.Longitude;assets=rmfield(assets,'Longitude');end
if isfield(assets,'Latitude'), assets.lat=assets.Latitude; assets=rmfield(assets,'Latitude');end
if isfield(assets,'VulnCurveID'),assets.DamageFunID=assets.VulnCurveID;assets = rmfield(assets,'VulnCurveID');end

% check for mandatory fields
if ~isfield(assets,'Value')
    fprintf('Error: no Value column in assets tab, aborted\n')
    assets = [];
    if strcmp(fE,'.ods')
        fprintf('> make sure there are no cell comments in the .ods file, as they trouble odsread\n');
    end
    return
end
if ~isfield(assets,'lon'),fprintf('Error: no Longitude (lon) column in assets tab, aborted\n');assets = [];return;end
if ~isfield(assets,'lat'),fprintf('Error: no Latitude (lat) column in assets tab, aborted\n') ;assets = [];return;end

% delete NaNs if there are invalid entries
assets = climada_entity_check(assets,'lon',0,'assets'); % check for lon to be complete
assets = climada_entity_check(assets,'lat',0,'assets'); % check for lat to be complete
assets = climada_entity_check(assets,'Value',0,'assets'); % check for Value to be complete
assets = climada_entity_check(assets,'Value_unit',0,'assets'); % check, as this is a cell array...

% rename .Reference_year to .reference_year (OLD, for backward
% compatibility, does NOT work in Octave, see new tab names)
% david.bresch@gmail.com: this code piece will be removed summer 2017
if isfield(assets,'Reference_year'),assets.reference_year=assets.Reference_year;assets=rmfield(assets,'Reference_year');end
% add assets.refence_year, that describes the time stamp of the assets, use only first entry
if isfield(assets,'reference_year') % if not, it is added in climada_assets_complete (see below)
    if ~isnumeric(assets.reference_year)
        assets=rmfield(assets,'reference_year');
    else
        assets.reference_year=assets.reference_year(1);
    end
end

% make sure we have all fields and they are 'correct'
assets = climada_assets_complete(assets);

% encode assets
if ischar(hazard) && strcmpi(hazard,'NOENCODE')
    fprintf('Note: assets not encoded\n')
else
    assets = climada_assets_encode(assets,hazard);
end

end % climada_assets_read