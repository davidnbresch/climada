function scenario = climada_scenario_name(entity,hazard)
% climada set scenario name
% NAME:
%   climada_scenario_name
% PURPOSE:
%   given an entity and a hazard, define a scenario name, based on
%   assets.reference_year, assets.region, hazard.reference_year,
%   hazard.scenario
% 
% CALLING SEQUENCE:
%   scenario = climada_scenario_name(entity,hazard)
% EXAMPLE:
%   scenario = climada_scenario_name(entity,hazard)
%   scenario = climada_scenario_name;
% INPUTS:
%   entity: an entity structure or an entity .mat file, see climada_assets_encode(climada_assets_read)
%       If a file and no path provided, default path ../data/entities is
%       used (and name can be without extension .mat)
%       > promted for if not given
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       If a file and no path provided, default path ../data/hazards is
%       used (and name can be without extension .mat)
%       > promted for if not given
% OUTPUTS:
%   scenario, a structure with fields
%       .name: a string, e.g. Assets 2014, Hazard 2014 no climate change, Florida 
%              or Assets 2014, Hazard 2030 moderate climate change, Florida
%       .name_simple: a string with a simplified version of the scenario name, 
%              e.g., 2014, no climate change, Florida, or 2030 moderate
%              climate change, Florida
%       .assets_year: 2014, 2030, 2040, 2050, etc.
%       .region: a string, read from assets in excel, e.g. Florida, San Salvador, etc.
%       .hazard_year: 2014, 2030, 2040, 2050, taken from hazard.refence_year
%       .hazard_scenario: a string, taken from hazard.scenario, e.g. no climate change, 
%              moderate climate change, extreme climate change
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151127, init
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

scenario=[]; % init output

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('hazard','var'),hazard=[];end
% if ~exist('EDS','var'),EDS=[];end

entity = climada_entity_load(entity);
hazard = climada_hazard_load(hazard);

% entity = climada_entity_load(EDS);

if ~isempty(entity) && ~isempty(hazard)
    if isfield(entity,'assets')
        if isfield(entity.assets,'region')
            region = entity.assets.region;
        else
            region = 'Unknown region';
        end
        if isfield(entity.assets,'reference_year')
            assets_year = entity.assets.reference_year;
        else
            assets_year = climada_global.present_reference_year;
        end
    end
    
    if isfield(hazard,'scenario')
        hazard_scenario = hazard.scenario;
    else
        hazard_scenario = 'no climate change';
    end
    if isfield(hazard,'reference_year')
        hazard_year = hazard.reference_year;
    else
        hazard_year = climada_global.present_reference_year;
    end

    % full scenario name
    name = sprintf('Assets %d, Hazard %d %s, %s',assets_year, hazard_year, hazard_scenario, region);
    
    % a simpler scenario name
    % either today or climate change
    if assets_year == hazard_year
        name_simple = sprintf('%d, %s, %s',hazard_year,hazard_scenario,region);
    end
    % only economic growth
    if assets_year>hazard_year
        name_simple = sprintf('%d, Economic growth, %s',assets_year,region);
    end
          
    if hazard_year>assets_year
        name_simple = sprintf('%d, %s, no growth, %s',hazard_year,hazard_scenario,region);
    end
    
    scenario.name = name;
    scenario.name_simple = name_simple;
    scenario.assets_year = assets_year;
    scenario.region = region;
    scenario.hazard_year = hazard_year;
    scenario.hazard_scenario = hazard_scenario;
    
end


