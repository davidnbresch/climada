function [risk_today,risk_econ_growth,risk_climate_change]=climada_demo_waterfall_graph(climada_demo_params,omit_plot,nice_numbers)
% climada
% NAME:
%   climada_demo_waterfall_graph
% PURPOSE:
%   produce the waterfall graph for the climada GUI
%   (first time, it reads the demo entity from the Excel file demo_today.xls)
%   run the calculations and show the waterfall graph
%
%   see also: climada_demo_gui, normally called therefrom
% CALLING SEQUENCE:
%   climada_demo_waterfall_graph(climada_demo_params,omit_plot);
% EXAMPLE:
%   climada_demo_params.growth=0.02;climada_demo_params.scenario=1;
%   climada_demo_waterfall_graph(climada_demo_params);
% INPUTS:
%   climada_demo_params: a structure with the climada parameters the demo GUI allows to edit:
%       growth: the percentage, decimal (0.02 means 2% CAGR until 2030)
%       scenario: 0, 1 or 2 for no, moderate and high climate change
%      > ususally set in GUI, hard-coded for testing (if nothing handed over or empty)
% OPTIONAL INPUT PARAMETERS:
%   omit_plot: if =1, omit plotting (faster), degfault=0 (do plot)
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20110625
% David N. Bresch, david.bresch@gmail.com, 20130316, ELS->EDS...
% David N. Bresch, david.bresch@gmail.com, 20150402, area compatibility with version 8 (R2014...)
% David N. Bresch, david.bresch@gmail.com, 20150805, entity re-read from Excel if Excel edited (to allow for experimentation)
% David N. Bresch, david.bresch@gmail.com, 20150805, entity and hazard set files defined in climada_init_vars
% David N. Bresch, david.bresch@gmail.com, 20140816, automatic update if entity changed
%-

risk_today          = [];
risk_econ_growth    = [];
risk_climate_change = [];

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('climada_demo_params', 'var'), climada_demo_params = []; end
if ~exist('omit_plot'          , 'var'), omit_plot           = 0; end
if ~exist('nice_numbers'       , 'var'), nice_numbers        = 1; end


% PARAMETERS
%
fontsize_           = 8;
if ismac, fontsize_ = 11;end % larger font on Mac looks better

% entity used for the demo GUI (set in climada_init_vars, do not edit here):
climada_demo_entity_excel_file=climada_global.demo_gui.entity_excel_file;
[fP,fN]=fileparts(climada_demo_entity_excel_file);
climada_demo_entity_save_file=[fP filesep fN '.mat'];

% hazard sets to be used for the GUI (set in climada_init_vars, do not edit here)
hazard_present=climada_global.demo_gui.hazard_present;
hazard_moderate_change=climada_global.demo_gui.hazard_moderate_change;
hazard_high_change=climada_global.demo_gui.hazard_high_change;

if isempty(climada_demo_params) % set for simple TEST
    climada_demo_params.growth   = 0.02;
    climada_demo_params.scenario = 1;
end

% get the entity (note that climada_entity_read only reads if .xls is more
% recent than an eventually existing .mat)
entity_present = climada_entity_read(climada_demo_entity_excel_file,hazard_present);
% add reference_year
% entity_present.assets.reference_year = climada_global.present_reference_year;

% update entity (we start from entity_today, kind of the 'template')
% -------------
entity_future = entity_present;

% update growth
delta_years                = climada_global.future_reference_year - climada_global.present_reference_year;
growth_factor              = (1+climada_demo_params.growth)^delta_years;
entity_future.assets.Value = entity_present.assets.Value.*growth_factor;
entity_future.assets.Cover = entity_future.assets.Value;
% add reference_year
% entity_future.assets.reference_year = climada_global.future_reference_year;

%fprintf('CAGR of %2.1f%% leads to cumulated growth of %3.0f%% until %i\n',...
%    climada_demo_params.growth*100,...
%    growth_factor*100,climada_global.future_reference_year);


% trigger the re-calculation:
% ---------------------------

if climada_demo_params.scenario == 0
    hazard_future = hazard_present;
elseif climada_demo_params.scenario == 1
    hazard_future = hazard_moderate_change;
elseif climada_demo_params.scenario == 2
    hazard_future = hazard_high_change;
end % climada_demo_params.scenario

EDS_present         = climada_EDS_calc(entity_present, hazard_present, 'present');
EDS_economic_growth = climada_EDS_calc(entity_future , hazard_present, 'present');
EDS_future          = climada_EDS_calc(entity_future , hazard_future , 'present');

risk_today          = EDS_present.ED;
risk_econ_growth    = EDS_economic_growth.ED - EDS_present.ED;
risk_climate_change = EDS_future.ED          - EDS_economic_growth.ED;
total_climate_risk  = EDS_future.ED;

%fprintf(' \t risk today \t\t\t %2.2e\n \t risk_econ_growth \t\t %2.2e\n \t risk_climate_change \t %2.2e\n \t total_climate_risk \t %2.2e\n',...
%    risk_today,risk_econ_growth,risk_climate_change,total_climate_risk);

if ~omit_plot
    
    if nice_numbers
        factor     = 10^-8; %for nice numbers
        ylabel_str = 'Expected damage (Mio USD)';
    else
        factor     = 1;
        ylabel_str = 'Expected damage (USD)';
    end
        
    eco_label   = {'Low' 'Middle' 'High'};
    cc_label    = {'No'  'Middle' 'High'};
    slider2_max = 0.05;
    slider2_min = 0.01;
    eco_index   = round((climada_demo_params.growth-slider2_min)/(slider2_max-slider2_min)*(length(eco_label)-1))+1;
    cc_index    = climada_demo_params.scenario+1;
    xticklabel_ = {'', eco_label{eco_index}, cc_label{cc_index},''};
    % plotting
    % --------
    
    % the primitive way (no waterfall)
    % bar([risk_today,risk_today+risk_econ_growth,...
    %     risk_today+risk_econ_growth+risk_climate_change,...
    %     risk_today+risk_econ_growth+risk_climate_change]);
    % set(gca,'XTickLabel',{'risk today','economic growth','climate change','total climate risk'});
    % ylabel('expected damage')
    plot([0,5],[0,total_climate_risk]*factor,'.w');
    hold on; %axis off
    
    for box_i=1:4
        if box_i==1
            x = [0,1];
            y = [risk_today,risk_today]*factor;
            level     = 0*factor;
            FaceColor = [255 215   0]/255; %yellow
            textcolor = 'k';
            %FaceColor = [224 238 224 ]/255; grey %FaceColor = [0.3 0.01 .0];
        end
        if box_i==2 %economic growth
            x = [1.5,2.5];
            y = [risk_today+risk_econ_growth,risk_today+risk_econ_growth]*factor;
            level     = risk_today*factor;
            FaceColor = [255 127   0 ]/255; %orange
            textcolor = 'w';
            %FaceColor = [180 238 180  ]/255;light green %[205 201 165]/255; %FaceColor = [0.5 .1 .1];
        end
        if box_i==3 %climate change
            x = [3,4];
            y = [total_climate_risk,total_climate_risk]*factor;
            level     = (risk_today+risk_econ_growth)*factor;
            FaceColor = [238  64   0 ]/255; %dark orange
            textcolor = 'w';
            %FaceColor = [155 205 155 ]/255; %green %FaceColor = [0.8 .1 .1];
        end
        if box_i==4
            x = [4.5,5.5];
            y = [total_climate_risk,total_climate_risk]*factor;
            level     = 0*factor;
            FaceColor = [205   0   0 ]/255; %red
            textcolor = 'w';
            %FaceColor = [105 139 105 ]/255; %dark green %FaceColor = [0.9 .1 .1];
        end
        %%FaceColor=FaceColor/max(FaceColor);
        %area('v6',x,y,level,'FaceColor',FaceColor,'EdgeColor',FaceColor);
        %area(x,y,level,'FaceColor',FaceColor,'EdgeColor',FaceColor);
        area(x,y,'BaseValue',level,'FaceColor',FaceColor,'EdgeColor',FaceColor);
        if level>0,area(x,[level level],'BaseValue',0,'FaceColor',[1 1 1],'EdgeColor',[1 1 1]);end
        text(mean(x), y(1)*0.9, num2str(y(1)-level(1),'%2.0f'),'horizontalalignment','center','fontweight','bold','color',textcolor)
    end % box_i
    xlim([-0.2 5.7])
    hold on
    set(gca,'XTick',[0.5,2,3.5,5]);
    set(gca,'XTickLabel',xticklabel_,'fontsize',fontsize_);
    ylim_  = get(gca,'ylim');
    text_y = -diff(ylim_)*0.1;
    
    text(0.5, text_y, 'Risk today'        ,'fontsize',fontsize_, 'horizontalalignment','center')
    text(2.0, text_y, 'economic growth'   ,'fontsize',fontsize_, 'horizontalalignment','center')
    text(3.5, text_y, 'climate change'    ,'fontsize',fontsize_, 'horizontalalignment','center')
    text(5.0, text_y, 'Total climate risk','fontsize',fontsize_, 'horizontalalignment','center')
    
    ylabel(ylabel_str)
    %axis tight
    box off
    set(gca,'XGrid','off')
    set(gca,'TickLength',[0,0],'layer','top')
end

return
