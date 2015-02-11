function entity_adjusted=climada_entity_value_GDP_adjust(entity_file_regexp,mode_selector)
% scale up asset values
% MODULE:
%   country_risk
% NAME:
%   climada_entity_value_GDP_adjust
% PURPOSE:
%   Scale up asset values based on a country's estimated total asset value.
%   The total asset value is derived as follows:
%       - normalize the asset values
%       - multiply with the country's GDP
%       - multiply with a factor that depends on a country's income
%         group, i.e., its GDP per capita. This last factor is the KEY
%         ASSUMPTION here, see income_group_factors in PARAMETERS in code
%
%   If an entity has a field entity.assets.Value_today, the code calculates
%   the factor to entity.assets.Value and applies this factor after GDP
%   adjustment (this way, the code does not scale _future entities back to
%   today).
%
%   The entities' asset values are first normalized and then
%   multiplied by a factor that depends on a country's income group (low,
%   lower middle, upper middle, or high). The choice of this factor is
%   based on a comparison of climada entities to estimates for total asset
%   values in countries where such data are available. This comparison
%   showed that in general, adjusting the Climada asset values requires a
%   higher multiplication factor the wealthier a country is. Thus, as a
%   rule of thumb, the value of all assets in a country can be estimated by
%       Total_asset_value = GDP * (1+income_group_factor)
%   where GDP is the country's gross domestic product, and
%   income_group_factor ranges from 2 for low income countries to 5 for
%   high income countries.
%
%   Caution: as soon as the entity has a field entity.assets.admin0_ISO3 or
%   entity.assets.admin0_name, it is adjusted, unless there are non-empty
%   fields entity.assets.admin1_name or entity.assets.admin1_code, in which
%   case it skips adjustment.
%
%   Note: to avoid any troubles, Cover is set equal to Value.
%
%   Prior calls: e.g. climada_nightlight_entity, country_risk_calc
%   Next calls: e.g. country_risk_calc
% CALLING SEQUENCE:
%   entity_adjusted=climada_entity_value_GDP_adjust(entity_file_regexp,mode_selector)
% EXAMPLE:
%   entity_adjusted=climada_entity_value_GDP_adjust('../data/*.mat') % put .. in
%   entity_adjusted=climada_entity_value_GDP_adjust('BEL_Belgium_entity.mat')
% INPUT:
%   entity_file_regexp: the full filename of the entity to be scaled up
%       or a regexp expression, e.g. for all entities:
%       entity_file_regexp=[climada_global.data_dir filesep 'entities' filesep '*.mat']
% OPTIONAL INPUT PARAMETERS:
%   mode_selector: =1, print step-by-step to stdout, =0, not (default)
%       If =2, do not care for Value_today, just adjust to GDP*income_group_factors
%       If =3, use GDP_future instead of GDP_today (if this column is in
%       the economic_indicators_mastertable.xls, otherwise throw an error).
%       In this case, ignore Value_today, just scale with GDP_future.
% OUTPUTS:
%   entity_adjusted: entity with adjusted asset values, also stored as .mat
%       file (only last entity if entity_file_regexp covers more than one)
% MODIFICATION HISTORY:
% Melanie Bieli, melanie.bieli@bluewin.ch, 20150121, initial
% David N. Bresch, david.bresch@gmail.com, 20150121, cleanup
% David N. Bresch, david.bresch@gmail.com, 20150122, mode_selector added
% David N. Bresch, david.bresch@gmail.com, 20150122, mode_selector=3 added
% David N. Bresch, david.bresch@gmail.com, 20150204, processing moved to climada_entity_value_GDP_adjust_one
%-

% initialize output
entity_adjusted = [];

% set global variables and directories
global climada_global
if ~climada_init_vars,return;end % init/import global variables

% check input
if ~exist('entity_file_regexp','var'),entity_file_regexp='';end
if ~exist('mode_selector','var'),      mode_selector      =0;end


% PARAMETERS
%
% the table with global GDP etc info (per country)
economic_data_file=[climada_global.data_dir filesep 'system' filesep 'economic_indicators_mastertable.xls'];
%
% missing data indicator (any missing in Excel has this entry)
misdat_value=-999;
%
% income group depending scale-up factors
% we take the income group number (1..4) from the
% economic_indicators_mastertable and use it as index to the
% income_group_factors:
income_group_factors = [2 3 4 5];


% prompt for entity_file_regexp if not given
if isempty(entity_file_regexp) % local GUI
    entity_file_regexp=[climada_global.data_dir filesep 'entities' filesep '*.mat'];
    [filename, pathname] = uigetfile(entity_file_regexp, 'Select entity:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_file_regexp=fullfile(pathname,filename);
    end
end


% find the desired entity / entities
fP = fileparts(entity_file_regexp);
D_entity_mat = dir(entity_file_regexp);

% loop over entity files and adjust asset values
for file_i=1:length(D_entity_mat)
    
    entity_file_i = [fP filesep D_entity_mat(file_i).name];
    try
        load(entity_file_i)
        entity=climada_entity_value_GDP_adjust_one(entity,mode_selector);
        fprintf('saving %s in %s (by %s)\n',D_entity_mat(file_i).name,fP,mfilename)
        save(entity_file_i,'entity')
        
    catch
        fprintf('skipped (invalid entity): %s\n',D_entity_mat(file_i).name);
        entity.assets=[]; % dummy
    end
    
end % ~isempty(country_index)

end % climada_entity_value_GDP_adjust