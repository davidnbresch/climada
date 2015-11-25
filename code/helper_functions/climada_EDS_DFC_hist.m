function climada_EDS_DFC_hist(EDS,EDS_comparison,Percentage_Of_Value_Flag)
% climada
% NAME:
%   climada_EDS_DFC
% PURPOSE:
%   plot occurrence Damage exceedence Frequency Curve (DFC)
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
%   EDS_comparison: likeEDS see above), plotted (fine lines) for comparison
%       not prompted for, if not given,unless set to 'ASK'
%   Percentage_Of_Value_Flag: if =1, scale vertical axis with Value, such
%       that damage as percentage of value is shown, instead of damage amount,
%       default=0 (damage amount shown). Very useful to compare DFCs of
%       different portfolios to see relative differences in risk
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20100108
% David N. Bresch, david.bresch@gmail.com, 20100109, comparison added
% David N. Bresch, david.bresch@gmail.com, 20130316, ELS->EDS...
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('EDS','var'),EDS=[];end
if ~exist('EDS_comparison','var'),EDS_comparison='';end
if ~exist('Percentage_Of_Value_Flag','var'),Percentage_Of_Value_Flag=0;end

% PARAMETERS
%
% plot_linetype_symbol_color=['b- ';'g- ';'r- ';'c- ';'m- ';'b: ';'g: ';'r: ';'c: ';'m: ';'b--';'g--';'r--';'c--';'m--'];
plot_linetype_symbol_color=['b*- ';'go- ';'rp- ';'c.- ';'ms- ';'bv: ';'gd: ';'r^: ';'c*: ';'mo: ';'bp--';'g.--';'rs--';'cv--';'md--'];
plot_linetype_symbol_color_i=1;
% from help plot:
%            b     blue          .     point              -     solid
%            g     green         o     circle             :     dotted
%            r     red           x     x-mark             -.    dashdot 
%            c     cyan          +     plus               --    dashed   
%            m     magenta       *     star
%            y     yellow        s     square
%            k     black         d     diamond
%                                v     triangle (down)
%                                ^     triangle (up)
%                                <     triangle (left)
%                                >     triangle (right)
%                                p     pentagram
%                                h     hexagram

% prompt for EDS if not given
if isempty(EDS) % local GUI
    EDS=[climada_global.data_dir filesep 'results' filesep '*.mat'];
    [filename, pathname] = uigetfile(EDS, 'Select EDS:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        EDS=fullfile(pathname,filename);
    end
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

% load the EDS, if a filename has been passed
if ~isstruct(EDS)
    EDS_file=EDS;EDS=[];
    load(EDS_file);
end

if exist('measures_impact','var') % if a results file is loaded
    EDS=measures_impact.EDS;
end

if isfield(EDS,'EDS')
    EDS_temp=EDS;
    EDS=EDS_temp.EDS;EDS_temp=[];
end

no_generated = size(EDS.orig_event_flag,2)/sum(EDS.orig_event_flag) ;
legend_str   = {};
fig = climada_figuresize(0.4,0.9);

for EDS_i=1:length(EDS)
               
    %historical           
    [sorted_damage,exceedence_freq]... 
                    = climada_damage_exceedence(EDS(EDS_i).damage(1:no_generated:end),...
                                              EDS(EDS_i).frequency(1:no_generated:end)*no_generated);      
    nonzero_pos     = find(exceedence_freq);
    sorted_damage   = sorted_damage(nonzero_pos);
    exceedence_freq = exceedence_freq(nonzero_pos);
    return_period   = 1./exceedence_freq;
    if Percentage_Of_Value_Flag,sorted_damage = sorted_damage/EDS(EDS_i).Value*100; end
    plot(return_period, sorted_damage, plot_linetype_symbol_color(plot_linetype_symbol_color_i,:),'LineWidth',1,'linestyle',':','markersize',3);
    hold on
    %plot_linetype_symbol_color_i = plot_linetype_symbol_color_i+1;
    if plot_linetype_symbol_color_i>length(plot_linetype_symbol_color), plot_linetype_symbol_color_i=1; end
    if isfield(EDS(EDS_i),'annotation_name'), legend_str{end+1}=[EDS(EDS_i).annotation_name ' historical']; end
    %if isfield(EDS(EDS_i),'annotation_name'), legend_str{EDS_i}=[EDS(EDS_i).annotation_name ' historical']; end
    
    %probabilistic
    [sorted_damage,exceedence_freq]... 
                    = climada_damage_exceedence(EDS(EDS_i).damage,EDS(EDS_i).frequency);        
    nonzero_pos     = find(exceedence_freq);
    sorted_damage   = sorted_damage(nonzero_pos);
    exceedence_freq = exceedence_freq(nonzero_pos);
    return_period   = 1./exceedence_freq;
    if Percentage_Of_Value_Flag,sorted_damage = sorted_damage/EDS(EDS_i).Value*100; end
    plot(return_period,sorted_damage,plot_linetype_symbol_color(plot_linetype_symbol_color_i,:),'LineWidth',1);
    hold on
    plot_linetype_symbol_color_i = plot_linetype_symbol_color_i+1;
    
    if plot_linetype_symbol_color_i>length(plot_linetype_symbol_color), plot_linetype_symbol_color_i=1; end
    if isfield(EDS(EDS_i),'annotation_name'), legend_str{end+1}=EDS(EDS_i).annotation_name; end
    %if isfield(EDS(EDS_i),'annotation_name'), legend_str{EDS_i}=EDS(EDS_i).annotation_name; end
    
end % EDS_i
if ~isempty(legend_str),legend(legend_str,'Interpreter','none');end % add legend
grid on; % show grid
xlabel('Return period (years)')
if Percentage_Of_Value_Flag
    ylabel('Damage as percentage of value')
else
    ylabel('Damage amount')
end
set(gcf,'Color',[1 1 1])

% add title
[fP,hazard_name] = fileparts(EDS(1).hazard.filename);
[fP,assets_name] = fileparts(EDS(1).assets.filename);
title_str        = sprintf('%s | %s',assets_name,hazard_name);
title_str        = strrep(title_str,'_',' '); % since title is LaTEX format
title_str        = strrep(title_str,'|','\otimes'); % LaTEX format
title(title_str,'FontSize',8);

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

    % attention, fromnow on, EDS holds the EDS for comparison

    if exist('measures_impact','var') % if a results file is loaded
        EDS = measures_impact.EDS;
    end
    
    if isfield(EDS,'EDS')
        EDS_temp = EDS;
        EDS      = EDS_temp.EDS;
        EDS_temp = [];
    end

    hold on;
    %plot_linetype_symbol_color_i = 1; % start with same line colors order again
    plot_linetype_symbol_color_i = 2; 
    
    for EDS_i=1:length(EDS)
        
        %historical           
        [sorted_damage,exceedence_freq]... 
                        = climada_damage_exceedence(EDS(EDS_i).damage(1:no_generated:end),...
                                                  EDS(EDS_i).frequency(1:no_generated:end)*no_generated);      
        nonzero_pos     = find(exceedence_freq);
        sorted_damage   = sorted_damage(nonzero_pos);
        exceedence_freq = exceedence_freq(nonzero_pos);
        return_period   = 1./exceedence_freq;
        if Percentage_Of_Value_Flag,sorted_damage = sorted_damage/EDS(EDS_i).Value*100; end
        plot(return_period, sorted_damage, plot_linetype_symbol_color(plot_linetype_symbol_color_i,:),'LineWidth',1,'linestyle',':','markersize',3);
        hold on
        %plot_linetype_symbol_color_i = plot_linetype_symbol_color_i+1;
        if plot_linetype_symbol_color_i>length(plot_linetype_symbol_color), plot_linetype_symbol_color_i=1; end
        if isfield(EDS(EDS_i),'annotation_name'), legend_str{end+1}=[EDS(EDS_i).annotation_name ' historical']; end
        %if isfield(EDS(EDS_i),'annotation_name'), legend_str{EDS_i}=[EDS(EDS_i).annotation_name ' historical']; end

        %probabilistic
        [sorted_damage,exceedence_freq]...
                        = climada_damage_exceedence(EDS(EDS_i).damage,EDS(EDS_i).frequency);
        nonzero_pos     = find(exceedence_freq);
        sorted_damage   = sorted_damage(nonzero_pos);
        exceedence_freq = exceedence_freq(nonzero_pos);
        return_period   = 1./exceedence_freq;
        if Percentage_Of_Value_Flag, sorted_damage = sorted_damage/EDS(EDS_i).Value*100; end
        plot(return_period,sorted_damage,plot_linetype_symbol_color(plot_linetype_symbol_color_i,:),'LineWidth',1);
        hold on
        plot_linetype_symbol_color_i = plot_linetype_symbol_color_i+1;
        if plot_linetype_symbol_color_i>length(plot_linetype_symbol_color), plot_linetype_symbol_color_i=1; end
        if isfield(EDS(EDS_i),'annotation_name'), legend_str{end+1} = EDS(EDS_i).annotation_name; end
        %if isfield(EDS(EDS_i),'annotation_name'), legend_str{end+1} = EDS(EDS_i).annotation_name; end
    end % EDS_i
    if ~isempty(legend_str),legend(legend_str,'Interpreter','none','location','se');end % add legend

    % add title
    [fP,hazard_name] = fileparts(EDS(1).hazard.filename);
    [fP,assets_name] = fileparts(EDS(1).assets.filename);
    title_str_comp   = sprintf('%s | %s (fine lines)',assets_name,hazard_name);
    title_str_comp   = strrep(title_str_comp,'_',' '); % since title is LaTEX format
    title_str_comp   = strrep(title_str_comp,'|','\otimes'); % LaTEX format
    title_strs{1}    = title_str;
    title_strs{2}    = title_str_comp;
    title(title_strs,'FontSize',8);

    hold off

end % comparison

return
