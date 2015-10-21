function measures_impact=climada_measures_impact_parametric(measures_impact,index_def)
% climada template
% MODULE:
%   core
% NAME:
%   climada_measures_impact_parametric
% PURPOSE:
%   Add parametric insurance to measures. Define index payout (attachement,
%   cover or exit, tick value) and the centroid_ID at which the hazard is
%   being evaluated.
%
%   previous call: climada_measures_impact
%   next call: climada_adaptation_cost_curve
%
%   TEST settings:
%   climada_demo_step_by_step % run this to get a reasonable measures_impact structure
%   index_def.attachement=40;index_def.cover=30;index_def.tick_value=1.0000e+09;
%   index_def.centroid_index=50;
%   measures_impact=climada_measures_impact_parametric(measures_impact,index_def)
%   climada_adaptation_event_view(measures_impact,[10,150,1500])
% CALLING SEQUENCE:
%   measures_impact=climada_measures_impact_parametric(measures_impact,index_def)
% EXAMPLE:
%   measures_impact=climada_measures_impact_parametric(climada_measures_impact)
% INPUTS:
%   measures_impact: the output from climada_measures_impact
%   index_def: the parametric index definition, with fields (in the
%       metric of the pertinent hazard intensity)
%       attachement: the attachement point
%       cover: the cover (if missing, calculated from exit)
%       exit: the exit (if missing, calculated from cover)
%       tick_value: the payout per unit, default=1 (in the monetary unit)
%       centroid_ID: the centroid ID (in the hazard set) at which the index
%           insurance is evaluated or
%       centroid_index: the index (in the hazard set) at which the index
%           insurance is evaluated. If both centroid_ID and centroid_index
%           are passed, centroid_index is used
%       markup: the multiplier to get to cost, default=2
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20151021, intial
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('measures_impact','var'),measures_impact=[];end
if ~exist('index_def','var'),index_def=[];end

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
% check and set default values for index_def
if ~isfield(index_def,'attachement'),index_def.attachement=0;end
if ~isfield(index_def,'tick_value'),index_def.tick_value=1;end
if ~isfield(index_def,'markup'),index_def.markup=2;end
if ~isfield(index_def,'cover') && isfield(index_def,'exit')
    index_def.cover=index_def.exit-index_def.attachement;
elseif ~isfield(index_def,'exit') && isfield(index_def,'cover')
    index_def.exit=index_def.attachement+index_def.cover;
else
    fprintf('Error: index_def: either exit OR cover need to be defined\n');
    return
end
if ~isfield(index_def,'centroid_ID') && ~isfield(index_def,'centroid_index')
    fprintf('Error: index_def: either centroid_ID OR centroid_index need to be defined\n');
    return
end
if abs(index_def.cover-(index_def.exit-index_def.attachement))>0
    fprintf('Warning: index_def: cover and exit not consistent (using cover)\n');
end

% check, whether last entry IS ALREADY index insurance
if ~strcmp(measures_impact.measures.name{end},'index insurance')
    
    % first, move reference EDS to end+1 to create a space for index measure
    measures_impact.EDS(end+1)=measures_impact.EDS(end);
    % reset damage fields
    measures_impact.EDS(end-1).damage=measures_impact.EDS(end-1).damage*0;
    measures_impact.EDS(end-1).ED_at_centroid=measures_impact.EDS(end-1).ED_at_centroid*0;
    measures_impact.EDS(end-1).ED=0;
    measures_impact.EDS(end-1).comment='index insurance event set';
    
    % add fields
    measures_impact.risk_transfer(end+1)=0;
    measures_impact.DFC(end+1,:)=measures_impact.DFC(end,:)*0;
    measures_impact.ED(end+1)=measures_impact.ED(end); % copy
    measures_impact.benefit(end+1)=0;
    measures_impact.cb_ratio(end+1)=0;
    measures_impact.ED_benefit(end+1)=0;
    measures_impact.ED_risk_transfer(end+1)=0;
    measures_impact.ED_cb_ratio(end+1)=0;
    
    measures_impact.measures.name{end+1}='index insurance';
    measures_impact.measures.color{end+1}='0.8 0.8 0.8';
    measures_impact.measures.cost(end+1)=0;
    measures_impact.measures.hazard_high_frequency_cutoff(end+1)=0;
    measures_impact.measures.hazard_event_set{end+1}='nil';
    measures_impact.measures.MDD_impact_a(end+1)=0;
    measures_impact.measures.MDD_impact_b(end+1)=0;
    measures_impact.measures.PAA_impact_a(end+1)=0;
    measures_impact.measures.PAA_impact_b(end+1)=0;
    measures_impact.measures.damagefunctions_map{end+1}='nil';
    measures_impact.measures.risk_transfer_attachement(end+1)=0;
    measures_impact.measures.risk_transfer_cover(end+1)=0;
    measures_impact.measures.color_RGB(end+1,:)=[0.8 0.8 0.8];
    measures_impact.measures.damagefunctions_mapping(end+1).map_from=[];
    measures_impact.measures.damagefunctions_mapping(end+1).map_to=[];
    measures_impact.measures.hazard_intensity_impact_b(end+1)=0;
else
    fprintf('Note: measures_impact already contains ''index insurance'', just updating...\n');
end % adding fields

% calculate index insurance payout
if exist(measures_impact.EDS(end-1).hazard.filename,'file')
    load(measures_impact.EDS(end-1).hazard.filename)
    
    if ~isfield(index_def,'centroid_index'),index_def.centroid_index=find(hazard.centroid_ID==index_def.centroid_ID);end
        
    hazard_vect=full(hazard.intensity(:,index_def.centroid_index));
    payout=(min(max(hazard_vect-index_def.attachement,0),index_def.cover)*index_def.tick_value)';
    fprintf('adding index insurance payout event set... (min/max %g/%g)\n',min(payout),max(payout));
    measures_impact.EDS(end-1).damage=measures_impact.EDS(end).damage-payout;
    measures_impact.EDS(end-1).ED=measures_impact.EDS(end-1).damage*measures_impact.EDS(end-1).frequency';
    
    % add impact results
    measures_impact.ED(end-1)=measures_impact.EDS(end-1).ED;
    measures_impact.cb_ratio(end)=index_def.markup;
    measures_impact.ED_cb_ratio(end)=measures_impact.cb_ratio(end);
    measures_impact.ED_risk_transfer(end)=0;
    
    % discount benefit
    n_years    = climada_global.future_reference_year - climada_global.present_reference_year + 1;
    benefits = ones(1,n_years)*(measures_impact.ED(end)-measures_impact.ED(end-1)); % same benefit each year
    
    % check whether measures_impact contain discount_rates, add default, if not
    if ~isfield(measures_impact,'discount_rates');measures_impact.discount_rates=benefits*0+0.02;end % HARD WIRED 2%
    
    measures_impact.benefit(end)=climada_NPV(benefits,measures_impact.discount_rates);
    measures_impact.ED_benefit(end)=measures_impact.benefit(end);
    measures_impact.measures.cost(end)=measures_impact.benefit(end)*index_def.markup;
    
    % add DFC
    measures_impact.DFC(end,:)=climada_EDS_DFC_report(measures_impact.EDS(end-1),0,'lean');
    
else
    fprintf('Error: hazard set not found (%s)\n',measures_impact.EDS(end).hazard.filename);
end

end % climada_measures_impact_parametric