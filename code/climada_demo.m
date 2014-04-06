function climada_demo
% climada
% NAME:
%   climada_demo
% PURPOSE:
%   a brief demo of climada by way of an interactive GUI
%   
% CALLING SEQUENCE:
%   climada_demo
% EXAMPLE:
%   climada_demo
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20120116
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

close all force
climada_demo_gui

return
