function [S,untreated_fields]=climada_subarray(S,pos,silent_mode,exempt_fieldnames)
% climada template
% MODULE:
%   core
% NAME:
%   climada_subarray
% PURPOSE:
%   given a typical climada structure S, perform S.a=S.a(:,pos) 
%   this means the SECOND dimension gets selected, the FIRST remains
%   untreated.
%
% CALLING SEQUENCE:
%   [S,untreated_fields]=climada_subarray(S,pos,silent_mode)
% EXAMPLE:
%   S.a=1:10;S.b=1:10;S.c='gaga';S.d=7;S.e=repmat({'abc'},1,10);S.f=2:11;S.g=[S.a',S.a']'
%   [S,untreated_fields]=climada_subarray(S,3:6,-1,{'f'})
%   entity.assets=climada_subarray(entity.assets,find(entity.assets.Value>0))
% INPUTS:
%   S: a structure
%   pos: the positions to keep
% OPTIONAL INPUT PARAMETERS:
%   silent_mode: if =1, do not warn etc, default=0, if =-1, list all
%       treated fields to stdout
%   exempt_fieldnames: a list {'field_a','field_b'} not to be treated
% OUTPUTS:
%   S: S restricted to pos
%   untreated_fields: a structure, the list with the fieldnames without
%       application of pos 
% MODIFICATION HISTORY
% David N. Bresch, david.bresch@gmail.com, 20161023, initial
% David N. Bresch, david.bresch@gmail.com, 20170212, untreated_fields
% David N. Bresch, david.bresch@gmail.com, 20170221, silent_mode
% David N. Bresch, david.bresch@gmail.com, 20170224, a must be 1xn
% David N. Bresch, david.bresch@gmail.com, 20170806, exempt_fieldnames added
% David N. Bresch, david.bresch@gmail.com, 20170806, switched from (pos) to (:,pos)
%-

untreated_fields={}; % init

% poor man's version to check arguments
if ~exist('S','var'),S=[];end
if ~exist('pos','var'),return;end
if ~exist('silent_mode','var'),silent_mode=0;end
if ~exist('exempt_fieldnames','var'),exempt_fieldnames={};end

if ~isstruct(S),return;end

field_names=fieldnames(S);

for field_i=1:length(field_names)
    %fprintf('checking %s\n',field_names{field_i})
    treat_field=0; % now check:
    if size(S.(field_names{field_i}),2)>=length(pos),treat_field=1;end
    if ischar(S.(field_names{field_i})),treat_field=0;end
    if ismember(field_names{field_i},exempt_fieldnames),treat_field=0;end
    if treat_field
        try
            S.(field_names{field_i})=S.(field_names{field_i})(:,pos); % was (pos) until 20170806
            if silent_mode==-1,fprintf('-> treated %s\n',field_names{field_i});end
        catch
            if ~silent_mode,fprintf('Warning: field %s not treated\n',char(field_names{field_i}));end
            untreated_fields{end+1}=field_names{field_i};
        end
    else
        if silent_mode==-1,fprintf('-> %s not treated\n',field_names{field_i});end
        untreated_fields{end+1}=field_names{field_i};
    end
end % field_i

end % climada_subarray