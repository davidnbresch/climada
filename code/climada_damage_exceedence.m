function [sorted_damage,exceedence_freq,cumulative_probability,sorted_freq,event_index_out]=climada_damage_exceedence(event_damage,event_freq,event_index);
% climada event damage hazard probabilistic stochastic
% NAME:
%   climada_damage_exceedence
% PURPOSE:
%   sort the damages descendingly
%   calculate the exceedence frequency
%   calculate the cumulative probability
%
% CALLING SEQUENCE:
%   [damage,exceedence_freq,cumulative_probability]=climada_damage_exceedence(event_damage,event_freq);
% EXAMPLE:
%   [damage,exceedence_freq,cumulative_probability]=climada_damage_exceedence([10 1000 100],[0.1 0.001 0.01]);
% INPUTS:
%   event_damage: event damages (array)
%   event_freq: occurrence frequency of each event damage (array)
% OPTIONAL INPUT PARAMETERS:
%   event_index: the event_ID for each event_damage
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
%-

event_index_out=[]; % init

% sort descendingly (could also be done by sortrows, but more explicit here)
[sorted_damage,sort_index]=sort(event_damage); % ascendingly
sort_index=sort_index(end:-1:1); % descendingly
sorted_damage=event_damage(sort_index); % sort damages descendingly
sorted_freq=event_freq(sort_index); % sort frequencies accordingly
if exist('event_index'),event_index_out=event_index(sort_index);end;

% calculate exceedence frequency
exceedence_freq=cumsum(sorted_freq);

% calculate cumulative probability
cumulative_probability=[1 1-exceedence_freq(1:end-1)/exceedence_freq(end)]; % since exceedence frequency(end) is f_total

return;
