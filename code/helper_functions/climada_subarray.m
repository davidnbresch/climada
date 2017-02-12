function [S,untreated_fields]=climada_subarray(S,pos)
% climada template
% MODULE:
%   core
% NAME:
%   climada_subarray
% PURPOSE:
%   given a typical climada structure S, perform S.a=S.a(pos) for all a of
%   dimensions 1xn
%
% CALLING SEQUENCE:
%   [S,untreated_fields]=climada_subarray(S,pos)
% EXAMPLE:
%   S.a=1:10;S.b=1:10;S.c='gaga';S.d=7;S.e=repmat({'abc'},1,10);
%   S=climada_subarray(S,3:6)
%   entity.assets=climada_subarray(entity.assets,find(entity.assets.Value>0))
% INPUTS:
%   S: a structure
%   pos: the positions to keep
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   S: S restricted to pos
%   untreated_fields: a structre, the list with the fieldnames without
%       application of pos 
% MODIFICATION HISTORY
% David N. Bresch, david.bresch@gmail.com, 20161023, initial
% David N. Bresch, david.bresch@gmail.com, 20170212, untreated_fields
%-

untreated_fields={}; % init

% poor man's version to check arguments
if ~exist('S','var'),S=[];end
if ~exist('pos','var'),return;end

if ~isstruct(S),return;end

field_names=fieldnames(S);

for field_i=1:length(field_names)
    %fprintf('checking %s\n',field_names{field_i})
    treat_field=0; % now check:
    if length(S.(field_names{field_i}))>length(pos),treat_field=1;end
    if ischar(S.(field_names{field_i})),treat_field=0;end
    if treat_field
        %fprintf('-> shortening\n')
        try
            S.(field_names{field_i})=S.(field_names{field_i})(pos);
        catch
            fprintf('Warning: field %s not treated\n',char(field_names{field_i}));
            untreated_fields{end+1}=field_names{field_i};
        end
    else
        untreated_fields{end+1}=field_names{field_i};
    end
end % field_i

end % climada_subarray