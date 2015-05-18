function measures=climada_measures_encode(measures)
% climada
% NAME:
%   climada_measures_encode
% PURPOSE:
%   encode measures, i.e. process the damagefunctions_map to concert it
%   into a damagefunctions_mapping, which allows climada_measures_impact to
%   switch damagefunctions for specific measures.
%
%   See also climada_damagefunctions_read and climada_damagefunctions_map
% CALLING SEQUENCE:
%   measures=climada_measures_encode(measures);
% EXAMPLE:
%   measures=climada_measures_encode(climada_measures_read);
% INPUTS:
%   measures: a structure, with the measures
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20100107
% David N. Bresch, david.bresch@gmail.com, 20141121, using only damagefunctions_map information
% David N. Bresch, david.bresch@gmail.com, 20150103, some checks for .ods imported entities
% David N. Bresch, david.bresch@gmail.com, 20150518, safety checkin
%-

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('measures','var'),measures=[];return;end

% PARAMETERS
%

% make sure measures are well-defined (to fix an issue with .ods sometimes
% reading more than the 'popupated' rows)
measures.name=measures.name(1:length(measures.cost));
measures.color=measures.color(1:length(measures.cost));
if isfield(measures,'hazard_event_set')
    measures.hazard_event_set=measures.hazard_event_set(1:length(measures.cost));
end
measures.damagefunctions_map=measures.damagefunctions_map(1:length(measures.cost));
if isfield(measures,'peril_ID')
    measures.peril_ID=measures.peril_ID(1:length(measures.cost));
end

if isfield(measures,'color')
    color_warning=0;
    % convert to RGB triplets
    for measure_i=1:length(measures.cost)
        try
            measures.color_RGB(measure_i,:)=str2num(measures.color{measure_i});
        catch
            % troubles reading this particular field from .ods, since a triple)
            color_warning=1;
            measures.color_RGB(measure_i,:)=[255 219 105]/255; % each range 0..1
        end
    end % measure_i
    if color_warning,fprintf('Note: measure colors not read properly, set to default (yellow, see entity.measures.color_RGB)\n');end
end

% interpret all the mappings

if isfield(measures,'damagefunctions_map')
    if isfield(measures,'damagefunctions'),DamageFunIDs=unique(measures.damagefunctions.DamageFunID);end
    for measure_i=1:length(measures.damagefunctions_map) % 20141121, used measures.cost before, 20150103 use cost for safety again
        damagefunctions_map=deblank(measures.damagefunctions_map{measure_i});
        if ~strcmp(damagefunctions_map,'nil')
            n_maps=length(findstr(damagefunctions_map,';'))+1; % always one map more than separators
            for map_i=1:n_maps
                [one_map,damagefunctions_map]=strtok(damagefunctions_map,';') ;
                [map_from,map_to]=strtok(one_map,'to');
                measures.damagefunctions_mapping(measure_i).map_from(map_i)=str2num(map_from);
                measures.damagefunctions_mapping(measure_i).map_to(map_i)=str2num(strrep(map_to,'to',''));
                if exist('DamageFunIDs','var')
                    if length(find(DamageFunIDs==measures.damagefunctions_mapping(measure_i).map_to(map_i)))~=1
                        fprintf('WARN: no damagefunction defined for DamageFunID %i\n',...
                            measures.damagefunctions_mapping(measure_i).map_to(map_i))
                    end
                end
            end % map_i
            if ~isempty(intersect(measures.damagefunctions_mapping(measure_i).map_from,measures.damagefunctions_mapping(measure_i).map_to))
                fprintf('WARN: circular mapping for measure %i (%s)\n',measure_i,measures.name{measure_i})
            end
        else
            measures.damagefunctions_mapping(measure_i).map_from=[]; % empty map
            measures.damagefunctions_mapping(measure_i).map_to=[];
        end % ~nil
    end % measure_i
end

% clean up peril_ID
if isfield(measures,'peril_ID')
    for peril_i=1:length(measures.peril_ID)
        if ~ischar(measures.peril_ID{peril_i})
            measures.peril_ID{peril_i}=''; % from [NaN]
        end
    end % peril_i
end

return