function [entity,entity_save_file] = climada_entity_read(entity_filename,hazard)
% climada assets read import
% NAME:
%   climada_entity_read
% PURPOSE:
%   read the file with the assets, damage functions, measures etc.
%   climada_assets_encode is automatically invoked
%
%   read also the damagefunctions sheet, if it exists (and run some checks)
%
%   read also the measures sheet, if it exists (in this case,
%   climada_measures_encode is automatically invoked)
%
%   read also the discount sheet, if it exists (and run some checks)
%
%   The code invokes climada_spreadsheet_read to really read the data,
%   which implements .xls and .ods files
%
%   For .xls, the sheet names are dynamically checked, for .ods, the sheet
%   names are hard-wired (see code), means for .ods, all the sheets
%   'assets','damagefunctions','measures' and 'discount' need to exist.
%
%   NOTE: For backward compatibility, the code does read OLD entity files
%   with a tab vulnerability (instead of damagefunctions) and VulnCurveID ...
%   It renames respective fields in the resulting entity structure.
%
%   Please consider climada_damagefunction_read in case you would like to
%   read damagefunctions separately.
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
%   [entity,entity_save_file]=climada_entity_read(entity_filename,hazard)
% EXAMPLE:
%   entity=climada_entity_read;
% INPUTS:
%   entity_filename: the filename of the Excel (or .ods) file with the assets
%       If no path provided, default path ../data/entities is used
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       > promted for if not given (out of climada_assets_encode)
%       ='NOENCODE' or 'noencode': do not encode assets, see climada_assets_encode
% OUTPUTS:
%   entity: a structure, with
%       assets: a structure, with
%           Latitude: the latitude of the values
%           Longitude: the longitude of the values
%           Value: the total insurable value
%           Deductible: the deductible
%           Cover: the cover
%           DamageFunID: the damagefunction curve ID
%       damagefunctions: a structure, with
%           DamageFunID: the damagefunction curve ID
%           Intensity: the hazard intensity
%           MDD: the mean damage degree (severity of single asset damage)
%           PAA: the percentage of assets affected
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
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

entity=[];
entity_save_file=[];

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('entity_filename','var'),entity_filename=[];end
if ~exist('hazard','var'),hazard=[];end

% PARAMETERS
%

% prompt for entity_filename if not given
if isempty(entity_filename) % local GUI
    entity_filename      = [climada_global.data_dir filesep 'entities' filesep '*' climada_global.spreadsheet_ext];
    [filename, pathname] = uigetfile(entity_filename, 'Select entity file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_filename = fullfile(pathname,filename);
    end
end

[fP,fN,fE] = fileparts(entity_filename);

if isempty(fP) % complete path, if missing
    entity_filename=[climada_global.data_dir filesep 'entities' filesep fN fE];
    [fP,fN,fE] = fileparts(entity_filename);
end

entity_save_file=[fP filesep fN '.mat'];
if climada_check_matfile(entity_filename,entity_save_file)
    % there is a .mat file more recent than the Excel
    load(entity_save_file)
    
    % check for valid/correct entity.assets.filename
    if ~strcmp(entity_save_file,entity.assets.filename)
        entity.assets.filename=entity_save_file;
        entity.damagefunctions.filename=entity_save_file;
        entity.measures.filename=entity_save_file;
        entity.discount.filename=entity_save_file;
        save(entity_file,'entity')
    end

else
    
    % read assets
    % -----------
    assets                   = climada_spreadsheet_read('no',entity_filename,'assets',1);
    
    if isfield(assets,'Longitude'),assets.lon=assets.Longitude;assets=rmfield(assets,'Longitude');end
    if isfield(assets,'Latitude'), assets.lat=assets.Latitude; assets=rmfield(assets,'Latitude');end
   % if isfield(assets,'Value'),    assets.value=assets.Value; assets=rmfield(assets,'Value');end
    
    if ~isfield(assets,'Value')
        fprintf('Error: no Value column in assets tab, aborted\n')
        if strcmp(fE,'.ods') && climada_global.octave_mode
            fprintf('> make sure there are no cell comments in the .ods file, as they trouble odsread\n');
        end
        return
    end
    
    % check for OLD naming convention, VulnCurveID -> DamageFunID
    if isfield(assets,'VulnCurveID')
        assets.DamageFunID=assets.VulnCurveID;
        assets=rmfield(assets,'VulnCurveID');
    end
    
    if ischar(hazard) && strcmpi(hazard,'NOENCODE')
        fprintf('Note: assets not encoded\n')
    else
        % encode assets
        entity.assets = climada_assets_encode(assets,hazard);
    end
    
    % figure out the file type
    [~,~,fE]=fileparts(entity_filename);
    
    if strcmp(fE,'.ods') || climada_global.octave_mode
        % hard-wired sheet names for files of type .ods
        % alos hard-wired since troubles with xlsfinfo in Octave
        sheet_names={'damagefunctions','measures','discount'};
    else
        % inquire sheet names from .xls
        [~,sheet_names] = xlsfinfo(entity_filename);
    end
    
    try
        % read damagefunctions
        % --------------------
        for sheet_i=1:length(sheet_names) % loop over tab (sheet) names
            if strcmp(sheet_names{sheet_i},'damagefunctions')
                entity.damagefunctions=climada_spreadsheet_read('no',entity_filename,'damagefunctions',1);
            end
            if strcmp(sheet_names{sheet_i},'vulnerability')
                entity.damagefunctions=climada_spreadsheet_read('no',entity_filename,'vulnerability',1);
            end
        end % sheet_i
        
        if isfield(entity,'damagefunctions') && sum(isnan(entity.assets.DamageFunID))<length(entity.assets.DamageFunID)
            
            % check for OLD naming convention, VulnCurveID -> DamageFunID
            if isfield(entity.damagefunctions,'VulnCurveID')
                entity.damagefunctions.DamageFunID=entity.damagefunctions.VulnCurveID;
                entity.damagefunctions=rmfield(entity.damagefunctions,'VulnCurveID');
            end
            
            % remove MDR, since MDR=MDD*PAA and hence we better
            % re-calculate where needed (in climada_damagefunctions_plot)
            if isfield(entity.damagefunctions,'MDR'),entity.damagefunctions=rmfield(entity.damagefunctions,'MDR');end
            
            % check consistency (a damagefunction definition for each DamageFunID)
            asset_DamageFunIDs=unique(entity.assets.DamageFunID);
            damagefunctions_DamageFunIDs=unique(entity.damagefunctions.DamageFunID);
            tf=ismember(asset_DamageFunIDs,damagefunctions_DamageFunIDs);
            if length(find(tf))<length(tf)
                fprintf('WARN: DamageFunIDs in assets might not all be defined in damagefunctions tab\n')
            end
            
            entity.damagefunctions.datenum=entity.damagefunctions.DamageFunID*0+now; % add datenum
        end
        
    catch ME
        fprintf('WARN: no damagefunctions data read, %s\n',ME.message)
    end
    
    % try to read also the measures (if exists)
    % -----------------------------
    for sheet_i=1:length(sheet_names) % loop over tab (sheet) names
        if strcmp(sheet_names{sheet_i},'measures')
            %%fprintf('NOTE: also reading measures tab\n');
            measures        = climada_spreadsheet_read('no',entity_filename,'measures',1);
            
            % rename vuln_map, since otherwise climada_measures_encode does not treat it
            if isfield(measures,'vuln_map'),measures.damagefunctions_map=measures.vuln_map;measures=rmfield(measures,'vuln_map');end
            
            entity.measures = climada_measures_encode(measures);
            
            % check for OLD naming convention, vuln_MDD_impact_a -> MDD_impact_a
            if isfield(entity.measures,'vuln_MDD_impact_a'),entity.measures.MDD_impact_a=entity.measures.vuln_MDD_impact_a;entity.measures=rmfield(entity.measures,'vuln_MDD_impact_a');end
            if isfield(entity.measures,'vuln_MDD_impact_b'),entity.measures.MDD_impact_b=entity.measures.vuln_MDD_impact_b;entity.measures=rmfield(entity.measures,'vuln_MDD_impact_b');end
            if isfield(entity.measures,'vuln_PAA_impact_a'),entity.measures.PAA_impact_a=entity.measures.vuln_PAA_impact_a;entity.measures=rmfield(entity.measures,'vuln_PAA_impact_a');end
            if isfield(entity.measures,'vuln_PAA_impact_b'),entity.measures.PAA_impact_b=entity.measures.vuln_PAA_impact_b;entity.measures=rmfield(entity.measures,'vuln_PAA_impact_b');end            
        end
    end % sheet_i
    
    try
        % try to read also the discount sheet (if exists)
        % -----------------------------------
        for sheet_i=1:length(sheet_names) % loop over tab (sheet) names
            if strcmp(sheet_names{sheet_i},'discount')
                %%fprintf('NOTE: also reading measures tab\n');
                entity.discount = climada_spreadsheet_read('no',entity_filename,'discount',1);
            end
        end % sheet_i
    catch ME
        fprintf('WARN: no discount data read, %s\n',ME.message)
    end
    
    % save entity as .mat file for fast access
    fprintf('saving entity as %s\n',entity_save_file);
    save(entity_save_file,'entity');
end % climada_check_matfile

return