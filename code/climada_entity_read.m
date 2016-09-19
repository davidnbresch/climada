function [entity,entity_save_file] = climada_entity_read(entity_filename,hazard,force_read)
% climada entity import, read assets, damagefunctions, discount and measures
% NAME:
%   climada_entity_read
% PURPOSE:
%   read the file with the assets, damagefunctions, measures and discount.
%   Calls climada_assets_read, climada_damagefunctions_read,
%   climada_measures_read and climada_discount_read.
%   climada_assets_encode and climada_measures_encode is automatically invoked
%
%   The code invokes climada_spreadsheet_read to really read the data,
%   which implements .xls and .ods files
%
%   To test this code, use entity_template.xls, entity_template.xlsx or
%   entity_template.ods. ADVANCED use: entity_template_ADVANCED.xlsx (.ods)
%
%   For .xls, the sheet names are dynamically checked, for .ods, the sheet
%   names are hard-wired (see code), means for .ods, all the sheets
%   'assets', 'damagefunctions', 'measures' and 'discount' need to exist.
%
%   NOTE: For backward compatibility, the code does read OLD entity files
%   with a tab vulnerability (instead of damagefunctions) and VulnCurveID ...
%   It renames respective fields in the resulting entity structure.
%
%   OCTAVE: Please install the io package first, ether directly from source
%   forge with: pkg install -forge io -auto
%   or, (e.g. in case this fails, get the io package first from Octave
%   source forge and then install from the downloaded package:
%   pkg install {local_path}/io-2.2.5.tar -auto
%   Note that it looks like Octave prefers .xlsx files
%
%   next step: likely climada_ELS_calc
% CALLING SEQUENCE:
%   [entity,entity_save_file] = climada_entity_read(entity_filename,hazard)
% EXAMPLE:
%   entity = climada_entity_read;
% INPUTS:
%   entity_filename: the filename of the Excel (.xls, .xlsx or .ods) file with the assets
%       If no path provided, default path ../data/entities is used
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       > promted for if not given (out of climada_assets_encode)
%       ='NOENCODE' or 'noencode': do not encode assets, see climada_assets_encode
%   force_read: if =1, force reading from the Excel file, do NOT use the
%       possibly already exissting .mat file (climada does alaways read from
%       Excel in case the Excal has been edited since last time read).
%       Default=0.
% OUTPUTS:
%   entity: a structure, with
%       assets: a structure, with
%           .lat: the latitude of the values
%           .lon: the longitude of the values
%           .Value: the total insurable value
%           .Deductible: the deductible
%           .Cover: the cover
%           .DamageFunID: the damagefunction curve ID
%       damagefunctions: a structure, with
%           .DamageFunID: the damagefunction curve ID
%           .Intensity: the hazard intensity
%           .MDD: the mean damage degree (severity of single asset damage)
%           .PAA: the percentage of assets affected
%       measures: a structure, with (not all just a list of the most frequent variables)
%           .name
%           .cost
%           .hazard_intensity_impact_a
%           .hazard_intensity_impact_b
%           .hazard_event_set
%           .MDD_impact_a
%           .MDD_impact_b
%           .PAA_impact_a
%           .PAA_impact_b
%           .assets_file
%           .regional_scope: if assets tab found wich specifies the regional_scope of a measure
%       discount: a structure, with
%           .yield_ID: yield ID
%           .year: year
%           .discount_rate: discount_rate per year
%   assets tab found wich specifies the regional_scope of a measure
%   entity_save_file: the name the encoded entity got saved to
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20090920
% Lea Mueller, 20110720
% David N. Bresch, david.bresch@gmail.com, 20130328, vuln_MDD_impact -> MDD_impact ...
% David N. Bresch, david.bresch@gmail.com, 20141029, entity_save_file added as output
% David N. Bresch, david.bresch@gmail.com, 20141121, hint to climada_damagefunction_read added
% David N. Bresch, david.bresch@gmail.com, 20141221, damagefunctions.MDR removed and NOENCODE added
% David N. Bresch, david.bresch@gmail.com, 20141230, cleanup
% David N. Bresch, david.bresch@gmail.com, 20150101, Octave compatibility (at least for .xlsx)
% David N. Bresch, david.bresch@gmail.com, 20150805, allow for name without path on input
% David N. Bresch, david.bresch@gmail.com, 20150829, check for valid/correct entity.assets.filename
% Lea Mueller, muellele@gmail.com, 20150831, assign assets.Value_unit with climada_global.Value_unit if not given
% Lea Mueller, muellele@gmail.com, 20150907, add damagefunctions check and measures check
% Lea Mueller, muellele@gmail.com, 20150908, add assets even it not encoded
% Lea Mueller, muellele@gmail.com, 20151016, delete nans if there are invalid entries
% Lea Mueller, muellele@gmail.com, 20151119, call climada_assets_read, climada_damagefunctions_read, climada_measures_read, climada_discount_read
% David N. Bresch, david.bresch@gmail.com, 20151229, old commented code deleted (finish 20151119 update)
% Lea Mueller, muellele@gmail.com, 20160523, complete extension, if missing
% David N. Bresch, david.bresch@gmail.com, 20160524, allow for entity without assets (e.g. called from nightlight entity)
% David N. Bresch, david.bresch@gmail.com, 20160908, entities_dir used
% David N. Bresch, david.bresch@gmail.com, 20160919, reading tab names added
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

entity = [];
entity_save_file = [];

% poor man's version to check arguments
if ~exist('entity_filename','var'), entity_filename = [];end
if ~exist('hazard','var'),          hazard = [];end
if ~exist('force_read','var'),      force_read = 0;end

% PARAMETERS
%

% prompt for entity_filename if not given
if isempty(entity_filename) % local GUI
    entity_filename      = [climada_global.entities_dir filesep '*' climada_global.spreadsheet_ext];
    [filename, pathname] = uigetfile(entity_filename, 'Select entity file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_filename = fullfile(pathname,filename);
    end
end

[fP,fN,fE] = fileparts(entity_filename);
if isempty(fE),fE=climada_global.spreadsheet_ext;end
if isempty(fP) % complete path, if missing
    entity_filename=[climada_global.entities_dir filesep fN fE];
end
[fP,fN] = fileparts(entity_filename);
entity_save_file=[fP filesep fN '.mat'];

if climada_check_matfile(entity_filename,entity_save_file) && ~force_read
    % there is a .mat file more recent than the Excel
    load(entity_save_file)
    
    % check for valid/correct entity.assets.filename
    if isfield(entity,'assets')
        if ~isfield(entity.assets,'filename'),entity.assets.filename=entity_save_file;end
        if ~strcmp(entity_save_file,entity.assets.filename)
            entity.assets.filename=entity_save_file;
            entity.damagefunctions.filename=entity_save_file;
            entity.measures.filename=entity_save_file;
            entity.discount.filename=entity_save_file;
            save(entity_save_file,'entity')
        end
    end % isfield(entity,'assets')
    
else
    % read assets
    entity.assets = climada_assets_read(entity_filename,hazard);
        
    % read damagefunctions
    entity.damagefunctions = climada_damagefunctions_read(entity_filename);
    
    % read measures
    entity.measures = climada_measures_read(entity_filename);
    
    % read discount sheet
    entity.discount = climada_discount_read(entity_filename);
    
    % read names sheet
    entity.names = climada_names_read(entity_filename);
    % if it exists, copy reference year to assets (where it is most likely used)
    if isfield(entity.names,'reference_year'),...
            entity.assets.reference_year=entity.names.reference_year;end
    
    % save entity as .mat file for fast access
    fprintf('saving entity as %s\n',entity_save_file);
    save(entity_save_file,'entity');
    
end % climada_check_matfile

end % climada_entity_read