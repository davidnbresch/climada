function AEV = climada_adaptation_event_view(measures_impact,comparison_return_periods)
% climada measures impact climate adaptation damage frequency effect
% NAME:
%   climada_adaptation_event_view
% PURPOSE:
%   show the effect of measures for events of different return periods
%   see also: climada_adaptation_cost_curve
% CALLING SEQUENCE:
%   climada_adaptation_event_view(measures_impact,comparison_return_periods)
% EXAMPLE:
%   climada_adaptation_event_view(climada_measures_impact(climada_entity_read)) % from scratch
% INPUTS:
%   measures_impact: either a struct containing the impacts of measures or a measures_impact file (.mat with a struct)
%       see climada_measures_impact
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   comparison_return_periods: the list of return periods to show the
%       comparison for, default is [10 25 100]
% OUTPUTS:
%   graph, and AEV, a stucture which holds the data of the graph:
%       damage(measure_i,return_period_i): the damage for measure_i at return_period_i
%           damage(end,return_period_i) holds the damage with no measures
%       return_period(return_period_i): the list of return periods
%       frequency(return_period_i): the list of frequencies
%       effect(measure_i,return_period_i): the effect of measure_i at return_period_i
%       total_effect(return_period_i): the total effect of all measures at return_period_i
%       cumulated(return_period_i): for each return period, a struct,with
%           effect(measure_i): the cumulated effect up to measure i
%           NOTE: measures ordered as in adaptation cost curve
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20100109
% David N. Bresch, david.bresch@gmail.com, 20150402, compatibility with version 8ff (R2014...)
% David N. Bresch, david.bresch@gmail.com, 20151021, checked to work for index insurance, too
% Lea Mueller, muellele@gmail.com, 20151125, correct 'FaceColor' issue for version 8
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('measures_impact','var'),measures_impact=[];end
if ~exist('comparison_return_periods','var'),comparison_return_periods=[];end

% PARAMETERS
%
% set default comparison return periods
if isempty(comparison_return_periods),comparison_return_periods=[10 25 100];end

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
    measures_impact_file=measures_impact;measures_impact=[];
    load(measures_impact_file);
end

fontsize_ = 12*climada_global.font_scale;

title_str=measures_impact.title_str;
%fprintf('%s\n',title_str);

% construct the DFC for each EDS, store at pre-defined points
n_EDS=length(measures_impact.EDS);
DFC_comparison_frequencies=1./comparison_return_periods;
AEV.damage=zeros(n_EDS,length(DFC_comparison_frequencies)); % allocate
AEV.return_period=comparison_return_periods;
AEV.frequency=DFC_comparison_frequencies;
for EDS_i=1:n_EDS
    [sorted_damage,exceedence_freq]=climada_damage_exceedence(measures_impact.EDS(EDS_i).damage,measures_impact.EDS(EDS_i).frequency);
    AEV.damage(EDS_i,:)=interp1(exceedence_freq,sorted_damage,DFC_comparison_frequencies);
end % EDS_i

n_measures=length(measures_impact.measures.cost);

% calculate the effect of each measure
AEV.effect=zeros(n_measures-1,length(DFC_comparison_frequencies)); % allocate
AEV.total_effect=zeros(1,length(DFC_comparison_frequencies));
for measure_i=1:n_measures
    AEV.effect(measure_i,:)=AEV.damage(end,:)-AEV.damage(measure_i,:);
    AEV.total_effect=AEV.total_effect+AEV.effect(measure_i,:);
end

% the same sort order as in adaptation cost curve
[~,sort_index] = sort(measures_impact.cb_ratio);

for return_period_i=1:length(comparison_return_periods)
    AEV.cumulated{return_period_i}.effect=[0;cumsum(AEV.effect(sort_index,return_period_i))]';
end % return_period_i

% a dummy plot to open the figure and set the axes
xmax=length(comparison_return_periods);
ymax=max(max(AEV.damage));
plot([0,xmax],[ymax,ymax],'.w'); hold on
set(gcf,'Color',[1 1 1]); % set background color white
set(gca,'FontSize',fontsize_);
xlabel('return period')
ylabel('event damage amount')

version_str=version;
for return_period_i=1:length(comparison_return_periods)
    XTickLabel{return_period_i}=num2str(comparison_return_periods(return_period_i));
    x1=return_period_i-1;
    x2=return_period_i;
    
    % plot each measure
    if strcmp(version_str(1),'6') || climada_global.octave_mode
        for measure_i=n_measures:-1:1
            area([x1 x2],...
                [AEV.cumulated{return_period_i}.effect(measure_i+1),AEV.cumulated{return_period_i}.effect(measure_i+1)],...
                'FaceColor',measures_impact.measures.color_RGB(sort_index(measure_i),:),'EdgeColor','none');
        end % measure_i
        
    elseif strcmp(version_str(1),'7')
        for measure_i=1:n_measures
            area([x1 x2],...
                [AEV.cumulated{return_period_i}.effect(measure_i+1),AEV.cumulated{return_period_i}.effect(measure_i+1)],...
                'BaseValue',AEV.cumulated{return_period_i}.effect(measure_i+1),...
                'FaceColor',measures_impact.measures.color_RGB(sort_index(measure_i),:),'EdgeColor','none');
        end % measure_i
        
    else % version 8 and later
        Y=[];
        for measure_i=1:n_measures
            yy=AEV.cumulated{return_period_i}.effect(measure_i+1)-AEV.cumulated{return_period_i}.effect(measure_i);
            Y(1,measure_i)=yy;Y(2,measure_i)=yy;
            h=area([x1 x2],Y,'BaseValue',0,'EdgeColor','none');hold on
        end % measure_i
        for measure_i=1:n_measures
            color = measures_impact.measures.color_RGB(sort_index(measure_i),:);
            set(h(measure_i),'FaceColor',color)
            % this does not work for version 8
            %h(measure_i).FaceColor = measures_impact.measures.color_RGB(sort_index(measure_i),:);
        end % measure_i
    end % version
    
    % plot the total damage
    area([x1 x2],...
        [AEV.damage(end,return_period_i),AEV.damage(end,return_period_i)],...
        'FaceColor','none','EdgeColor',[0 0 0]);
end % return_period_i

% annotate names of measures
for measure_i=1:n_measures
    y_pos=(AEV.cumulated{end}.effect(measure_i)+AEV.cumulated{end}.effect(measure_i+1))/2;
    text(length(comparison_return_periods)-0.9,y_pos,...
        measures_impact.measures.name{sort_index(measure_i)},'Rotation',0,'fontsize',fontsize_);
    if length(comparison_return_periods)>1
        y_pos=(AEV.cumulated{end-1}.effect(measure_i)+AEV.cumulated{end-1}.effect(measure_i+1))/2;
        text(length(comparison_return_periods)-1.9,y_pos,...
            measures_impact.measures.name{sort_index(measure_i)},'Rotation',0,'fontsize',fontsize_);
        %     y_pos=(AEV.cumulated{end-2}.effect(measure_i)+AEV.cumulated{end-2}.effect(measure_i+1))/2;
        %     text(length(comparison_return_periods)-2.9,y_pos,...
        %         measures_impact.measures.name{sort_index(measure_i)},'Rotation',0);
    end
end

% write return period labels in x-axis
set(gca,'XTick',0.5:1:length(comparison_return_periods)-0.5);
set(gca,'XTickLabel',XTickLabel);

% add title
title_str=measures_impact.title_str;
title_str=strrep(title_str,'_',' '); % since title is LaTEX format
title_str=strrep(title_str,'|','\otimes'); % LaTEX format
title(title_str,'FontSize',8);

end % climada_adaptation_event_view