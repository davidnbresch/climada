function EDS = climada_measure_regional_scope(EDS_in,within_scope,EDS_control)
% climada
% NAME:
%   climada_measure_regional_scope
% PURPOSE:
%   Limit impact of measure to a given regional scope, correct
%   EDS.ED_at_centroid and EDS.ED.
%   Note: EDS.damage now holds an incorrect value, and should not be used anyore
%   to be called in climada_measures_impact
% CALLING SEQUENCE:
%   EDS = climada_measure_regional_scope(EDS_in,regional_scope,EDS_control)
% EXAMPLE:
%   EDS = climada_measure_regional_scope(EDS_in,regional_scope,EDS_control)
% INPUTS:
%   EDS_in: a climada EDS structure with .ED_at_centroid
%   within_scope: an logical array defining the regional scope
%   EDS_control: a climada EDS structure with .ED_at_centroid with original damage values without measure
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   EDS: a climada EDS structure with corrected damages depening on regional impact of measure
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150908, init
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('EDS_in','var'), EDS_in = ''; end
if ~exist('within_scope','var'), within_scope = ''; end
if ~exist('EDS_control','var'), EDS_control = ''; end
        
EDS = []; % init

if isempty(EDS_in); return, end
if isempty(within_scope); EDS = EDS_in; return, end
if isempty(EDS_control); EDS = EDS_in; return, end

% check that ED_at_centroid exists, otherwise we cannot proceed
if ~isfield(EDS_in,'ED_at_centroid'), return, end
if ~isfield(EDS_control,'ED_at_centroid'), return, end

% check that regional_scope vector has the correct dimension 
if ~size(within_scope,1) == numel(EDS_in.ED_at_centroid)
    fprintf('Regional scope of measures does not match with number of assets./n')
    return
end

% limit impact of measure to a given regional scope
EDS = EDS_in; %init
EDS.ED_at_centroid(~within_scope) = EDS_control.ED_at_centroid(~within_scope);
EDS.ED = sum(EDS.ED_at_centroid);
EDS.Value = EDS_control.Value;



        

