function climada_DFC_compare(EDS,DFC_file,Percentage_Of_Value_Flag,plot_loglog,scenario_comparison_flag,EDS_multiplier)
% climada
% NAME:
%   climada_DFC_compare
% PURPOSE:
%   compare climada results (Event damage set, EDS) and the resulting
%   damage frequency curve (DFC) with DFC from file, e.g. to compare with
%   other models. Purely visual inspection (as the eye of the beholder
%   integrates sch complex information far better than any code...)
%
%   Instead of a lengthy description of the exact content of the Excel
%   file, see the one example (climada_DFC_compare_file.xls) in the
%   core climada data results folder. Note that the code (and the format
%   of the Excel) is peril-independent. If troubles with .xls, save as
%   Excel95.
%
%   See also climada_EDS_calc and climada_EDS_DFC
% CALLING SEQUENCE:
%   climada_DFC_compare(EDS,DFC_file,Percentage_Of_Value_Flag,plot_loglog)
% EXAMPLE:
%   DFC_file=[climada_global.data_dir filesep 'results' filesep 'climada_DFC_compare_file.xls']; % the example file
%   climada_DFC_compare(EDS,DFC_file)
%   climada_DFC_compare(EDS,'',0,0,1,1/5)
%
%   % all in one, e-g frequency_screw on hazard and EDS_multiplier:
%   entity_blend=climada_assets_encode(climada_entity_load) % select 'Germany_entity.mat' and WS_Europe.mat from ws_europe module
%   module_data_dir=[fileparts(fileparts(which('climada_DFC_compare'))) filesep 'data'];
%   DFC_file=[module_data_dir filesep 'climada_DFC_compare_file.xls'];
%   frequency_screw=0.25;
%   EDS_multiplier=1/3;
%   climada_DFC_compare(climada_EDS_calc(entity_blend,...
%       winterstorm_blend_hazard_event_sets('WS_Europe_blend.mat',...
%       frequency_screw)),'',0,0,1,EDS_multiplier)
% INPUTS:
%   EDS: a climada EDS, as produced by climada_EDS_calc
%   DFC_file: an Excel file with a DFC (currently only one single DFC
%       supported).If troubles with .xls, save as Excel95 first.
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   Percentage_Of_Value_Flag: if =1, scale vertical axis with Value, such
%       that damage as percentage of value is shown, instead of damage amount,
%       default=0 (damage amount shown). Very useful to compare DFCs of
%       different portfolios to see relative differences in risk
%   plot_loglog: if =1, plot logarithmic scale both axes
%       =0 plot linear axes (default)
%   scenario_comparison_flag: also compare single scenario event losses (if
%       in Excel, as tab 'Footprint Report').
%   EDS_multiplier: a simple multiplier to multiply the EDS damage with (to
%       experiment with a correction factor, highly EXPERIMENTAL
%       (default=1, obviously)
% OUTPUTS:
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141206, initial 'Samichlaus'
% David N. Bresch, david.bresch@gmail.com, 20141212, minor edits
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('EDS','var'),                     EDS=[];                    end
if ~exist('DFC_file','var'),                DFC_file='';               end
if ~exist('Percentage_Of_Value_Flag','var'),Percentage_Of_Value_Flag=0;end
if ~exist('plot_loglog','var'),             plot_loglog=0;             end
if ~exist('scenario_comparison_flag','var'),scenario_comparison_flag=0;end
if ~exist('EDS_multiplier','var'),          EDS_multiplier=1;          end

% locate the module's data
%module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% PARAMETERS
%
% TEST:
%close all
%DFC_file=[climada_global.data_dir filesep 'results' filesep 'climada_DFC_compare_file.xls'];

% prompt for DFC_file if not given
if isempty(DFC_file) % local GUI
    DFC_file=[climada_global.data_dir filesep 'results' filesep '*.xls'];
    [filename, pathname] = uigetfile(DFC_file, 'Open file with DFC:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        DFC_file=fullfile(pathname,filename);
    end
end

% plot the EDS
% ------------
for EDS_i=1:length(EDS) % apply the EXPERIMENTAL EDS_multiplier (default=1)
    EDS(EDS_i).damage=EDS(EDS_i).damage*EDS_multiplier;
    EDS(EDS_i).ED_at_centroid=EDS(EDS_i).ED_at_centroid*EDS_multiplier;
    EDS(EDS_i).ED=EDS(EDS_i).ED*EDS_multiplier;
end % EDS_i
[~,legend_str,return_period,sorted_damage] = ...
    climada_EDS_DFC(EDS,'',Percentage_Of_Value_Flag,plot_loglog);

% read the file with DEF cor comparison
% -------------------------------------
DFC_cmp=climada_xlsread('no',DFC_file,'Loss Frequency Curve',1);
% DFC_cmp should contain (only what we need further down):
% Return_Period: [n x 1 double]
% Peril: {n x 1 cell}
% Loss: [n x 1 double]
% Loss_of_TIV: [n x 1 double]

EL_cmp=climada_xlsread('no',DFC_file,'Expected Loss',1);
% EL_cmp should contain (only what we need further down):
% TIV (we take the first number, i.e. TIV(1)
% Ground_Up_Loss (we take the first number, i.e. Ground_Up_Loss(1)

if scenario_comparison_flag
    scenario_cmp=climada_xlsread('no',DFC_file,'Footprint Report',1);
    % scenario_cmp should contain (only what we need further down, if
    % footprint_comparison_flag=1):
    % Description: {n x 1 cell}
    % Expected_Loss: [n x 1 double]
    % Return_Period: [n x 1 double]
end

% compare Value (sum insured) and damages
% ---------------------------------------
EL_cmp_TIV=NaN;
try
    EL_cmp_TIV=EL_cmp.TIV{1};
catch
    try
        EL_cmp_TIV=EL_cmp.TIV(1);
    end
end
if EL_cmp_TIV==0,EL_cmp_TIV=NaN;end % avoid division by zero
fprintf('Value (TIV) of EDS= %g, comparison=%g, EDS/cmp=%g\n',...
    EDS(1).Value,EL_cmp_TIV,EDS(1).Value/EL_cmp_TIV);

cmp_correction=EDS(1).Value/EL_cmp_TIV;
if abs(cmp_correction-1)>0.01
    fprintf('NOTE: DFC damages multiplied by %f\n',cmp_correction);
    DFC_cmp.Loss=DFC_cmp.Loss*cmp_correction;
    if scenario_comparison_flag,scenario_cmp.Expected_Loss=scenario_cmp.Expected_Loss*cmp_correction;end
end

% add the comparison to the figure
% --------------------------------
cmp_return_period=DFC_cmp.Return_Period;
if Percentage_Of_Value_Flag
    cmp_sorted_damage=DFC_cmp.Loss_of_TIV*100;
else
    cmp_sorted_damage=DFC_cmp.Loss;
end % Percentage_Of_Value_Flag

hold on;
if plot_loglog
    loglog(cmp_return_period,cmp_sorted_damage,'-g','LineWidth',3,'markersize',1);
else
    plot(cmp_return_period,cmp_sorted_damage,  '-g','LineWidth',3,'markersize',1);
end % plot_loglog

if ~isempty(legend_str) % add legend
    legend_str{end+1}=[' comparison ' DFC_cmp.Peril{1}];
    legend(legend_str,'Interpreter','none','location','nw');
end

% compare damages
% simply interpolate to the standard return periods and divide...
DFC_damage = interp1(return_period,sorted_damage,climada_global.DFC_return_periods);
cmp_damage = interp1(cmp_return_period,cmp_sorted_damage,climada_global.DFC_return_periods);

fprintf('ret per:');fprintf('%g\t\t',climada_global.DFC_return_periods);fprintf('\n');
fprintf('EDS:    ');fprintf('%g\t',DFC_damage);                         fprintf('\n');
fprintf('cmp:    ');fprintf('%g\t',cmp_damage);                         fprintf('\n');
cmp_damage(cmp_damage==0)=NaN; % avoid division by zero
fprintf('EDS/cmp:');fprintf('%g\t\t',DFC_damage./cmp_damage);           fprintf('\n');

if scenario_comparison_flag
    
    if Percentage_Of_Value_Flag
        scenario_cmp.Expected_Loss=scenario_cmp.Expected_Loss./EL_cmp_TIV*100;
    end
    
    for scenario_i=1:length(scenario_cmp.Expected_Loss)
        if plot_loglog
            loglog(scenario_cmp.Return_Period(scenario_i),...
                scenario_cmp.Expected_Loss(scenario_i),'xr','markersize',3);
        else
            plot(scenario_cmp.Return_Period(scenario_i),...
                scenario_cmp.Expected_Loss(scenario_i),'xr','markersize',3);
        end
        text(scenario_cmp.Return_Period(scenario_i),scenario_cmp.Expected_Loss(scenario_i),scenario_cmp.Description{scenario_i});
        
    end % scenario_i
    
end % scenario_comparison_flag

return
