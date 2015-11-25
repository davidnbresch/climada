function climada_waterfall_graph_advanced(return_period, check_printplot, EDS1, EDS2, EDS3, EDS4, EDS5, EDS6)
% climada water fall plot adapatation cost
% NAME:
%   climada_waterfall_graph
% PURPOSE:
%   waterfall figure, expected loss for specified return period for
%   - today,
%   - increase from economic growth,
%   - increase from high climate change, total expected loss 2030
%   for the n EDS passed on
% CALLING SEQUENCE:
%   climada_waterfall_graph(return_period,check_printplot,EDS1, EDS2, EDS3,...)
% EXAMPLES:
%   climada_waterfall_graph_advanced('AEL',0,EDS_2014,EDS_2030)
% INPUTS:
%   return_period:  requested return period for according expected loss (e.g. =100),or
%                   annual expted loss (='AEL'), prompted if not given
%   check_printplot:if set to 1, figure saved, default 0.
% OPTIONAL INPUT PARAMETERS:
%   EDSn: Event damage set, see e.g. climada_EDS_calc
% OUTPUTS:
%   waterfall graph
% MODIFICATION HISTORY:
% Lea Mueller, 20110622
% Martin Heynen, 20120307
% david.bresch@gmail.com, 20140804, GIT update
% david.bresch@gmail.com, 20141020, moved from tc_rain to core climada
%-

global climada_global
if ~climada_init_vars, return; end

% check function inputs and assign the "input case":
%   - no_input-->prompt for files
%   - only wind EDS given
%   - wind and rain EDS given
%   - none of the above --> stopp, warning

if     ~exist('EDS1','var') && ~exist('EDS2','var') && ~exist('EDS3','var')...
        && ~exist('EDS4','var') && ~exist('EDS5','var') && ~exist('EDS6','var')
    
    case_='no_input';
    
    EDS1 = [];
    EDS2 = [];
    EDS3 = [];
    EDS4 = [];
    EDS5 = [];
    EDS6 = [];
    
elseif exist('EDS1','var') && exist('EDS2','var') && exist('EDS3','var')...
        && (~exist('EDS4','var') || isempty(EDS4)) && (~exist('EDS5','var')...
        || isempty(EDS5)) && (~exist('EDS6','var') || isempty(EDS5))
    
    case_='only_wind_EDS';
    
    
    
elseif  exist('EDS1','var') && exist('EDS2','var') && exist('EDS3','var')...
        && exist('EDS4','var') && exist('EDS5','var') && exist('EDS6','var')
    
    case_='wind_and_rain_EDS';
    
    
    
else   %no valid input
    warning('m_id','function stopped: please choose as function input 3 EDS structs or 6 EDS structs to include the EDS_rain, respectively or select the according files if no input is stated')
    return;
end

if ~exist('return_period'  ,'var'), return_period   = []; end
if ~exist('check_printplot','var'), check_printplot = 0; end


%add stats and create EDS struct according to the "function input case"
switch case_
    case 'no_input'
        
        prompt   ='Do you want to include EDS from another hazard (e.g. rain)? (y=yes, n=no)';
        name     ='more than one hazard  ?';
        defaultanswer = {'y or n'};
        answer   = inputdlg(prompt, name, 1, defaultanswer);
        
        if strcmp(answer{1},'y')
            nr_EDS_to_prompt=6;
        else
            nr_EDS_to_prompt=3;
        end
        
        % load EVENT LOSS SET
        % prompt for EDS if not given
        % local GUI
        % save filenames and pathnames
        EDS                  = [climada_global.data_dir filesep 'results' filesep '*.mat'];
        EDS_default          = [climada_global.data_dir filesep 'results' filesep ['select EXACTLY ', num2str(nr_EDS_to_prompt), ' EDS .mat']];
        [filename, pathname] = uigetfile(EDS, ['Select the ' , num2str(nr_EDS_to_prompt), '  EDS files:'],EDS_default,'MultiSelect','on');
        if isequal(filename,0) || isequal(pathname,0)
            warning('m_id2','function stopped: please choose as function input 3 EDS structs or 6 EDS structs to include the EDS_rain, respectively or select the according files if no input is stated')
            return;
        end
        
        %load files with the above prompted fielnames, add stats and create EDS struct
        if iscell(filename)
            for i = 1:length(filename);
                %get var name
                %N:\SRZTIH\Sustainability\Climada\climada_small_NEU_9_4_2012\climada\data\results\EDS_2030_rain.mat
                load(fullfile(pathname,filename{i}))
                %save loaded file under EDS1
                EDS1 = eval(strtok(filename{i},'.'));
                %add statistics if not yet there
                if ~isfield(EDS1,'loss_sort')
                    EDS1 = climada_EDS_stats(EDS1, 0);
                end
                %temporarily save in EDS
                EDS_(i) = EDS1;
            end
            %rename to EDS
            EDS = EDS_;
            clear EDS_
        else
            load(fullfile(pathname,filename))
        end
        
        
        
        
        
    case {'only_wind_EDS','wind_and_rain_EDS'}
        EDS    = struct([]);
        %MH add stats to given input EDS
        % check if statistics are given, if not add statistics
        if ~isfield(EDS1,'loss_sort'),EDS1 = climada_EDS_stats(EDS1, 0);end
        if ~isfield(EDS2,'loss_sort'),EDS2 = climada_EDS_stats(EDS2, 0);end
        if ~isfield(EDS3,'loss_sort'),EDS3 = climada_EDS_stats(EDS3, 0);end
        
        EDS    = EDS1;
        EDS(2) = EDS2;
        EDS(3) = EDS3;
        
        if strcmp(case_,'wind_and_rain_EDS')
            if ~isfield(EDS4,'loss_sort'),EDS4 = climada_EDS_stats(EDS4, 0);end
            if ~isfield(EDS5,'loss_sort'),EDS5 = climada_EDS_stats(EDS5, 0);end
            if ~isfield(EDS6,'loss_sort'),EDS6 = climada_EDS_stats(EDS6, 0);end
            
            EDS(4) = EDS4;
            EDS(5) = EDS5;
            EDS(6) = EDS6;
        end
end %end switch


%sepparate EDS_TC and EDS_RAIN, EDS(1:3)-> wind, EDS(4:6)-> rain
%up to now EDS from rain have the field EDS.hazard.peril_ID='TC_rain'
if length(EDS)>3
    count1=0;
    count2=0;
    for EDS_i = 1:length(EDS)
        if strcmp(EDS(1,EDS_i).hazard.peril_ID,'TC_rain')
            count1=count1+1;
            EDS_rain(count1)=EDS(1,EDS_i);
        else
            count2=count2+1;
            EDS_wind(count2)=EDS(1,EDS_i);
        end
    end
    EDS    = struct([]);
    EDS=[EDS_wind, EDS_rain];
end


%prompt for return period or annual expected loss (AEL)
if isempty(return_period)
    prompt   ='Choose specific return period or annual expected loss [e.g. 1, 10, 500, AEL]:';
    name     ='Return period or annual expected loss';
    defaultanswer = {'AEL or 1 or 50 etc'};
    answer   = inputdlg(prompt, name, 1, defaultanswer);
    if strcmp(answer{1},'AEL')
        return_period = 9999;
    else
        return_period = str2num(answer{1});
    end
elseif ischar(return_period)
    if strcmp(return_period,'AEL')
        return_period = 9999;
    else
        fprintf('Please indicate return period (e.g. 1, 34, 50) or "AEL"\n "%s" does not exist\n',return_period)
        return
    end
end


% check if annual expected loss is requested and if not find index for
% requested return period save all losses under loss
for EDS_i = 1:length(EDS)
    if return_period == 9999
        loss(EDS_i) = EDS(EDS_i).EL;
    else
        r_index = EDS(1).R_fit == return_period;
        if sum(r_index)<1
            fprintf('\n--no information available for requested return period %i -- \n...--please select one of the following return periods:  --\n',int2str(return_period))
            disp(int2str(EDS(EDS_i).R_fit'))
            fprintf('\n')
            loss = [];
            return
        else
            loss(EDS_i) = EDS(EDS_i).loss_fit(r_index);
        end
    end
    % identification of EDS_i
    hazard_name       = strtok(EDS(EDS_i).hazard.comment,',');
    hazard_name       = horzcat(hazard_name, ' ', int2str(EDS(EDS_i).reference_year));
    [fP, assets_name] = fileparts(EDS(EDS_i).assets.filename);
    str               = sprintf('%s | %s',assets_name, hazard_name);
    str               = strrep(str,'_',' '); % since title is LaTEX format
    str               = strrep(str,'|','\otimes'); % LaTEX format
    legend_str{EDS_i} = str;
end % EDS_i


%Sort loss to know which is the loss_today, loss_eco, loss_eco_cc
[loss_wind index1]      = sort(loss(1:3),'ascend');
if length(EDS)>3
    [loss_rain index2]      = sort(loss(4:6),'ascend');
    index2=index2+3;
end

%Sort strings for the legend
legend_str_1=legend_str(index1);
if length(EDS)>3
    legend_str_2=legend_str(index2);
    legend_str_new={legend_str_1(1), legend_str_1(2), legend_str_1(3),...
        legend_str_2(1),legend_str_2(2),legend_str_2(3)}
else
    legend_str_new={legend_str_1(1), legend_str_1(2), legend_str_1(3)}
    
end

%sum up wind and rain loss
if length(EDS)>3
    loss=[loss_wind + loss_rain];
else
    loss=loss_wind;
end


% gets digits of loss
digits = log10(max(loss));
digits = floor(digits)-1;
loss = loss*10^-digits;
loss_wind = loss_wind*10^-digits;
if length(EDS)>3
    loss_rain = loss_rain*10^-digits;
end
dig  = digits;


if length(EDS)>3
    loss_rain_difference = [loss_rain(1) loss_rain(2)-loss_rain(1) loss_rain(3)-loss_rain(2)]
end


%----------
% figure
%----------

fig        = climada_figuresize(0.57,0.7);
color_     = [227 236 208;...   %hazard 1
    194 214 154;...   %hazard 1
    181 205  133;...  %hazard 1
    197 190 151;...   %hazard 1
    207 216 188;...   %hazard 2
    174 194 134;...   %hazard 2
    161 185  113;...  %hazard 2
    177 170  131;...  %hazard 2
    120 120 120]/256; %dotted line
stretch    = 0.3; %width of bars
loss_count = length(loss)+1;

loss=[0 loss];
fontsize_=8;

hold on
%total loss wind
area([loss_count-stretch loss_count+stretch], loss(4)*ones(1,2),'facecolor',color_(4,:),'edgecolor','none')


% single losses wind
% area([loss_count-stretch loss_count+stretch], loss(8)*ones(1,2),'facecolor',[109 101 104]/255,'edgecolor','none')
for i = 1:5-2 %1:length(loss)-2
    h(i) = patch( [i-stretch i+stretch i+stretch i-stretch],...
        [loss(i) loss(i) loss(i+1) loss(i+1)],...
        color_(i,:),'edgecolor','none');
    if i==1
        plot([i+stretch 4+stretch],[loss(i+1) loss(i+1)],':','color',color_(9,:))
    else
        plot([i+stretch 4-stretch],[loss(i+1) loss(i+1)],':','color',color_(9,:))
    end
end

% add losses from rain
if length(EDS)>3
    %add total loss coming from rain
    patch( [4-stretch 4+stretch 4+stretch 4-stretch],...
        [loss_wind(3) loss_wind(3) loss(4) loss(4)],...
        color_(8,:),'edgecolor','none');
    
    %add single losses coming from rain
    for i = 1:5-2 %1:length(loss)-2
        h(i+3) = patch( [i-stretch i+stretch i+stretch i-stretch],...
            [loss(i+1)-loss_rain_difference(i) loss(i+1)-loss_rain_difference(i) loss(i+1) loss(i+1)],...
            color_(i+4,:),'edgecolor','none');
        if i==1
            plot([i+stretch 4+stretch],[loss(i+1) loss(i+1)],':','color',color_(9,:))
        else
            plot([i+stretch 4-stretch],[loss(i+1) loss(i+1)],':','color',color_(9,:))
        end
    end
end

N = -abs(floor(log10(max(loss)))-1);
loss_disp(1) = round(  loss(2)          *10^N)/10^N;
loss_disp(2) = round( (loss(3)-loss(2)) *10^N)/10^N;
loss_disp(3) = round( (loss(4)-loss(3)) *10^N)/10^N;
loss_disp(4) = round(  loss(4)          *10^N)/10^N;


%losses above bars
text(1, loss(2)                      , int2str(loss_disp(1)), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontWeight','bold','fontsize',fontsize_);
text(2, loss(2)   + (loss(3)-loss(2))/2, int2str(loss_disp(2)), 'color','w', 'HorizontalAlignment','center', 'VerticalAlignment','middle','FontWeight','bold','fontsize',fontsize_);
text(3, loss(3)   + (loss(4)-loss(3))/2, int2str(loss_disp(3)), 'color','w', 'HorizontalAlignment','center', 'VerticalAlignment','middle','FontWeight','bold','fontsize',fontsize_);
text(4, loss(4)                      , int2str(loss_disp(4)), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontWeight','bold','fontsize',fontsize_);

%axis range and ylabel
xlim([0.5 4.5])
ylim([0   max(loss)*1.25])
ylabel(['Loss amount \cdot 10^', int2str(dig)],'fontsize',fontsize_)

%arrow
climada_arrow  ([4 loss(2)], [4 loss(4)], 40, 10, 30,'width',1.5,'Length',10, 'BaseAngle',90, 'EdgeColor','none', 'FaceColor',[256 256 256]/256);
text   (4, loss(2)-max(loss)*0.02, ['+ ' int2str((loss(4)-loss(2))/loss(2)*100) '%'], 'color','w','HorizontalAlignment','center','VerticalAlignment','top','fontsize',fontsize_);

%remove xlabels and ticks
set(gca,'xticklabel',[],'FontSize',10,'XTick',zeros(1,0));

%title
if return_period == 9999
    text   (1- stretch, max(loss)*1.2, {'Annual Expected Loss (AEL)'}, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','bold','fontsize',fontsize_);
else
    text   (1- stretch, max(loss)*1.2, {'Expected loss with a return period of ' int2str(return_period) ' years'}, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','bold','fontsize',fontsize_);
end

%xlabels
text   (1- stretch, loss(1)-max(loss)*0.02, {[num2str(climada_global.present_reference_year) ' today''s'];'expected loss'}, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_);
text   (2- stretch, loss(1)-max(loss)*0.02, {'Incremental increase';'from economic';'gowth; no climate';'change'}, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_);
text   (3- stretch, loss(1)-max(loss)*0.02, {'Incremental increase';'from climate change'}, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_);
text   (4- stretch, loss(1)-max(loss)*0.02, {[num2str(climada_global.future_reference_year) ', total'];'expected loss'}, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_);

%Legend
if length(EDS)>3
    L = legend([h(1),h(4),h(2),h(5),h(3),h(6)],[legend_str_new{1},legend_str_new{4},legend_str_new{2},legend_str_new{5},legend_str_new{3},legend_str_new{6}],'location','NorthOutside','fontsize',fontsize_);
    set(L,'Box', 'off')
    
else
    L = legend(h,[legend_str_new{1},legend_str_new{2},legend_str_new{3}],'location','NorthOutside','fontsize',fontsize_);
    set(L,'Box', 'off')
end


if isempty(check_printplot)
    choice = questdlg('print?','print');
    switch choice
        case 'Yes'
            check_printplot = 1;
    end
end

if check_printplot %(>=1)
    print(fig,'-dpdf',[climada_global.data_dir foldername])
    %close
    fprintf('saved 1 FIGURE in folder %s \n', foldername);
end

return




