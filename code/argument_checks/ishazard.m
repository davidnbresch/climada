function ok = ishazard(hazard)
% check if valid hazard struct
% MODULE:
%   core
% NAME:
%   ishazard
% PURPOSE:
%   For quick arg checking, defining and standardising hazard structs to have the
%   minimum required fields.
% PREVIOUS STEP:
% CALLING SEQUENCE:
%   ok = ishazard(hazard)
% EXAMPLE:
%   ok = ishazard(hazard)
% INPUTS:
%   hazard:     any struct to be checked
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   ok:         1 if input satisfies the conditions to be a hazard struct
%               0 otherwise
% MODIFICATION HISTORY:
% Gilles Stassen, gillesstassen@hotmail.com, 20150826 init
% David N. Bresch, david.bresch@gmail.com, 20161008, units, orig_event_flag, yyyy, mm, dd, datenum and reference_year are optional
%-

ok = 0; % init

err_msg = '';

if ~exist('hazard', 'var'), err_msg = 'invalid argument';           end
if isempty(hazard),         err_msg = 'argument empty';             end
if ~isstruct(hazard),       err_msg = 'hazard must be a structure'; end

if ~isempty(err_msg)
    cprintf([1 0 0],'ERROR: %s\n',err_msg)
    return;
end

% required fields which define a hazard struct
flds =  {
    'lon'
    'lat'
    'intensity'
    'centroid_ID'
    'peril_ID'
    %'units'
    'frequency'
    'event_ID'
    %'orig_event_flag'
    %'yyyy'
    %'mm'
    %'dd'
    %'datenum'
    %'reference_year'
    };

ok = 1;
missing_flds = {}; % init
for fld_i = 1:length(flds)
    if ~isfield(hazard,flds(fld_i))
        ok = 0;
        missing_flds{end+1} = flds{fld_i};
    end
end

if ~ok
    cprintf([1 0 0],'ERROR: invalid hazard structure - missing required fields:\n')
    for fld_i =1:length(missing_flds)
        fprintf('\t\t- %s\n',missing_flds{fld_i})
    end
end

end % ishazard