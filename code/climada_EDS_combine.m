function EDS=climada_EDS_combine(EDS1,EDS2)
% climada EDS combine
% MODULE:
%   core
% NAME:
%   climada_EDS_combine
% PURPOSE:
%   Combine two event damage sets (EDS), i.e. add damages. The codes in
%   essence takes EDS=EDS1 and then adds relevant fields (damage,
%   ED_at_centroid) from EDS2. Hence please make sure the 'main' peril is
%   in EDS1 (e.g. TC in EDS1, TS in EDS2).
%
%   call before: climada_EDS_calc
%   see also: country_risk_EDS_combine, which also allows to calculate the
%       maximally combined EDS
% CALLING SEQUENCE:
%   EDS=climada_EDS_combine(EDS1,EDS2)
% EXAMPLE:
%   EDS=climada_EDS_combine(EDS1,EDS2)
% INPUTS:
%   EDS1: a climada EDS (as returned eg by climada_EDS_calc)
%       if EDS1 is in fact an array of EDS1(i), the code will combine all
%       matching EDSs within (e.g. TC and TS)
%       This way, climada_EDS_combine can be called once to sum up all
%       matching EDSs within an EDS(i)
%   EDS2: a climada EDS (as returned eg by climada_EDS_calc)
%       if EDS2 is an array of EDS2(i), the code will recursively treat
%       them
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   EDS: the combined EDS
%       Please note that assets are likely not meaningful, since just taken
%       from EDS1 (in order to allow to store resulting EDS back into an
%       array of EDSs if needed)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150114, initial
% David N. Bresch, david.bresch@gmail.com, 20150203, array of EDS1 and empty EDS2 allowed
%-

EDS=[]; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('EDS1','var'),return;end
if ~exist('EDS2','var'),EDS2=[];end

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
% set default value for param2 if not given

if isempty(EDS2)
    if length(EDS1)==1
        EDS=EDS1;
        return % nothing to do
    else
        % EDS1 contains more than one EDS, try recursive
        fprintf('more than one EDS1\n');
        EDS=climada_EDS_combine(EDS1(1),EDS1(2:end));
        return
    end
elseif length(EDS2)>1
    % EDS2 contains more than one EDS, try recursive
    fprintf('more than one EDS2\n');
    EDS2=climada_EDS_combine(EDS2(1),EDS2(2:end));
end

% by now, EDS1 and EDS2 should be one EDS each
if length(EDS1)>1 || length(EDS2)>1
    fprintf('Error: more than one EDS in EDS1/2 not implemented yet\n');
    return
end

EDS=EDS1; % init output

if length(EDS1.damage)==length(EDS2.damage)
    EDS.damage=EDS.damage+EDS2.damage;
    EDS.Value =EDS.Value+ EDS2.Value;
    EDS.comment=sprintf('combined %s & %s',char(EDS.hazard.peril_ID),char(EDS2.hazard.peril_ID));
    EDS.annotation_name=[EDS.annotation_name ' & ' EDS2.annotation_name];
    EDS.ED=EDS.damage*EDS.frequency'; % re-calculate ED
    
    % consistency checks
    if length(EDS1.ED_at_centroid)==length(EDS2.ED_at_centroid)
        EDS.ED_at_centroid=EDS.ED_at_centroid+EDS2.ED_at_centroid;
    else
        fprintf('Warning: ED_at_centroid length differs, using EDS1, set to zero\n');
        EDS.ED_at_centroid=EDS.ED_at_centroid*0;
    end
    if abs(EDS2.reference_year-EDS1.reference_year)>0
        EDS.reference_year=max(EDS2.reference_year,EDS1.reference_year);
        fprintf('Warning: reference_year, latest taken: %g\n',EDS.reference_year);
    end
    
    if sum(EDS2.event_ID-EDS1.event_ID)>0
        EDS.reference_year=max(EDS2.reference_year,EDS1.reference_year);
        fprintf('Severe warning: event_ID does not match, EDS1 taken\n');
    end
    
    % simple treatment of sub-perils
    if strcmp(EDS.hazard.peril_ID,'TS'),EDS.hazard.peril_ID='TC';end
    if strcmp(EDS.hazard.peril_ID,'TR'),EDS.hazard.peril_ID='TC';end
    
%     % cumbersome (or imposible) to combine assets, only keep track of source
%     % BUT: if assets structure is changed, we might later have troubles
%     % assigning the output as an EDS(i) - hence we might re-consider this
%     % section here (just comment it if you run into troubles)
%     assets_filename{1}=EDS1.assets.filename;
%     assets_filename{2}=EDS2.assets.filename;
%     EDS=rmfield(EDS,'assets');
%     EDS.assets.filename=assets_filename;
    
else
    fprintf('Error: EDS.damage length does not match, nothing added\n');
end

end % climada_EDS_combine
