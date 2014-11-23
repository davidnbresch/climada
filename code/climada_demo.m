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
% David N. Bresch, david.bresch@gmail.com, 20141123, waitbar suppressed for speedup (noticeable)
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

waitbar_status=climada_global.waitbar; % store configuration
climada_global.waitbar=0; % substantial speedup

close all force
climada_demo_gui

climada_global.waitbar=waitbar_status; % set back

return
