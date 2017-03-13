function res=climada_template(param1,param2)
% climada template
% MODULE:
%   module name
% NAME:
%   climada_template
% PURPOSE:
%   <describe purpose and use here>
%
%   NOTE: this template also contains the use of climada_progress2stdout
%
%   previous call: <note the most usual previous call here>
%   next call: <note the most usual next function call here>
% CALLING SEQUENCE:
%   res=climada_template(param1,param2);
% EXAMPLE:
%   climada_template(param1,param2);
% INPUTS:
%   param1:
%       > promted for if not given
%   OPTION param1: a structure with the fields...
%       this way, parameters can be passed on a fields, see below
% OPTIONAL INPUT PARAMETERS:
%   param2: as an example
% OUTPUTS:
%   res: the output, empty if not successful
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20160603
% David N. Bresch, david.bresch@gmail.com, 20170212, climada_progress2stdout
% David N. Bresch, david.bresch@gmail.com, 20170313, reverted from erroneous save under another name
%-

res=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('param1','var'),param1=[];end % OR:
if ~exist('param1','var'),param1=struct;end % in case we want to pass all parameters as structure
if ~exist('param2','var'),param2=[];end

% locate the module's (or this code's) data folder (usually  a folder
% 'parallel' to the code folder, i.e. in the same level as code folder)
module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
% set default value for param2 if not given
if isempty(param2),param2=2;end
%
% if we want to pass all parameters via the first argument, we can do so:
if isstruct(param1)
    if ~isfield(param1,'field1'),param1.field1='param1_field1';end
    if ~isfield(param1,'field2'),param1.field2=2;end
end

% template to prompt for filename if not given
if isempty(param1) % local GUI
    param1=[climada_global.data_dir filesep '*.mat'];
    [filename, pathname] = uigetfile(param1, 'Open:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        param1=fullfile(pathname,filename);
    end
end

% just to show what's in (should one call climada_template ;-)
% param1
% param2
% module_data_dir

% template for-loop with progress to stdout
n_events = 1000;
fprintf('processing %i events\n',n_events);
climada_progress2stdout    % init, see terminate below
for event_i=1:n_events
    
    % your calculations here
    for i=1:5000,sqrt(i)*exp(event_i);end % DUMMY
    
    climada_progress2stdout(event_i,n_events,100,'events'); % update
end % event_i
climada_progress2stdout(0) % terminate

end % climada_template