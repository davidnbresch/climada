function [EDS,ok]=climada_EDS_combine(EDS,EDS2,force_combination,verbose)
% climada EDS combine
% MODULE:
%   core
% NAME:
%   climada_EDS_combine
% PURPOSE:
%   Combine two event damage sets (EDS), i.e. add damages. You can either
%   pass one array of EDSs in EDS, in which case all matching EDSs within are
%   combined (even if they are not stored at subsequent positions), or you
%   can pass EDS and EDS2, in which case the code first combines any
%   matching EDSs in EDS and then adds from EDS2.
%   In this latter case, please make sure the 'main' peril(s) are
%   in EDS (e.g. TC in EDS, TS in EDS2). Note that ONLY damages are
%   added, we do NOT add Value/assets, as most often the sub-peril is on
%   the same asset base. Hence edit the resulting EDS yourself in case
%   Value should be additive.
%
%   call before: climada_EDS_calc, e.g.
%       EDS(1)=climada_EDS_calc, EDS(2)=climada_EDS_calc ...
%   see also: country_risk_EDS_combine (climada module country_risk)
% CALLING SEQUENCE:
%   [EDS,ok]=climada_EDS_combine(EDS,EDS2,force_combination,verbose)
% EXAMPLE:
%   EDS=climada_EDS_combine(EDS)
% INPUTS:
%   EDS: a climada EDS (as returned eg by climada_EDS_calc)
%       if EDS is in fact an array of EDS(i), the code will combine all
%       matching EDSs within (e.g. TC and TS, if damage vector is of same length)
%       This way, climada_EDS_combine can be called once to sum up all
%       matching EDSs.
% OPTIONAL INPUT PARAMETERS:
%   EDS2: a climada EDS (as returned eg by climada_EDS_calc)
%       if EDS2 is an array of EDS2(i), the code will recursively treat
%       them. Please note that more complex cases need to be treated using
%       only EDS (e.g. sub-perils not following each other in sequence in
%       the EDS).
%   force_combination: also combine if ok=0 upon return when combining
%       recursively. Default=1, Set =0 to only combine EDSs that match
%       perfectly (i.e. same reference_year and event_ID)
%   verbose: =1 print information about combining to stdout, =0 only print
%       errors, othwerwise silent
% OUTPUTS:
%   EDS: the combined EDS
%       Please note that assets are just taken from the first EDS(i) of each
%       (sub) hazard. 
%   ok: =1 if combination successful, =0 otherwise, also if the basic
%       combination worked (same length of damage vector), but some issues
%       with either ED_at_centroid, reference_year, frequency or event_ID
%       occurred. In some instances, it might still be justified to use the
%       combined EDS, even if ok=0 upon return.
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150114, initial
% David N. Bresch, david.bresch@gmail.com, 20150203, array of EDSs and empty EDS2 allowed
% David N. Bresch, david.bresch@gmail.com, 20150215, Value taken from EDS, not added
% David N. Bresch, david.bresch@gmail.com, 20151231, major overhaul, mastering complex cases, like many sub-perils at once
%-

ok=0; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('EDS','var'),EDS=[];return;end
if ~exist('EDS2','var'),EDS2=[];end
if ~exist('force_combination','var'),force_combination=1;end
if ~exist('verbose','var'),verbose=0;end

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below

if length(EDS)>1 % a bit of analysis of EDS
    damage_length=zeros(1,length(EDS)); % init
    for EDS_i=1:length(EDS)
        damage_length(EDS_i)=length(EDS(EDS_i).damage);
    end % EDS_i
    
    % we now call climada_EDS_combine for all EDSs with the same length of
    % EDS(i).damage. 
    unique_damage_length=unique(damage_length);
    pos_vect=1:length(damage_length); % init
    EDS_ok=ones(1,length(damage_length)); % init
    for unique_i=1:length(unique_damage_length)
        % find all EDSs with same damage vector length (all other checks happen below)
        ismember_i=ismember(damage_length,unique_damage_length(unique_i));
        ismember_i=pos_vect(ismember_i); % convert boolean to index
        for member_i=2:length(ismember_i) % more than one with same length
            if verbose
                fprintf('combining %i (%s) and %i (%s)\n',...
                ismember_i(1),       EDS(ismember_i(1)).peril_ID,...
                ismember_i(member_i),EDS(ismember_i(member_i)).peril_ID);
            end
            % kind of recursively calling climada_EDS_combine
            [EDS_one,comb_ok]=climada_EDS_combine(EDS(ismember_i(1)),EDS(ismember_i(member_i)));
            if comb_ok || force_combination % either ok or forced
                EDS(ismember_i(1))=EDS_one;
                EDS_ok(ismember_i(member_i))=0; % mark the added one
            end
        end % member_i
    end % unique_i
    EDS=EDS(logical(EDS_ok)); % keep only non-touched and combined ones
end % length(EDS)>1

if isempty(EDS2)
    return % all done with EDS
elseif length(EDS2)>1
    % just add to EDS, then call climada_EDS_combine for the full EDS again
    EDS=[EDS EDS2];
    if verbose,fprintf('more than one EDS in EDS2 - recursion\n');end
    EDS=climada_EDS_combine(EDS);
    return
end

% by now, EDS and EDS2 should be one EDS each
if length(EDS)>1 || length(EDS2)>1
    fprintf('ERROR: more than one EDS in EDS2 (after recursion, should not occurr ;-)\n');
    return
end

if length(EDS.damage)==length(EDS2.damage)
    EDS.damage=EDS.damage+EDS2.damage;
    % Note: do NOT add EDS.Value, as most often the sub-peril is on the same asset base
    EDS.comment=sprintf('combined %s & %s',char(EDS.hazard.peril_ID),char(EDS2.hazard.peril_ID));
    EDS.annotation_name=[EDS.annotation_name ' & ' EDS2.annotation_name];
    EDS.ED=EDS.damage*EDS.frequency'; % re-calculate ED
    ok=1;
    
    % consistency checks
    
    if length(EDS.ED_at_centroid)==length(EDS2.ED_at_centroid)
        EDS.ED_at_centroid=EDS.ED_at_centroid+EDS2.ED_at_centroid;
    else
        fprintf('Warning: ED_at_centroid length differs, using EDS, set to zero\n');
        EDS.ED_at_centroid=EDS.ED_at_centroid*0;
        ok=0;
    end
    
    if abs(EDS2.reference_year-EDS.reference_year)>0
        EDS.reference_year=max(EDS2.reference_year,EDS.reference_year);
        fprintf('Warning: reference_year, latest taken: %g\n',EDS.reference_year);
        ok=0;
    end
    
    if sum(EDS2.event_ID-EDS.event_ID)>0
        fprintf('Severe warning: event_ID does not match, EDS taken\n');
        ok=0;
    end
    
    if sum(EDS2.frequency-EDS.frequency)>0
        fprintf('Severe warning: frequency does not match, EDS taken\n');
        ok=0;
    end
    
    % simple treatment of sub-perils (hard-wired names ...)
    if strcmp(EDS.hazard.peril_ID,'TS'),EDS.hazard.peril_ID='TC';end
    if strcmp(EDS.hazard.peril_ID,'TR'),EDS.hazard.peril_ID='TC';end
    if strcmp(EDS.peril_ID,'TS'),EDS.peril_ID='TC';end
    if strcmp(EDS.peril_ID,'TR'),EDS.peril_ID='TC';end
    
else
    fprintf('ERROR: EDS.damage length does not match, nothing added\n');
    ok=0;
end

end % climada_EDS_combine