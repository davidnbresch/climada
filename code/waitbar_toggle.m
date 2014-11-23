function waitbar_toggle
% climada
% NAME:
%   waitbar_toggle
% PURPOSE:
%   toggle waitbar (calling once suppresses the waitbar, calling again
%   brings it back).
%
%   Simply sets climada_global.waitbar=0, just for ease of use,
%   that's why it comes also with a function name without 'climada_'
%
% CALLING SEQUENCE:
%   waitbar_toggle
% EXAMPLE:
%   waitbar_toggle
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141123
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables
climada_global.waitbar=not(climada_global.waitbar);
if climada_global.waitbar
    fprintf('waitbar: on\n');
else
    fprintf('waitbar: off\n');
end