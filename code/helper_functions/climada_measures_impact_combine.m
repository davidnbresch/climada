function measures_impact=climada_measures_impact_combine(measures_impact1,measures_impact2)
% climada measures impact combine
% MODULE:
%   core
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
%   measures_impact=climada_measures_impact_combine(measures_impact1,measures_impact2)
% EXAMPLE:
%   measures_impact=climada_measures_impact_combine(measures_impact1,measures_impact2)
% INPUTS:
%   measures_impact1: a climada measures_impact structure (as returned eg 
%       by climada_measures_impact).
%   measures_impact2: a climada measures_impact structure (as returned eg 
%       by climada_measures_impact) if measures_impact2 is an array of 
%       measures_impact2(i), the code will recursively treat them
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   measures_impact: the combined measures_impact
%       Please note that assets are likely not meaningful, since just taken
%       from measures_impact1 (in order to allow to store resulting measures_impact back into an
%       array of measures_impacts if needed)
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150617, init, based on climada_EDS_combine
%-

measures_impact=[]; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('measures_impact1','var'),return;end
if ~exist('measures_impact2','var'),measures_impact2=[];end

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
% set default value for param2 if not given

if isempty(measures_impact2)
    if length(measures_impact1)==1
        measures_impact=measures_impact1;
        return % nothing to do
    else
        % measures_impact1 contains more than one measures_impact, try recursive
        fprintf('more than one measures_impact1\n');
        measures_impact=climada_measures_impact_combine(measures_impact1(1),measures_impact1(2:end));
        return
    end
elseif length(measures_impact2)>1
    % measures_impact2 contains more than one measures_impact, try recursive
    fprintf('more than one measures_impact2\n');
    measures_impact2=climada_measures_impact_combine(measures_impact2(1),measures_impact2(2:end));
end

% by now, measures_impact1 and measures_impact2 should be one measures_impact each
if length(measures_impact1)>1 || length(measures_impact2)>1
    fprintf('Error: more than one measures_impact in measures_impact1/2 not implemented yet\n');
    return
end


measures_impact=measures_impact1; % init output

%loop over all measures from measures_impact1
for m_i = 1:length(measures_impact1.ED)-1
    
    %find same measure in measures_impact2
    indx = find(strcmp(measures_impact1.measures.name(m_i),measures_impact2.measures.name));
    if indx>0 & numel(indx)==1
        % add expectedd damage from different perils
        measures_impact.ED(m_i)               = measures_impact1.ED(m_i)               + measures_impact2.ED(indx);
        % add benefits, risk_transfer, ED_cb_ratio
        measures_impact.ED_benefit(m_i)       = measures_impact1.ED_benefit(m_i)       + measures_impact2.ED_benefit(indx);
        measures_impact.ED_risk_transfer(m_i) = measures_impact1.ED_risk_transfer(m_i) + measures_impact2.ED_risk_transfer(indx);
        measures_impact.benefit(m_i)          = measures_impact1.benefit(m_i)          + measures_impact2.benefit(indx);
        measures_impact.risk_transfer(m_i)    = measures_impact1.risk_transfer(m_i)    + measures_impact2.risk_transfer(indx);

        % do NOT add costs, as most often the cost of a measure is already the total cost
        % measures_impact.measures.cost(m_i)  = measures_impact1.measures.cost(m_i)    + measures_impact2.measures.cost(indx) ; 
    
        %recalculate CB_ratio
        %costs are costs as in measures table plus expected damage (for risk transfer only)
        measures_impact.cb_ratio(m_i)         = ( measures_impact1.measures.cost(m_i) +measures_impact1.risk_transfer(m_i)...
                                                 +measures_impact2.measures.cost(indx)+measures_impact2.risk_transfer(indx))...
                                                /measures_impact.benefit(m_i);
        measures_impact.ED_cb_ratio(m_i)      = ( measures_impact1.measures.cost(m_i) +measures_impact1.risk_transfer(m_i)...
                                                 +measures_impact2.measures.cost(indx)+measures_impact2.risk_transfer(indx))...
                                                /measures_impact.benefit(m_i);                        
    end
end
% add expectedd damage from different perils, without measures
measures_impact.ED(end)  = measures_impact1.ED(end) + measures_impact2.ED(end);
% add total climate risk
measures_impact.NPV_total_climate_risk = measures_impact1.NPV_total_climate_risk + measures_impact2.NPV_total_climate_risk;

% append all perils
measures_impact.peril_ID = ['Combined' measures_impact1.peril_ID ', ' measures_impact2.peril_ID];
% measures_impact.peril_ID = {measures_impact1.peril_ID measures_impact2.peril_ID};

% add up risk premiums
measures_impact.risk_premium_fgu = measures_impact1.risk_premium_fgu + measures_impact2.risk_premium_fgu;
measures_impact.risk_premium_net = measures_impact1.risk_premium_net + measures_impact2.risk_premium_net;


end % climada_measures_impact_combine
