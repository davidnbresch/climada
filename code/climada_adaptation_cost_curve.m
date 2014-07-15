function [insurance_benefit, insurance_cost] = climada_adaptation_cost_curve(measures_impact, measures_impact_comparison,x_text_control,y_text_control,scaled_AED,nice_numbers,reverse_cb,plot_arrow)
% climada measures impact climate adaptation cost curve
% NAME:
%   climada_adaptation_cost_curve
% PURPOSE:
%   plot adaptation cost curve
%   see also: climada_adaptation_event_view
%
%   NOTE: The mode with output arguments insurance_benefit and
%   insurance_cost is only used when called from
%   climada_play_adapt_cost_curve, no relevance for lecture
% CALLING SEQUENCE:
%   climada_adaptation_cost_curve(measures_impact,measures_impact_comparison)
% EXAMPLE:
%   climada_adaptation_cost_curve(climada_measures_impact(climada_entity_read)) % from scratch
%   climada_adaptation_cost_curve(climada_measures_impact,climada_measures_impact) % one needs to really understand what's going on
%   climada_adaptation_cost_curve('','','','',0,0,1) % inverted c/b
% INPUTS:
%   measures_impact: either a struct containing the impacts of measures or a measures_impact file (.mat with a struct)
%       see climada_measures_impact
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   measures_impact_comparison: same as measures_impact, but for comparison
%       (will be shown in overlay). Not prompted for, so please specify in
%       call, or enter 'ASK' in climada_adaptation_cost_curve('','ASK')
%   x_text_control: controls the horizontal distribution of the text labels
%       (divider of the length of the x-axis, default=20)
%   y_text_control: controls the vertical distribution of the text labels
%       (divider of the length of the y-axis, default=50)
%   scaled_AED: scaled annual expected damage (only used by Lea Mueller),
%       default=0 (inactive)
%   nice_numbers: used in the special mode for the climada_play_gui, where
%       this code is called from climada_play_adapt_cost_curve,
%       default=0 (inactive)
%   reverse_cb: reverse the vertical axis (=1), instead of cost/benefit,
%       show benefit per cost, default=0
%   plot_arrows: whether we do (=1) or don't (=0) plot arrows underneath
%       the x-axis to show cost-effective measures and non-cost-effective
%       measures extent, has occasionally some issues, hence default =0
% OUTPUTS:
%   insurance_benefit and insurance_cost: only used when called from
%       climada_play_adapt_cost_curve, see there (in essence to write
%       insurance cost on the GUI)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091228
% David N. Bresch, david.bresch@gmail.com, 20091230 major revision, appreance similar to ECA graphs
% David N. Bresch, david.bresch@gmail.com, 20130316 EDS->EDS
% David N. Bresch, david.bresch@gmail.com, 20130316 compatibility for both direct call as well as via climada_demo_gui
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

called_from_play_adapt_cost_curve=0; % default
if nargout>0,called_from_play_adapt_cost_curve=1;end % called from climada_play_adapt_cost_curve

% poor man's version to check arguments
if ~exist('measures_impact'           , 'var'), measures_impact            = []; end
if ~exist('measures_impact_comparison', 'var'), measures_impact_comparison = ''; end
if ~exist('x_text_control'            , 'var'), x_text_control             = []; end
if ~exist('y_text_control'            , 'var'), y_text_control             = []; end
if ~exist('scaled_AED'                , 'var'), scaled_AED                 = 0 ; end
if ~exist('nice_numbers'              , 'var'), nice_numbers               = []; end
if ~exist('reverse_cb'                , 'var'), reverse_cb                 = 0; end
if ~exist('plot_arrows'               , 'var'), plot_arrows                = 0; end

% PARAMETERS
%
% controls the horizontal/vertical distribution of the text labels (divider of the
% length of the x/y-axis)
if isempty(x_text_control), x_text_control=30;end
if isempty(y_text_control), y_text_control=50;end


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

% set the extras for the play gui
if called_from_play_adapt_cost_curve
    scaled_AED            = 1;
    nice_numbers          = 1;
    add_insurance_measure = 1;
    fontsize_             = 8; % 20140527, on PC, use smaller
    if ismac, fontsize_   = 11;end % 20140516, was 8, too small
else
    add_insurance_measure = 0;
    fontsize_             = 11;
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

if add_insurance_measure % NOTE: this section not relevant for lecture
    %cover residual damage with insurance
    insurance_benefit    = tot_climate_risk - sum(measures_impact.benefit);
    %calculate insurance costs
    insurance_percentage = insurance_benefit/tot_climate_risk;
    insurance_cost_vs_percentage = [0.3 1; 1.4 3];
    if insurance_percentage < min(insurance_cost_vs_percentage(1,:))
        insurance_cost = min(insurance_cost_vs_percentage(2,:));
    else
        insurance_cost = interp1(insurance_cost_vs_percentage(1,:),insurance_cost_vs_percentage(2,:),insurance_percentage);
    end
    insurance_cost     = insurance_cost*insurance_benefit;
    insurance_cb       = insurance_cost/insurance_benefit;
end

n_years    = climada_global.future_reference_year - climada_global.present_reference_year + 1;
if nice_numbers
    % scaled, used if called from climada_play_adapt_cost_curve
    if nice_numbers == 1
        fct        = 10^-8;
        nr_format  = '\t %4.1f';
        xlabel_str = sprintf('Averted damage (Mio USD)');
    else
        fct        = 10^-nice_numbers;
        nr_format  = '\t %4.1f';
        xlabel_str = sprintf('Averted damage over %d years (10^%1.0f USD)',n_years, nice_numbers);
    end
else
    fct        = 1;
    nr_format  = '%2.1e';
    xlabel_str = sprintf('Averted damage over %d years (USD)',n_years);
end


%% correct risk transfer to not cover more than actual climate risk
risk_transfer_idx = strcmp(measures_impact.measures.name,'risk transfer');
if any(risk_transfer_idx) && sum(measures_impact.benefit)>tot_climate_risk
    fprintf('Risk transfer is corrected to cover only actual climate risk.\n')
    measures_impact.benefit(risk_transfer_idx)  = tot_climate_risk - sum(measures_impact.benefit(~risk_transfer_idx));
    %measures_impact.cb_ratio(risk_transfer_idx) = measures_impact.measures.cost(risk_transfer_idx)/measures_impact.benefit(risk_transfer_idx);
end

title_str                    = measures_impact.title_str;
[sorted_cb_ratio,sort_index] = sort(measures_impact.cb_ratio);
if reverse_cb,sorted_cb_ratio=1./sorted_cb_ratio;end

% COMMAND WINDOW: results
fprintf('%s :\n',title_str);
n_measures = length(measures_impact.measures.cost);
fprintf('\t Measure \t\t\t Cost \t\t\t Benefit \t\t CB_ratio\n');
if scaled_AED
    fprintf('\t \t    \t\t\t(Mio USD)\t\t(Mio USD)\t\t(USD/USD)\n');
elseif nice_numbers>1
    fprintf('\t \t\t    \t\t(10^%1.0f USD)\t\t(10^%1.0f USD)\t\t(USD/USD)\n', nice_numbers, nice_numbers);
else
    fprintf('\t \t    \t\t\t(USD)\t\t\t(USD)\t\t\t(USD/USD)\n');
end
for measure_i = 1:n_measures
    m_name = [measures_impact.measures.name{measure_i} '                    '];
    m_name = m_name(1:25);
    fprintf(['\t %s ' nr_format ' \t ' ['\t' nr_format] ' \t\t\t\t %2.1f \n'],...
        m_name,...
        (measures_impact.measures.cost(measure_i)+measures_impact.risk_transfer(measure_i))*fct,...
        measures_impact.benefit(measure_i)*fct,...
        measures_impact.cb_ratio(measure_i));
end % measure_i
if add_insurance_measure % NOTE: this section not relevant for lecture
    fprintf('\t Residual covered by insurance')
    fprintf([nr_format ' \t ' ['\t' nr_format] '\t\t\t\t %2.1f\n'],...
        insurance_cost*fct, insurance_benefit*fct, insurance_cb)
    if reverse_cb,insurance_cb=1./insurance_cb;end
    sorted_cb_ratio = [sorted_cb_ratio insurance_cb];
else
    fprintf('\t Residual damage \n')
    fprintf(['\t\t\t\t\t\t\t' nr_format '  \t ' ['\t ' nr_format] '\t\t\t\t %2.1f\n'],...
        0, (tot_climate_risk-sum(measures_impact.benefit))*fct, 0)
end
cumulated_benefit = [0, cumsum(measures_impact.benefit(sort_index)),  tot_climate_risk]*fct;

% PLOT: a dummy plot to open the figure and set the axes
xmax      = max(cumulated_benefit);
ymax      = max([max(sorted_cb_ratio),1.1]);
if called_from_play_adapt_cost_curve
    plot([0,xmax],[ymax,ymax],'.w'); hold on
    set(gca,'FontSize',fontsize_);
else
    climada_figuresize(0.5,0.7);
    subaxis(1,1,1,'Mb',0.18)
    set(subaxis(1),'FontSize',fontsize_);hold on
end
xlabel(xlabel_str,'fontsize',fontsize_+1)
if reverse_cb
    ylabel('Benefit/cost ratio (USD/USD)','fontsize',fontsize_+1)
else
    ylabel('Cost/benefit ratio (USD/USD)','fontsize',fontsize_+1)
end;

% plot measures
for measure_i = 1:n_measures+add_insurance_measure
    if measure_i == n_measures+1 %insurance cover, only if called from climada_play_adapt_cost_curve
        % NOTE: this section not relevant for lecture
        area(cumulated_benefit(measure_i:measure_i+1), [insurance_cb, insurance_cb],...
            'FaceColor',[193 193 193 ]/255,'EdgeColor','w'); %grey
    else
        area(cumulated_benefit(measure_i:measure_i+1),...
            [sorted_cb_ratio(measure_i), sorted_cb_ratio(measure_i)],...
            'FaceColor',measures_impact.measures.color_RGB(sort_index(measure_i),:),'EdgeColor','w');
    end
end

% annotate names of measures
for measure_i = 2:n_measures+1 %first entry = 0
    if ~isnan(sorted_cb_ratio(measure_i-1))
        text(cumulated_benefit(measure_i)-(cumulated_benefit(measure_i)-cumulated_benefit(measure_i-1))/2,...
            max(sorted_cb_ratio)/y_text_control,...
            [measures_impact.measures.name{sort_index(measure_i-1)},...
            '  (', num2str(sorted_cb_ratio(measure_i-1),'%2.2f'),')'], 'Rotation',90,'FontSize',fontsize_);
    end
end
% show net present value of total climate risk
plot(tot_climate_risk*fct,0,'d','color',[205 0 0]/255,'markerfacecolor',[205 0 0]/255,'markersize',10)
tcr_str = sprintf('Total climate risk\n%.0f USD',tot_climate_risk*fct);
text(tot_climate_risk*fct*0.93,max(sorted_cb_ratio)/y_text_control, tcr_str,...
    'HorizontalAlignment','center','VerticalAlignment','bottom','fontsize',fontsize_,'color',[205 0 0]/255)

if add_insurance_measure % NOTE: this section not relevant for lecture
    %insurance to cover residual damage
    measure_i = measure_i+1;
    text(cumulated_benefit(measure_i)-(cumulated_benefit(measure_i)-cumulated_benefit(measure_i-1))/2,...
        max(sorted_cb_ratio)/y_text_control,...
        ['Insurance','  (', num2str(sorted_cb_ratio(measure_i-1),'%2.1f'),')'], 'Rotation',90,'FontSize',fontsize_);
end
% % show total unmitigated expected damage ED
% plot(measures_impact.ED(end)*fct,0,'xr','MarkerSize',6); % red cross on x-axis
% text(measures_impact.ED(end)*fct,max(sorted_cb_ratio)/y_text_control,'ED','Rotation',90,'Color','red','FontSize',fontsize_,'fontweight','bold');


if plot_arrows
    % arrow below graph to indicate cost-efficient adaptation and residual damage
    if called_from_play_adapt_cost_curve
        y_ = -max(sorted_cb_ratio)*1.2*0.18;
        arrow_width  = 10;
        arrow_length = 10;
    else
        y_ = -max(sorted_cb_ratio)*1.2*0.14;
        arrow_width  = 15;
        arrow_length = 15;
    end    
    s_ = 0.5;
    m_cost_eff = sum(sorted_cb_ratio<=1)+1;
    climada_arrow([cumulated_benefit(end) y_*1.0], [cumulated_benefit(m_cost_eff)+s_/2 y_*1.0],...
        'width',arrow_width,'Length',arrow_length, 'BaseAngle',90, 'TipAngle',50,'EdgeColor','none', 'FaceColor',[205 0 0]/255);
    if add_insurance_measure
        text(mean(cumulated_benefit([end end-1])),y_, 'Non-cost-efficient','color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_-1,'fontweight','bold');
    else
        climada_arrow([cumulated_benefit(m_cost_eff) y_*1.0], [cumulated_benefit(end-1)+s_/2 y_*1.0],...
            'width',arrow_width-9,'Length',arrow_length-5, 'BaseAngle',90, 'TipAngle',50,'EdgeColor','none', 'FaceColor',[255 127   0]/255);
        text((cumulated_benefit(m_cost_eff)+cumulated_benefit(end-1))/2,y_, 'Non-cost-efficient'       ,'color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_-1,'fontweight','bold');
        text(mean(cumulated_benefit([end end-1])),y_, 'Residual damage','color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_-1,'fontweight','bold');
    end
    if cumulated_benefit(m_cost_eff)>0
        climada_arrow([0 y_], [cumulated_benefit(m_cost_eff)-s_/2 y_],...
            'width',arrow_width,'Length',arrow_length, 'BaseAngle',90, 'TipAngle',50,'EdgeColor','none', 'FaceColor',[0 197 205]/255);
        text(cumulated_benefit(m_cost_eff)/2,y_, 'Cost-efficient adaptation','color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_-1,'fontweight','bold');
    end
    %%% FOR LEA: next code line is the tricky one, leave
    %%%it commented, and arrows show nicely, but unfortunately the vertical
    %%%axis goes below zero and the arrows are shown below zero line...
    %%%ylim([0 max(sorted_cb_ratio)*1.1])
    % xlim([0 max(cumulated_benefit)*1.03]) % was commented already
end

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
    n_measures     = length(measures_impact.measures.cost);
    
    fprintf('\t Measure \t\t\t\t Cost \t\t\t Benefit \t CB_ratio\n');
    for measure_i = 1:n_measures
        fprintf(['\t %s \t\t\t' nr_format ' \t ' ['\t' nr_format] ' \t\t\t %2.1f \n'],...
            measures_impact.measures.name{measure_i},...
            (measures_impact.measures.cost(measure_i)+measures_impact.risk_transfer(measure_i))*fct,...
            measures_impact.benefit(measure_i)*fct,...
            measures_impact.cb_ratio(measure_i));
    end % measure_i
    
    if scaled_AED
        measures_impact.measures.cost = bsxfun(@times, measures_impact.measures.cost, scale_factor);
        measures_impact.risk_transfer = bsxfun(@times, measures_impact.risk_transfer, scale_factor);
        measures_impact.benefit       = bsxfun(@times, measures_impact.benefit      , scale_factor);
        %total climate risk
        tot_climate_risk              = bsxfun(@times, measures_impact.NPV_total_climate_risk, scale_factor);
    else
        %total climate risk
        tot_climate_risk              = measures_impact.NPV_total_climate_risk;
    end
    [sorted_cb_ratio,sort_index] = sort(measures_impact.cb_ratio);
    cumulated_benefit            = [0, cumsum(measures_impact.benefit(sort_index)),  tot_climate_risk]*fct;
    
    % to scale such that the plot comprises both
    xmax = max([xmax, cumulated_benefit(end)]);
    ymax = max([max(sorted_cb_ratio),1.1,ymax]);
    hold on; plot([0,xmax],[ymax,ymax],'.w');
    
    % plot measures (semi-transparent)
    version_no=str2double(strsplit(version,'.'));version_no=version_no(1);% get main version number
    for measure_i = 1:n_measures
        if version_no>6 % for version 7 and later
            patch([cumulated_benefit(measure_i:measure_i+1) cumulated_benefit(measure_i+1:-1:measure_i)],... %
                [0 0 sorted_cb_ratio(measure_i) sorted_cb_ratio(measure_i)],...
                measures_impact.measures.color_RGB(sort_index(measure_i),:),...
                'FaceAlpha',0.2, 'EdgeColor',[.9 .9 .9]);
        else % reverse compatibility
            % area('v6',...) creates patch objects instead of areaseries
            % objects for compatibility with MATLAB 6.5 and earlier.
            area('v6',cumulated_benefit(measure_i:measure_i+1),... %
                [sorted_cb_ratio(measure_i),sorted_cb_ratio(measure_i)],...
                'FaceColor',measures_impact.measures.color_RGB(sort_index(measure_i),:),...
                'FaceAlpha',0.2,'EdgeColor',[.9 .9 .9]);
        end % version
    end
    
    % annotate names of measures (smaller and in greyshade)
    for measure_i = 1:n_measures
        text(cumulated_benefit(measure_i)+cumulated_benefit(end)/x_text_control,...
            sorted_cb_ratio(measure_i), measures_impact.measures.name{sort_index(measure_i)},...
            ... %max(sorted_cb_ratio)/y_text_control, measures_impact.measures.name{sort_index(measure_i)},...
            'Rotation',90,'FontSize',fontsize_,'Color',[.5 .5 .5],'horizontalalignment','right ');
    end
    
    % show total unmitigated expected damage ED
    plot(measures_impact.ED(end)*fct,0,'o','MarkerSize',5,'Color',[255 127 36]/255); % orange circle on x-axis
    text(measures_impact.ED(end)*fct,max(sorted_cb_ratio)/y_text_control,'ED','Rotation',90,'FontSize',fontsize_,'Color',[255 127 36]/255);
    % show NPV of total climate risk TCR
    if isfield(measures_impact,'NPV_total_climate_risk')
        plot(measures_impact.NPV_total_climate_risk*fct,0,'o','MarkerSize',5,'Color',[169 169 169]/255); % grey circle on x-axis
        text(measures_impact.NPV_total_climate_risk*fct,max(sorted_cb_ratio)/y_text_control,'TCR','Rotation',90,'Color',[169 169 169]/255,'FontSize',fontsize_);
    end
    
    both_title_str{1} = title_str;
    comp_title_str    = strrep(comp_title_str,'_',' '); % since title is LaTEX format
    comp_title_str    = strrep(comp_title_str,'|','\otimes'); % LaTEX format
    both_title_str{2} = ['comparison ' comp_title_str];
    title(both_title_str,'FontSize',fontsize_);
    
end


plot([0 xmax],[1 1],':k');
xlim([0 xmax*1.1])
if called_from_play_adapt_cost_curve
    set(gca,'layer','top')
else
    set(subaxis(1),'layer','top')
end

box off
%axis tight % to get max area used

return
