function measures_impact = climada_measures_impact_read(measures)
% climada measures impact read (from measures-xls file)
% NAME:
%   climada_measures_impact_read
% PURPOSE:
%   Create measures_impact struct from measures.cost and
%   measures.benefit, read from the excel file. Works only if field
%   "benefit" is given in the measures-xls file.
%   
%   Plot adaptation cost curve directy with measures-xls field instead of
%   calculation benefits with climada_measures_impact
% CALLING SEQUENCE:
%  measures_impact = climada_measures_impact_read(measures)
% EXAMPLE:
%    measures_impact = climada_measures_impact_read
%    measures_impact = climada_measures_impact_read('measures_impact_xls.xls')
% INPUTS:
%   measures: the measures as read from climada_measures_read or the 
%       filename of the Excel file with the measures
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   measures_impact: a structure that can be plotted with climada_adaptation_cost_curve,
%       i.e. with fields .benefit, .cb_ratio, .measures, etc.
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20160523, init
% Lea Mueller, muellele@gmail.com, 20160531, NVP_total_climate_risk is an array instead of a vector
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

measures_impact = []; %init

% poor man's version to check arguments
if ~exist('measures','var'), measures = [];end

% PARAMETERS

% read the measures if not given
if isempty(measures) || ischar(measures) , measures = climada_measures_read(measures); end

% key field to create the measures_impact structure is "benefit"
if ~isfield(measures,'benefit'), return, end

% perform some basic checks
if numel(measures.benefit) ~= numel(measures.cost), return, end
if isempty(measures.benefit), return, end

fprintf('Field "benefit" found in measures. We create a struct "measures_impact" to be plotted directly in adaptation cost curve.\n')

n_measures = numel(measures.cost);

% calculate cb_ratio
if ~isfield(measures,'cb_ratio')
    measures.cb_ratio = measures.cost./measures.benefit;
end

% fill risk_transfer with zeros
if ~isfield(measures,'risk_transfer'), measures.risk_transfer = zeros(n_measures,1); end

% fill ED with nan
if ~isfield(measures,'ED'), measures.ED = nan(n_measures+1,1); end

% fill title_str with ''
if ~isfield(measures,'title_str'), measures.title_str = ''; end

% fill NPV_total_climate_risk with nan
if ~isfield(measures,'NPV_total_climate_risk'), measures.NPV_total_climate_risk = nan; end

% fill Value_display_unit_name with climada_global
if ~isfield(measures,'Value_display_unit_name'), measures.Value_display_unit_name = climada_global.Value_display_unit_name; end
if ~isfield(measures,'Value_display_unit_fact'), measures.Value_display_unit_name = climada_global.Value_display_unit_fact; end
if ~isfield(measures,'cost_display_unit_name'), measures.cost_display_unit_name = climada_global.cost_display_unit_name; end
if ~isfield(measures,'cost_display_unit_fact'), measures.cost_display_unit_fact = climada_global.cost_display_unit_fact; end

if iscell(measures.Value_display_unit_name), measures.Value_display_unit_name = measures.Value_display_unit_name{1}; end
if iscell(measures.cost_display_unit_name), measures.cost_display_unit_name = measures.cost_display_unit_name{1}; end

if numel(measures.Value_display_unit_fact)>1, measures.Value_display_unit_fact = measures.Value_display_unit_fact(1); end
if numel(measures.cost_display_unit_fact)>1, measures.cost_display_unit_fact = measures.cost_display_unit_fact(1); end
if numel(measures.NPV_total_climate_risk)>1, measures.NPV_total_climate_risk = measures.NPV_total_climate_risk(1); end

% put fields into separate structure and revove from measures
measures_impact.benefit = measures.benefit;
% make sure it is an 1xn vector
measures_impact.benefit = reshape(measures_impact.benefit,1,n_measures);

measures_impact.cb_ratio = measures.cb_ratio;
measures_impact.ED = measures.ED;
measures_impact.risk_transfer = measures.risk_transfer;
measures_impact.Value_display_unit_name = measures.Value_display_unit_name;
measures_impact.Value_display_unit_fact = measures.Value_display_unit_fact;
measures_impact.cost_display_unit_name = measures.cost_display_unit_name;
measures_impact.cost_display_unit_fact = measures.cost_display_unit_fact;
measures_impact.NPV_total_climate_risk = measures.NPV_total_climate_risk;
measures_impact.title_str = measures.title_str;
measures_impact.EDS = ''; %so that the struct is identified as measures_impact in climada_measures_impact_load

measures = rmfield(measures,'benefit');
measures = rmfield(measures,'cb_ratio');
measures = rmfield(measures,'ED');
measures = rmfield(measures,'risk_transfer');
measures = rmfield(measures,'Value_display_unit_name');
measures = rmfield(measures,'Value_display_unit_fact');
measures = rmfield(measures,'cost_display_unit_name');
measures = rmfield(measures,'cost_display_unit_fact');
measures = rmfield(measures,'NPV_total_climate_risk');
measures = rmfield(measures,'title_str');

% add measures 
measures_impact.measures = measures;

return
