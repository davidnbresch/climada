function fig = climada_adaptation_bar_chart_v2(measures_impact,sort_measures,scale_benefit,benefit_str,legend_location,tcr_off,cost_unit,xlim_value)
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
% Lea Mueller, muellele@gmail.com, 20150924, add cost_unit and xlim_value, introduce climada_digit_set
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

called_from_climada_demo = 0; % default
if nargout>0,called_from_climada_demo = 1;end % called from climada_play_adapt_cost_curve

% poor man's version to check arguments
if ~exist('measures_impact'           , 'var'), measures_impact            = []; end
if ~exist('sort_measures'             , 'var'), sort_measures              = ''; end
if ~exist('scale_benefit'             , 'var'), scale_benefit              = ''; end
if ~exist('benefit_str'               , 'var'), benefit_str                = ''; end
if ~exist('legend_location'           , 'var'), legend_location            = ''; end
if ~exist('tcr_off'                   , 'var'), tcr_off                    = ''; end
if ~exist('cost_unit'                 , 'var'), cost_unit                  = ''; end
if ~exist('xlim_value'                , 'var'), xlim_value                 = ''; end


% PARAMETERS
if isempty(sort_measures), sort_measures = 0; end
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

% set Value_unit
if isfield(measures_impact,'Value_unit')
    Value_unit_str = measures_impact(1).Value_unit;
else
    Value_unit_str = climada_global.Value_unit;
end

if isempty(cost_unit), cost_unit = Value_unit_str; end

n_years = climada_global.future_reference_year - climada_global.present_reference_year + 1;

% % correct risk transfer to not cover more than actual climate risk
% risk_transfer_idx = strcmp(measures_impact(1).measures.name,'risk transfer');
% if any(risk_transfer_idx) && sum(measures_impact(1).benefit)>tot_climate_risk
%     fprintf('Risk transfer is corrected to cover only actual climate risk.\n')
%     measures_impact(1).benefit(risk_transfer_idx)  = tot_climate_risk - sum(measures_impact(1).benefit(~risk_transfer_idx));
%     %measures_impact.cb_ratio(risk_transfer_idx) = measures_impact.measures.cost(risk_transfer_idx)/measures_impact.benefit(risk_transfer_idx);
% end


% special case for people, set cb_ratio as people not affected per 100'000 USD invested
if strcmp(measures_impact(1).Value_unit,'people') & scale_benefit==1
    scale_benefit = 20000; %cost_factor = 10000;
end

% get all important numbers for graph
% benefits, NPV tot climate risk, costs, cb_ratio
n_impacts = numel(measures_impact);
n_measures = numel(measures_impact(1).benefit);

benefit = zeros(n_measures,n_impacts);
cost = zeros(n_measures,n_impacts);
bc_ratio = zeros(n_measures,n_impacts);
NPV_tot_climate_risk = zeros(1,n_impacts);

for impact_i = 1:n_impacts
    benefit(:,impact_i) = measures_impact(impact_i).benefit;
    cost(:,impact_i) = measures_impact(impact_i).measures.cost/scale_benefit;
    bc_ratio(:,impact_i) = 1./measures_impact(impact_i).cb_ratio*scale_benefit;
    NPV_tot_climate_risk(impact_i) = measures_impact(impact_i).NPV_total_climate_risk;
    legendstr{impact_i} = strrep(measures_impact(impact_i).title_str,'_',' ');
    titlestr{impact_i} = strrep(measures_impact(impact_i).title_str,'_',' ');
end

% calculate digits
[digit, digit_str] = climada_digit_set(benefit);
[digit_cost, digit_cost_str] = climada_digit_set(cost*scale_benefit);

% set title and other figure parameters
fontsize_ = 10;
title_str = measures_impact(1).title_str;
if isempty(benefit_str)
    benefit_str = sprintf('Net present value benefits \n(%s %s, %d years)',measures_impact(1).Value_unit, digit_str, n_years);
end
xlabel_str = sprintf('Costs (%s %s)',cost_unit, digit_cost_str);
% xlabel_str = sprintf('NPV averted damage over %d years (%s %s)',n_years,Value_unit_str,digit_str);
% fct        = 1;
% nr_format  = '%2.1e';

if scale_benefit == 1
    ylabel_str_1 = sprintf('%s /',measures_impact(1).Value_unit);
else
    ylabel_str_1 = sprintf('%s / %d',measures_impact(1).Value_unit,scale_benefit);
end
ylabel_str_2 = cost_unit;
ylabelstr = sprintf('Benefit-cost ratio (%s %s)',ylabel_str_1,ylabel_str_2);

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
% special case for Barisal
if strcmp(benefit_str,'Risk reduction in AED (%)'), bc_ratio=bc_ratio/scale_benefit;end
for m_i = 1:n_measures
    bc_ratio_str{m_i} = sprintf(' %5.1f',bc_ratio(m_i,1));
end

% % special colormap for salvador
% cmap = climada_colormap('measures',numel(measures_impact.measures.name));
% measures_impact.measures.color_RGB(sort_index,:) = cmap;

% set figure parameters
width = 1.0; %.0; % width = 1.2;
color_cost_ref = [158 158 135]/255; % lighter grey for costs
% color_benefit(2,:) = [51 153 51]/255; % green for benefits
% color_benefit(1,:) = [154 205 50]/255; % lighter green for reference benefits
color_benefit = flipud(climada_colormap('benefit_adaptation_bar_chart',n_impacts));

% % reference
% width_ref = width*1;
% color_benefit_ref = [154 205 50]/255; % lighter green for reference benefits
color_cost = [95 95 81]/255; % grey for reference costs

% create bar chart
fig = climada_figuresize(0.8,0.7);% fig = climada_figuresize(1.0,0.7); for Barisal

hold on
h = barh([1:n_measures]-0,[fliplr(benefit) zeros(size(cost(:,1)))],width*1.3);
h_cost = barh(1:n_measures,[zeros(size(benefit)) cost(:,1)],width*1.0);
% h = barh([fliplr(benefit) cost(:,1)],width);
set(gca,'ytick',1:1:n_measures,'yticklabel',measure_names)
% if ~strcmp(measures_impact.Value_unit,'people') end
if ~tcr_off
    g = plot(ones(2,1)*NPV_tot_climate_risk(1),[0 n_measures+1],'-.','color',color_benefit(end,:));
end
set(h_cost(end),'FaceColor',color_cost,'EdgeColor',color_cost,'LineWidth',0.1);
set(h(end),'FaceColor',color_cost,'EdgeColor',color_cost,'LineWidth',0.1);
for impact_i = 1:n_impacts
    set(h(impact_i),'FaceColor',color_benefit(impact_i,:),'EdgeColor',color_benefit(impact_i,:),'LineWidth',0.1);
end
if ~tcr_off
    l = legend([h(end:-1:1) g],{'Costs' legendstr{:} 'NPV total climate risk'},'location',legend_location);
else
    l = legend([h(end:-1:1)],{'Costs' legendstr{:}},'location',legend_location);
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
% xlim([0 NPV_tot_climate_risk(1)*1.3])
% special case for Barisal
if strcmp(benefit_str,'Risk reduction in AED (%)'), xlim([0 100]),end
if isempty(xlim_value)
    xlim([0 NPV_tot_climate_risk(1)*1.3])
else
    xlim([0 xlim_value])
end
set(gca,'Xaxislocation','top','xcolor',color_cost)
xlabel(xlabel_str)

% add title
title(titlestr,'FontSize',fontsize_); 

% First, store the handle to those axes.
% Next create a second set of axes, 
% position This on top of the first and make it transparent.
ax1 = gca;
x_tick_top = get(ax1,'xtick'); % top handle
set(ax1, 'XTickLabel',x_tick_top*scale_benefit/10^digit_cost)
ax2 = axes('Position', get(ax1, 'Position'),'Color', 'none');
set(ax2, 'XAxisLocation', 'bottom','YAxisLocation','Right');
% set the same Limits and Ticks on ax2 as on ax1;
set(ax2, 'XLim', get(ax1, 'XLim'),'YLim', get(ax1, 'YLim'));
set(ax2, 'XTick', get(ax1, 'XTick'), 'YTick', get(ax1, 'YTick'));

% Set the x-tick and y-tick  labels for the second axes
x_tick_bottom = x_tick_top/10^digit;
x_label_bottom = sprintf('%s',benefit_str);
set(ax2, 'XTickLabel',x_tick_bottom,'YTickLabel',bc_ratio_str,'xcolor',color_benefit(end,:))
xlabel(x_label_bottom)
ylabel(ylabelstr)

set(ax1, 'ActivePositionProperty', 'position');
set(ax2, 'ActivePositionProperty', 'position');


return
