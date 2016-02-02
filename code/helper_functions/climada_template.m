function res=climada_template(param1,param2)
% climada template
% MODULE:
%   module name
% NAME:
%   climada_template
% PURPOSE:
%   Describe the purpouse in a few sentences
%   here: template for header and simple argument checks
% CALLING SEQUENCE:
%   climada_template(param1,param2);
% EXAMPLE:
%   climada_template(param1,param2);
% INPUTS:
%   param1: 
%       > promted for if not given
%   OPTION param1: a structure with the fields...
%       this way, parameters can be passed on a fields
% OPTIONAL INPUT PARAMETERS:
%   param2: as an example
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150128
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

% locate the module's (or this code's) data folder (usually  afolder
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
param1
param2
module_data_dir

% template for-loop with waitbar or progress to stdout
t0       = clock;
n_events = 10000;
msgstr   = sprintf('processing %i events',n_events);
mod_step = 10; % first time estimate after 10 events, then every 100

if climada_global.waitbar
    fprintf('%s (updating waitbar with estimation of time remaining every 100th event)\n',msgstr);
    h        = waitbar(0,msgstr);
    set(h,'Name','Event loop');
else
    fprintf('%s (waitbar suppressed)\n',msgstr);
    format_str='%s';
end

for event_i=1:n_events
    
    % your calculations here
    for i=1:5000,sqrt(i)*exp(event_i);end % DUMMY
    
    % the progress management
    if mod(event_i,mod_step)==0
        mod_step          = 100;
        t_elapsed_event   = etime(clock,t0)/event_i;
        events_remaining  = n_events-event_i;
        t_projected_sec   = t_elapsed_event*events_remaining;
        if t_projected_sec<60
            msgstr = sprintf('est. %3.0f sec left (%i/%i events)',t_projected_sec,   event_i,n_events);
        else
            msgstr = sprintf('est. %3.1f min left (%i/%i events)',t_projected_sec/60,event_i,n_events);
        end
        if climada_global.waitbar
            waitbar(event_i/n_events,h,msgstr); % update waitbar
        else
            fprintf(format_str,msgstr); % write progress to stdout
            format_str=[repmat('\b',1,length(msgstr)) '%s']; % back to begin of line
        end
    end
    
end % event_i
if climada_global.waitbar
    close(h) % dispose waitbar
else
    fprintf(format_str,''); % move carriage to begin of line
end
fprintf('after the loop\n')

return
