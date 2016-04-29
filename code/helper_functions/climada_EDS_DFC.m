function [DFC,fig,legend_str] = climada_EDS_DFC(EDS,EDS_comparison,Percentage_Of_Value_Flag,plot_loglog)
% climada
% NAME:
%   climada_EDS_DFC
% PURPOSE:
%   plot occurrence Damage exceedence Frequency Curve (DFC)
%   mainly does plotting, uses climada_EDS2DFC to convert EDS to DFC
%
%   See also: climada_EDS_DFC_match and climada_DFC_compare
% CALLING SEQUENCE:
%   climada_EDS_DFC(EDS,EDS_comparison,Percentage_Of_Value_Flag,plot_loglog)
% EXAMPLE:
%   climada_EDS_DFC(climada_EDS_calc(climada_entity_read))
% INPUTS:
%   EDS: either an event damage set, as e.g. returned by climada_EDS_calc or
%       a file containing such a structure
%       SPECIAL: we also accept a structure which contains an EDS, like
%       measures_impact.EDS
%       if EDS has the field annotation_name, the legend will show this
%       > EDS promted for if not given
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
%   DFC: a structure with fields
%       .return_period
%       .sorted_damage
%       .ED, .Value, .Value_unit, and .annotation_name
%   a figure with the DFC plot
%   legend_str: the legend string
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20100108
% David N. Bresch, david.bresch@gmail.com, 20100109, comparison added
% Lea Mueller, 20120816, comparison title of all comparisons, changed markersize
% David N. Bresch, david.bresch@gmail.com, 20130316, ELS->EDS...
% David N. Bresch, david.bresch@gmail.com, 20130316, slight cleanup
% Lea Mueller, muellele@gmail.com, 20150421, legend location SouthEast instead of NorthWest
% David N. Bresch, david.bresch@gmail.com, 20150515, line 212, legend_str{end+1}...
% David N. Bresch, david.bresch@gmail.com, 20150906, EDS.Value_unit used
% Lea Mueller, muellele@gmail.com, 20160308, add output DFC structure
% David N. Bresch, david.bresch@gmail.com, 20160429, calling EDS2DFC, DFC.Value instead of DFC.value
%-

DFC = []; DFC_comparison = []; fig = []; legend_str = []; %init

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('EDS','var'),EDS=[];end
if ~exist('EDS_comparison','var'),EDS_comparison='';end
if ~exist('Percentage_Of_Value_Flag','var'),Percentage_Of_Value_Flag=0;end
if ~exist('plot_loglog','var'),plot_loglog=0;end

% prompt for EDS if not given
EDS = climada_EDS_load(EDS);

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
% % order according to size of damage
% damage_        = arrayfun(@(x)(sum(x.damage)), EDS);
% [~,sort_index] = sort(damage_,'ascend');
% color_ = color_(sort_index,:);

marker_ = ['*- ';'o- ';'p- ';'s- ';'.- ';'v: ';'d: ';'^: ';'*: ';'o: ';'p--';'s--';'.--';'v--';'d--'];
ii      = 1;

DFC=climada_EDS2DFC(EDS,-1); % convert EDS to DFC

legend_str={};

for DFC_i=1:length(DFC)
    if Percentage_Of_Value_Flag
        damage=DFC(DFC_i).damage_of_value;
    else
        damage=DFC(DFC_i).damage*climada_global.Value_display_unit_fact;
    end
    if plot_loglog
        loglog(DFC(DFC_i).return_period,damage,marker_(ii,:),'color',color_(ii,:),'LineWidth',1.5,'markersize',msize);
    else
        plot(DFC(DFC_i).return_period,damage,marker_(ii,:),'color',color_(ii,:),'LineWidth',1.5,'markersize',msize);
    end
    hold on
    ii = ii+1; if ii>length(marker_), ii=1; end
    if isfield(DFC(DFC_i),'annotation_name'),legend_str{end+1}=strrep(DFC(DFC_i).annotation_name,'_',' '); end
end % DFC_i

grid on; % show grid
xlabel('Return period [years]')
if Percentage_Of_Value_Flag
    ylabel('Damage [% of value]')
else
    ylabel(['Damage [' climada_global.Value_display_unit_name ']']);
end

% add title
[~,hazard_name] = fileparts(EDS(1).hazard.filename);
[~,assets_name] = fileparts(EDS(1).assets.filename);
title_str        = sprintf('%s | %s',assets_name,hazard_name);
title_str        = strrep(title_str,'_',' '); % since title is LaTEX format
title_str        = strrep(title_str,'|','\otimes'); % LaTEX format
title_strs{1}    = title_str;

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
    
    DFC_comparison=climada_EDS2DFC(EDS,-1); % convert EDS to DFC
    
    for DFC_i=1:length(DFC_comparison)
        if Percentage_Of_Value_Flag
            damage=DFC_comparison(DFC_i).damage_of_value;
        else
            damage=DFC_comparison(DFC_i).damage*climada_global.Value_display_unit_fact;
        end
        if plot_loglog
            loglog(DFC_comparison(DFC_i).return_period,damage,marker_(ii,:),'color',color_(ii,:),'LineWidth',1.5,'markersize',msize);
        else
            plot(DFC_comparison(DFC_i).return_period,damage,marker_(ii,:),'color',color_(ii,:),'LineWidth',1.5,'markersize',msize);
        end
        hold on
        ii = ii+1; if ii>length(marker_), ii=1; end
        if isfield(DFC_comparison(DFC_i),'annotation_name'),legend_str{end+1}=strrep(DFC_comparison(DFC_i).annotation_name,'_',' '); end
        
        % add title
        [~,hazard_name]    = fileparts(EDS(DFC_i).hazard.filename);
        [~,assets_name]    = fileparts(EDS(DFC_i).assets.filename);
        title_str_comp      = sprintf('%s | %s',assets_name,hazard_name);
        title_strs{DFC_i+1} = strrep(strrep(title_str_comp,'_',' '),'|','\otimes'); % since title is LaTEX format
        
    end % DFC_i
end % comparison

%title(title_strs,'FontSize',12);
hold off
set(gca,'fontsize',12)
if ~isempty(legend_str),legend(legend_str,'Interpreter','none','location','NorthWest');end % add legend
set(gcf,'Color',[1 1 1]) % white background

% put the two together, DFC and DFC_comparison
n_DFC = numel(DFC);
n_DFC_comparison = numel(DFC_comparison);
if n_DFC_comparison>0, DFC(n_DFC+1:n_DFC+n_DFC_comparison) = DFC_comparison;end

return
