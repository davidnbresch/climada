function [is_today, is_eco, is_cc] = climada_scenario_waterfall_identify(measures_impact)
% climada identify scenarios today, eco and climate change
% NAME:
%   climada_scenario_waterfall_identify
% PURPOSE:
%   Given a measures_impact with multiple scenarios, identify scenario
%   today, economic development and climate change.
% 
% CALLING SEQUENCE:
%   [is_today, is_eco, is_cc] = climada_scenario_waterfall_identify(measures_impact)
% EXAMPLE:
%   [is_today, is_eco, is_cc] = climada_scenario_waterfall_identify(measures_impact)
% INPUTS:
%   measures_impact: a climate measures_impact structure with field
%    .scenario. 
%       > promted for if not given
% OUTPUTS:
%   is_today: a number pointing to the order in which the today's scenario
%       is located within measurse_impact 
%   is_eco: a number pointing to the order in which the economic scenario
%       is located within measurse_impact
%   is_cc: a number pointing to the order in which the climate change scenario
%       is located within measurse_impact
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151127, init
%-

is_today = []; is_eco = []; is_cc = []; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables


% poor man's version to check arguments
if ~exist('measures_impact','var'), measures_impact = [];end
if isempty(measures_impact), measures_impact = climada_measures_impact_load; end

if ~isfield(measures_impact,'scenario'),return, end

% SCENARIO
% get all scenario
for i = 1:numel(measures_impact)
    scenario_list{i,1} = measures_impact(i).scenario.name_simple;
    scenario_long_list{i,1} = measures_impact(i).scenario.name;
    assets_year(i,1) = measures_impact(i).scenario.assets_year;
    hazard_year(i,1) = measures_impact(i).scenario.hazard_year;
    hazard_scenario{i,1} = measures_impact(i).scenario.hazard_scenario;
    region{i,1} = measures_impact(i).scenario.region;
end

if numel(unique(scenario_list))<3, return, end

% we have at least two different hazard scenarios
is_hazard_today = strcmp(hazard_scenario,'no change');
assets_year_unique = unique(assets_year(is_hazard_today));

if numel(assets_year_unique)<2, return, end

% we have at least two different time horizons for assets
present_reference_year = min(assets_year_unique);
future_reference_year = max(assets_year_unique);

hazard_year_unique = unique(hazard_year(~is_hazard_today));

is_future_hazard_year = ismember(hazard_year_unique,future_reference_year);
future_hazard_year = hazard_year_unique(is_future_hazard_year);

if future_hazard_year~= future_reference_year, return, end

% we have found the unique combinations
is_today = find(assets_year == present_reference_year .* strcmp(hazard_scenario,'no change'));
is_eco = find(assets_year == future_reference_year .* strcmp(hazard_scenario,'no change'));
is_cc = find(assets_year == future_reference_year .* ~strcmp(hazard_scenario,'no change'));

if isempty(is_today) || isempty(is_eco) || isempty(is_cc), return, end

% take only the first entry
is_today = is_today(1);
is_eco = is_eco(1);
is_cc = is_cc(1);



