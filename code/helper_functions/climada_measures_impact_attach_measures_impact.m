function measures_impact = climada_measures_impact_attach_measures_impact(measures_impact1,measures_impact2,silent_mode)
% climada measures attach another measures_impact
% MODULE:
%   core/helper_functions
% NAME:
%   climada_measures_impact_attach_measures_impact
% PURPOSE:
%   Attach/enlarge a measure impact structure with another one. I.e.
%   if you have calculated two measures_impact based on two different
%   entity.measures, add both into one structure (does not add up benefits
%   or damages, but enlarges the structure).
%
% CALLING SEQUENCE:
%   measures_impact = climada_measures_impact_attach_measures_impact(measures_impact1,measures_impact2,silent_mode)
% EXAMPLE:
%   measures_impact = climada_measures_impact_attach_measures_impact(measures_impact1,measures_impact2,silent_mode)
% INPUTS:
%   measures_impact1: a climada measures_impact structure (as returned eg 
%       by climada_measures_impact).
%   measures_impact2: a climada measures_impact structure (as returned eg 
%       by climada_measures_impact) if measures_impact2 is an array of 
%       measures_impact2(i), the code will find the matching scenario
% OPTIONAL INPUT PARAMETERS:
%   silent_mode: default is 1, set to 0, if you want command line output
% OUTPUTS:
%   measures_impact: the combined measures_impact
%       Please note that assets are likely not meaningful, since just taken
%       from measures_impact1 (in order to allow to store resulting measures_impact back into an
%       array of measures_impacts if needed)
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151217, init 
%-

measures_impact = []; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('measures_impact1','var'),return;end
if ~exist('measures_impact2','var'),return;end
if ~exist('silent_mode','var'), silent_mode = ''; end


% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
% set default value for param2 if not given
if isempty(silent_mode), silent_mode = 1; end 

% init output
measures_impact = measures_impact1; 

% get all scenarios
clear scenario1 scenario2
for s_i = 1:numel(measures_impact1)
    scenario1{s_i,1} = measures_impact1(s_i).scenario.name;
end
for s_i = 1:numel(measures_impact2)
    scenario2{s_i,1} = measures_impact2(s_i).scenario.name;
end
scenario = unique({scenario1{:} scenario2{:}});

% loop over all scenarios
for s_i = 1:numel(scenario)
    n_measures_part_1 = numel(measures_impact1(s_i).EDS)-1;
    n_measures_part_2 = numel(measures_impact2(s_i).EDS)-1;
    
    % attach EDS (ED_at_centroid, ...)
    measures_impact(s_i).EDS(n_measures_part_1+1:n_measures_part_1+1+n_measures_part_2) = measures_impact2(s_i).EDS;
    
    % attach ED, DFC, risk_transfer...
    measures_impact(s_i).ED = [measures_impact1(s_i).ED(1:end-1) measures_impact2(s_i).ED];
    measures_impact(s_i).DFC(n_measures_part_1+1:n_measures_part_1+n_measures_part_2,:) = measures_impact2(s_i).DFC;
    measures_impact(s_i).risk_transfer = [measures_impact1(s_i).risk_transfer measures_impact2(s_i).risk_transfer];
    measures_impact(s_i).benefit = [measures_impact1(s_i).benefit measures_impact2(s_i).benefit];
    measures_impact(s_i).cb_ratio = [measures_impact1(s_i).cb_ratio measures_impact2(s_i).cb_ratio];
    measures_impact(s_i).ED_benefit = [measures_impact1(s_i).ED_benefit measures_impact2(s_i).ED_benefit];
    measures_impact(s_i).ED_risk_transfer = [measures_impact1(s_i).ED_risk_transfer measures_impact2(s_i).ED_risk_transfer];
    measures_impact(s_i).ED_cb_ratio = [measures_impact1(s_i).ED_cb_ratio measures_impact2(s_i).ED_cb_ratio];
    
    % attach measures
    measures_impact(s_i).measures = climada_measures_attach_measures(measures_impact1(s_i).measures,measures_impact2(s_i).measures,silent_mode);
end


