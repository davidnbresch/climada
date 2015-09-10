function fig = climada_adaptation_bar_chart(measures_impact,measures_impact_comparison,sort_measures,cb_text_control)
% climada measures impact climate adaptation bar chart
% NAME:
%   climada_adaptation_bar_chart
% PURPOSE:
%   plot adaptation bar chart (NPV benefits and costs)
%   see also: climada_adaptation_cost_curve
%
% CALLING SEQUENCE:
%   climada_adaptation_bar_chart(measures_impact,measures_impact_comparison,sort_measures)
% EXAMPLE:
%   climada_adaptation_bar_chart(climada_measures_impact(climada_entity_read),'',1) % from scratch
%   climada_adaptation_bar_chart(climada_measures_impact,climada_measures_impact) % one needs to really understand what's going on
% INPUTS:
%   measures_impact: either a struct containing the impacts of measures or a measures_impact file (.mat with a struct)
%       see climada_measures_impact
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   measures_impact_comparison: same as measures_impact, but for comparison
%       (will be shown in overlay). Not prompted for, so please specify in
%       call, or enter 'ASK' in climada_adaptation_cost_curve('','ASK')
%   sort_measures: if set to 1, sort measures according to size of benefit
%   cb_text_control: control position of cb_ratio 
% OUTPUTS:
%   fig: a figure handle
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150908, init
% Lea Mueller, muellele@gmail.com, 20150910, set cost_factor to 20'000
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

called_from_climada_demo=0; % default
if nargout>0,called_from_climada_demo=1;end % called from climada_play_adapt_cost_curve

% poor man's version to check arguments
if ~exist('measures_impact'           , 'var'), measures_impact            = []; end
if ~exist('measures_impact_comparison', 'var'), measures_impact_comparison = ''; end
if ~exist('sort_measures'             , 'var'), sort_measures              = ''; end
if ~exist('cb_text_control'           , 'var'), cb_text_control            = ''; end

% additional parameters that are necessary for the code, maybe useful later
% if we decide to include it in climada_demo
if ~exist('scaled_AED'                , 'var'), scaled_AED                 = 0 ; end
if ~exist('nice_numbers'              , 'var'), nice_numbers               = []; end

called_from_climada_demo = 0;

% PARAMETERS
if isempty(sort_measures), sort_measures=0;end
if isempty(cb_text_control), cb_text_control=1.05;end

% prompt for measures_impact if not given
if isempty(measures_impact) % local GUI
    measures_impact=[climada_global.data_dir filesep 'results' filesep '*.mat'];
    [filename, pathname] = uigetfile(measures_impact, 'Select measures impacts:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        measures_impact=fullfile(pathname,filename);
    end
end
if ~isstruct(measures_impact_comparison)
    if strcmp(measures_impact_comparison,'ASK')
        measures_impact_comparison=[climada_global.data_dir filesep 'results' filesep '*.mat'];
        [filename, pathname] = uigetfile(measures_impact_comparison, 'Select measures impacts for comparison:');
        if isequal(filename,0) || isequal(pathname,0)
            return; % cancel
        else
            measures_impact_comparison=fullfile(pathname,filename);
        end
    end
end
% load the measures set, if a filename has been passed
if ~isstruct(measures_impact)
    measures_impact_file = measures_impact; measures_impact = [];
    load(measures_impact_file);
end

% set the extras for climada_demo
if called_from_climada_demo
    scaled_AED            = 1;
    nice_numbers          = 1;
    add_insurance_measure = 1;
    fontsize_             = 8; % 20140527, on PC, use smaller
    if ismac, fontsize_   = 11;end % 20140516, was 8, too small
else
    add_insurance_measure = 0;
    %fontsize_             = 11;
    fontsize_             = 10;
end

% set Value_unit
if isfield(measures_impact,'Value_unit')
    Value_unit_str = measures_impact.Value_unit;
else
    Value_unit_str = climada_global.Value_unit;
end

if scaled_AED
    scale_factor = measures_impact.ED(end) /measures_impact.NPV_total_climate_risk;
    measures_impact.measures.cost = bsxfun(@times, measures_impact.measures.cost, scale_factor);
    measures_impact.risk_transfer = bsxfun(@times, measures_impact.risk_transfer, scale_factor);
    measures_impact.benefit       = bsxfun(@times, measures_impact.benefit      , scale_factor);
    %total climate risk
    tot_climate_risk  = bsxfun(@times, measures_impact.NPV_total_climate_risk, scale_factor);
else
    %total climate risk
    tot_climate_risk  = measures_impact.NPV_total_climate_risk;
end

% maybe of later use
% if add_insurance_measure % NOTE: this section not relevant for lecture
%     %cover residual damage with insurance
%     insurance_benefit    = tot_climate_risk - sum(measures_impact.benefit);
%     %calculate insurance costs
%     insurance_percentage = insurance_benefit/tot_climate_risk;
%     insurance_cost_vs_percentage = [0.3 1; 1.4 3];
%     if insurance_percentage < min(insurance_cost_vs_percentage(1,:))
%         insurance_cost = min(insurance_cost_vs_percentage(2,:));
%     else
%         insurance_cost = interp1(insurance_cost_vs_percentage(1,:),insurance_cost_vs_percentage(2,:),insurance_percentage);
%     end
%     insurance_cost     = insurance_cost*insurance_benefit;
%     insurance_cb       = insurance_cost/insurance_benefit;
% end

n_years    = climada_global.future_reference_year - climada_global.present_reference_year + 1;

% set format for numbers (for command line output)
if nice_numbers
    % scaled, used if called from climada_play_adapt_cost_curve
    if nice_numbers == 1
        fct        = 10^-8;
        nr_format  = '\t %4.1f';
        xlabel_str = sprintf('NPV averted damage (Mio %s)',Value_unit_str);
    else
        fct        = 10^-nice_numbers;
        nr_format  = '\t %4.1f';
        xlabel_str = sprintf('NPV averted damage over %d years (10^%1.0f %s)',n_years,nice_numbers,Value_unit_str);
    end
else
    fct        = 1;
    nr_format  = '%2.1e';
    xlabel_str = sprintf('NPV averted damage over %d years (%s)',n_years,Value_unit_str);
end
% nr_format_benefit  = nr_format;
% nr_format_bc_ratio = '%2.1f';

% correct risk transfer to not cover more than actual climate risk
risk_transfer_idx = strcmp(measures_impact.measures.name,'risk transfer');
if any(risk_transfer_idx) && sum(measures_impact.benefit)>tot_climate_risk
    fprintf('Risk transfer is corrected to cover only actual climate risk.\n')
    measures_impact.benefit(risk_transfer_idx)  = tot_climate_risk - sum(measures_impact.benefit(~risk_transfer_idx));
    %measures_impact.cb_ratio(risk_transfer_idx) = measures_impact.measures.cost(risk_transfer_idx)/measures_impact.benefit(risk_transfer_idx);
end

% special case for people, set cb_ratio as people not affected per 100'000 USD invested
if strcmp(measures_impact.Value_unit,'people')
    cost_factor = 20000;%cost_factor = 10000;
    xlabel_str = sprintf('NPV benefits (%s, %d years)\n Costs (%d USD)',measures_impact.Value_unit, n_years, cost_factor);
    %mean(measures_impact.measures.cost' ./ measures_impact.benefit)
    nr_format_benefit = strrep(nr_format,'.1e','.0f');
    measures_impact.cb_ratio = measures_impact.cb_ratio/cost_factor;
    measures_impact.measures.cost = measures_impact.measures.cost/cost_factor;
else
    cost_factor = 1;
    xlabel_str = sprintf('NPV benefits (%s, %d years)\n Costs (USD)',measures_impact.Value_unit, n_years);
end

title_str = measures_impact.title_str;
% sort measures according to size of benefit, not cb_ratio
if sort_measures
    [sorted_benefit,sort_index] = sort(measures_impact.benefit,'ascend'); 
    legend_location = 'south';
else
    sorted_benefit = measures_impact.benefit;
    sort_index      = numel(measures_impact.cb_ratio):-1:1; 
    legend_location = 'north';
end
% if reverse_cb,sorted_cb_ratio= 1./sorted_cb_ratio;end

% % special colormap for salvador
% cmap = climada_colormap('measures',numel(measures_impact.measures.name));
% measures_impact.measures.color_RGB(sort_index,:) = cmap;

fig = climada_figuresize(0.8,0.7);
n_measures = numel(measures_impact.benefit);
benefit_costs = climada_concatenate_lon_lat(measures_impact.benefit(sort_index), measures_impact.measures.cost(sort_index));
width = 1.0;
% width = 1.2;
h = barh(benefit_costs,width);
hold on
set(gca,'ytick',1:1:n_measures,'yticklabel',measures_impact.measures.name(sort_index))
% if ~strcmp(measures_impact.Value_unit,'people')
    g = plot(ones(2,1)*tot_climate_risk,[0 n_measures+1],'-.k');
% end
x_location = tot_climate_risk*cb_text_control;
for m_i = 1:n_measures
    text(x_location,m_i,sprintf('%2.1f',1./measures_impact.cb_ratio(sort_index(m_i))),'fontsize',fontsize_)
end
set(h(1),'FaceColor',[51 153 51]/255,'EdgeColor',[51 153 51]/255,'LineWidth',0.1);% green for benefits
set(h(2),'FaceColor',[158 158 135]/255,'EdgeColor',[158 158 135]/255,'LineWidth',0.1);% grey for costs

l = legend([h g],'Benefits','Costs','NPV total climate risk','location',legend_location);
legend('boxoff')
set(l,'fontsize',fontsize_-1);
% legendstr = {'Benefits', 'Costs'}
xlabel(xlabel_str)
xlim([0 tot_climate_risk*1.17])
set(gca,'Xaxislocation','top')

% add title
title_str=strrep(title_str,'_',' '); % since title is LaTEX format
title_str=strrep(title_str,'|','\otimes'); % LaTEX format
title(title_str,'FontSize',fontsize_);

% comparison scenario
if ~isempty(measures_impact_comparison)
    if ~isstruct(measures_impact_comparison)
        measures_impact_comparison_file = measures_impact_comparison;
        clear measures_impact_comparison
        load(measures_impact_comparison_file);
    else
        measures_impact = measures_impact_comparison;
    end
    
    % NOTE: measures_impact holds now the impacts for comparison! (load overloaded this)
    
    % expert mode, overlay with a second EDS for comparison - but scaling
    % etc is kept. EDS must be for same measures (not checked, assumed
    % expert user is really an expert)
    
    comp_title_str = measures_impact.title_str;
    fprintf('comparison %s :\n',comp_title_str);
    
    % special case for people, set cb_ratio as people not affected per 100'000 USD invested
    if strcmp(measures_impact.Value_unit,'people')
        measures_impact.cb_ratio = measures_impact.cb_ratio/cost_factor;
        measures_impact.measures.cost = measures_impact.measures.cost/cost_factor;
    elseif cost_factor>1 % used people in the measures_impact before
        measures_impact.cb_ratio = measures_impact.cb_ratio/cost_factor;
        measures_impact.measures.cost = measures_impact.measures.cost/cost_factor;
        measures_impact.benefit = measures_impact.benefit/cost_factor;
    end

    %width_comparison = width*0.3;
    %h2 = barh(measures_impact.benefit(sort_index),width_comparison);
    %set(h2(1),'FaceColor',[26 76 26]/255,'EdgeColor',[26 76 26]/255,'LineWidth',0.1);% green for benefits
    %set(get(h2(1),'child'), 'facealpha',0.2,'edgealpha',0.2)
    %l = legend([h h2],'Benefits','Costs','B. comparison');
    
    width_comparison = width*1;
    alpha_value = 0.5;
    benefit_costs = climada_concatenate_lon_lat(measures_impact.benefit(sort_index), measures_impact.measures.cost(sort_index));
    h2 = barh(benefit_costs,width_comparison);
    set(h2(1),'FaceColor',[51 153 51]/255,'EdgeColor',[51 153 51]/255,'LineWidth',0.1);% green for benefits
    set(get(h2(1),'child'), 'facealpha',alpha_value,'edgealpha',alpha_value)
    set(h2(2),'FaceColor',[95 95 81]/255,'EdgeColor',[95 95 81]/255,'LineWidth',0.1);% darker grey for costs
    set(get(h2(2),'child'), 'facealpha',alpha_value,'edgealpha',alpha_value)
    %l = legend([h h2],'Benefits','Costs','B. comparison','C. comparison','location','north');
    %set(l,'fontsize',fontsize_-1);
    
    both_title_str{1} = title_str;
    comp_title_str    = strrep(comp_title_str,'_',' '); % since title is LaTEX format
    comp_title_str    = strrep(comp_title_str,'|','\otimes'); % LaTEX format
    both_title_str{2} = ['comparison ' comp_title_str];
    title(both_title_str,'FontSize',fontsize_); 
end

box on
set(gca,'layer','top')



return
