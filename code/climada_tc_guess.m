%batch code climada_tc_guess
% climada template
% MODULE:
%   core
% NAME:
%   climada_tc_guess
% PURPOSE:
%   bring up the GUI to calculate event damages.
%
%   Given a single track file, calculate the damage for all countries
%   posibbly hit (i.e. at least one node within country boders)
%
%   Plus generate ensemble 'forecast' damage
%
%   Fetches data from: weather.unisys.com/hurricane, but since the format
%   and layout of the webpage changed, it only works back to about 2006...
%   earier years will,likely lead to errors. In such cases, retrieve the TC
%   track file manually and run the code by passing the track file in the
%   first variable (UNISYS_regi)
%
%   Just a wrapper for climada_tc_event_damage_ens_gui
% CALLING SEQUENCE:
%   climada_tc_guess
% EXAMPLE:
%   climada_tc_guess
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   GUI
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20161009
%-

climada_tc_event_damage_ens_gui;