function climada_template(param1,param2)
% climada
% NAME:
%   climada_template
% PURPOSE:
%   
% CALLING SEQUENCE:
%   climada_template(param1,param2);
% EXAMPLE:
%   climada_template(param1,param2);
% INPUTS:
%   param1: 
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   param2: as an example
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141206
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('param1','var'),param1=[];end
if ~exist('param2','var'),param2=[];end

% locate the module's data
module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% PARAMETERS
%
% set default value for param2 if not given
if isempty(param2),param2=2;end

% prompt for param1 if not given
if isempty(param1) % local GUI
    param1=[climada_global.data_dir filesep '*.mat'];
    [filename, pathname] = uigetfile(param1, 'Open:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        param1=fullfile(pathname,filename);
    end
end

return
