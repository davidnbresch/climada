function res = climada_EDS_DFC_report(EDS,Percentage_Of_Value_Flag,report_style)
% climada
% NAME:
%   climada_EDS_DFC_report
% PURPOSE:
%   plot occurrence Damage exceedence Frequency Curve (DFC)
% CALLING SEQUENCE:
%   res=climada_EDS_DFC_report(EDS,Percentage_Of_Value_Flag,report_style)
% EXAMPLE:
%   res=climada_EDS_DFC_report(climada_EDS_calc(climada_entity_read))
% INPUTS:
%   EDS: either an event damage set, as e.g. returned by climada_EDS_calc or
%       a file containing such a structure
%       SPECIAL: we also accept a structure which contains an EDS, like
%       measures_impact.EDS
%       if EDS has the field annotation_name, the legend will show this
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   Percentage_Of_Value_Flag: if =1, scale vertical axis with Value, such
%       that damage as percentage of value is shown, instead of damage amount,
%       default=0 (damage amount shown). Very useful to compare DFCs of
%       different portfolios to see relative differences in risk
%   report_style: 'lean' for only the damages at predefined return periods
%       'std' (default): the damages at return periods.
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
if ~exist('Percentage_Of_Value_Flag','var'),Percentage_Of_Value_Flag=0;end
if ~exist('report_style','var'),report_style='std';end

% PARAMETERS
%

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

% load the entity, if a filename has been passed
if ~isstruct(EDS)
    EDS_file=EDS;EDS=[];
    load(EDS_file);
end

if exist('measures_impact','var') % if a results file is loaded
    EDS=measures_impact.EDS;
end

if isfield(EDS,'EDS')
    EDS_temp = EDS;
    EDS      = EDS_temp.EDS;
    EDS_temp = [];
end

DFC_exceedence_freq = 1./climada_global.DFC_return_periods;

for EDS_i=1:length(EDS)
    [sorted_damage,exceedence_freq] = climada_damage_exceedence(EDS(EDS_i).damage, EDS(EDS_i).frequency);
    nonzero_pos                   = find(exceedence_freq);
    sorted_damage                   = sorted_damage(nonzero_pos);
    exceedence_freq               = exceedence_freq(nonzero_pos);
    if Percentage_Of_Value_Flag
        sorted_damage = sorted_damage/EDS(EDS_i).Value*100;
    end
    res.return_periods            = climada_global.DFC_return_periods;
    res.damage(EDS_i,:)             = interp1(exceedence_freq,sorted_damage,DFC_exceedence_freq);
    
end % EDS_i

if strcmp(report_style,'lean')
    tmp = res;
    res = [];
    res = tmp.damage;
end

return
