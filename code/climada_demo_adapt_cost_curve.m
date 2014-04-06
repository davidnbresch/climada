function [impact_present, impact_future, insurance_benefit, insurance_cost] = climada_demo_adapt_cost_curve(climada_demo_params,omit_plot, scaled_AED, nice_numbers)
% climada
% NAME:
%   climada_demo_adapt_cost_curve
% PURPOSE:
%   update the demo entity etc. to reflect parameter changes
%   (first time, it reads the demo entity from the Excel file demo_present.xls)
%   run the calculations and call climada_adaptation_cost_curve for the
%   visualization (all in one, hence easy to call from the GUI)
%   
%   see also: climada_demo_gui, normally called therefrom
% CALLING SEQUENCE:
%   [impact_present,impact_future]=climada_demo_adapt_cost_curve(climada_demo_params,omit_plot);
% EXAMPLE:
%   climada_demo_params.growth=0.02;climada_demo_params.scenario=1;climada_demo_params.measures.beachnourish=1;
%   climada_demo_params.measures.mangroves=1;climada_demo_params.measures.seawall=1;
%   climada_demo_params.measures.quality=1;climada_demo_params.measures.insurance_deductible=0;
%   [impact_present,impact_future]=climada_demo_adapt_cost_curve(climada_demo_params);
% INPUTS:
%   climada_demo_params: a structure with the climada parameters the demo GUI allows to edit:
%       growth: the percentage, decimal (0.02 means 2% CAGR until 2030)
%       scenario: 0, 1 or 2 for no, moderate and high climate change
%       discount_rate: the discount rate used to discount damages
%       measures, a sub-structure with
%          beachnourish: the level of investment 0..1
%          mangroves: 0..1
%          seawall: 0..1, costs non-linear (power 4)
%          quality: 0..1, costs non-linear (power 4)
%          insurance_deductible: 0..1, costs dealt with also in EDS
%      > ususally set in GUI, hard-coded for testing (if nothing handed over or empty)
% OPTIONAL INPUT PARAMETERS:
%   omit_plot: if =1, omit plotting (faster), degfault=0 (do plot)
% OUTPUTS:
%   impact_present: impact structure, see climada_measures_impact
%   impact_future: impact structure, see climada_measures_impact
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20110623, Ashdown Park
% David N. Bresch, david.bresch@gmail.com, 20130328, vuln_MDD_impact -> MDD_impact...
%-

impact_present = []; % init
impact_future  = []; % init

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('climada_demo_params', 'var'), climada_demo_params = []; end
if ~exist('omit_plot'          , 'var'), omit_plot           = 0 ; end
if ~exist('scaled_AED'         , 'var'), scaled_AED          = 1 ; end
if ~exist('nice_numbers'       , 'var'), nice_numbers        = 1 ; end

% PARAMETERS
%
% filename and path to the entity used for the demo GUI:
climada_demo_entity_excel_file = [climada_global.data_dir filesep 'entities' filesep 'demo_today.xls'];
climada_demo_entity_save_file  = [climada_global.data_dir filesep 'entities' filesep 'demo_today.mat'];
%
% the hazard sets to be used:
hazard_present         = [climada_global.data_dir filesep 'hazards' filesep 'TCNA_today_small.mat'];
hazard_moderate_change = [climada_global.data_dir filesep 'hazards' filesep 'TCNA_2030med_small.mat'];
hazard_high_change     = [climada_global.data_dir filesep 'hazards' filesep 'TCNA_2030high_small.mat'];

if isempty(climada_demo_params) % set for simple TEST
   climada_demo_params.growth                        = 0.02;
   climada_demo_params.scenario                      = 1;
   climada_demo_params.discount_rate                 = 0.02;
   climada_demo_params.measures.mangroves            = 1;
   climada_demo_params.measures.beachnourish         = 1;
   climada_demo_params.measures.seawall              = 1;
   climada_demo_params.measures.quality              = 1;
   %climada_demo_params.measures.insurance_deductible = 0;
end

% load the entity we use for this:
if ~exist(climada_demo_entity_save_file,'file')
   % first time, load from Excel
   entity_present = climada_entity_read(climada_demo_entity_excel_file,hazard_present);
   %%climada_entity_save(entity_present,climada_demo_entity_save_file); % for future fast access, new done already in climada_entity_read
else
   load(climada_demo_entity_save_file) % contains entity_present
   entity_present = entity; entity = []; % to free up memory
end

% update entity (we start from entity_today, kind of the 'template')
% -------------

% update discount rate
if isfield(climada_demo_params,'discount_rate')
   entity_present.discount.discount_rate = entity_present.discount.discount_rate*0 + climada_demo_params.discount_rate;
end

entity_future = entity_present;
% update growth
delta_years   = climada_global.future_reference_year - climada_global.present_reference_year;
growth_factor = (1+climada_demo_params.growth)^delta_years;
entity_future.assets.Value = entity_present.assets.Value.*growth_factor;

%fprintf('CAGR of %2.1f%% leads to cumulated growth of %3.0f%% until %i\n',...
%   climada_demo_params.growth*100,...
%   growth_factor*100, climada_global.future_reference_year);


% mangroves (we only adjust what's relevant for this measure!)
measures_i = 1; % hard-wired, see Excel sheet
%fprintf('measure %s set to %d%%\n', char(entity_future.measures.name(measures_i)),...
%   climada_demo_params.measures.mangroves*100);
entity_future.measures.cost(measures_i)                     = entity_present.measures.cost(measures_i)*...
                                                              climada_demo_params.measures.mangroves; % costs linear
entity_future.measures.hazard_intensity_impact(measures_i)  = entity_present.measures.hazard_intensity_impact(measures_i)*...
                                                              climada_demo_params.measures.mangroves;
entity_present.measures.cost(measures_i)                    = entity_future.measures.cost(measures_i);
entity_present.measures.hazard_intensity_impact(measures_i) = entity_future.measures.hazard_intensity_impact(measures_i);


% beachnourish (we only adjust what's relevant for this measure!)
measures_i = 2; % hard-wired, see Excel sheet
%fprintf('measure %s set to %d%%\n', char(entity_future.measures.name(measures_i)),...
%   climada_demo_params.measures.beachnourish*100);
entity_future.measures.cost(measures_i)                     = entity_present.measures.cost(measures_i)*...
                                                              climada_demo_params.measures.beachnourish; % costs linear
entity_future.measures.hazard_intensity_impact(measures_i)  = entity_present.measures.hazard_intensity_impact(measures_i)*...
                                                              climada_demo_params.measures.beachnourish;
entity_present.measures.cost(measures_i)                    = entity_future.measures.cost(measures_i);
entity_present.measures.hazard_intensity_impact(measures_i) = entity_future.measures.hazard_intensity_impact(measures_i);


% seawall (we only adjust what's relevant for this measure!)
measures_i = 3; % hard-wired, see Excel sheet
%fprintf('measure %s set to %d%%\n', char(entity_future.measures.name(measures_i)),...
%   climada_demo_params.measures.seawall*100);
entity_future.measures.cost(measures_i)                         = entity_present.measures.cost(measures_i)*...
                                                                  (climada_demo_params.measures.seawall); % costs non-linear
rp = 1/entity_present.measures.hazard_high_frequency_cutoff(measures_i); % linear in return period
% linear in return period (well... let's try)
entity_future.measures.hazard_high_frequency_cutoff(measures_i) = 1/(rp*climada_demo_params.measures.seawall); 
if climada_demo_params.measures.seawall==0
    entity_future.measures.hazard_high_frequency_cutoff(measures_i) = 1;
end
entity_present.measures.cost(measures_i)                         = entity_future.measures.cost(measures_i);
entity_present.measures.hazard_high_frequency_cutoff(measures_i) = entity_future.measures.hazard_high_frequency_cutoff(measures_i);


% quality (we only adjust what's relevant for this measure!)
measures_i = 4; % hard-wired, see Excel sheet
%fprintf('measure %s set to %d%%\n', char(entity_future.measures.name(measures_i)),...
%   climada_demo_params.measures.quality*100);
entity_future.measures.cost(measures_i) = entity_present.measures.cost(measures_i)*...
                                          (climada_demo_params.measures.quality); % costs non-linear
max_delta = 1 - entity_present.measures.MDD_impact_a(measures_i);
entity_future.measures.MDD_impact_a(measures_i)  = 1-max_delta*(climada_demo_params.measures.quality^2); % linear in MDD
%entity_future.measures.MDD_impact_b(measures_i)=entity_present.measures.MDD_impact_b(measures_i)*...
%    climada_demo_params.measures.quality; % linear in MDD
entity_present.measures.cost(measures_i)              = entity_future.measures.cost(measures_i);
entity_present.measures.MDD_impact_a(measures_i) = entity_future.measures.MDD_impact_a(measures_i);
%entity_present.measures.MDD_impact_b(measures_i)=entity_future.measures.MDD_impact_b(measures_i);


% % insurance_deductible (we only adjust what's relevant for this measure!)
% measures_i = 5; % hard-wired, see Excel sheet
% fprintf('measure %s set to %d%%\n', char(entity_future.measures.name(measures_i)),...
%    climada_demo_params.measures.insurance_deductible*100);
% % tuned such that 100% attachement just leads to about no event hitting...
% exposed_fraction_sum_insured = 0.4;
% sum_insured=sum(entity_future.assets.Value);
% entity_future.measures.risk_transfer_attachement(measures_i)=...
%    exposed_fraction_sum_insured*sum_insured*climada_demo_params.measures.insurance_deductible; % linear deductible
% entity_future.measures.risk_transfer_cover(measures_i)=sum_insured; % on the safe side
% % a simple model for the costs
% insurance_loading_cost=(1-climada_demo_params.measures.insurance_deductible)*0.05*exposed_fraction_sum_insured*sum_insured; % capital costs
% entity_future.measures.cost(measures_i)=insurance_loading_cost; % expected damage calculated
% %entity_future.measures.cost(measures_i)=entity_present.measures.cost(measures_i)*(1-climada_demo_params.measures.insurance_deductible);
% entity_present.measures.risk_transfer_attachement(measures_i)=entity_future.measures.risk_transfer_attachement(measures_i);
% entity_present.measures.risk_transfer_cover(measures_i)=entity_future.measures.risk_transfer_cover(measures_i);
% entity_present.measures.cost(measures_i)=entity_future.measures.cost(measures_i);

% same measures also for present
%%entity_present.measures=entity_future.measures;

% trigger the re-calculation:
% ---------------------------

impact_present = climada_measures_impact(entity_present,hazard_present,'no');

if climada_demo_params.scenario==0
   hazard_future = hazard_present;
elseif climada_demo_params.scenario==1
   hazard_future = hazard_moderate_change;
elseif climada_demo_params.scenario==2
   hazard_future = hazard_high_change;
end % climada_demo_params.scenario

impact_future = climada_measures_impact(entity_future,hazard_future,impact_present);
%impact_future=climada_measures_impact(entity_future,hazard_future,'no'); %the fast way, no real discounting

if ~omit_plot
   % plot the adaptation cost curve
   % ------------------------------
   [insurance_benefit, insurance_cost] = climada_adaptation_cost_curve(impact_future,[],[],[], scaled_AED, nice_numbers);
else
    insurance_benefit = [];
    insurance_cost    = [];
end

return