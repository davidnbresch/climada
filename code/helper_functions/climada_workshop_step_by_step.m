% climada template
% MODULE:
%   core
% NAME:
%   climada_workshop_step_by_step
% PURPOSE:
%   batch file to TEST the climada exercise, first, it calls 
%   climada_demo_step_by_step then runs all commands as in
%   climada_workshop_step_by_step.docx (.pdf) 
%
%   See also climada_demo_step_by_step
%
% CALLING SEQUENCE:
%   climada_workshop_step_by_step
% EXAMPLE:
%   climada_workshop_step_by_step
% INPUTS:
%   none, a batch file
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20160829, initial
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

climada_demo_step_by_step;
entity.assets.Value=entity.assets.Value*1.2;
figure;climada_EDS_DFC(climada_EDS_calc(entity,hazard));

entity.assets.Value=entity.assets.Value/1.2; % reset
entity.damagefunctions.MDD=entity.damagefunctions.MDD*0.8;
figure;climada_EDS_DFC(climada_EDS_calc(entity,hazard));

entity.damagefunctions.MDD=entity.damagefunctions.MDD/0.9; % reset
entity.measures.name % aha, we see that measure 4 is the building code
entity.measures.cost(4)=entity.measures.cost(4)/2; % half the cost
figure;
climada_adaptation_cost_curve(climada_measures_impact(entity,hazard,'no'));

entity.measures.cost(4)=entity.measures.cost(4)*2; % reset
entity.measures.MDD_impact_a(4)=.85; % reduce damage by 15% (instead of 25%)
figure;
climada_adaptation_cost_curve(climada_measures_impact(entity,hazard,'no'));

load([pwd filesep 'data' filesep 'entities' filesep 'demo_today.mat']);
load([pwd filesep 'data' filesep 'hazards' filesep 'TCNA_today_small.mat']);

EDS=climada_EDS_calc(entity,hazard);
figure; climada_EDS_DFC(EDS);

f_screw=1.1;i_screw=1.03;
hazard_CC=climada_tc_hazard_clim_scen(hazard,'no',f_screw,i_screw);
EDS_CC=climada_EDS_calc(entity,hazard_CC);
EDS_CC.annotation_name='TCNA CC small';
figure; climada_EDS_DFC(EDS,EDS_CC);

entity_future=entity; % make a copy
entity_future.assets.Value=entity_future.assets.Value*1.51; % inflate
entity_future.assets.Cover=entity_future.assets.Value; % technical step

save([pwd filesep 'data' filesep 'entities' filesep 'demo_future'],'entity_future');

EDS_future=climada_EDS_calc(entity_future,hazard);
EDS_future_CC=climada_EDS_calc(entity_future,hazard_CC);

climada_waterfall_graph(EDS,EDS_future,EDS_future_CC,9999); %

impact_today=climada_measures_impact(entity,hazard,'no');
impact_future=climada_measures_impact(entity_future,hazard_CC,impact_today);

climada_adaptation_cost_curve(impact_future);

if climada_global.octave_mode
    figure;climada_adaptation_cost_curve(impact_future);
    figure;climada_adaptation_cost_curve(impact_today); % to compare
else
    figure;climada_adaptation_cost_curve(impact_future,impact_today);
end % climada_global.octave_mode
