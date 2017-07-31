function [entity,entity_save_file] = climada_entity_read(entity_filename,hazard,force_read)
% climada entity import, read assets, damagefunctions, discount and measures
% NAME:
%   climada_entity_read
% PURPOSE:
%   read the file with the assets, damagefunctions, measures, discount and
%   names tabs. Calls climada_assets_read, climada_damagefunctions_read,
%   climada_measures_read and climada_discount_read. climada_assets_encode
%   and climada_measures_encode are automatically invoked.
%
%   The code invokes climada_spreadsheet_read to really read the data,
%   which implements .xls, .xlsx and .ods files
%
%   To test this code, use entity_template.xls, entity_template.xlsx or
%   entity_template.ods. ADVANCED use: entity_template_ADVANCED.xlsx (.ods)
%
%   For .xls and .xslx the sheet names are dynamically checked, for .ods, the sheet
%   names are hard-wired (see code), means for .ods, at least the sheets
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
%   If this fails, consider https://github.com/davidnbresch/Octave_io_fix
%
%   next step: likely climada_ELS_calc
% CALLING SEQUENCE:
%   [entity,entity_save_file] = climada_entity_read(entity_filename,hazard,force_read)
% EXAMPLE:
%   entity=climada_entity_read('entity_template','TCNA_today_small',1);
%   entity=climada_entity_read('entity_template_ADVANCED','TCNA_today_small',1);
% INPUTS:
%   entity_filename: the filename of the Excel (.xls, .xlsx or .ods) file with the assets
%       If no path provided, default path ../data/entities is used
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       > promted for if not given (out of climada_assets_encode)
%       ='NOENCODE' or 'noencode': do not encode assets, see climada_assets_encode
%   force_read: if =1, force reading from the Excel file, do NOT use the
%       possibly already existing .mat file (climada does alaways read from
%       Excel in case the Excal has been edited since last time read).
%       Default=0.
% OUTPUTS:
%   entity: a structure, with (please run the first example above and then
%       inspect entity for the latest content)
%       assets: itself a structure, with
%           lat: [1xn double] the latitude of the values
%           lon: [1xn double] the longitude of the values
%           Value: [1xn double] the total insurable value
%           Value_unit: {1xn cell}
%           Deductible: [1xn double] the deductible, default=0
%           Cover: [1xn double] the cover, defualt=Value
%           DamageFunID: [1xn double] the damagefunction curve ID
%           filename: the filename the content has been imported from
%           Category_ID: [1xn double] the category ID, see also entity.names
%           Region_ID: [1xn double] the region ID, see also entity.names
%           reference_year: [double] the year the assets are valid for
%           centroid_index: [1xn double] the centroids the assets have been
%               encoede to (unless you specifiec 'NOENCODE') 
%           hazard: only present if you did encode, itself a struct with
%               filename: the filename with path to the hazard you used
%               comment: the free comment as in hazard.comment
%       damagefunctions: itself a structure, with
%           DamageFunID: [nx1 double] the damagefunction curve ID
%           Intensity: [nx1 double] the hazard intensity
%           MDD: [nx1 double] the mean damage degree (severity of single asset damage)
%           PAA: [nx1 double] the percentage of assets affected
%           peril_ID: {nx1 cell} the peril_ID (such as 'TC', 'EQ')
%           Intensity_unit: {nx1 cell} the intensity unit (such as 'm/s', 'MMI')
%           name: {nx1 cell} a free name, eg. 'TC default'
%           datenum: [nx1 double] the datenum of this record being last
%               modified (set to import date)
%       measures: itself a structure, with
%           name: {nx1 cell} the (free) name of the measure
%           color: {nx1 cell} the color as RGB triple (e.g. '0.5 0.5 0.5')
%               to color the measure for display purposes
%           color_RGB: [nx3 double] the color converted from a string as in
%               color to RGB values as double
%           cost: [nx1 double] the cost of the measure. Make sure it is the
%               same units as assets.Value ;-)
%           hazard_intensity_impact_a: [nx1 double] the a parameter to
%               convert hazard intensity, i.e. i_used=i_orig*a+b
%           hazard_intensity_impact_b: [nx1 double] the b parameter to
%               convert hazard intensity, i.e. i_used=i_orig*a+b
%           hazard_high_frequency_cutoff: [nx1 double] the frequency
%           cutoff, i.e. set =1/30 to signify a measure which avoids any
%               damage up to 30 years of return period
%           hazard_event_set: {nx1 cell} to provide an alternative hazard
%               event set for a specific measure (advanced use only)
%           MDD_impact_a: [nx1 double] the a parameter to
%               convert MDD, i.e. MDD_used=MDD_orig*a+b
%           MDD_impact_b: [nx1 double] the b parameter to
%               convert MDD, i.e. MDD_used=MDD_orig*a+b
%           PAA_impact_a: [nx1 double] the a parameter to
%               convert PAA, i.e. PAA_used=PAA_orig*a+b
%           PAA_impact_b: [nx1 double] the b parameter to
%               convert PAA, i.e. PAA_used=PAA_orig*a+b
%           damagefunctions_map: {nx1 cell} to map to an alternative damage
%               function, contains elements such as '1to3;4to27' which means
%               map DamageFunID 1 to 3 and 4 to 27 to implement the impact of
%               the measure
%           damagefunctions_mapping: [1xn struct] the machine-readable
%               version of damagefunctions_map, with fields
%               damagefunctions_mapping(i).map_from: the (list of)
%               DamageFunIDs to map from, i.e. =[1 4] for the example above
%               damagefunctions_mapping(i).map_to: the (list of)
%               DamageFunIDs to map to, i.e. =[3 27] for the example above
%           peril_ID: {nx1 cell} the peril the respective measure applies
%               to (to allow for a multi-peril analysis driven by one entity
%               file - the user still needs to run climada_measures_impact for
%               each peril separately
%           damagefunctions: a full damagefunctions struct (as decribed
%               above), which gets 'switched to' when calculating measure's
%               impacts (see code climada_measures_impact). It is usally a
%               copy of entity.damagefunctions (as the entity file read for
%               measures does cntain a tab damagefunctions, hence gets read
%               again, does no harm...)
%           risk_transfer_attachement: [nx1 double] the attachement point
%               for risk transfer
%           risk_transfer_cover: [nx1 double] the cover for risk transfer
%           filename: the filename the content has been imported from
%           Region_ID: [nx1 double] NOT USED currently, see remark for regional_scope
%           assets_file: {nx1 cell} NOT USED currently, see remark for assets_file
%           /regional_scope/: (only supported in earlier climada release 2)
%               if assets tab found wich specifies the regional_scope of a measure 
%           /assets_file/: (only supported in earlier climada release 2)
%               to provide assets for a regional scope
%       discount: a structure, with
%           yield_ID: an ID to implement several yield curves (not supported yet, default=1)
%           year: the year a particular discount rate is valid for. If you
%               use a constant discount rate, just provide the same number for
%               each year (as in the template).
%           discount_rate: the discount_rate (e.g. 0.02 for 2%, but you can
%               format the cell as percentage in Exel - but not in .ods) per year 
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
% David N. Bresch, david.bresch@gmail.com, 20160920, try .xlsx if .xls not found, documentation updated
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

entity = [];
entity_save_file = [];

% poor man's version to check arguments
if ~exist('entity_filename','var'), entity_filename = [];end
if ~exist('hazard',         'var'), hazard = [];end
if ~exist('force_read',     'var'), force_read = 0;end

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
    if ~exist(entity_filename,'file');
        fprintf('Note: %s does nor exist, switched to .xlsx\n',entity_filename)
        entity_filename=[climada_global.entities_dir filesep fN '.xlsx']; % try this, too
    end
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
            save(entity_save_file,'entity',climada_global.save_file_version)
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
    
    climada_global_save_file_version=climada_global.save_file_version; % store
    if strcmpi(fN,'entity_template')
        climada_global.save_file_version='-v7';
        fprintf('SPECIAL: saved as version %s for Octave compatibility\n',climada_global.save_file_version)
    end
    
    % save entity as .mat file for fast access
    fprintf('saving entity as %s\n',entity_save_file);
    save(entity_save_file,'entity',climada_global.save_file_version);
    
    climada_global.save_file_version=climada_global_save_file_version; % reset

end % climada_check_matfile

end % climada_entity_read