function event_ii = climada_find_most_severe_event(hazard,event_i)
% climada find most severe hazard event
% MODULE:
%   climada/helper_functions
% NAME:
%   climada_find_most_severe_event
% PURPOSE:
%   find most severe hazard event (or second most or third most severe)
%   among others to be used in climada_map_plot
% CALLING SEQUENCE:
%   event_ii = climada_find_most_severe_event(hazard,event_i)
% EXAMPLE:
%   event_ii = climada_find_most_severe_event(hazard,-1) % identify most severe event
% INPUTS:
%   hazard: hazard structure
%       > prompted for if empty
%   event_i: the i-th event in the hazard event set to be displayed
%       if event_i=0, the maximum intensity at each centroid is shown
%       if event_i=-i, the i-th 'largest' event (sum of intensities) is shown
%           e.g. for event_i=-2, the second largest event is shown
%       default=-1 (just to get something on the screen ;-)
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   event_ii, an index that points to the identified event
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20160129, init
%-

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('hazard','var'),hazard=[];end
if ~exist('event_i','var'),event_i=[];end

hazard = climada_hazard_load(hazard);
if isempty(hazard),return;end

hazard = climada_hazard2octave(hazard); % Octave compatibility for -v7.3 mat-files

if isempty(event_i), event_i = -1; end
if event_i>0; fprintf('To identify the most severe event, please input -1, use -2 for the second most severe event and so on.\n'); return; end

if event_i<0
    % search for i-most severe event
    event_sum = sum(hazard.intensity,2);
    [~,sorted_i] = sort(event_sum);
    event_ii = sorted_i(length(sorted_i)+event_i+1);
end



