function [fig,legend_str,return_period,sorted_damage] = climada_EDS_DFC(EDS,EDS_comparison,Percentage_Of_Value_Flag,plot_loglog)
% climada
% NAME:
%   climada_EDS_DFC
% PURPOSE:
%   plot occurrence Damage exceedence Frequency Curve (DFC)
%
%   See also: climada_EDS_DFC_match and climada_DFC_compare
% CALLING SEQUENCE:
%   climada_EDS_DFC(EDS,EDS_comparison,Percentage_Of_Value_Flag)
% EXAMPLE:
%   climada_EDS_DFC(climada_EDS_calc(climada_entity_read))
% INPUTS:
%   EDS: either an event damage set, as e.g. returned by climada_EDS_calc or
%       a file containing such a structure
%       SPECIAL: we also accept a structure which contains an EDS, like
%       measures_impact.EDS
%       if EDS has the field annotation_name, the legend will show this
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   EDS_comparison: like EDS see above, plotted (fine lines) for comparison
%       not prompted for, if not given,unless set to 'ASK'
%   Percentage_Of_Value_Flag: if =1, scale vertical axis with Value, such
%       that damage as percentage of value is shown, instead of damage amount,
%       default=0 (damage amount shown). Very useful to compare DFCs of
%       different portfolios to see relative differences in risk
%   plot_loglog: if =1, plot logarithmic scale both axes, =0 plot linear
%       axes (default)
% OUTPUTS:
%   a figure with the DFC plot
%   legend_str: the legend string
%   return_period: the return periods as shown (for the last DFC plottet,
%       be careful)
%   sorted_damage: the damage as shown (for the last DFC plottet,
%       be careful)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20100108
% David N. Bresch, david.bresch@gmail.com, 20100109, comparison added
% Lea Mueller, 20120816, comparison title of all comparisons, changed markersize
% David N. Bresch, david.bresch@gmail.com, 20130316, ELS->EDS...
% David N. Bresch, david.bresch@gmail.com, 20130316, slight cleanup
% David N. Bresch, david.bresch@gmail.com, 20141206, legend_str as output added
%-

fig=[];legend_str=[];

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('EDS','var'),EDS=[];end
if ~exist('EDS_comparison','var'),EDS_comparison='';end
if ~exist('Percentage_Of_Value_Flag','var'),Percentage_Of_Value_Flag=0;end
if ~exist('plot_loglog','var'),plot_loglog=0;end


% prompt for EDS if not given
if isempty(EDS) % local GUI
    EDS=[climada_global.data_dir filesep 'results' filesep '*.mat'];
    %[filename, pathname] = uigetfile(EDS, 'Select EDS:');
    [filename, pathname] = uigetfile(EDS, 'Select EDS:','MultiSelect','on');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        if iscell(filename)
            for i = 1:length(filename)
                % rename EDS to EDS1
                vars = whos('-file', fullfile(pathname,filename{i}));
                load(fullfile(pathname,filename{i}));
                %temporarily save in EDS_temp
                EDS_temp(i) = eval(vars.name);           
                clear (vars.name)
            end
            EDS = EDS_temp;
        else
            EDS = fullfile(pathname,filename);
        end        
    end
end
% load the EDS, if a filename has been passed
if ~isstruct(EDS)
    EDS_file=EDS; EDS=[];
    load(EDS_file);
end


% prompt for EDS_comparison
if strcmp(EDS_comparison,'ASK')
    EDS_comparison=[climada_global.data_dir filesep 'results' filesep '*.mat'];
    [filename, pathname] = uigetfile(EDS_comparison, 'Select EDS for comparison:');
    if isequal(filename,0) || isequal(pathname,0)
        EDS_comparison='';
    else
        EDS_comparison=fullfile(pathname,filename);
    end
end

if exist('measures_impact','var') % if a results file is loaded
    EDS=measures_impact.EDS;
end

if isfield(EDS,'EDS')
    EDS_temp = EDS;
    EDS      = EDS_temp.EDS;
    EDS_temp = [];
end


%define figure parameters
msize      = 5;
legend_str = {};
color_     = [255 215   0 ;...   %today
              255 127   0 ;...   %eco 
              238  64   0 ;...   %clim
              205   0   0 ;...   %total risk
              120 120 120]/256;  %dotted line]/255;              
if length(EDS)>  size(color_,1)    
    color_ = jet(length(EDS));
end
% order accroding to size of damage
damage_                 = arrayfun(@(x)(sum(x.damage)), EDS);
[~,sort_index] = sort(damage_,'ascend');
color_ = color_(sort_index,:);

marker_ = ['*- ';'o- ';'p- ';'.- ';'s- ';'v: ';'d: ';'^: ';'*: ';'o: ';'p--';'.--';'s--';'v--';'d--'];
ii      = 1;

%create figure
%fig = climada_figuresize(0.5,0.8);         

for EDS_i=1:length(EDS)
    [sorted_damage,exceedence_freq]... 
                    = climada_damage_exceedence(EDS(EDS_i).damage,EDS(EDS_i).frequency);
    nonzero_pos     = find(exceedence_freq);
    sorted_damage   = sorted_damage(nonzero_pos);
    exceedence_freq = exceedence_freq(nonzero_pos);
    return_period   = 1./exceedence_freq;
    if Percentage_Of_Value_Flag,sorted_damage = sorted_damage/EDS(EDS_i).Value*100; end
    if plot_loglog
        loglog(return_period,sorted_damage,marker_(ii,:),'color',color_(ii,:),'LineWidth',1.5,'markersize',msize);
    else
        plot(return_period,sorted_damage,marker_(ii,:),'color',color_(ii,:),'LineWidth',1.5,'markersize',msize);
    end
    hold on
    ii = ii+1; if ii>length(marker_), ii=1; end
    if isfield(EDS(EDS_i),'annotation_name'),legend_str{EDS_i}=strrep(EDS(EDS_i).annotation_name,'_',' '); end
end % EDS_i

set(gca,'fontsize',12)
if ~isempty(legend_str),legend(legend_str,'Location','NorthWest');end % add legend
%if ~isempty(legend_str),legend(legend_str,'Interpreter','none','location','NorthWest');end % add legend
grid on; % show grid
xlabel('Return period (years)')
if Percentage_Of_Value_Flag
    ylabel('Damage as percentage of value')
else
    ylabel('Damage amount')
end
% set(gcf,'Color',[1 1 1])

% add title
[~,hazard_name] = fileparts(EDS(1).hazard.filename);
[~,assets_name] = fileparts(EDS(1).assets.filename);
title_str        = sprintf('%s | %s',assets_name,hazard_name);
title_str        = strrep(title_str,'_',' '); % since title is LaTEX format
title_str        = strrep(title_str,'|','\otimes'); % LaTEX format
% title(title_str,'FontSize',12);

hold off;

if ~isempty(EDS_comparison)
    % load the entity, if a filename has been passed
    if ~isstruct(EDS_comparison)
        EDS_comparison_file = EDS_comparison;
        EDS_comparison      = [];
        load(EDS_comparison_file);
    else
        EDS            = EDS_comparison;
        EDS_comparison = [];
    end

    % attention, from now on, EDS holds the EDS for comparison

    if exist('measures_impact','var') % if a results file is loaded
        EDS = measures_impact.EDS;
    end
    
    if isfield(EDS,'EDS')
        EDS_temp = EDS;
        EDS      = EDS_temp.EDS;
        EDS_temp = [];
    end

    hold on;
    ii = 2; %go to next color
    if length(EDS)>  size(color_,1)-1   
        color_ = jet(length(EDS)+1);
    end
    
    for EDS_i=1:length(EDS)
        [sorted_damage,exceedence_freq]...
                        = climada_damage_exceedence(EDS(EDS_i).damage,EDS(EDS_i).frequency);
        nonzero_pos     = find(exceedence_freq);
        sorted_damage   = sorted_damage(nonzero_pos);
        exceedence_freq = exceedence_freq(nonzero_pos);
        return_period   = 1./exceedence_freq;
        if Percentage_Of_Value_Flag, sorted_damage = sorted_damage/EDS(EDS_i).Value*100; end
        plot(return_period, sorted_damage, marker_(ii,:), 'color',color_(ii,:), 'LineWidth',1.2, 'markersize',msize);
        hold on
        ii = ii+1; if ii>length(marker_), ii=1; end
        if isfield(EDS(EDS_i),'annotation_name'), legend_str{EDS_i}=strrep(EDS(EDS_i).annotation_name,'_',' '); end
        % add title
        [~,hazard_name]    = fileparts(EDS(EDS_i).hazard.filename);
        [~,assets_name]    = fileparts(EDS(EDS_i).assets.filename);
        title_str_comp      = sprintf('%s | %s',assets_name,hazard_name);
        title_strs{EDS_i+1} = strrep(strrep(title_str_comp,'_',' '),'|','\otimes'); % since title is LaTEX format
        
    end % EDS_i
    if ~isempty(legend_str),legend(legend_str,'Location','NorthWest');end % add legend
    %if ~isempty(legend_str),legend(legend_str,'Interpreter','none','location','NorthWest');end % add legend
    title_strs{1}    = title_str;
    title(title_strs,'FontSize',12);
    hold off
    
end % comparison

set(gcf,'Color',[1 1 1]) % white background

return
