function climada_progress2stdout(event_i,n_events,mod_step,msg_str)
% climada template
% MODULE:
%   core
% NAME:
%   climada_template
% PURPOSE:
%   show progress on stdout
%
% CALLING SEQUENCE:
%   climada_progress2stdout(event_i,n_events,mod_step,msg_str)
% EXAMPLE:
%   climada_progress2stdout          % init
%   climada_progress2stdout(-1,[],1) % init with mod_step 1 insted of 10 (default)
%   n_events=10000;
%   for i=1:n_events
%       a=cos(pi*i)
%       climada_progress2stdout(i,n_events,100,'events');
%   end % i
%   climada_progress2stdout(0); % terminate
% INPUTS:
%   event_i: the current event, if =-1 (or not provided) init the counter
%   n_events: to total number of events in the loop
% OPTIONAL INPUT PARAMETERS:
%   mod_step: the number of steps between reporting to stdout, default=10
%   msg_str: the string message in the reporting line, i.e.
%       est.  XXX sec left (10/10000 {msg_str}), default: =''
% OUTPUTS:
%   res: the output, empty if not successful
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20170212
% David N. Bresch, david.bresch@gmail.com, 20170216 all fine
% Samuel Eberenz, eberenz@posteo.eu, 20180209, redo init if not done properly
%-

persistent progress2stdout_data

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('event_i','var'), event_i  = -1;end
if ~exist('n_events','var'),n_events =  0;end
if ~exist('mod_step','var'),mod_step = 10;end
if ~exist('msg_str','var'), msg_str  = '';end

if event_i==0,fprintf(progress2stdout_data.format_str,'');return,end % terminate, move carriage to begin of line

if event_i==-1 || isempty(progress2stdout_data)% init
    progress2stdout_data.t0         = clock;
    progress2stdout_data.mod_step   = mod_step;
    progress2stdout_data.format_str = '%s';
    if event_i==-1, return; end
end

% the progress management
if mod(event_i,progress2stdout_data.mod_step)==0
    progress2stdout_data.mod_step = mod_step;
    t_elapsed_event   = etime(clock,progress2stdout_data.t0)/event_i;
    events_remaining  = n_events-event_i;
    t_projected_sec   = t_elapsed_event*events_remaining;
    if t_projected_sec<60
        msgstr = sprintf('est. %3.0f sec left (%i/%i %s)',t_projected_sec,   event_i,n_events,msg_str);
    else
        msgstr = sprintf('est. %3.1f min left (%i/%i %s)',t_projected_sec/60,event_i,n_events,msg_str);
    end
    fprintf(progress2stdout_data.format_str,msgstr); % write progress to stdout
    progress2stdout_data.format_str=[repmat('\b',1,length(msgstr)) '%s']; % back to begin of line
    % end
end

end % climada_progress2stdout