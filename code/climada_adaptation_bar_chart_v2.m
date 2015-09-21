function fig = climada_adaptation_bar_chart_v2(measures_impact,sort_measures,cb_text_control,scale_benefit,benefit_str,legend_location,tcr_off)
% climada measures impact climate adaptation bar chart
% NAME:
%   climada_adaptation_bar_chart_v2
% PURPOSE:
%   plot adaptation bar chart (NPV benefits and costs)
%   see also: climada_adaptation_cost_curve
%
% CALLING SEQUENCE:
%   climada_adaptation_bar_chart_v2(measures_impact,sort_measures,cb_text_control,scale_benefit,benefit_str,legend_location,tcr_off)
% EXAMPLE:
%   climada_adaptation_bar_chart_v2(climada_measures_impact(climada_entity_read),'',1) % from scratch
% INPUTS:
%   measures_impact: a climada measures_impact structure, can hold multiple measures_impacts
%       see climada_measures_impact
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   sort_measures: if set to 1, sort measures according to size of benefit
%   cb_text_control: control position of cb_ratio 
% OUTPUTS:
%   fig: a figure handle
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150921, init
% Lea Mueller, muellele@gmail.com, 20150921, measures_impact can hold multiple measures_impact(impact_i)
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

called_from_climada_demo = 0; % default
if nargout>0,called_from_climada_demo = 1;end % called from climada_play_adapt_cost_curve

% poor man's version to check arguments
if ~exist('measures_impact'           , 'var'), measures_impact            = []; end
if ~exist('sort_measures'             , 'var'), sort_measures              = ''; end
if ~exist('cb_text_control'           , 'var'), cb_text_control            = ''; end
if ~exist('scale_benefit'             , 'var'), scale_benefit              = ''; end
if ~exist('benefit_str'               , 'var'), benefit_str                = ''; end
if ~exist('legend_location'           , 'var'), legend_location            = ''; end
if ~exist('tcr_off'                   , 'var'), tcr_off                    = ''; end


% additional parameters that are necessary for the code, maybe useful later
% if we decide to include it in climada_demo
if ~exist('scaled_AED'                , 'var'), scaled_AED                 = 0 ; end
if ~exist('nice_numbers'              , 'var'), nice_numbers               = []; end

called_from_climada_demo = 0;

% PARAMETERS
if isempty(sort_measures), sort_measures = 0; end
if isempty(cb_text_control), cb_text_control = 1.05; end
if isempty(scale_benefit), scale_benefit = 1.0; end
if isempty(tcr_off), tcr_off = 0; end


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
    Value_unit_str = measures_impact(1).Value_unit;
else
    Value_unit_str = climada_global.Value_unit;
end

% if scaled_AED
%     scale_factor = measures_impact(1).ED(end) /measures_impact(1).NPV_total_climate_risk;
%     measures_impact(1).measures.cost = bsxfun(@times, measures_impact(1).measures.cost, scale_factor);
%     measures_impact(1).risk_transfer = bsxfun(@times, measures_impact(1).risk_transfer, scale_factor);
%     measures_impact(1).benefit       = bsxfun(@times, measures_impact(1).benefit      , scale_factor);
%     %total climate risk
%     tot_climate_risk  = bsxfun(@times, measures_impact.NPV_total_climate_risk, scale_factor);
% else
%     %total climate risk
%     tot_climate_risk  = measures_impact(1).NPV_total_climate_risk;
% end

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
risk_transfer_idx = strcmp(measures_impact(1).measures.name,'risk transfer');
if any(risk_transfer_idx) && sum(measures_impact(1).benefit)>tot_climate_risk
    fprintf('Risk transfer is corrected to cover only actual climate risk.\n')
    measures_impact(1).benefit(risk_transfer_idx)  = tot_climate_risk - sum(measures_impact(1).benefit(~risk_transfer_idx));
    %measures_impact.cb_ratio(risk_transfer_idx) = measures_impact.measures.cost(risk_transfer_idx)/measures_impact.benefit(risk_transfer_idx);
end

% special case for people, set cb_ratio as people not affected per 100'000 USD invested
if strcmp(measures_impact(1).Value_unit,'people')
    cost_factor = 20000;%cost_factor = 10000;
    xlabel_str = sprintf('Costs (%d USD)',cost_factor);
    %xlabel_str = sprintf('NPV benefits (%s, %d years)\n Costs (%d USD)',measures_impact.Value_unit, n_years, cost_factor);
    %mean(measures_impact.measures.cost' ./ measures_impact.benefit)
    nr_format_benefit = strrep(nr_format,'.1e','.0f');
    measures_impact(1).cb_ratio = measures_impact(1).cb_ratio/cost_factor;
    measures_impact(1).measures.cost = measures_impact(1).measures.cost/cost_factor;
    %if isempty(benefit_str)
    %    benefit_str = sprintf('NPV benefits (%s, %d years)',measures_impact.Value_unit, n_years);
    %end
else
    cost_factor = 1;
    %xlabel_str = sprintf('NPV benefits (%s, %d years)\n Costs (USD)',measures_impact.Value_unit, n_years);
    xlabel_str = sprintf('Costs (%s)',measures_impact(1).Value_unit);
end
if isempty(benefit_str)
    benefit_str = sprintf('NPV benefits (%s, %d years)',measures_impact(1).Value_unit, n_years);
end
    
title_str = measures_impact(1).title_str;


% get all important numbers for graph
% benefits, NPV tot climate risk, costs, cb_ratio
n_impacts = numel(measures_impact);
n_measures = numel(measures_impact(1).benefit);

benefit = zeros(n_measures,n_impacts);
cost = zeros(n_measures,n_impacts);
bc_ratio = zeros(n_measures,n_impacts);
NPV_tot_climate_risk = zeros(1,n_impacts);

for impact_i = 1:n_impacts
    benefit(:,impact_i) = measures_impact(impact_i).benefit*scale_benefit;
    cost(:,impact_i) = measures_impact(impact_i).measures.cost;
    bc_ratio(:,impact_i) = 1./measures_impact(impact_i).cb_ratio;
    NPV_tot_climate_risk(impact_i) = measures_impact(impact_i).NPV_total_climate_risk;
    legendstr{impact_i} = measures_impact(impact_i).title_str;
    titlestr{impact_i} = strrep(measures_impact(impact_i).title_str,'_',' ');
end

% sort measures according to size of benefit, not cb_ratio
if sort_measures
    if sort_measures>n_impacts, sort_measures = 1; end
    [sorted_benefit,sort_index] = sort(benefit(:,sort_measures),'ascend'); 
    if isempty(legend_location), legend_location = 'south'; end
else
    sort_index = n_measures:-1:1;
    if isempty(legend_location), legend_location = 'north'; end
end
% order all the fields accordingly
benefit = benefit(sort_index,:);
cost = cost(sort_index,:);
bc_ratio = bc_ratio(sort_index,:);
measure_names = measures_impact(1).measures.name(sort_index);

% bc_ratio for original measures_impact
bc_ratio_str = cell(n_measures,1);
for m_i = 1:n_measures
    bc_ratio_str{m_i} = sprintf(' %5.1f',bc_ratio(m_i,1));
end

% % special colormap for salvador
% cmap = climada_colormap('measures',numel(measures_impact.measures.name));
% measures_impact.measures.color_RGB(sort_index,:) = cmap;

% set figure parameters
width = 1.0; %.0; % width = 1.2;
color_cost_ref = [158 158 135]/255; % lighter grey for costs
color_benefit(2,:) = [51 153 51]/255; % green for benefits
color_benefit(1,:) = [154 205 50]/255; % lighter green for reference benefits

% % reference
% width_ref = width*1;
% color_benefit_ref = [154 205 50]/255; % lighter green for reference benefits
color_cost = [95 95 81]/255; % grey for reference costs


% create bar chart
fig = climada_figuresize(1.0,0.7);
h = barh([fliplr(benefit) cost(:,1)],width);
hold on
set(gca,'ytick',1:1:n_measures,'yticklabel',measure_names)
% if ~strcmp(measures_impact.Value_unit,'people') end
if ~tcr_off
    g = plot(ones(2,1)*NPV_tot_climate_risk(1),[0 n_measures+1],'-.k');
end
set(h(end),'FaceColor',color_cost,'EdgeColor',color_cost,'LineWidth',0.1);
for impact_i = 1:n_impacts
    set(h(impact_i),'FaceColor',color_benefit(impact_i,:),'EdgeColor',color_benefit(impact_i,:),'LineWidth',0.1);
end
if ~tcr_off
    l = legend([h(end:-1:1) g],{'Costs' legendstr{:} 'NPV total climate risk'},'location',legend_location);
else
    l = legend(h(end:-1:1),{'Costs' legendstr{:}},'location',legend_location);
end
legend('boxoff')
set(l,'fontsize',fontsize_-1);
if n_impacts > 1
    if sum(cost(:,1)) ~= sum(cost(:,2))
        h2 = barh([zeros(size(benefit)) cost(:,2)],width);
        set(h2(end),'FaceColor',color_cost_ref,'EdgeColor',color_cost_ref,'LineWidth',0.1);
        l = legend([h2(end) h(end:-1:1)],{'Capex' 'Opex' legendstr{:}},'location',legend_location);
        legend('boxoff')
    end
end
xlim([0 NPV_tot_climate_risk(1)*1.17])
set(gca,'Xaxislocation','top','xcolor',color_cost)
xlabel(xlabel_str)

% add title
title(titlestr,'FontSize',fontsize_); 

% First, store the handle to those axes.
% Next create a second set of axes, 
% position This on top of the first and make it transparent.
ax1 = gca;
ax2 = axes('Position', get(ax1, 'Position'),'Color', 'none');
set(ax2, 'XAxisLocation', 'bottom','YAxisLocation','Right');
% set the same Limits and Ticks on ax2 as on ax1;
set(ax2, 'XLim', get(ax1, 'XLim'),'YLim', get(ax1, 'YLim'));
set(ax2, 'XTick', get(ax1, 'XTick'), 'YTick', get(ax1, 'YTick'));

% Set the x-tick and y-tick  labels for the second axes
x_tick_top = get(ax1,'xtick'); % top handle
x_tick_bottom = x_tick_top/scale_benefit;
x_label_bottom = sprintf('Benefit (%s)',benefit_str);
set(ax2, 'XTickLabel',x_tick_bottom,'YTickLabel',bc_ratio_str,'xcolor',color_benefit(end,:))
xlabel(x_label_bottom)
ylabel('Benefit-cost ratio')

set(ax1, 'ActivePositionProperty', 'position');
set(ax2, 'ActivePositionProperty', 'position');



% box on
% set(gca,'layer','top')

% % comparison scenario
% if ~isempty(measures_impact_comparison)
    % NOTE: measures_impact holds now the impacts for comparison! (load overloaded this)
    
    % expert mode, overlay with a second EDS for comparison - but scaling
    % etc is kept. EDS must be for same measures (not checked, assumed
    % expert user is really an expert)
    
%     if isempty(alpha_value)
%         alpha_value = 0.5;
%     end
%         
%     comp_title_str = measures_impact.title_str;
%     fprintf('comparison %s :\n',comp_title_str);
%     
%     % special case for people, set cb_ratio as people not affected per 100'000 USD invested
%     if strcmp(measures_impact.Value_unit,'people')
%         measures_impact.cb_ratio = measures_impact.cb_ratio/cost_factor;
%         measures_impact.measures.cost = measures_impact.measures.cost/cost_factor;
%     elseif cost_factor>1 % used people in the measures_impact before
%         measures_impact.cb_ratio = measures_impact.cb_ratio/cost_factor;
%         measures_impact.measures.cost = measures_impact.measures.cost/cost_factor;
%         measures_impact.benefit = measures_impact.benefit/cost_factor;
%     end

    %width_comparison = width*0.3;
    %h2 = barh(measures_impact.benefit(sort_index),width_comparison);
    %set(h2(1),'FaceColor',[26 76 26]/255,'EdgeColor',[26 76 26]/255,'LineWidth',0.1);% green for benefits
    %set(get(h2(1),'child'), 'facealpha',0.2,'edgealpha',0.2)
    %l = legend([h h2],'Benefits','Costs','B. comparison');
    
%     benefit_costs = climada_concatenate_lon_lat(measures_impact.benefit(sort_index)*scale_benefit, measures_impact.measures.cost(sort_index));
%     h2 = barh(benefit_costs,width_ref);
%     set(h2(1),'FaceColor',color_benefit_ref,'EdgeColor',color_benefit_ref,'LineWidth',0.1);% green for benefits
%     set(h2(2),'FaceColor',color_cost_ref,'EdgeColor',color_cost_ref,'LineWidth',0.1);
%     % disable for barisal
%     if alpha_value>0
%         set(get(h2(1),'child'), 'facealpha',alpha_value,'edgealpha',alpha_value)
%         set(get(h2(2),'child'), 'facealpha',alpha_value,'edgealpha',alpha_value)
%     end
% 
%     if ~tcr_off
%         l = legend([h(2) h2(2) h(1) h2(1) g],'Capex+Opex','Capex','Benefit 2015','Benefit 2050','NPV total climate risk','location',legend_location);
%     else
%         %l = legend([h h2],'Benefits','Costs','B. comparison','C. comparison','location','north');
%         l = legend([h(2) h2(2) h(1) h2(1)],'Capex+Opex','Capex','Benefit 2015','Benefit 2050','location',legend_location);
%         
%     end
%     set(l,'fontsize',fontsize_-1);
%     legend('boxoff')

%     both_title_str{1} = title_str;
%     comp_title_str    = strrep(comp_title_str,'_',' '); % since title is LaTEX format
%     comp_title_str    = strrep(comp_title_str,'|','\otimes'); % LaTEX format
%     both_title_str{2} = ['comparison ' comp_title_str];
%     title(both_title_str,'FontSize',fontsize_); 
% end




return
