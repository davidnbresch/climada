function [insurance_benefit,insurance_cost,params]=climada_cost_curve(measures_impact,params)
% climada measures impact climate adaptation cost curve
% NAME:
%   climada_cost_curve
% PURPOSE:
%   plot adaptation cost curve, color measures according to benefit/cost
%   ratio (see measures_impact.color_keep to keep colors as defined in
%   measures)
%
%   see also: climada_adaptation_event_view
%
%   NOTE: The mode with output arguments insurance_benefit and
%   insurance_cost is only used when called from climada_demo (the flag
%   params.called_from_climada_demo), no relevance for standard use.
%
%   Previous call climada_measures_impact
%   or read benefits directly from excel file with climada_measures_read
% CALLING SEQUENCE:
%   [insurance_benefit,insurance_cost,params]=climada_cost_curve(measures_impact,params)
% EXAMPLE:
%   % obtain an entity and calculate impact of measures to display:
%   demo_entity=climada_entity_read('demo_today','TCNA_today_small');
%   measures_impact   =climada_measures_impact(demo_entity,'TCNA_today_small'   ,'no');
%   measures_impact(2)=climada_measures_impact(demo_entity,'TCNA_2030med_small' ,measures_impact(1));
%   measures_impact(3)=climada_measures_impact(demo_entity,'TCNA_2030high_small',measures_impact(1));
%   climada_cost_curve(measures_impact)
%   params=climada_cost_curve('params') % to return default parameters
% INPUTS:
%   measures_impact: either a struct containing the impacts of measures or
%       a measures_impact file (.mat with a struct) see climada_measures_impact
%       > promted for if not given
%       If theres is a field measures_impact.y_axis_max, it defines the
%       maximum of the vertical axis (to shape plots comparable). There are
%       no checks any more, hence if you provide a stange number, you get a
%       strange vertical scale ;-)
%       If theres is a field measures_impact.x_axis_max, it defines the
%       maximum of the horizontal axis (to shape plots comparable).
%       If there is a field measures_impact.color_keep, the colors as
%       defined in measures are kept, otherwise nice colors are assigned.
%       if ='params', just return default parameters

%   measures_impact_comparison: same as measures_impact, but for comparison
%       (will be shown in overlay). Not prompted for, so please specify in
%       call, or enter 'ASK' in climada_cost_curve('','ASK')
%       If there is a field measures_impact_comparison.label_comparison,
%       it defines whether comparison wll be labeld (=1, default) or not (=0)
%       If =0, also do not label TCR (total climate risk) for comparison
%       These setting are usually good for decluttered plots for presentations

% OPTIONAL INPUT PARAMETERS:
%   params: a structure with fields (see also entity='params' above):
%    reverse_cb: (=1, default) show benefit per cost
%       Set =0 to show cost/beenfit
%    plot_arrows: whether we do (=1) or don't (=0, default) plot arrows
%       underneath the x-axis to show cost-effective measures and
%       non-cost-effective measures extent.
%    annotate_measures: whether we label the measures (=1, default) or not
%    y_text_control: controls the vertical distribution of the text labels
%       (divider of the length of the y-axis, default=50)
%    xlabel_str: the label of the x-axis
%    FaceAlpha: the transparency of the plot (default=1, no transparency)
%    EdgeColor: the color of the edge of the boxes, default ='none', but
%       could be color a triple, such as =[.9 .9 .9] 
%    called_from_climada_demo: internal use
% OUTPUTS:
%   insurance_benefit and insurance_cost: only used when called from
%       climada_play_adapt_cost_curve, see there (in essence to write
%       insurance cost on the GUI). For illustrative purposes only!
%   params: the params structure with the values set and/or used
%       this way, some paramters that are defined based upon content of
%       measures_impact can be modified for subsequent calls.
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20170828, complete overhaul, based on old climada_adaptation_cost_curve
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('measures_impact', 'var'), measures_impact = []; end
if ~exist('params','var'),           params          = struct;end

% check for some parameter fields we need
if ~isfield(params,'called_from_climada_demo'), params.called_from_climada_demo=[];end
if ~isfield(params,'reverse_cb'),               params.reverse_cb=[];end
if ~isfield(params,'plot_arrows'),              params.plot_arrows=[];end
if ~isfield(params,'annotate_measures'),        params.annotate_measures=[];end
if ~isfield(params,'xlabel_str'),               params.xlabel_str=[];end
if ~isfield(params,'y_text_control'),           params.y_text_control=[];end
if ~isfield(params,'FaceAlpha'),                params.FaceAlpha=[];end
if ~isfield(params,'EdgeColor'),                params.EdgeColor=[];end


% PARAMETERS
%
% set defaults
if isempty(params.called_from_climada_demo), params.called_from_climada_demo=0;end
if isempty(params.reverse_cb),        params.reverse_cb        =  1;end
if isempty(params.plot_arrows),       params.plot_arrows       =  0;end
if isempty(params.annotate_measures), params.annotate_measures =  1;end
% params.xlabel_str defined based on content of measures_impact
if isempty(params.y_text_control),    params.y_text_control    = 50;end
if isempty(params.FaceAlpha),         params.FaceAlpha         =  1;end % transparency
if isempty(params.EdgeColor),         params.EdgeColor         =  'none';end
%
% some dependencies between 
if nargout>0,params.called_from_climada_demo=1;end % called from climada_play_adapt_cost_curve
%
% some internal defaults
add_insurance_measure = 0; % see below, only used if called from climada_demo GUI
%
% set some fonts
fontsize_             = 8.5*climada_global.font_scale;
if ismac, fontsize_   = 12 *climada_global.font_scale;end % 20140516, was 8, too small


% just return (default) paramters if called wit no inputs
if strcmpi(measures_impact,'params'),insurance_benefit=params;return;end

% prompt for measures_impact if not given
if ~isstruct(measures_impact),measures_impact = climada_measures_impact_load(measures_impact);end

% figure how many sets of measures we have
n_impacts=length(measures_impact);

% (recursively) loop
if n_impacts>1
    fprintf('overlay with %i sets of measures\n',n_impacts);
    max_xlim=[];max_ylim=[]; % init
    params.FaceAlpha=1/n_impacts; % set transparency
    params.FaceAlpha
    
    for impacts_i=1:n_impacts
        if impacts_i>1,hold on;end % to add
        climada_cost_curve(measures_impact(impacts_i),params)
        
        % make sure we keep max boundaries
        xlim_=xlim;if isempty(max_xlim),max_xlim=xlim_;end
        max_xlim(1)=min(max_xlim(1),xlim_(1));
        max_xlim(2)=min(max_xlim(2),xlim_(2));
        ylim_=ylim;if isempty(max_ylim),max_ylim=ylim_;end
        max_ylim(1)=min(max_ylim(1),ylim_(1));
        max_ylim(2)=min(max_ylim(2),ylim_(2));
    end % impacts_i
    
    xlim(max_xlim);ylim(max_ylim);
    hold off;drawnow
    
else % one measures_impact, process it
    
    % complete some fields
if ~isfield(measures_impact,'x_axis_max'),measures_impact.x_axis_max=[];end
if ~isfield(measures_impact,'y_axis_max'),measures_impact.y_axis_max=[];end
if ~isfield(measures_impact,'color_keep'),measures_impact.color_keep=0;end

tot_climate_risk  = measures_impact.NPV_total_climate_risk; % shorter name

% some parameters
n_years           = climada_global.future_reference_year - climada_global.present_reference_year + 1;
params.xlabel_str = sprintf('NPV averted damage over %d years (%s)',n_years,measures_impact.Value_display_unit_name);

% convert to display units
% only local, avoids very long lines with conversion factors
measures_impact.cb_ratio      = measures_impact.cb_ratio; % no conversion
measures_impact.benefit       = measures_impact.benefit      *measures_impact.Value_display_unit_fact;
measures_impact.ED            = measures_impact.ED           *measures_impact.Value_display_unit_fact;
tot_climate_risk              = tot_climate_risk             *measures_impact.Value_display_unit_fact;
measures_impact.measures.cost = measures_impact.measures.cost*measures_impact.cost_display_unit_fact;
measures_impact.risk_transfer = measures_impact.risk_transfer*measures_impact.cost_display_unit_fact;

if params.called_from_climada_demo % only if called from climada_demo GUI
    add_insurance_measure = 1;
    fontsize_             = 10; % =8 until 20160427
    if ismac, fontsize_   = 11;end % 20140516, was 8, too small
    params.xlabel_str = sprintf('Averted damage (%s)',measures_impact.Value_display_unit_name);
    scale_factor = measures_impact.ED(end)/tot_climate_risk;
    scale_factor=scale_factor/100; % MAGIC, 20160429
    measures_impact.measures.cost = bsxfun(@times, measures_impact.measures.cost, scale_factor);
    measures_impact.risk_transfer = bsxfun(@times, measures_impact.risk_transfer, scale_factor);
    measures_impact.benefit       = bsxfun(@times, measures_impact.benefit      , scale_factor);
    tot_climate_risk  = bsxfun(@times, tot_climate_risk, scale_factor);
end

if add_insurance_measure % NOTE: this section not relevant for lecture
    % cover residual damage with insurance
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
    
    % convert to cost display units
    insurance_cost=insurance_cost/measures_impact.Value_display_unit_fact*measures_impact.cost_display_unit_fact;
end

% correct risk transfer to not cover more than actual climate risk (climada_demo)
risk_transfer_idx = strcmp(measures_impact.measures.name,'risk transfer');
if any(risk_transfer_idx) && sum(measures_impact.benefit)>tot_climate_risk
    fprintf('Risk transfer is corrected to cover only actual climate risk.\n')
    measures_impact.benefit(risk_transfer_idx)  = tot_climate_risk - sum(measures_impact.benefit(~risk_transfer_idx));
end

title_str                    = measures_impact.title_str;
[sorted_cb_ratio,sort_index] = sort(measures_impact.cb_ratio);
CostBenefit_str='Cost/Benefit';
if params.reverse_cb
    sorted_cb_ratio= 1./sorted_cb_ratio;
    CostBenefit_str='Benefit/Cost';
end

if ~measures_impact.color_keep
    try
        cmap = climada_colormap('measures',numel(measures_impact.measures.name));
        measures_impact.measures.color_RGB(:,sort_index) = cmap;
    catch
        fprintf('WARNING: automatic color assignment failed, colors as defined in measures used\n');
    end
end

% print results to stdout
% -----------------------
fprintf('\n%s :\n',title_str);
n_measures = length(measures_impact.measures.cost);
fprintf(' Measure 		   Cost (%s)  Benefit (%s)  %s\n',...
    measures_impact.cost_display_unit_name,measures_impact.Value_display_unit_name,CostBenefit_str);
for measure_i = 1:n_measures
    m_name = [measures_impact.measures.name{measure_i} '                    '];
    m_name = m_name(1:25);
    fprintf(' %s %4.2g            %4.2g               %4.2g\n',m_name,...
        (measures_impact.measures.cost(measure_i)+measures_impact.risk_transfer(measure_i)),...
        measures_impact.benefit(measure_i),sorted_cb_ratio(measure_i));
end % measure_i
if add_insurance_measure % NOTE: this section not relevant for lecture
    if params.reverse_cb,insurance_cb=1./insurance_cb;end
    fprintf(' *Covered by insurance     %4.2g            %4.2g               %4.2g\n',...
        insurance_cost, insurance_benefit, insurance_cb);
    sorted_cb_ratio = [sorted_cb_ratio insurance_cb];
else
    fprintf(' *Residual damage                         *%4.2g*\n',tot_climate_risk-sum(measures_impact.benefit));
end

cumulated_benefit = [0, cumsum(measures_impact.benefit(sort_index)),  tot_climate_risk];

% put together the adaptation cost curve
% --------------------------------------
xmax = max(cumulated_benefit); % dummy plot to start with
if ~isempty(measures_impact.x_axis_max),xmax = measures_impact.x_axis_max;end
ymax = max([max(sorted_cb_ratio),1.1]);
if ~isempty(measures_impact.y_axis_max),ymax = measures_impact.y_axis_max;end
plot([0,xmax],[ymax,ymax],'.w'); hold on
set(gca,'FontSize',fontsize_);
if ~params.called_from_climada_demo,set(gcf,'Color',[1 1 1]);end
xlabel(params.xlabel_str,'fontsize',fontsize_+1)
%ylabelstr = sprintf('%s ratio (%s/%s)',CostBenefit_str,measures_impact.Value_display_unit_name,measures_impact.cost_display_unit_name);
ylabelstr = sprintf('%s ratio (%s/%s)',CostBenefit_str,measures_impact.Value_unit,measures_impact.cost_unit);
ylabel(ylabelstr,'fontsize',fontsize_+1)

% plot measures
for measure_i = 1:n_measures+add_insurance_measure
    if measure_i == n_measures+1 % insurance cover, only if called from climada_play_adapt_cost_curve
        % NOTE: this section not relevant for lecture
        area(cumulated_benefit(measure_i:measure_i+1), [insurance_cb, insurance_cb],...
            'FaceColor',[193 193 193 ]/255,'EdgeColor','w'); %grey
    else        
            
        patch([cumulated_benefit(measure_i:measure_i+1) cumulated_benefit(measure_i+1:-1:measure_i)],...
            [0 0 sorted_cb_ratio(measure_i) sorted_cb_ratio(measure_i)],...
            measures_impact.measures.color_RGB(:,sort_index(measure_i))',... % transposed 20170828
            'FaceAlpha',params.FaceAlpha,'EdgeColor',params.EdgeColor);
        
%         area(cumulated_benefit(measure_i:measure_i+1),...
%             [sorted_cb_ratio(measure_i), sorted_cb_ratio(measure_i)],...
%             'FaceColor',measures_impact.measures.color_RGB(:,sort_index(measure_i)),'EdgeColor','w');

    end
end

if params.annotate_measures
    % annotate names of measures
    for measure_i = 2:n_measures+1 %first entry = 0
        if ~isnan(sorted_cb_ratio(measure_i-1))
            text(cumulated_benefit(measure_i)-(cumulated_benefit(measure_i)-cumulated_benefit(measure_i-1))/2,...
                max(sorted_cb_ratio)/params.y_text_control,...
                [measures_impact.measures.name{sort_index(measure_i-1)},...
                '  (', num2str(sorted_cb_ratio(measure_i-1),'%2.1f'),')'], 'Rotation',90,'FontSize',fontsize_);
        end
    end
end

if ~params.called_from_climada_demo && params.annotate_measures
    
    % show net present value of total climate risk
    plot(tot_climate_risk,0,'d','color',[205 0 0]/255,'markerfacecolor',[205 0 0]/255,'markersize',10)
    tcr_str = sprintf('Total climate risk\n %.0f %s',tot_climate_risk,measures_impact.Value_display_unit_name);
    text(tot_climate_risk*0.93,max(sorted_cb_ratio)/params.y_text_control, tcr_str,...
        'HorizontalAlignment','center','VerticalAlignment','bottom','fontsize',fontsize_,'color',[205 0 0]/255)
    
    % show total unmitigated expected damage ED
    plot(measures_impact.ED(end),0,'o','MarkerSize',5,'Color',[255 127 36]/255); % orange circle on x-axis
    text(measures_impact.ED(end),max(sorted_cb_ratio)/params.y_text_control,'ED','Rotation',90,'FontSize',fontsize_,'Color',[255 127 36]/255);
end

if add_insurance_measure && params.annotate_measures % NOTE: this section not relevant for lecture
    %insurance to cover residual damage
    measure_i = measure_i+1;
    text(cumulated_benefit(measure_i)-(cumulated_benefit(measure_i)-cumulated_benefit(measure_i-1))/2,...
        max(sorted_cb_ratio)/params.y_text_control,...
        ['Insurance','  (', num2str(sorted_cb_ratio(measure_i-1),'%2.1f'),')'], 'Rotation',90,'FontSize',fontsize_);
end

if params.plot_arrows
    % arrow below graph to indicate cost-efficient adaptation and residual damage
    if params.called_from_climada_demo
        y_ = -max(sorted_cb_ratio)*1.2*0.18;
        arrow_width  = 10;
        arrow_length = 10;
    else
        y_ = -max(sorted_cb_ratio)*1.2*0.14;
        arrow_width  = 15;
        arrow_length = 15;
    end
    s_ = 0.5;
    if params.reverse_cb
        m_cost_eff = sum(sorted_cb_ratio>=1)+1;
    else
        m_cost_eff = sum(sorted_cb_ratio<=1)+1;
    end
    climada_arrow([cumulated_benefit(end) y_*1.0], [cumulated_benefit(m_cost_eff)+s_/2 y_*1.0],...
        'width',arrow_width,'Length',arrow_length, 'BaseAngle',90, 'TipAngle',50,'EdgeColor','none', 'FaceColor',[205 0 0]/255);
    if add_insurance_measure
        text(mean(cumulated_benefit([end end-1])),y_, 'Non-cost-effective','color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_-1,'fontweight','bold');
    else
        climada_arrow([cumulated_benefit(m_cost_eff) y_*1.0], [cumulated_benefit(end-1)+s_/2 y_*1.0],...
            'width',arrow_width-9,'Length',arrow_length-5, 'BaseAngle',90, 'TipAngle',50,'EdgeColor','none', 'FaceColor',[255 127   0]/255);
        text((cumulated_benefit(m_cost_eff)+cumulated_benefit(end-1))/2,y_, 'Non-cost-efficient'       ,'color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_-1,'fontweight','bold');
        text(mean(cumulated_benefit([end end-1])),y_, 'Residual damage','color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_-1,'fontweight','bold');
    end
    if cumulated_benefit(m_cost_eff)>0
        climada_arrow([0 y_], [cumulated_benefit(m_cost_eff)-s_/2 y_],...
            'width',arrow_width,'Length',arrow_length, 'BaseAngle',90, 'TipAngle',50,'EdgeColor','none', 'FaceColor',[0 197 205]/255);
        text(cumulated_benefit(m_cost_eff)/2,y_, 'Cost-effective','color','w','HorizontalAlignment','center','VerticalAlignment','middle','fontsize',fontsize_-1,'fontweight','bold');
    end
    ylim([0 max(sorted_cb_ratio)*1.1])
    xlim([0 max(cumulated_benefit)*1.03]) % was commented already
    if ~isempty(measures_impact.x_axis_max),xlim([0 measures_impact.x_axis_max]);end
    if ~isempty(measures_impact.y_axis_max),ylim([0 measures_impact.y_axis_max]);end
end

% add title
title_str=strrep(title_str,'_',' '); % since title is LaTEX format
title_str=strrep(title_str,'|','\otimes'); % LaTEX format
title(title_str,'FontSize',fontsize_);
set(gcf,'Color',[1 1 1]); % white background

% % to scale such that the plot comprises both
% xmax = max([xmax, cumulated_benefit(end)]);
% if ~isempty(measures_impact.x_axis_max),xmax = measures_impact.x_axis_max;end
% ymax = max([max(sorted_cb_ratio),1.1,ymax]);
% if ~isempty(measures_impact.y_axis_max),ymax = measures_impact.y_axis_max;end
% hold on; plot([0,xmax],[ymax,ymax],'.w');
    


% 
% % comparison scenario
% if ~isempty(measures_impact_comparison)
%     
%     % Overlay with a second EDS for comparison - but scaling
%     % etc is kept. EDS must be for same measures (not checked, assumed
%     % expert user is really an expert)
%     
%     if ~isstruct(measures_impact_comparison)
%         measures_impact_comparison_file = measures_impact_comparison;
%         clear measures_impact_comparison
%         load(measures_impact_comparison_file);
%     else
%         measures_impact = measures_impact_comparison;
%     end
%     
%     if ~isfield(measures_impact,'x_axis_max'),measures_impact.x_axis_max=[];end
%     if ~isfield(measures_impact,'y_axis_max'),measures_impact.y_axis_max=[];end
%     if ~isfield(measures_impact,'color_keep'),measures_impact.color_keep=0;end
%     if ~isfield(measures_impact_comparison,'label_comparison'),measures_impact_comparison.label_comparison=1;end % default to label
%     
%     % NOTE: measures_impact holds now the impacts for comparison! (load overloaded this)
%     
%     % convert to display units
%     % only local, avoids very long lines with conversion factors
%     measures_impact.cb_ratio = measures_impact.cb_ratio;
%     measures_impact.benefit  = measures_impact.benefit *measures_impact.Value_display_unit_fact;
%     measures_impact.ED       = measures_impact.ED      *measures_impact.Value_display_unit_fact;
%     measures_impact.measures.cost = measures_impact.measures.cost*measures_impact.cost_display_unit_fact;
%     measures_impact.risk_transfer = measures_impact.risk_transfer*measures_impact.cost_display_unit_fact;
%     tot_climate_risk         = measures_impact.NPV_total_climate_risk*measures_impact.Value_display_unit_fact;
%     
%     comp_title_str = measures_impact.title_str;
%     fprintf('\ncomparison %s :\n',comp_title_str);
%     n_measures     = length(measures_impact.measures.cost);
%     
%     if params.called_from_climada_demo
%         measures_impact.measures.cost = bsxfun(@times, measures_impact.measures.cost, scale_factor);
%         measures_impact.risk_transfer = bsxfun(@times, measures_impact.risk_transfer, scale_factor);
%         measures_impact.benefit       = bsxfun(@times, measures_impact.benefit      , scale_factor);
%         %total climate risk
%         tot_climate_risk              = bsxfun(@times, tot_climate_risk, scale_factor);
%     end % params.called_from_climada_demo
%     
%     [sorted_cb_ratio,sort_index] = sort(measures_impact.cb_ratio);
%     if params.reverse_cb,sorted_cb_ratio=1./sorted_cb_ratio;end
%     cumulated_benefit            = [0, cumsum(measures_impact.benefit(sort_index)),  tot_climate_risk];
%     
%     % print results to stdout
%     % -----------------------
%     fprintf(' Measure 		   Cost (%s)  Benefit (%s)  %s\n',...
%         measures_impact.cost_display_unit_name,measures_impact.Value_display_unit_name,CostBenefit_str);
%     for measure_i = 1:n_measures
%         m_name = [measures_impact.measures.name{measure_i} '                    '];
%         m_name = m_name(1:25);
%         fprintf(' %s %4.2g            %4.2g               %4.2g\n',m_name,...
%             (measures_impact.measures.cost(measure_i)+measures_impact.risk_transfer(measure_i)),...
%             measures_impact.benefit(measure_i),sorted_cb_ratio(measure_i));
%     end % measure_i
%     fprintf(' *Residual damage                         *%4.2g*\n\n',tot_climate_risk-sum(measures_impact.benefit));
%     
%     % plot measures (semi-transparent)
%     % --------------------------------
%     % to scale such that the plot comprises both
%     xmax = max([xmax, cumulated_benefit(end)]);
%     if ~isempty(measures_impact.x_axis_max),xmax = measures_impact.x_axis_max;end
%     ymax = max([max(sorted_cb_ratio),1.1,ymax]);
%     if ~isempty(measures_impact.y_axis_max),ymax = measures_impact.y_axis_max;end
%     hold on; plot([0,xmax],[ymax,ymax],'.w');
%     
%     version_no=str2double(strsplit(version,'.'));version_no=version_no(1);% get main version number
%     for measure_i = 1:n_measures
%         if version_no>6 % for version 7 and later
%             patch([cumulated_benefit(measure_i:measure_i+1) cumulated_benefit(measure_i+1:-1:measure_i)],... %
%                 [0 0 sorted_cb_ratio(measure_i) sorted_cb_ratio(measure_i)],...
%                 measures_impact.measures.color_RGB(:,sort_index(measure_i)),...
%                 'FaceAlpha',0.2, 'EdgeColor',[.9 .9 .9]);
%         else % reverse compatibility
%             % area('v6',...) creates patch objects instead of areaseries
%             % objects for compatibility with MATLAB 6.5 and earlier.
%             area('v6',cumulated_benefit(measure_i:measure_i+1),... %
%                 [sorted_cb_ratio(measure_i),sorted_cb_ratio(measure_i)],...
%                 'FaceColor',measures_impact.measures.color_RGB(:,sort_index(measure_i)),...
%                 'FaceAlpha',0.2,'EdgeColor',[.9 .9 .9]);
%         end % version
%     end
%     
%     fontsize_comparison=ceil(fontsize_*.8);
%     if measures_impact_comparison.label_comparison
%         % annotate names of measures (smaller and in greyshade)
%         % annotate names of measures
%         for measure_i = 2:n_measures+1 %first entry = 0
%             if ~isnan(sorted_cb_ratio(measure_i-1))
%                 text(cumulated_benefit(measure_i)-(cumulated_benefit(measure_i)-cumulated_benefit(measure_i-1))/2,...
%                     max(sorted_cb_ratio)/params.y_text_control,...
%                     [measures_impact.measures.name{sort_index(measure_i-1)},...
%                     '  (', num2str(sorted_cb_ratio(measure_i-1),'%2.1f'),')'], 'Rotation',90,'FontSize',fontsize_,'Color',[.5 .5 .5]);
%             end
%         end
%     end % measures_impact_comparison.label_comparison
%     
%     % show total unmitigated expected damage ED
%     if measures_impact_comparison.label_comparison
%         plot(measures_impact.ED(end),0,'o','MarkerSize',5,'Color',[.5 .5 .5]); % circle on x-axis
%         text(measures_impact.ED(end),max(sorted_cb_ratio)/params.y_text_control,'ED','Rotation',90,'FontSize',fontsize_comparison,'Color',[.5 .5 .5]);
%         plot(tot_climate_risk,0,'d','MarkerSize',5,'Color',[169 169 169]/255); % diamond on x-axis
%         text(tot_climate_risk,max(sorted_cb_ratio)/params.y_text_control,'TCR','Rotation',90,'Color',[.5 .5 .5],'FontSize',fontsize_comparison);
%     end % measures_impact_comparison.label_comparison
%     
%     both_title_str{1} = title_str;
%     comp_title_str    = strrep(comp_title_str,'_',' '); % since title is LaTEX format
%     comp_title_str    = strrep(comp_title_str,'|','\otimes'); % LaTEX format
%     both_title_str{2} = ['comparison ' comp_title_str];
%     title(both_title_str,'FontSize',fontsize_);
%     
% end % ~isempty(measures_impact_comparison)

if params.called_from_climada_demo % only if called from climada_demo GUI
    % convert output back to original units
    insurance_benefit = insurance_benefit/measures_impact.Value_display_unit_fact*100;
    insurance_cost    = insurance_cost   /measures_impact.Value_display_unit_fact*100;
end % params.called_from_climada_demo

% to see the x- and y-ticks
set(gca, 'Layer','top')

end % climada_cost_curve