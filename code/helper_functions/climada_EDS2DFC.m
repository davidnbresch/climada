function DFC=climada_EDS2DFC(EDS,return_period)
% climada
% NAME:
%   climada_EDS2DFC
% PURPOSE:
%   convert an event damage set (EDS) into a Damage exceedence Frequency Curve (DFC)
%
%   prior call: climada_EDS_calc
%   See also: climada_EDS_DFC (which plots the DFC)
% CALLING SEQUENCE:
%   DFC=climada_EDS2DFC(EDS,return_period)
% EXAMPLE:
%   DFC=climada_EDS2DFC(climada_EDS_calc)
% INPUTS:
%   EDS: either an event damage set (or many, i.e. EDS(i), as e.g. returned by climada_EDS_calc or
%       a file containing such a structure
%       SPECIAL: we also accept a structure which contains an EDS, like
%       measures_impact.EDS
%       if EDS has the field annotation_name, the legend will show this
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   return_period: the vector of return periods for which we'd like to
%       obtain the damage. Default are the return periods as defined in
%       climada_global.DFC_return_periods
%       if empty, the default return periods as in climada_global.DFC_return_periods are used
%       if =-1, all points as returned by climada_damage_exceedence are used
%       if ='AED', the annual expected damage is returned, with return period=1
% OUTPUTS:
%   DFC: a strcture with a damage frequency curve (DFC)
%       return_period(i): the return periods
%       damage(i): the damage for return_period(i)
%       damage_of_value(i): damage as percentage of total asset value
%       peril_ID: the peril_ID
%       value: the total asset value
%       ED: the annual expected damage
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150120, initial
% David N. Bresch, david.bresch@gmail.com, 20160429, DFC.Value instead of DFC.value
% David N. Bresch, david.bresch@gmail.com, 20170504, allow for return_period='AED'
% David N. Bresch, david.bresch@gmail.com, 20170626, DFC.Value_unit
%-

DFC=[]; % init

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('EDS','var'),EDS=[];end
if ~exist('return_period','var'),return_period=climada_global.DFC_return_periods;end

if return_period(1)==-1;return_period=[];end % to force returning all

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

if exist('measures_impact','var') % if a results file is loaded
    EDS=measures_impact.EDS;
end

if isfield(EDS,'EDS')
    EDS_temp = EDS;
    EDS      = EDS_temp.EDS;
    EDS_temp = [];
end

% now, we're ready to do the conversion

for EDS_i=1:length(EDS)
    
    [sorted_damage,exceedence_freq]...
        = climada_damage_exceedence(EDS(EDS_i).damage,EDS(EDS_i).frequency);
    nonzero_pos     = find(exceedence_freq);
    sorted_damage   = sorted_damage(nonzero_pos);
    exceedence_freq = exceedence_freq(nonzero_pos);
    EDS_return_period   = 1./exceedence_freq;
    
    DFC(EDS_i).Value           = EDS(EDS_i).Value;
    DFC(EDS_i).Value_unit      = EDS(EDS_i).Value_unit;
    DFC(EDS_i).ED              = EDS(EDS_i).ED;
    DFC(EDS_i).peril_ID        = EDS(EDS_i).peril_ID;
    if isempty(return_period)
        % return all return periods
        DFC(EDS_i).damage          = sorted_damage;
        DFC(EDS_i).return_period   = EDS_return_period;
    elseif ischar(return_period)
        if ~strcmpi(return_period,'AED'),fprintf('WARNING: returning AED\n');end
        % simply return the annual expected damage
        DFC(EDS_i).damage=DFC(EDS_i).ED;
        DFC(EDS_i).return_period   = 1;
    else
        % simply interpolate to the standard return periods
        DFC(EDS_i).damage          = interp1(EDS_return_period,sorted_damage,return_period);
        DFC(EDS_i).return_period   = return_period;
    end
    if ~isempty(DFC(EDS_i).Value)
        DFC(EDS_i).damage_of_value = DFC(EDS_i).damage/DFC(EDS_i).Value;
    end
    
    if isfield(EDS(EDS_i),'annotation_name')
        DFC(EDS_i).annotation_name=EDS(EDS_i).annotation_name;
    else
        DFC(EDS_i).annotation_name='';
    end
    
end % EDS_i

end % climada_EDS2DFC