function TF=climada_contains(str,pattern)
% climada template
% MODULE:
%   core
% NAME:
%   climada_contains
% PURPOSE:
%   wrapper for contains() function, which does not exist on Octave
%
% CALLING SEQUENCE:
%   in=contains(str, pattern)
% INPUTS:
%   str: string
%   pattern: string
% OUTPUTS:
%   in: the indices of the points within the polygon (see help inpolygon)
% MODIFICATION HISTORY:
% Mark Westcott, mark.westcott@vivideconomics.com, 20180622, initial

global climada_global
if ~climada_init_vars,return;end % init/import global variables


if ~climada_global.octave_mode
  TF = contains(str,pattern); % MATLAB
else

  if(  (!(ischar (str) && isvector (str))) && (!ischar(str) && !iscellstr(str)) )
    error("Search term should be a character vector, or cell array of character vectors.");
  end;

  if (!iscellstr(str))
    str = cellstr(str);
  end

  TF = cellfun(@numel, strfind (str, pattern));
  
 end
