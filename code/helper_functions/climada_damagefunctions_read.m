function [damagefunctions,entity] = climada_damagefunctions_read(damagefunction_filename,entity)
% climada damage function vulnerability read import
% NAME:
%   climada_damagefunctions_read
% PURPOSE:
%   read a file with damage functions (vulnerabilities), usually called in
%   climada_entity_read, which reads a full entity file, i.e. assets, 
%   damagefunctions, discount and measures. The field "Intensity" is
%   mandatory otherwise damagefunctions are not read.
%
%   The code invokes climada_spreadsheet_read to really read the data,
%   which implements .xls and .ods files
%
%   For .xls, the sheet names are dynamically checked, for .ods, the sheet
%   names are hard-wired (see code), means for .ods, all the sheets
%   'assets','damagefunctions','measures' and 'discount' need to exist.
%
%   NOTE: For backward compatibility, the code does read OLD files
%   with a tab vulnerability (instead of damagefunctions) and VulnCurveID ...
%   It renames respective fields in the resulting structure.
%
%   See also climada_damagefunction_map and climada_damagefunctions_plot
% CALLING SEQUENCE:
%   damagefunctions = climada_damagefunctions_read(damagefunction_filename)
% EXAMPLE:
%   damagefunctions = climada_damagefunctions_read
% INPUTS:
%   damagefunction_filename: the filename of the Excel file with the assets
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   entity: if an entity is passed, it's entity.damagefunctions is replaced
%       by the newly imported damagefunctions (EXPERT use, as the
%       DamageFunID have to be consistent, the code warns at least). 
%       See also climada_damagefunctions_map
% OUTPUTS:
%   damagefunctions: a structure, with
%           DamageFunID: the damagefunction curve ID
%           Intensity: the hazard intensity
%           MDD: the mean damage degree
%   entity: the entity (as on input, with exchanged damagefuncions)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141121, ICE initial
% David N. Bresch, david.bresch@gmail.com, 20141221, damagefunctions.MDR removed
% Lea Mueller, muellele@gmail.com, 20151016, delete nans if there are invalid entries
% Lea Mueller, muellele@gmail.com, 20151119, read first sheet if sheet "damagefunctions" is not found
% David Bresch, david.bresch@gmail.com, 20151119, bugfix for Octave to try/catch xlsinfo
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

damagefunctions = [];

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('damagefunction_filename','var'),damagefunction_filename='';end
if ~exist('entity','var'), entity = [];end

% PARAMETERS
%

% prompt for damagefunction_filename if not given
if isempty(damagefunction_filename) % local GUI
    damagefunction_filename      = [climada_global.entities_dir filesep '*' climada_global.spreadsheet_ext];
    [filename, pathname] = uigetfile(damagefunction_filename, 'Select damagefunctions file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        damagefunction_filename = fullfile(pathname,filename);
    end
end

% figure out the file type
[~,~,fE]=fileparts(damagefunction_filename);

if strcmp(fE,'.ods')
    % hard-wired sheet names for files of type .ods
    sheet_names={'damagefunctions','measures','discount'};
else
    try
        % inquire sheet names from .xls
        [~,sheet_names] = xlsfinfo(damagefunction_filename);
    catch
        sheet_names={'damagefunctions','measures','discount'};
    end
end

try
    % read damagefunctions
    % --------------------
    for sheet_i=1:length(sheet_names) % loop over tab (sheet) names
        if strcmp(sheet_names{sheet_i},'damagefunctions')
            damagefunctions=climada_spreadsheet_read('no',damagefunction_filename,'damagefunctions',1);
        end
        if strcmp(sheet_names{sheet_i},'vulnerability')
            damagefunctions=climada_spreadsheet_read('no',damagefunction_filename,'vulnerability',1);
        end
    end % sheet_i 
    if isempty(damagefunctions)
        fprintf('No sheet "damagefunctions" found, just reading the first sheet.\n')
        damagefunctions = climada_spreadsheet_read('no',damagefunction_filename,1);
    end
    
catch ME
    fprintf('WARN: no damagefunctions data read, %s\n',ME.message)
end

% .Intensity is mandatory
if ~isfield(damagefunctions,'Intensity')
    fprintf('Error: no Intensity column in damagefunctions tab, aborted\n')
    damagefunctions = [];
    if strcmp(fE,'.ods') && climada_global.octave_mode
        fprintf('> make sure there are no cell comments in the .ods file, as they trouble odsread\n');
    end
    return
end
    
% check for OLD naming convention, VulnCurveID -> DamageFunID
if isfield(damagefunctions,'VulnCurveID')
    damagefunctions.DamageFunID = damagefunctions.VulnCurveID;
    damagefunctions = rmfield(damagefunctions,'VulnCurveID');
end

damagefunctions.datenum = damagefunctions.DamageFunID*0+now; % add datenum

% remove MDR, since MDR=MDD*PAA and hence we better
% re-calculate where needed (in climada_damagefunctions_plot)
if isfield(damagefunctions,'MDR'),damagefunctions=rmfield(damagefunctions,'MDR');end

% delete nans if there are invalid entries
damagefunctions = climada_entity_check(damagefunctions,'DamageFunID');


if ~isempty(entity)
    entity=rmfield(entity,'damagefunctions'); % delete OLD
    entity.damagefunctions=damagefunctions; % attach NEW
    
    % check consistency (a damagefunction definition for each DamageFunID)
    asset_DamageFunIDs=unique(entity.assets.DamageFunID);
    damagefunctions_DamageFunIDs=unique(entity.damagefunctions.DamageFunID);
    tf=ismember(asset_DamageFunIDs,damagefunctions_DamageFunIDs);
    if length(find(tf))<length(tf)
        fprintf('WARNING: DamageFunIDs in assets might not all be defined in damagefunctions\n')
    end
end

end