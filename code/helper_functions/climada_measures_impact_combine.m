function measures_impact=climada_measures_impact_combine(measures_impact1,measures_impact2,combine_modus,silent_mode)
% climada measures impact combine
% MODULE:
%   core/helper_functions
% NAME:
%   climada_measures_impact_combine
% PURPOSE:
%   Combine two measure impact structures, i.e. add averted damages. The 
%   codes in essence takes measures_impact=measures_impact1 and then adds 
%   relevant fields (benfit, ED_benefit) from measures_impact2. Hence 
%   please make sure the 'main' peril is in measures_impact1 (e.g. TC in 
%   measures_impact1, TS in measures_impact2). Note that ONLY averted 
%   damages/benefits are added, we do NOT add costs, as most often the cost 
%   of the measures include the total costs. Hence edit the resulting 
%   measures_impact yourself in case costs should be additive.
%
%   call before: climada_adaptation_cost_curve
% CALLING SEQUENCE:
%   measures_impact=climada_measures_impact_combine(measures_impact1,measures_impact2,combine_modus,silent_mode)
% EXAMPLE:
%   measures_impact=climada_measures_impact_combine(measures_impact1,measures_impact2,combine_modus,silent_mode)
% INPUTS:
%   measures_impact1: a climada measures_impact structure (as returned eg 
%       by climada_measures_impact).
%   measures_impact2: a climada measures_impact structure (as returned eg 
%       by climada_measures_impact) if measures_impact2 is an array of 
%       measures_impact2(i), the code will recursively treat them
% OPTIONAL INPUT PARAMETERS:
%   combine_modus: a string, either 'add_measures' or 'delete_measures' to
%   add impacts from measures that only exist in measures_impact1 or
%       measures_impact2, or to delete measures that do not exist in both
%       measures_impacts
% OUTPUTS:
%   measures_impact: the combined measures_impact
%       Please note that assets are likely not meaningful, since just taken
%       from measures_impact1 (in order to allow to store resulting measures_impact back into an
%       array of measures_impacts if needed)
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150617, init based on climada_EDS_combine
% Lea Mueller, muellele@gmail.com, 20151202, combine also EDS, add 'delete_measures' option
% Lea Mueller, muellele@gmail.com, 20151202, add option silent_mode
%-

measures_impact=[]; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('measures_impact1','var'),return;end
if ~exist('measures_impact2','var'),measures_impact2=[];end
if ~exist('combine_modus','var'),combine_modus='';end
if ~exist('silent_mode','var'), silent_mode = ''; end


% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
% set default value for param2 if not given

if isempty(combine_modus),combine_modus ='add_measures';end
if isempty(silent_mode), silent_mode = 0; end 


if isempty(measures_impact2)
    if length(measures_impact1)==1
        measures_impact=measures_impact1;
        return % nothing to do
    else
        % measures_impact1 contains more than one measures_impact, try recursive
        if ~silent_mode, fprintf('more than one measures_impact1\n');end
        measures_impact=climada_measures_impact_combine(measures_impact1(1),measures_impact1(2:end),'',silent_mode);
        return
    end
elseif length(measures_impact2)>1
    % measures_impact2 contains more than one measures_impact, try recursive
    if ~silent_mode,fprintf('more than one measures_impact2\n');end
    measures_impact2=climada_measures_impact_combine(measures_impact2(1),measures_impact2(2:end),'',silent_mode);
end

% by now, measures_impact1 and measures_impact2 should be one measures_impact each
if length(measures_impact1)>1 || length(measures_impact2)>1
    fprintf('Error: more than one measures_impact in measures_impact1/2 not implemented yet\n');
    return
end

% init output
measures_impact = measures_impact1; 

% get names of all measures
measure_name_list = unique({measures_impact.measures.name{:} measures_impact2.measures.name{:}},'stable');

%loop over all measures from measures_impact1
for m_i = 1:numel(measure_name_list) %length(measures_impact1.ED)-1
    
    %find same measure in measures_impact1 and measures_impact2
    is_measure_1 = find(strcmp(measure_name_list{m_i},measures_impact1.measures.name));
    is_measure_2 = find(strcmp(measure_name_list{m_i},measures_impact2.measures.name));
    
    if ~isempty(is_measure_1) && ~isempty(is_measure_2)
        if numel(is_measure_2)==1 && numel(is_measure_1)==1
            
            if ~silent_mode,
                fprintf('Similar measure (%s), combine damage \n\t - %s \n\t - %s \n',measure_name_list{m_i},measures_impact1.peril_ID,measures_impact2.peril_ID)
            end
            
            % add EDS damage from different perils
            measures_impact.EDS(is_measure_1).ED_at_centroid = measures_impact1.EDS(is_measure_1).ED_at_centroid + ...
                                                               measures_impact2.EDS(is_measure_2).ED_at_centroid; 
            measures_impact.EDS(is_measure_1).ED             = measures_impact1.EDS(is_measure_1).ED + ...
                                                               measures_impact2.EDS(is_measure_2).ED;    
            measures_impact.EDS(is_measure_1).peril_ID       = ['Combined ' measures_impact1.EDS(is_measure_1).peril_ID ', ' ...
                                                                measures_impact2.EDS(is_measure_2).peril_ID];                                               
            % do not add EDS.Value

            % add expected damage from different perils
            measures_impact.ED(is_measure_1)               = measures_impact1.ED(is_measure_1)               + measures_impact2.ED(is_measure_2);
            % add benefits, risk_transfer, ED_cb_ratio
            if ~silent_mode,
                fprintf('Measure %s\n',measure_name_list{m_i})
                fprintf('MI1: %s, %s\n',measures_impact1.scenario.name, measures_impact1.peril_ID)
                fprintf('MI2: %s, %s\n',measures_impact2.scenario.name, measures_impact2.peril_ID)
            end
            measures_impact.ED_benefit(is_measure_1)       = measures_impact1.ED_benefit(is_measure_1)       + measures_impact2.ED_benefit(is_measure_2);
            measures_impact.ED_risk_transfer(is_measure_1) = measures_impact1.ED_risk_transfer(is_measure_1) + measures_impact2.ED_risk_transfer(is_measure_2);
            measures_impact.benefit(is_measure_1)          = measures_impact1.benefit(is_measure_1)          + measures_impact2.benefit(is_measure_2);
            measures_impact.risk_transfer(is_measure_1)    = measures_impact1.risk_transfer(is_measure_1)    + measures_impact2.risk_transfer(is_measure_2);

            % do NOT add costs, as most often the cost of a measure is already the total cost
            % measures_impact.measures.cost(m_i)  = measures_impact1.measures.cost(m_i)    + measures_impact2.measures.cost(indx) ; 

            %recalculate CB_ratio
            %costs are costs as in measures table plus expected damage (for risk transfer only)
            measures_impact.cb_ratio(is_measure_1)    = ( measures_impact1.measures.cost(is_measure_1) +measures_impact1.risk_transfer(is_measure_1)...
                                                         +measures_impact2.measures.cost(is_measure_2)+measures_impact2.risk_transfer(is_measure_2))...
                                                         /measures_impact.benefit(is_measure_1);
            measures_impact.ED_cb_ratio(is_measure_1) = ( measures_impact1.measures.cost(is_measure_1) +measures_impact1.risk_transfer(is_measure_1)...
                                                         +measures_impact2.measures.cost(is_measure_2)+measures_impact2.risk_transfer(is_measure_2))...
                                                         /measures_impact.benefit(is_measure_1);   
        end
                                                 
    else
        if strcmp(combine_modus,'add_measures')
            % measure exists in measures_impact2, but not in measures_impact1,
            % ADD this measure to the combined measures_impact
            if isempty(is_measure_1) && numel(is_measure_2)==1
                measures_impact.EDS(end+1) = measures_impact.EDS(end); % append a copy of 'control'
                measures_impact.EDS(end-1) = measures_impact2.EDS(is_measure_2); %overwrite second last with new measure

                measures_impact.ED(end+1) = measures_impact.ED(end); % append a copy of 'control'
                measures_impact.ED(end-1) = measures_impact2.ED(is_measure_2); %overwrite second last with new measure

                measures_impact.ED_benefit(end+1) = measures_impact2.ED_benefit(is_measure_2);
                measures_impact.ED_risk_transfer(end+1) = measures_impact2.ED_risk_transfer(is_measure_2);
                measures_impact.benefit(end+1) = measures_impact2.benefit(is_measure_2);
                measures_impact.risk_transfer(end+1) = measures_impact2.risk_transfer(is_measure_2);
                measures_impact.cb_ratio(end+1) = measures_impact2.cb_ratio(is_measure_2);
                measures_impact.ED_cb_ratio(end+1) = measures_impact2.ED_cb_ratio(is_measure_2); 
            end
        end %add_measures                                          
    end
end

% at the end, delete unwated measures
if strcmp(combine_modus,'delete_measures')
    %loop over all measures from measures_impact1
    for m_i = 1:numel(measure_name_list) 
        %find same measure in measures_impact1 and measures_impact2
        is_measure_1 = find(strcmp(measure_name_list{m_i},measures_impact1.measures.name));
        is_measure_2 = find(strcmp(measure_name_list{m_i},measures_impact2.measures.name), 1);
        
        % measure exists in measures_impact2, but not in measures_impact1,
        % DELETE this measure from the combined measures_impact
        if isempty(is_measure_1) || isempty(is_measure_2)
            if ~silent_mode, fprintf('Delete measure %s\n',measure_name_list{m_i}), end
            measures_impact.EDS(is_measure_1) = [];
            measures_impact.ED(is_measure_1) = [];
            measures_impact.ED_benefit(is_measure_1) = [];
            measures_impact.ED_risk_transfer(is_measure_1) = [];
            measures_impact.benefit(is_measure_1) = [];
            measures_impact.risk_transfer(is_measure_1) = [];
            measures_impact.cb_ratio(is_measure_1) = [];
            measures_impact.ED_cb_ratio(is_measure_1) = [];
        end
    end
end %delete_measures
        
% add expected damage from different perils, without measures
measures_impact.EDS(end).ED_at_centroid  = measures_impact1.EDS(end).ED_at_centroid + measures_impact2.EDS(end).ED_at_centroid;
measures_impact.EDS(end).ED              = sum(measures_impact.EDS(end).ED_at_centroid);
measures_impact.EDS(end).peril_ID        = ['Combined ' measures_impact1.EDS(end).peril_ID ', ' measures_impact2.EDS(end).peril_ID];    

% add expected damage from different perils, without measures
measures_impact.ED(end)  = measures_impact1.ED(end) + measures_impact2.ED(end);
% add total climate risk
measures_impact.NPV_total_climate_risk = measures_impact1.NPV_total_climate_risk + measures_impact2.NPV_total_climate_risk;

% append all perils
measures_impact.peril_ID = ['Combined ' measures_impact1.peril_ID ', ' strrep(measures_impact2.peril_ID,'Combined ','')];
% measures_impact.peril_ID = {measures_impact1.peril_ID measures_impact2.peril_ID};

% add up risk premiums
measures_impact.risk_premium_fgu = measures_impact1.risk_premium_fgu + measures_impact2.risk_premium_fgu;
measures_impact.risk_premium_net = measures_impact1.risk_premium_net + measures_impact2.risk_premium_net;


end % climada_measures_impact_combine
