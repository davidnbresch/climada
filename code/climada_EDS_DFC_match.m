function EDS=climada_EDS_DFC_match(EDS,DFC_file,match_ED_flag)
% climada EDS DFC
% NAME:
%   climada_EDS_DFC_match
% PURPOSE:
%   Given a climada event damage set (EDS) and a  damage frequency curve
%   (DFC) from file, adjust the EDS, such that the EDS best matches the
%   DFC (e.g. to 'reproduce' other model results with climada).
%
%   Instead of a lengthy description of the exact content of the Excel
%   file, see the one example (climada_DFC_compare_file.xls) in the
%   core climada data results folder. Note that the code (and the format
%   of the Excel) is peril-independent. If troubles with .xls, save as
%   Excel95.
%
%   There are three steps:
%   1) compare and if necessary adjust for EDS to have the same total Value
%      as the DFC (i.e. adjust EDS.damage, EDS.Value, EDS.assets.Value)
%   2) compare the DFCs of the EDS with the one read from file and adjust
%      the single event damages (EDS.damage) such that the adjusted DFC based
%      on the EDS matches the one from file
%   3) recalculate EDS.ED (expected damage) and compare withe the
%      Ground_Up_Loss of the DFC. Adjust EDS.damage once more and finally
%      recalculate EDS.ED again.
%
%   See also climada_EDS_calc, climada_EDS_DFC and climada_DFC_compare
% CALLING SEQUENCE:
%   EDS=climada_EDS_DFC_match(EDS,DFC_file)
% EXAMPLE:
%   DFC_file=[climada_global.data_dir filesep 'results' filesep 'climada_DFC_compare_file.xls']; % the example file
%   EDS=climada_EDS_DFC_match(EDS,DFC_file)
% INPUTS:
%   EDS: a climada EDS, as produced by climada_EDS_calc
%       Only EDS(1) is used for comparison, further EDSs are plotted, but
%       not compared.
%   DFC_file: an Excel file with a DFC (currently only one single DFC
%       supported).If troubles with .xls, save as Excel95 first.
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   match_ED_flag: =1 make sure the expected damage (ED) is matching
%       exactly (might lead to small differences on EDS), =0, do not match ED,
%       just match the DFC (default, as this leads to perfect match for return
%       periods).
%       If you set match_ED_flag=-99, the comparison plot of the DFCs is
%       omitted
% OUTPUTS:
%   EDS: EDS such that it best matches the DFC from file (events adjusted)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150118, initial
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('EDS','var'),           EDS           = [];end
if ~exist('DFC_file','var'),      DFC_file      = '';end
if ~exist('match_ED_flag','var'), match_ED_flag =  0;end

% PARAMETERS
%
% % TEST:
% close all
% entity_file=[climada_global.data_dir filesep 'entities' filesep 'Germany_entity.mat'];
% hazard_file=[climada_global.data_dir filesep 'hazards' filesep 'DEU_Germany_eur_WS_hist.mat'];
% entity=climada_entity_load(entity_file);
% load(hazard_file);
% EDS=climada_EDS_calc(entity,hazard);
% DFC_file=[climada_global.data_dir filesep 'results' filesep 'climada_DFC_compare_file.xls'];

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
if length(EDS)>1,fprintf('Warning, only EDS(1) treated\n');end

EDS=EDS(1);

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
if EDS.Value==0,EDS.Value=NaN;end % avoid division by zero
if EL_cmp_TIV==0,EL_cmp_TIV=NaN;end % avoid division by zero
Value_factor=EL_cmp_TIV/EDS.Value;
fprintf('--> EDS Value (and damages) corrected with factor %g (EDS= %g, DFC=%g)\n',...
    Value_factor,EDS.Value,EL_cmp_TIV);

% adjust the EDS to match the Value
EDS.Value=EDS.Value*Value_factor;
if isfield(EDS,'assets'),EDS.assets.Value=EDS.assets.Value*Value_factor;end
EDS.damage=EDS.damage*Value_factor;
EDS.ED    =EDS.ED    *Value_factor;

% compare the DFC
% ---------------
[sorted_damage,exceedence_freq,~,~,event_index_out]=...
    climada_damage_exceedence(EDS.damage,EDS.frequency,1:length(EDS.damage));
nonzero_pos     = find(exceedence_freq);
sorted_damage   = sorted_damage(nonzero_pos);
exceedence_freq = exceedence_freq(nonzero_pos);
event_index_out = event_index_out(nonzero_pos);
return_period   = 1./exceedence_freq;

% interpolate DFC_cmp damages to return periods as in EDS
DFC_cmp_damage = interp1(DFC_cmp.Return_Period,DFC_cmp.Loss,return_period,'linear');
DFC_cmp_damage(isnan(DFC_cmp_damage))=0;

% multiply each event damage withe the appropriate factor
EDS2DFC_factor=sorted_damage*0; % init
nonzero_pos = find(sorted_damage);
EDS2DFC_factor(nonzero_pos)=DFC_cmp_damage(nonzero_pos)./sorted_damage(nonzero_pos); % per event factor
fprintf('--> event damages corrected with factors %f..%f\n',...
    min(EDS2DFC_factor(EDS2DFC_factor>0)),max(EDS2DFC_factor(EDS2DFC_factor>0)))
EDS.damage(event_index_out)=EDS.damage(event_index_out).*EDS2DFC_factor; % apply factor to each event

% adjustement for annual expected loss
EDS.ED=EDS.damage*EDS.frequency';

if match_ED_flag>0 && isfield(EL_cmp,'Ground_Up_Loss')
    if EL_cmp.Ground_Up_Loss>0
        ED_factor=EL_cmp.Ground_Up_Loss/EDS.ED;
        fprintf('--> ED (expected damage) corrected with %f\n',ED_factor);
        EDS.damage=EDS.damage*ED_factor; % apply to damages
        EDS.ED=EDS.damage*EDS.frequency'; % update ED
    end
end

% recalculate the DFC of the EDS
[sorted_damage2,exceedence_freq2]=climada_damage_exceedence(EDS.damage,EDS.frequency);
nonzero_pos      = find(exceedence_freq2);
sorted_damage2   = sorted_damage2(nonzero_pos);
exceedence_freq2 = exceedence_freq2(nonzero_pos);
return_period2   = 1./exceedence_freq2;

% compare damages on standard return periods again
% ---------------
% simply interpolate to the standard return periods and divide...
EDS_damage     = interp1(return_period2,       sorted_damage2,climada_global.DFC_return_periods);
DFC_cmp_damage = interp1(DFC_cmp.Return_Period,DFC_cmp.Loss,  climada_global.DFC_return_periods);

% factors should now all be one or close to
fprintf('ret per:');fprintf('%g\t\t',climada_global.DFC_return_periods);fprintf('\n');
fprintf('EDS:    ');fprintf('%g\t',EDS_damage);                         fprintf('\n');
fprintf('DFC:    ');fprintf('%g\t',DFC_cmp_damage);                         fprintf('\n');
DFC_cmp_damage(DFC_cmp_damage==0)=NaN; % avoid division by zero
fprintf('EDS/DFC:');fprintf('%g\t',EDS_damage./DFC_cmp_damage);             fprintf('\n');

if match_ED_flag>-99
    plot(climada_global.DFC_return_periods,DFC_cmp_damage,'-g','LineWidth',3);hold on
    plot(climada_global.DFC_return_periods,EDS_damage,'.b');
    plot(climada_global.DFC_return_periods,EDS_damage,'-b');
    [~,fN]=fileparts(DFC_file);
    legend(['DFC: ' strrep(fN,'_',' ')],['EDS: ' strrep(EDS.annotation_name,'_',' ')]);
    set(gcf,'Color',[1 1 1])
end

end % climada_EDS_DFC_match
