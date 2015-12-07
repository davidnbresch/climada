function measures_impact = climada_measures_impact_combine_scenario(measures_impact1,measures_impact2,measures_impact3,peril_list,silent_mode)
% climada measures impact combine scenario
% MODULE:
%   core/helper_functions
% NAME:
%   climada_measures_impact_combine
% PURPOSE:
%   Combine measure impact structures for a given scenario, i.e. add
%   damages and averted damages for a list of selected perils, so that we have an
%   overall impact of averted damage per scenario. Needs
%   measures_impact.scenario field.
%
%   invokes: climada_measures_impact_combine
% CALLING SEQUENCE:
%   measures_impact=climada_measures_impact_combine_scenario(measures_impact1,measures_impact2,measures_impact3,peril_list,silent_mode)
% EXAMPLE:
%   measures_impact=climada_measures_impact_combine_scenario(measures_impact1,'','',{'TC' 'FL'})
% INPUTS:
%   measures_impact1: a climada measures_impact structure (as returned eg 
%       by climada_measures_impact).
%   measures_impact2: a climada measures_impact structure (as returned eg 
%       by climada_measures_impact) if measures_impact2 is an array of 
%       measures_impact2(i), the code will recursively treat them
%    measures_impact3: a climada measures_impact structure (as returned eg 
%       by climada_measures_impact) if measures_impact3 is an array of 
%       measures_impact3(i), the code will recursively treat them
%    peril_list: a cell with list of peril IDs, i.e. {'TC' 'FL'}
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   measures_impact: the combined measures_impact, summed up all perils per
%       scenario
%       Please note that assets are likely not meaningful, since just taken
%       from measures_impact1 (in order to allow to store resulting measures_impact back into an
%       array of measures_impacts if needed)
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151202, init
% Lea Mueller, muellele@gmail.com, 20151202, add option silent_mode
%-

measures_impact=[]; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('measures_impact1','var'),return;end
if ~exist('measures_impact2','var'),measures_impact2=[];end
if ~exist('measures_impact3','var'),measures_impact3=[];end
if ~exist('peril_list','var'),peril_list='';end
if ~exist('silent_mode','var'), silent_mode = ''; end



% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
% set default value for param2 if not given

if ~isfield(measures_impact1,'scenario'),return, end
if isempty(silent_mode), silent_mode = 0; end 

measures_impact = measures_impact1;
if ~isempty(measures_impact2) 
    if isfield(measures_impact2,'scenario')
        no_measures = numel(measures_impact2);
        measures_impact(end+1:end+no_measures) = measures_impact2;
    end
end
if ~isempty(measures_impact3) 
    if isfield(measures_impact3,'scenario')
        no_measures = numel(measures_impact3);
        measures_impact(end+1:end+no_measures) = measures_impact3;
    end
end
clear measures_impact1 measures_impact2 measures_impact3


% get all scenario names
for s_i=1:numel(measures_impact)
    scenario_all{s_i,1} = measures_impact(s_i).scenario.name;
    peril_list_all{s_i,1} = measures_impact(s_i).peril_ID;
end
scenario_unique = unique(scenario_all);



% loop over the unique scenarios
for s_i = 1:numel(scenario_unique)
    is_scenario = strcmp(scenario_all,scenario_unique{s_i});
    is_peril    = ismember(peril_list_all,peril_list);
    is_selected = logical(is_scenario .* is_peril);
    
    if sum(is_selected)>0
        measures_impact_temp = [];
        measures_impact_temp = measures_impact(is_selected);

        combine_modus = 'delete_measures';
        measures_impact_combined(s_i) = climada_measures_impact_combine(measures_impact_temp(1),measures_impact_temp(2:end),combine_modus,silent_mode);
    end
end

measures_impact = measures_impact_combined;


end % climada_measures_impact_combine_scenario
