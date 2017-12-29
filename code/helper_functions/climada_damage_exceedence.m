function [sorted_damage,exceedence_freq,cumulative_probability,sorted_freq,event_index_out]=climada_damage_exceedence(event_damage,event_freq,event_index,return_damage_RP_clean)
% climada event damage hazard probabilistic stochastic
% NAME:
%   climada_damage_exceedence
% PURPOSE:
%   sort the damages descendingly
%   calculate the exceedence frequency
%   calculate the cumulative probability
%
%   previous call: climada_EDS_calc
%   next call: see e.g. climada_EDS2DFC
% CALLING SEQUENCE:
%   [sorted_damage,exceedence_freq,cumulative_probability,sorted_freq,event_index_out]=...
%       climada_damage_exceedence(event_damage,event_freq,event_index,return_damage_RP_clean)
% EXAMPLE:
%   [damage,exceedence_freq,cumulative_probability]=climada_damage_exceedence([10 1000 100],[0.1 0.001 0.01]);
% INPUTS:
%   event_damage: event damages (array), e.g. EDS.damage
%   event_freq: occurrence frequency of each event damage (array), 
%       e.g. EDS.frequency( see climada_EDS_calc)
% OPTIONAL INPUT PARAMETERS:
%   event_index: the event_ID for each event_damage
%   return_damage_RP_clean: if =1, return damage and return period, only
%       non-zero damages, such that one can readily plot(exceedence_freq,sorted_damage)
%       Default=0, note that this switches the meaning of an output freq -> RP (!)
% OUTPUTS:
%   sorted_damage:   sorted damages (descendingly)
%   exceedence_freq: exceedence frequency for each damage
%   cumulative_probability: cumulative probability of each damage
%   sorted_freq: frequency sorted as event damages
%   event_index_out: event_index sorted as damages (only if provided input)
% RESTRICTIONS:
%   none
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20120430
% David N. Bresch, david.bresch@gmail.com, 20170727, return_damage_RP_clean added
% David N. Bresch, david.bresch@gmail.com, 20171229, bug in return_damage_RP_clean fixed
%-

event_index_out=[]; % init
if ~exist('return_damage_RP_clean','var'),return_damage_RP_clean=0;end
if ~exist('event_index','var'),event_index=[];end

% sort descendingly (could also be done by sortrows, but more explicit here)
[~,sort_index]=sort(event_damage); % ascendingly
sort_index=sort_index(end:-1:1); % descendingly
sorted_damage=event_damage(sort_index); % sort damages descendingly
sorted_freq=event_freq(sort_index); % sort frequencies accordingly
if ~isempty(event_index),event_index_out=event_index(sort_index);end;

% calculate exceedence frequency
exceedence_freq=cumsum(sorted_freq);

% calculate cumulative probability
cumulative_probability=[1 1-exceedence_freq(1:end-1)/exceedence_freq(end)]; % since exceedence frequency(end) is f_total

if return_damage_RP_clean
    nonzero_pos     = find(exceedence_freq);
    sorted_damage   = sorted_damage(nonzero_pos);
    exceedence_freq = exceedence_freq(nonzero_pos);
end % climada_damage_exceedence