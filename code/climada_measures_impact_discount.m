function measures_impact = climada_measures_impact_discount(entity,measures_impact,measures_impact_reference,unit_or_cat_flag,criterium)
% climada
% NAME:
%   climada_measures_impact_discount
% PURPOSE:
%   calculate the benefit-cost ratio based on discounted benefits and costs
%   for series of measures on a given set measures_impact.EDS
%   called from climada_measures_impact
%   can also be called separately in order to calculate benefit-cost ratio
%   only for a selection of assets (e.g. only for USD, or category 7)
%   previous step: climada_measures_impact
% CALLING SEQUENCE:
%   measures_impact = climada_measures_impact_discount(entity,measures_impact,measures_impact_reference,unit_or_cat_flag,criterium)
% EXAMPLE:
%   measures_impact = climada_measures_impact_discount(entity,measures_impact,'no')
%   measures_impact = climada_measures_impact_discount(entity,measures_impact,'no','unit','USD')
%   measures_impact = climada_measures_impact_discount(entity,measures_impact,'no','category',2)
% INPUTS:
%   entity: a read and encoded assets and damagefunctions file, see climada_assets_encode(climada_assets_read)
%       > promted for if not given
%   measures_impact: measures impact structure (e.g. portfolio future and measures future)
%       with only the following fields .EDS, .measures and .risk_transfer
% OPTIONAL INPUT PARAMETERS:
%   measures_impact_reference: reference measures (e.g. portfolio today and
%       measures today). Used to properly calculate the net present values
%       of future impacts
%       set to 'no' if you would not like to be asked for a reference
%   unit_or_cat_flag: a string, either 'unit' or 'category'
%   criterium: a string or an array to define the unit or category for the 
%       subselection of asset values, e.g. 'USD', 'people', 2
% OUTPUTS:
%   measures_impact: a structure with
%       ED(measure_i): the annual expected damage to the assets under measure_i,
%           last one ED(end) for no measures
%       benefit(measure_i): the benefit of measure_i
%       cb_ratio(measure_i): the cost/benefit ratio of measure_i
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150902, separate function to be called in climada_measures_impact
% Lea Mueller, muellele@gmail.com, 20150924, set to silent mode in climada_assets_select
% Lea Mueller, muellele@gmail.com, 20150925, correct discounting if reference scenario is provided
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('measures_impact','var'),measures_impact=[];end
if ~exist('measures_impact_reference','var'),measures_impact_reference=[];end
if ~exist('unit_or_cat_flag','var'),unit_or_cat_flag = '';end
if ~exist('criterium','var'),criterium = 0;end


% PARAMETERS

% prompt for entity if not given
if isempty(entity) % local GUI
    entity=[climada_global.data_dir filesep 'entities' filesep '*.mat'];
    [filename, pathname] = uigetfile(entity, 'Select encoded entity:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity=fullfile(pathname,filename);
    end
end
% load the entity, if a filename has been passed
if ~isstruct(entity)
    entity_file=entity;entity=[];
    vars = whos('-file', entity_file);
    load(entity_file);
    if ~strcmp(vars.name,'entity')
        entity = eval(vars.name);
        clear (vars.name)
    end
end

% prompt for measures_impact if not given
if isempty(measures_impact) % local GUI
    measures_impact=[climada_global.data_dir filesep 'results' filesep '*.mat'];
    [filename, pathname] = uigetfile(entity, 'Select measures_impact:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        measures_impact=fullfile(pathname,filename);
    end
end
% load the measures_impact, if a filename has been passed
if ~isstruct(measures_impact)
    measures_impact_file=measures_impact;measures_impact=[];
    vars = whos('-file', measures_impact_file);
    load(measures_impact_file);
    if ~strcmp(vars.name,'measures_impact')
        measures_impact = eval(vars.name);
        clear (vars.name)
    end
end

if ~isempty(measures_impact_reference)
    % load if a filename has been passed
    if ~isstruct(measures_impact_reference)
        if strcmp(measures_impact_reference,'no')
            measures_impact_reference = '';
        else
            measures_impact_reference_file = measures_impact_reference; measures_impact_reference = [];
            vars = whos('-file', measures_impact_reference_file);
            load(measures_impact_reference_file);
            if ~strcmp(vars.name,'measures_impact_reference')
                measures_impact_reference = eval(vars.name);
                clear (vars.name)
            end
        end
    end
    if ~isempty(measures_impact_reference) & ~strcmp(measures_impact_reference,'no')
        % reference is aleays today, warn if not
        reference_year = measures_impact_reference.EDS(end).reference_year;
        if reference_year ~= climada_global.present_reference_year
            %fprintf('WARNING: reference year for reference results is %i (should be %i)\n',reference_year,climada_global.present_reference_year);
        end
    end
end


% calculate the cost/benefit ratio also here (so we have all results in one
% -------------------------------------------------------------------------

if ~isfield(measures_impact,'EDS')
    fprintf('No EDS in measures_impact structure. Unable to proceed.\n')
end
EDS = measures_impact.EDS;

% set time horizon, number of years
n_measures = length(measures_impact.EDS)-1;
ED         = zeros(1,n_measures+1); % init
n_years    = climada_global.future_reference_year - climada_global.present_reference_year + 1;

% get the discount rates for years:
present_year_pos = find(entity.discount.year==climada_global.present_reference_year); % present year
future_year_pos  = find(entity.discount.year==climada_global.future_reference_year); % future year
discount_rates   = entity.discount.discount_rate(present_year_pos:future_year_pos);

% recalculate ED, maybe with only a subset of asset values, given by a criterium
is_selected = [];%init
silent_mode = 1;
if ~isempty(unit_or_cat_flag) & isfield(EDS,'ED_at_centroid')
    % select a specific set of assets to recalculate the total ED
    switch unit_or_cat_flag
        case 'unit'
            is_selected = climada_assets_select(entity,measures_impact.peril_ID,criterium,'',silent_mode);
        case 'category'
            is_selected = climada_assets_select(entity,measures_impact.peril_ID,'',criterium,silent_mode);     
        otherwise
            fprintf('WARNING: Selection of assets not found, please check %s.\n', unit_or_cat_flag)
    end
end

EDS = measures_impact.EDS;

% measures_impact_reference
if ~isempty(measures_impact_reference)
    EDS_reference = measures_impact_reference.EDS;
    if ~isempty(unit_or_cat_flag) & ~isfield(EDS_reference,'ED_at_centroid')
        fprintf('ERROR: measures_impact_reference does not have ED_at_centroid information, please check.\n')
    end
    
end

% recalculate ED with the selected subset of asset values
if ~isempty(is_selected)
    for measure_i = 1:n_measures+1
    	ED(measure_i) = full(sum(EDS(measure_i).ED_at_centroid(is_selected))); % calculate annual expected damage
        
        if ~isempty(measures_impact_reference)% calculate annual expected damage
            ED_reference(measure_i) = full(sum(EDS_reference(measure_i).ED_at_centroid(is_selected))); 
        end
    end
else
    for measure_i = 1:n_measures+1
        % first, calculate the ED (exepected damage) perspective
        ED(measure_i) = full(sum(EDS(measure_i).damage .* EDS(measure_i).frequency));
        if ~isempty(measures_impact_reference)% calculate annual expected damage for reference
            ED_reference(measure_i) = full(sum(EDS_reference(measure_i).damage .* EDS_reference(measure_i).frequency));
        end
    end
end
    

% time evolution of benefits etc. (linear if climada_global.impact_time_dependence=1)
time_dependence = (0:n_years-1).^climada_global.impact_time_dependence/(n_years-1)^climada_global.impact_time_dependence;

for measure_i = 1:n_measures
    % store damage frequency curve (DFC), for information only
    DFC(measure_i,:) = climada_EDS_DFC_report(EDS(measure_i),0,'lean');
    
    % second, calculate the NPV (net present value perspective)
    if isempty(measures_impact_reference)
        % no reference, hence we assume a steady-state, means we see the ED for each year from present to future
        benefits       = ones(1,n_years)*(ED(end)-ED(measure_i)); % same benefit each year
        risk_transfers = ones(1,n_years)*measures_impact.risk_transfer(measure_i); % same risk transfer costs each year
    else
        % time evolution of benefits
        present_benefit = ED_reference(end) - ED_reference(measure_i);
        future_benefit  = ED(end)-ED(measure_i);
        benefits        = present_benefit+(future_benefit-present_benefit)*time_dependence;
        % and similarly for risk transfer costs
        present_risk_transfer = measures_impact_reference.risk_transfer(measure_i);
        future_risk_transfer  = measures_impact.risk_transfer(measure_i);
        risk_transfers        = present_risk_transfer+(future_risk_transfer-present_risk_transfer)*time_dependence;
        
        % old, linear only, kept for backward compatibility, same as climada_global.impact_time_dependence=1
        %         d_benefit       = (future_benefit-present_benefit)/(n_years-1);
        %         d_benefits      = [0,ones(1,n_years-1)*d_benefit];
        %         benefits        = present_benefit+cumsum(d_benefits); % linear increase
        %         % and similarly for risk transfer costs
        %         present_risk_transfer = measures_impact_reference.ED_risk_transfer(measure_i);
        %         future_risk_transfer  = ED_risk_transfer(measure_i);
        %         d_risk_transfer       = (future_risk_transfer-present_risk_transfer)/(n_years-1);
        %         d_risk_transfers      = [0,ones(1,n_years-1)*d_risk_transfer];
        %         risk_transfers        = present_risk_transfer+cumsum(d_risk_transfers); 
    end
    
    % discount the benefits
    benefit(measure_i)       = climada_NPV(benefits,discount_rates);
    risk_transfer(measure_i) = climada_NPV(risk_transfers,discount_rates); % discount the risk transfer costs
    % costs are costs as in measures table plus expected damage (for risk transfer only)
    cb_ratio(measure_i)      = (measures_impact.measures.cost(measure_i)+risk_transfer(measure_i))/benefit(measure_i);
    
end % measure_i

% calculate the NPV of the full unaverted damages, too
% TCR stands for total climate risk
if isempty(measures_impact_reference)
    NPV_total_climate_risk = climada_NPV(ones(1,n_years)*ED(end), discount_rates);
else
    % time evolution of risk
    present_TCR = ED_reference(end);
    future_TCR  = ED(end);
    TCRs        = present_TCR+(future_TCR-present_TCR)*time_dependence;
    % old, linear only, kept for backward compatibility, same as climada_global.impact_time_dependence=1
    % d_TCR       = (future_TCR-present_TCR)/(n_years-1);
    % d_TCRs      = [0,ones(1,n_years-1)*d_TCR];
    % TCRs        = present_TCR+cumsum(d_TCRs); % linear increase
    NPV_total_climate_risk = climada_NPV(TCRs, discount_rates);
end

% store in measures
measures_impact.DFC              = DFC; % info only
measures_impact.ED               = ED;
measures_impact.benefit          = benefit;
measures_impact.risk_transfer    = risk_transfer;
measures_impact.cb_ratio         = cb_ratio;
measures_impact.NPV_total_climate_risk = NPV_total_climate_risk;

% probably to be removed
measures_impact.ED_benefit       = benefit;
measures_impact.ED_risk_transfer = risk_transfer;
measures_impact.ED_cb_ratio      = cb_ratio;




return
