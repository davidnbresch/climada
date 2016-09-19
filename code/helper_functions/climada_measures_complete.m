function measures = climada_measures_complete(measures)
% climada measures read import check complete
% NAME:
%   climada_measures_complete
% PURPOSE:
%   check for completeness of an measures structure, i.e. that all
%   fields are there and populated with default values (this speeds up all
%   later cimada calls, as we do not need to run many isfield commands
%   etc). This code also makes sure all arrays in measures are 1xN (they come
%   as Nx1 from Excel read). Run climada_measures_encode afterwards to
%   convert some of the human-readable fields (such as damagefunction
%   mappting '1to3').  
%
%   special: the field damagefunctions is NOT mandatory, one of the few
%   fields we check for in climada_measures_impact.
%
%   This code is kept as a separate function (i.e. called from but not part of
%   climada_measures_read) in order to allow calling it for measures not read
%   from an Excel file, e.g. if a user constructs the entity structure
%   him/herself.
%
%   called from: climada_measures_read
%   next call: climada_measures_encode (recommended)
% CALLING SEQUENCE:
%   measures = climada_measures_complete(measures)
% EXAMPLE:
%   entity.measures=climada_measures_complete(entity.measures)
% INPUTS:
%   measures: the measures structure of entity.measures, 
%       see climada_entity_read
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%    measures: same as input, with fields completed
% MODIFICATION HISTORY:
% david.bresch@gmail.com, 20160918, initial
%-

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('measures','var'),measures=[];end
if isempty(measures),return;end

% PARAMETERS
%

% check for minimal field requiremenets
if ~isfield(measures,'cost'),fprintf('Severe warning: cost missing, invalid measures structure\n');end
if ~isfield(measures,'MDD_impact_a'),fprintf('Severe warning: MDD_impact_a missing, invalid measures structure\n');end
if ~isfield(measures,'MDD_impact_b'),fprintf('Severe warning: MDD_impact_b missing, invalid measures structure\n');end
           
if isfield(measures,'MDD_impact_a'),measures.MDD_impact_a = clmeco_LOCAL_TRANSPOSE(measures.MDD_impact_a);end
if isfield(measures,'MDD_impact_b'),measures.MDD_impact_b = clmeco_LOCAL_TRANSPOSE(measures.MDD_impact_b);end

% add missing fields
if ~isfield(measures,'filename'),  measures.filename = 'undefined';end
if ~isfield(measures,'hazard_intensity_impact_a'),measures.hazard_intensity_impact_a = measures.MDD_impact_a*0+1;end
if ~isfield(measures,'hazard_intensity_impact_b'),measures.hazard_intensity_impact_b = measures.MDD_impact_b*0;end
if ~isfield(measures,'PAA_impact_a'),             measures.PAA_impact_a =              measures.MDD_impact_a*0+1;end
if ~isfield(measures,'PAA_impact_b'),             measures.PAA_impact_b =              measures.MDD_impact_b*0;end
if ~isfield(measures,'hazard_high_frequency_cutoff'),measures.hazard_high_frequency_cutoff = measures.MDD_impact_a*0;end
if ~isfield(measures,'Region_ID'),                measures.Region_ID =                 measures.MDD_impact_a*0;end
if ~isfield(measures,'risk_transfer_attachement'),measures.risk_transfer_attachement = measures.MDD_impact_a*0;end
if ~isfield(measures,'risk_transfer_cover'),      measures.risk_transfer_cover =       measures.MDD_impact_a*0;end
if ~isfield(measures,'color_RGB'),                measures.color_RGB = repmat(.5,size(measures.MDD_impact_a,1),3);end
if ~isfield(measures,'hazard_event_set'),   measures.hazard_event_set    = repmat({'nil'},size(measures.MDD_impact_a,1));end
if ~isfield(measures,'damagefunctions_map'),measures.damagefunctions_map = repmat({'nil'},size(measures.MDD_impact_a,1));end
if ~isfield(measures,'assets_file'),        measures.assets_file = repmat({'nil'},size(measures.MDD_impact_a,1));end
if ~isfield(measures,'peril_ID'),           measures.assets_file = repmat({'XX'},size(measures.MDD_impact_a,1));end
if ~isfield(measures,'name'),               measures.name = repmat({'undef'},size(measures.MDD_impact_a,1));end
if ~isfield(measures,'color'),              measures.color = repmat({'.5 .5 .5'},size(measures.MDD_impact_a,1));end                     
                  
% make sure we have Nx1 arrays
if isfield(measures,'hazard_intensity_impact_a'),measures.hazard_intensity_impact_a = clmeco_LOCAL_TRANSPOSE(measures.hazard_intensity_impact_a);end
if isfield(measures,'hazard_intensity_impact_b'),measures.hazard_intensity_impact_b = clmeco_LOCAL_TRANSPOSE(measures.hazard_intensity_impact_b);end
if isfield(measures,'PAA_impact_a'),measures.PAA_impact_a = clmeco_LOCAL_TRANSPOSE(measures.PAA_impact_a);end
if isfield(measures,'PAA_impact_b'),measures.PAA_impact_b = clmeco_LOCAL_TRANSPOSE(measures.PAA_impact_b);end
if isfield(measures,'hazard_high_frequency_cutoff'),measures.hazard_high_frequency_cutoff = clmeco_LOCAL_TRANSPOSE(measures.hazard_high_frequency_cutoff);end
if isfield(measures,'Region_ID'),measures.Region_ID = clmeco_LOCAL_TRANSPOSE(measures.Region_ID);end
if isfield(measures,'risk_transfer_attachement'),measures.risk_transfer_attachement = clmeco_LOCAL_TRANSPOSE(measures.risk_transfer_attachement);end
if isfield(measures,'risk_transfer_cover'),measures.risk_transfer_cover = clmeco_LOCAL_TRANSPOSE(measures.risk_transfer_cover);end
if isfield(measures,'risk_transfer_cover'),measures.risk_transfer_cover = clmeco_LOCAL_TRANSPOSE(measures.risk_transfer_cover);end
if isfield(measures,'hazard_event_set'),measures.hazard_event_set = clmeco_LOCAL_TRANSPOSE(measures.hazard_event_set);end
if isfield(measures,'damagefunctions_map'),measures.damagefunctions_map = clmeco_LOCAL_TRANSPOSE(measures.damagefunctions_map);end
if isfield(measures,'assets_file'),measures.assets_file = clmeco_LOCAL_TRANSPOSE(measures.assets_file);end
if isfield(measures,'peril_ID'),measures.peril_ID = clmeco_LOCAL_TRANSPOSE(measures.peril_ID);end
if isfield(measures,'name'),measures.name = clmeco_LOCAL_TRANSPOSE(measures.name);end
if isfield(measures,'color'),measures.color = clmeco_LOCAL_TRANSPOSE(measures.color);end
         
end % climada_measures_complete

function arr=clmeco_LOCAL_TRANSPOSE(arr)
if size(arr,1)<size(arr,2),arr=arr';end
end % clmeco_LOCAL_TRANSPOSE