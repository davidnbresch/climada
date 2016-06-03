function [assets,assets_save_file] = climada_assets_read(assets_filename,hazard)
% climada assets read import
% NAME:
%   climada_assets_read
% PURPOSE:
%   read assets with .lon, .lat, .Values. climada_assets_encode is 
%   automatically invoked.
%   usually called from climada_entity_read, see climada_entity_read for
%   more information. The field "Value" is
%   mandatory otherwise assets are not read.
%
%   The code invokes climada_spreadsheet_read to really read the data,
%   which implements .xls and .ods files
%   For .xls, the sheet names are dynamically checked, for .ods, the sheet
%   names are hard-wired (see code), means for .ods, the sheet
%   'assets' needs to exist.
% CALLING SEQUENCE:
%   [assets,assets_save_file] = climada_assets_read(assets_filename,hazard)
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
%   assets_save_file: the name the encoded assets got saved to
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151117, init from climada_entity_read to read only assets
% David Bresch, david.bresch@gmail.com, 20151119, bugfix for Octave to try/catch xlsinfo
% Lea Mueller, muellele@gmail.com, 20151127, add assets.region and assets.refence_year
% Lea Mueller, muellele@gmail.com, 20151207, return if already a complete assets structure as input
% Lea Mueller, muellele@gmail.com, 20151207, invoke climada_assets_category_ID
% david.bresch@gmail.com, 20160603, make sure we have 1xN arrays
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

assets = [];
assets_save_file = [];

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('assets_filename','var'),assets_filename = [];end
if ~exist('hazard','var'),hazard=[];end

% PARAMETERS
%

% if already a complete assets, return
if isfield(assets_filename,'lon') && isfield(assets_filename,'lat') && isfield(assets_filename,'Value')
    assets = assets_filename; return
end
if isstruct(assets_filename), assets_filename = ''; end

% prompt for entity_filename if not given
if isempty(assets_filename) % local GUI
    assets_filename      = [climada_global.data_dir filesep 'entities' filesep '*' climada_global.spreadsheet_ext];
    [filename, pathname] = uigetfile(assets_filename, 'Select assets file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        assets_filename = fullfile(pathname,filename);
    end
end



% figure out the file type
[fP,fN,fE] = fileparts(assets_filename);

if isempty(fP) % complete path, if missing
    assets_filename=[climada_global.data_dir filesep 'entities' filesep fN fE];
    [fP,fN,fE] = fileparts(assets_filename);
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
    fprintf('WARN: no assets data read, %s\n',ME.message)
end


% rename .Longitude to .lon and .Latitude to .lat
if isfield(assets,'Longitude'),assets.lon=assets.Longitude;assets=rmfield(assets,'Longitude');end
if isfield(assets,'Latitude'), assets.lat=assets.Latitude; assets=rmfield(assets,'Latitude');end

% .Value is mandatory
if ~isfield(assets,'Value')
    fprintf('Error: no Value column in assets tab, aborted\n')
    assets = [];
    if strcmp(fE,'.ods') && climada_global.octave_mode
        fprintf('> make sure there are no cell comments in the .ods file, as they trouble odsread\n');
    end
    return
end

% make sure we have 1xN arrays
assets.lon                                         =climasre_LOCAL_TRANSPOSE(assets.lon);
assets.lat                                         =climasre_LOCAL_TRANSPOSE(assets.lat);
assets.Value                                       =climasre_LOCAL_TRANSPOSE(assets.Value);
if isfield(assets,'DamageFunID'),assets.DamageFunID=climasre_LOCAL_TRANSPOSE(assets.DamageFunID);end
if isfield(assets,'Deductible'), assets.Deductible =climasre_LOCAL_TRANSPOSE(assets.Deductible);end
if isfield(assets,'Cover'),      assets.Cover      =climasre_LOCAL_TRANSPOSE(assets.Cover);end
    
% assign value units if not given in xls-entity with global values
if ~isfield(assets,'Value_unit')
    assets.Value_unit = repmat({climada_global.Value_unit},size(assets.Value));
end

if isfield(assets,'Category'), assets = climada_assets_category_ID(assets); end

% add assets.region, use only first entry
% rename .Region to .region
if isfield(assets,'Region'),assets.region=assets.Region;assets=rmfield(assets,'Region');end
if isfield(assets,'region')
    assets.region=assets.region{1};
else
    assets.region='unknown region';
end

% add assets.refence_year, that describes the time horizon of the assets, use only first entry
% rename .Reference_year to .reference_year
if isfield(assets,'Reference_year'),assets.reference_year=assets.Reference_year;assets=rmfield(assets,'Reference_year');end
if isfield(assets,'reference_year')
    if ~isnumeric(assets.reference_year)
        assets=rmfield(assets,'reference_year');
    else
        assets.reference_year=assets.reference_year(1);
    end
end
if ~isfield(assets,'reference_year'),assets.reference_year=climada_global.present_reference_year;end  

% check for OLD naming convention, VulnCurveID -> DamageFunID
if isfield(assets,'VulnCurveID')
    assets.DamageFunID = assets.VulnCurveID;
    assets = rmfield(assets,'VulnCurveID');
end

% delete nans if there are invalid entries
assets = climada_entity_check(assets,'lon');

% encode assets
if ischar(hazard) && strcmpi(hazard,'NOENCODE')
    fprintf('Note: assets not encoded\n')
else 
    assets = climada_assets_encode(assets,hazard);
end

% % save entity as .mat file for fast access
%fprintf('saving entity as %s\n',assets_save_file);
%save(assets_save_file,'entity');
% % end % climada_check_matfile
    
end % climada_assets_read

function arr=climasre_LOCAL_TRANSPOSE(arr)
if size(arr,1)>size(arr,2),arr=arr';end
end % climasre_LOCAL_TRANSPOSE
