function [EDS1, EDS2, EDS3, is_today, is_eco, is_cc] = climada_measures_impact2EDS_waterfall(measures_impact,measure_no,category_selected,silent_mode)
% climada measures impact combine scenario
% MODULE:
%   core/helper_functions
% NAME:
%   climada_measures_impact2EDS_waterfall
% PURPOSE:
%   Extract 3 EDS from measures_impact that contains 3 or more
%   structs/scenarios to plot waterfall (in the next step)
%   
%   invokes: climada_scenario_identify if more than 3 structs given
% NEXT: climada_waterfall_graph
% CALLING SEQUENCE:
%   [EDS1, EDS2, EDS3, is_today, is_eco, is_cc] = climada_measures_impact2EDS_waterfall(measures_impact,measure_no,category_selected,silent_mode)
% EXAMPLE:
%   [EDS1, EDS2, EDS3] = climada_measures_impact2EDS_waterfall(measures_impact)
% INPUTS:
%   measures_impact: a climada measures_impact structure (as returned eg 
%       by climada_measures_impact). Holds at least three structs (one for
%       today, one for econ. development, one for climate change).
% OPTIONAL INPUT PARAMETERS:
%   measure_no: default is end/control scenario, but can also be a specific measure
%   category_selected: a string or a cell, e.g. 'Houses', or {'Houses' 'Public'},  if empty all assets will be selected
%   silent_mode: default =0
% OUTPUTS:
%   EDS1: a climada EDS struct for scenario today, with EDS.ED summed for a
%      specific category
%   EDS2: same as above but for scenario economic development
%   EDS3: same as above but for scenario climate change
%   is_today: a number pointing to the order in which the original EDS was
%      located within measurse_impact
%   is_eco: a number pointing to the order in which the original EDS was
%      located within measurse_impact
%   is_cc: a number pointing to the order in which the original EDS was
%      located within measurse_impact
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151202, init
% Lea Mueller, muellele@gmail.com, 20151202, add option silent_mode
%-

EDS1 = []; EDS2 = []; EDS3 = [];% init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('measures_impact','var'), return; end
if ~exist('measure_no','var'), measure_no = 1; end
if ~exist('category_selected','var'), category_selected = ''; end
if ~exist('silent_mode','var'), silent_mode = ''; end


% PARAMETERS
% define all parameters here - no parameters to be defined in code below
if ~isfield(measures_impact,'scenario'),return, end
% if isempty(measure_no), measure_no = 1; end 
if isempty(measure_no), measure_no = numel(measures_impact(1).EDS); end
if isempty(silent_mode), silent_mode = 0; end 


% identify scenarios, today, economic development, climate change
% only if we have more than 3 scenarios
is_today = 1; is_eco = 2; is_cc = 3;
if numel(measures_impact)>3
    [is_today, is_eco, is_cc] = climada_scenario_waterfall_identify(measures_impact);
end
clear EDS
EDS(1) = measures_impact(is_today).EDS(measure_no);
EDS(2) = measures_impact(is_eco).EDS(measure_no);
EDS(3) = measures_impact(is_cc).EDS(measure_no);

% add scenario names
EDS(1).annotation_name = measures_impact(is_today).scenario.name_simple;
EDS(2).annotation_name = measures_impact(is_eco).scenario.name_simple;
EDS(3).annotation_name = measures_impact(is_cc).scenario.name_simple;

% recalculate EDS.ED based on selected category/ies
% select specific locations (based on categories, or units)
silent_mode = 0;

for i = 1:3
    clear entity
    entity.assets = EDS(1).assets;
    is_selected = climada_assets_select(entity,[],[],category_selected,silent_mode);
    EDS(i).ED_at_centroid(~is_selected) = 0;
    EDS(i).ED = sum(EDS(i).ED_at_centroid);
end

EDS1 = EDS(1);
EDS2 = EDS(2);
EDS3 = EDS(3);

end % climada_measures_impact2EDS_waterfall
