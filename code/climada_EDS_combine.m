function EDS=climada_EDS_combine(EDS1,EDS2)
% climada template
% MODULE:
%   module name
% NAME:
%   climada_EDS_combine
% PURPOSE:
%   Combine two event damage sets (EDS), i.e. add damages. The codes in
%   essence takes EDS=EDS1 and then adds relevan tfields (damage,
%   ED_at_centroid) from EDS2. Hence please make sure the 'main' peril is
%   in EDS1 (e.g. TC in EDS1, TS in EDS2).
%
%   call before: climada_EDS_calc
% CALLING SEQUENCE:
%   EDS=climada_EDS_combine(EDS1,EDS2)
% EXAMPLE:
%   EDS=climada_EDS_combine(EDS1,EDS2)
% INPUTS:
%   EDS1: a climada EDS (as returned eg by climada_EDS_calc)
%       if EDS is in fact an array of EDS(i), the code will combine all
%       matching EDSs within (e.g. TC and TS)
%   EDS2: a climada EDS (as returned eg by climada_EDS_calc)
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   EDS: the combined EDS
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150114, initial
%-

EDS=[]; % init output

global climada_global
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
    fprintf('Error: EDS(i) not implemented yet\n');
    return
else
    if length(EDS1)>1 || length(EDS2)>1
        fprintf('Error: more than one EDS in EDS1/2 not implemented yet\n');
        return
    end
    
    if length(EDS1.damage)==length(EDS2.damage)
        EDS=EDS1; % init output
        EDS.damage=EDS.damage+EDS2.damage;
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
        if abs(EDS2.Value-EDS1.Value)>0
            EDS.Value=max(EDS2.Value,EDS1.Value);
            fprintf('Warning: value differs, max taken: %g\n',EDS.Value);
        end
        if abs(EDS2.reference_year-EDS1.reference_year)>0
            EDS.reference_year=max(EDS2.reference_year,EDS1.reference_year);
            fprintf('Warning: reference_year, latest taken: %g\n',EDS.reference_year);
        end
        
        if sum(EDS2.event_ID-EDS1.event_ID)>0
            EDS.reference_year=max(EDS2.reference_year,EDS1.reference_year);
            fprintf('Severe warning: event_ID does not match, EDS1 taken\n');
        end
        
        % to do: treat/check
        % EDS1.hazard.peril_ID
        
        %          % EDS1.assets
        %
        %          filename: 'Mexico'
        %          Latitude: [1x25086 double]
        %          Longitude: [1x25086 double]
        %          Value: [1x25086 double]
        %          admin0_name: 'Mexico'
        %          admin0_ISO3: 'MEX'
        
    else
        fprintf('Error: EDS.damage length does not match, nothing added\n');
    end
end

end
