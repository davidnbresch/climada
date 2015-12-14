function  fig = climada_waterfall_graph(EDS1,EDS2,EDS3,return_period,check_printplot,legend_on)
% waterfall figure, expected damage for specified return period for
% - today,
% - increase from economic development,
% - increase from high climate change, total expected damage 2030
% for the three EDS quoted above
% NAME:
%   climada_waterfall_graph
% PURPOSE:
%   plot expected damage for specific return period
% CALLING SEQUENCE:
%   climada_waterfall_graph(EDS1,EDS2,EDS3,return_period,check_printplot)
% EXAMPLE:
%   climada_waterfall_graph
% INPUTS:
%   none
% OPTIONAL INPUT PARAMETERS:
%   EDS:            three event damage sets
%                   - today
%                   - economic development
%                   - cc combined with economic development, future
%   return_period:  requested return period for according expected damage,or
%                   annual expected damage, prompted if not given
%                   Default is annual expected damage (EDS.ED)
%   check_printplot:if set to 1, figure saved, default 0.
%       if =-1, avoid all the additonal labels etc (for e.g. slides)
% OUTPUTS:
%   waterfall graph
% MODIFICATION HISTORY:
% Lea Mueller, 20110622
% Martin Heynen, 20120329
% David N. Bresch, david.bresch@gmail.com, 20130316 EDS->EDS
% David N. Bresch, david.bresch@gmail.com, 20150419 try-catch for arrow plotting
% Lea Mueller, muellele@gmail.com, 20150831, integrate Value_unit from EDS1.Value_unit
% David N. Bresch, david.bresch@gmail.com, 20150906 ED as default for return_period
% David N. Bresch, david.bresch@gmail.com, 20150906 font scale and label texts shortened
% David N. Bresch, david.bresch@gmail.com, 20150907 font scale and label texts shortened
% Lea Mueller, muellele@gmail.com, 20150930, introduce climada_digit_set
% Lea Mueller, muellele@gmail.com, 20151020, add TIV for future reference year
% Lea Mueller, muellele@gmail.com, 20151030, bugfix in climada_arrow
% Lea Mueller, muellele@gmail.com, 20151209, set no_fig=1, add legend_on=1
%-

global climada_global
if ~climada_init_vars, return; end

% poor man's version to check arguments
if ~exist('EDS1'           ,'var'), EDS1 = []; end
if ~exist('EDS2'           ,'var'), EDS2 = []; end
if ~exist('EDS3'           ,'var'), EDS3 = []; end
if ~exist('return_period'  ,'var'), return_period   = 9999; end
if ~exist('check_printplot','var'), check_printplot = 0; end
if ~exist('legend_on','var'), legend_on = ''; end


no_fig = 1;

if isempty(legend_on), legend_on = 1; end
%---------------------------------------------
%% load EVENT damage SET if not given
%---------------------------------------------
% prompt for EDS if not given
if isempty(EDS1) % local GUI
    EDS                  = [climada_global.data_dir filesep 'results' filesep '*.mat'];
    EDS_default          = [climada_global.data_dir filesep 'results' filesep 'Select exactly three EDS .mat'];
    [filename, pathname] = uigetfile(EDS, 'Select EDS:',EDS_default,'MultiSelect','on');
    if isequal(filename,0) || isequal(pathname,0)
        %return; % cancel
        EDS1   = climada_EDS_stats(climada_EDS_calc, 0);
        if ischar(EDS1); fig = []; return; end
        climada_EDS_save(EDS1,'EDS_today')
        
        EDS2   = climada_EDS_stats(climada_EDS_calc, 0);
        if ischar(EDS2); fig = []; return; end
        climada_EDS_save(EDS2,'EDS_future_eco')
        
        EDS3   = climada_EDS_stats(climada_EDS_calc, 0);
        if ischar(EDS3); fig = []; return; end
        climada_EDS_save(EDS3,'EDS_future_cc')
        
        EDS    = struct([]);
        EDS    = EDS1;
        EDS(2) = EDS2;
        EDS(3) = EDS3;
    end
else
    % check if statistics are given, if not add statistics
    if ~isfield(EDS1,'damage_sort')
        EDS1 = climada_EDS_stats(EDS1, 0);
    end
    if ~isfield(EDS2,'damage_sort')
        EDS2   = climada_EDS_stats(EDS2, 0);
    end
    if ~isfield(EDS3,'damage_sort')
        EDS3 = climada_EDS_stats(EDS3, 0);
    end
    EDS    = struct([]);
    EDS    = EDS1;
    EDS(2) = EDS2;
    EDS(3) = EDS3;
end
% load the EDS, if a filename has been passed
if ~isstruct(EDS1)
    if iscell(filename)
        for i = 1:length(filename);
            % rename EDS to EDS1
            vars = whos('-file', fullfile(pathname,filename{i}));
            load(fullfile(pathname,filename{i}))
            EDS1 = eval(vars.name);
            % add statistics if not yet there
            if ~isfield(EDS1,'damage_sort')
                EDS1 = climada_EDS_stats(EDS1, 0);
            end
            clear (vars.name)
            %temporarily save in EDS
            EDS_(i) = EDS1;
        end
        %rename to EDS
        EDS = EDS_;
        clear EDS_
    else
        load(fullfile(pathname,filename))
    end
    
end


% default return period, 250 years
if ~exist ('return_period', 'var'), return_period = []   ; end
%if isempty(return_period)         , return_period = 9999 ; end
%if isempty(return_period)         , return_period = 10 ; end
if isempty(return_period)
    prompt   ='Choose specific return period or annual expected damage [e.g. 1, 10, 500, AED]:';
    name     ='Return period or annual expected damage';
    defaultanswer = {'AED or 1 or 50 etc'};
    answer   = inputdlg(prompt, name, 1, defaultanswer);
    if strcmp(answer{1},'AED')
        return_period = 9999;
    else
        return_period = str2num(answer{1});
    end
elseif ischar(return_period)
    if strcmp(return_period,'AED')
        return_period = 9999;
    else
        fprintf('Please indicate return period (e.g. 1, 34, 50) or "AED"\n "%s" does not exist\n',return_period)
        return
    end
end


for EDS_i = 1:length(EDS)
    % check if annual expected damage is requested
    if return_period == 9999
        damage(EDS_i) = EDS(EDS_i).ED;
    else
        % find index for requested return period
        r_index = EDS(EDS_i).R_fit == return_period;
        if sum(r_index)<1
            fprintf('\n--no information available for requested return period %d year -- \n',return_period)
            
            fprintf('--calculate damage for specific return period %d  --\n', return_period)
            EDS(EDS_i) = climada_EDS_stats(EDS(EDS_i), '', return_period);
            r_index    = EDS(EDS_i).R_fit == return_period;
            
            %R_show = sprintf('%d, ', EDS(EDS_i).R_fit');
            %R_show(end-1:end) = [];
            %fprintf('--please sEDect one of the following return periods:  --\n %s\n', R_show)
            %damage = [];
            %return
        end
        damage(EDS_i) = EDS(EDS_i).damage_fit(r_index);
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

% damage = permute(damage,[1 3 2]);

% today, eco, cc, future damage
[damage index]      = sort(damage,'ascend');
damage(4)           = damage(3);

% set unit string
if isfield(EDS1,'Value_unit')
    unit_str = EDS1.Value_unit;
else
    unit_str = climada_global.Value_unit;
end

%digits of damage
[digits, digit_str] = climada_digit_set(damage);
damage = damage*10^-digits;
% % digits = log10(max(damage));
% % digits = floor(digits)-1;
% % digits = 9;
% digits = 0; %digits = 6;
% dig    = digits;

% TIV of portfolio
[digit_TIV, digit_TIV_str] = climada_digit_set([EDS(1).Value]);
% [digit_TIV, digit_TIV_str] = climada_digit_set([EDS(:).Value]);
TIV = unique([EDS(:).Value])*10^-digit_TIV;
% TIV = round(unique([EDS(:).Value])*10^-digit_TIV);
% TIV_nr = round(unique([EDS(:).Value])*10^-digits);
% N      = -abs(floor(log10(max(TIV_nr)))-1);
% TIV_nr = round(TIV_nr*10^N)/10^N;


% set ylabel
if isfield(EDS,'Value_unit')
    Value_unit = EDS.Value_unit;
else
    Value_unit = climada_global.Value_unit;
end
if isempty(digit_str)
    ylabel_str = sprintf('Damage (%s)',Value_unit);
else
    ylabel_str = sprintf('Damage (%s %s)',Value_unit,digit_str);
end

%----------
%% figure
%----------
% fontsize_  = 8;
fontsize_  = 12*climada_global.font_scale;
fontsize_2 = fontsize_ - 3;
fontsize_3  = 12; % does not scale, since additional labels
% stretch    = 0.3;
stretch    = 0.3;

if ~no_fig
    fig = climada_figuresize(0.57,0.7);
end
% yellow - red color scheme
color_     = [255 215   0 ;...   %today
    255 127   0 ;...   %eco
    238  64   0 ;...   %clim
    205   0   0 ;...   %total risk
    120 120 120]/256;  %dotted line]/255;
color_(1:4,:) = brighten(color_(1:4,:),0.3);

% % green color scheme
% color_     = [227 236 208;...   %today
%               194 214 154;...   %eco
%               181 205  133;...  %clim
%               197 190 151;...   %total risk
%               120 120 120]/256; %dotted line]/255;
% color_(1:4,:) = brighten(color_(1:4,:),-0.5);

damage_count = length(damage);
damage       = [0 damage];

hold on
area([damage_count-stretch damage_count+stretch], damage(4)*ones(1,2),'facecolor',color_(4,:),'edgecolor','none')
for i = 1:length(damage)-2
    h(i) = patch( [i-stretch i+stretch i+stretch i-stretch],...
        [damage(i) damage(i) damage(i+1) damage(i+1)],...
        color_(i,:),'edgecolor','none');
    %     if i==1
    %           plot([i+stretch 4+stretch],[damage(i+1) damage(i+1)],':','color',color_(5,:))
    %     else
    %           plot([i+stretch 4-stretch],[damage(i+1) damage(i+1)],':','color',color_(5,:))
    %     end
end
for i = 1:length(damage)-2
    if i==1
        plot([i+stretch 4+stretch],[damage(i+1) damage(i+1)],':','color',color_(5,:))
    else
        plot([i+stretch 4-stretch],[damage(i+1) damage(i+1)],':','color',color_(5,:))
    end
end

%number of digits before the comma (>10) or behind the comma (<10)
damage_disp(1) = damage(2);
damage_disp(2) = damage(3)-damage(2);
damage_disp(3) = damage(4)-damage(3);
damage_disp(4) = damage(4);

if max(damage)>100
    N = -abs(floor(log10(max(damage)))-1);
    N = 0;
    damage_disp = round(damage_disp*10^N)/10^N;
    N = 0;
else
    %N = round(log10(max(damage_disp)));
    N = 2;
end


%damages above bars
strfmt = ['%2.' int2str(N) 'f'];
dED = 0.0;
text(1, damage(2)                     , num2str(damage_disp(1),strfmt), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontWeight','bold','fontsize',fontsize_);
text(2-dED, damage(2)+ (damage(3)-damage(2))/2, num2str(damage_disp(2),strfmt), 'color','w', 'HorizontalAlignment','center', 'VerticalAlignment','middle','FontWeight','bold','fontsize',fontsize_);
text(3-dED, damage(3)+ (damage(4)-damage(3))/2, num2str(damage_disp(3),strfmt), 'color','w', 'HorizontalAlignment','center', 'VerticalAlignment','middle','FontWeight','bold','fontsize',fontsize_);
text(4, damage(4)                     , num2str(damage_disp(4),strfmt), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontWeight','bold','fontsize',fontsize_);

%remove xlabels and ticks
set(gca,'xticklabel',[],'FontSize',10,'XTick',zeros(1,0),'layer','top');

%axis range and ylabel
xlim([0.5 4.5])
ylim([0   max(damage)*1.25])
ylabel(ylabel_str,'fontsize',fontsize_)
% ylabel(['Damage amount \cdot 10^{', int2str(dig) '}'],'fontsize',fontsize_)

%arrow eco
% dED2 = 0.05;
dED2 = stretch+0.05;
% dED3 = 0.10;
dED3 = stretch+0.07;
try
    climada_arrow ([2+dED2 damage(2)], [2+dED2 damage(3)], 40, 10, 30,'width',1.5,'Length',10, 'BaseAngle',90, 'EdgeColor','none', 'FaceColor',[0.5 0.5 0.5]);
catch
    fprintf('Warning: arrow printing failed in %s (1)\n',mfilename);
end
text (2+dED3, damage(2)+diff(damage(2:3))*0.5, ['+' int2str((damage(3)-damage(2))/damage(2)*100) '%'], ...
    'color',[0. 0. 0.],'HorizontalAlignment','left','VerticalAlignment','middle','fontsize',fontsize_-1);

%arrow cc
try
    climada_arrow ([3+dED2 damage(3)], [3+dED2 damage(4)], 40, 10, 30,'width',1.5,'Length',10, 'BaseAngle',90, 'EdgeColor','none', 'FaceColor',[0.5 0.5 0.5]);
catch
    fprintf('Warning: arrow printing failed in %s (2)\n',mfilename);
end
text (3+dED3, damage(3)+diff(damage(3:4))*0.5, ['+' int2str((damage(4)-damage(3))/damage(2)*100) '%'], ...
    'color',[0. 0. 0.],'HorizontalAlignment','left','VerticalAlignment','middle','fontsize',fontsize_-1);

%arrow total
try
    climada_arrow ([4 damage(2)], [4 damage(4)], 40, 10, 30,'width',1.5,'Length',10, 'BaseAngle',90, 'EdgeColor','none', 'FaceColor',[256 256 256]/256);
catch
    fprintf('Warning: arrow printing failed in %s (3)\n',mfilename);
end
text (4, damage(2)-max(damage)*0.02, ['+' int2str((damage(4)-damage(2))/damage(2)*100) '%'], 'color','w','HorizontalAlignment','center','VerticalAlignment','top','fontsize',fontsize_);


%title
if check_printplot>=0
    if return_period == 9999
        textstr = 'Annual Expected Damage (AED)';
    else
        textstr = ['Expected damage with a return period of ' int2str(return_period) ' years'];
    end
    if strcmp(Value_unit,'people')
        textstr_TIV = sprintf('Total population (%d): %3.1f %s %s',climada_global.present_reference_year,TIV(1),digit_TIV_str,unit_str);
        textstr_TIV_2 = sprintf('Total population (%d): %3.1f %s %s',climada_global.future_reference_year,TIV(2),digit_TIV_str,unit_str);
    else
        textstr_TIV = sprintf('Total assets (%d): %3.1f %s %s',climada_global.present_reference_year,TIV(1),digit_TIV_str,unit_str);
        textstr_TIV_2 = sprintf('Total assets (%d): %3.1f %s %s',climada_global.future_reference_year,TIV(2),digit_TIV_str,unit_str);
    end
    text(1-stretch, max(damage)*1.20,textstr, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','bold','fontsize',fontsize_);
    text(1-stretch, max(damage)*1.15,textstr_TIV, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','normal','fontsize',fontsize_2);
    text(1-stretch, max(damage)*1.10,textstr_TIV_2, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','normal','fontsize',fontsize_2);
end

% if return_period == 9999
%     text(1- stretch, max(damage)*1.2, {'Annual Expected damage (AED)'}, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','bold','fontsize',fontsize_);
%  else
%     text(1- stretch, max(damage)*1.2, ['Expected damage with a return period of ' int2str(return_period) ' years'], 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','bold','fontsize',fontsize_);
% end

%xlabel
text(1-stretch, damage(1)-max(damage)*0.02, {'Risk today',['(' num2str(climada_global.present_reference_year) ')']}, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_2);
text(2-stretch, damage(1)-max(damage)*0.02, {'Economic','development'},'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_2);
text(3-stretch, damage(1)-max(damage)*0.02, {'Climate','change'},                                 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_2);
text(4-stretch, damage(1)-max(damage)*0.02, {['Risk ' num2str(climada_global.future_reference_year)]}, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_2);

%Legend
%L = legend(h,legend_str(index),'location','NorthOutside','fontsize',fontsize_2);
%set(L,'Box', 'off')
if check_printplot>=0
    if legend_on
        L=legend(h, legend_str(index),'Location','NorthEast');
        set(L,'Box', 'off')
        set(L,'Fontsize',fontsize_3)
    end
end


if isempty(check_printplot)
    choice = questdlg('print?','print');
    switch choice
        case 'Yes'
            check_printplot = 1;
    end
end


if check_printplot>0 %(>=1)
    print(fig,'-dpdf',[climada_global.data_dir foldername])
    fprintf('saved 1 FIGURE in folder %s \n', foldername);
end

end % climada_waterfall_graph