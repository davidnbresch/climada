function hazard_info=climada_hazards(entity,peril_ID,check_plots)
% climada template
% MODULE:
%   core
% NAME:
%   climada_hazards
% PURPOSE:
%   generate the standard probabilistic hazard event sets for a given
%   entity (tiehr one country or any combination or...). If the hazard
%   set(s) already exist, they are NOT regenerated.
%
%   just a caller for centroids_generate_hazard_sets
%
%   Note: to speed up hazard set generation, you might set climada_global.patfor=1
%
%   previous call (usually): entity=climada_entity_country
%   next call: EDS=climada_EDS_calc(entity,hazard)
% CALLING SEQUENCE:
%   res=climada_template(param1,param2);
% EXAMPLE:
%   climada_template(param1,param2);
% INPUTS:
%   entity: an entity, see climada_entity_country or
%       climada_entity_read or climada_entity_load. Only assets.lat/lon
%       and (if present) distance2coast_km are used.
%       > prompted for if empty
% OPTIONAL INPUT PARAMETERS:
%   peril_ID: if not empty, generate hazard set only for specified peril
%       peril_ID can be 'TC','TS','TR','EQ','VQ','WS'..., default='' for all
%   check_plots: if =1, show figures to check hazards etc.
%       If =0, skip figures (default)
% OUTPUTS:
%   stores the hazard sets in climada_global.hazards_dir
%   centroids_hazard_info: a structure with hazard information, with fields
%       res.hazard(hazard_i) with
%           peril_ID: 'TC' or ...
%           hazard_set_file: the full filename of the hazard set generated
%           data_file: for TC only: the file sused to generste the event set
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20170624
%-

hazard_info=[]; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('peril_ID','var'),peril_ID='';end
if ~exist('check_plots','var'),check_plots=0;end

if length(which('centroids_generate_hazard_sets'))<2
    fprintf(['Country risk module not found. Please download ' ...
        '<a href="https://github.com/davidnbresch/climada_module_country_risk">'...
        'climada_module_country_risk</a> from Github.\n'])
else
    hazard_info=centroids_generate_hazard_sets(entity,1,0,check_plots,peril_ID);
end

end % climada_hazards