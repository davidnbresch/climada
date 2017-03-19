function [res,params]=climada_calibrate(entity,hazard,damage_data,params)
% climada template
% MODULE:
%   module name
% NAME:
%   climada_template
% PURPOSE:
%   calibrate one single peril for a given set of assets (e.g. within a
%   country or region) and a set of reported damages.
%
%   Since the code is quite versatile, the input damage_data can be of
%   different from (mapped to events, unmapped but with hazard index or
%   with unique ID, unmapped and just to be used 'bulk'). See description
%   of damage_data and please read once the whole.
%
%   previous call: many
%   next call: climada_EDS_calc, see also: climada_DFC_compare
% CALLING SEQUENCE:
%   res=climada_calibrate(entity,hazard,damage_data,params)
% EXAMPLE:
%   p.hazard_file='GLB_0360as_TC_hist';entity=isimip_gdp_entity('USA',p);
%   entity=climada_entity_load('USA_0360as_entity');
%   damage_data=isimip_damage_read('','',entity.hazard.ID_no);
%   pos=strmatch('USA',damage_data.ISO);damage_data=climada_subarray(damage_data,pos);  
%   res=climada_calibrate(entity,[],damage_data);
%   params=climada_calibrate('params'); % return default parameters
% INPUTS:
%   entity: an entity structure or an entity .mat file, see climada_assets_encode(climada_assets_read)
%       If a file and no path provided, default path ../data/entities is
%       used (and name can be without extension .mat)
%       > promted for if not given
%       SPECIAL: entity might contain hazard in entity.hazard 
%       SPECIAL: entity might contain damage_data in entity.damage_data
%       if ='params', just return default parameters, in res, i.e. the
%           first output, already.
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       If a file and no path provided, default path ../data/hazards is
%       used (and name can be without extension .mat). If hazard is empty
%       and entity contains hazard in entity.hazard, this hazard is used.
%       Minimum fileds of hazard struct are: 
%       peril_ID, event_ID, centroid_ID, intensity and frequency 
%   damage_data: a structure with damage data, mapped onto single events to
%       match with hazard, four options:
%     damage data mapped to events already:
%       damage(record_i): the reported damage for event i, which
%           corresponds to event_i in the hazard, i.e. to
%           hazard.event_ID(event_i) etc., with damage(event_i)=0 for all
%           events with no damage.
%       NOTE: if length of damage_data.damage and number of events in
%       hazard is exactly the same, we assume this option to be the case.
%     damage with a mapping table:
%       damage(i): damage for record i
%       hazard_index(i): index into hazard.*(hazard_index(i))
%     damage with a unique ID as in the hazard
%       damage(i): damage for record i
%       ID_no(i): ID which corresponds to hazard.ID_no
%     just a set of damages, not associated with hazard events:
%       damage(i): damage of damage record i, not mapped to any event
%     for all three options, we have the following additional field(s)
%       n_years: the number of years the damage records represent (prio 1),
%           as this can be more years than between min/max(year) OR
%       year(i): year of record i (prio 2). If present, we can at least
%           macth by year and compare simulated vs reported annual damage
%       frequency(i): occurence frequency of damage record i
%       NOTE: if none of n_years, year or frequency is provided, we assume
%           the same timespan as for hazard, i.e. hazard.frequency
% OPTIONAL INPUT PARAMETERS:
%   params: a structure with fields (see also entity='params' above):
%    log10: if =1 (default, show log10(damages), linear else (=0)
% OUTPUTS:
%   res: the output, empty if not successful
%       =params, if entity='params' on input
%   params: as on input, plus some information
%    damage_data_type: which type of mapping reorted with simulated damages
%       has been used.
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20170315, initial
%-

res=[]; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('entity','var'),entity=[];end
if ~exist('hazard','var'),hazard=[];end
if ~exist('damage_data','var'),damage_data=[];end
if ~exist('params','var'),params=struct;end

% locate the module's (or this code's) data folder (usually  a folder
% 'parallel' to the code folder, i.e. in the same level as code folder)
%module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% PARAMETERS
%
% pass all parameters via params
if isstruct(params)
    if ~isfield(params,'damage_data_type'),params.damage_data_type='';end % output!
    if ~isfield(params,'log10'),params.log10=[];end
end
%
if isempty(params.log10),params.log10=1;end

if strcmpi(entity,'params'),res=params;return;end % special case, return the full params structure

entity=climada_entity_load(entity);
if isempty(entity),return;end

% check whether entity contains hazard and/or damage data
if isempty(hazard)      && isfield(entity,'hazard'),     hazard     =entity.hazard;end
if isempty(damage_data) && isfield(entity,'damage_data'),damage_data=entity.damage_data;end

% check for different options of damage data
if length(damage_data.damage)==length(hazard.event_ID)
    % we assume damage data mapped to events already, with
    % damage(event_i)=0 for all events with no damage
    % damage(record_i): the reported damage for event i, which
    % corresponds to event_i in the hazard, i.e. to hazard.event_ID(event_i) etc.
    damage_data.hazard_index=1:length(damage_data.damage); % has to match
    params.damage_data_type='matching event_ID';
elseif isfield(damage_data,'hazard_index')
    % damage(i): damage for record i
    % hazard_index(i): index into hazard.*(hazard_index(i))
    params.damage_data_type='matching hazard_index';
elseif isfield(damage_data,'ID_no') && isfield(hazard,'ID_no')
    matched=0;
    not_matched=0;
    n_records=length(damage_data.ID_no);
    damage_data.hazard_index  =damage_data.ID_no*0; % init
    damage_data.hazard_matched=damage_data.hazard_index; % init
    for record_i=1:n_records % we do this explicitely for lisibility
        pos=find(hazard.ID_no==damage_data.ID_no(record_i));
        if length(pos)==1
            damage_data.hazard_index(record_i)=pos;
            damage_data.hazard_matched(record_i)=1;
            matched=matched+1;
        else
            not_matched=not_matched+1;
        end
    end % record_i
    damage_data.hazard_matched=logical(damage_data.hazard_matched);
    
    fprintf('%i of %i (%i%%) records matched with hazard events (%i%% of total damage value)\n',...
        matched,n_records,ceil(matched/n_records*100),...
        ceil(sum(damage_data.damage(damage_data.hazard_matched))/sum(damage_data.damage)*100));
    
    % only keep matched damage records
    damage_data=climada_subarray(damage_data,damage_data.hazard_matched);
    params.damage_data_type='matching hazard_index (ID_no)';
else
    params.damage_data_type='no matching';
end
    
% complete damage data
if ~isfield(damage_data,'Value'),damage_data.Value=[];end
if ~isfield(damage_data,'peril_ID'),damage_data.peril_ID='';end
if ~isfield(damage_data,'ED'),damage_data.ED=[];end
if ~isfield(damage_data,'frequency')
    damage_data.frequency=damage_data.damage*0+1;
    if ~isfield(damage_data,'n_years') && isfield(damage_data,'year')
        damage_data.n_years=max(damage_data.year)-min(damage_data.year)+1;
    end
    if isfield(damage_data,'n_years')
        damage_data.frequency=damage_data.frequency/damage_data.n_years;
    else
        fprintf('No year or frequency information in damage_data, assuming same timespan/frequency as hazard\n')
        damage_data.frequency=damage_data.frequency*(hazard.frequency(1));
    end
end

% construct the damage data DFC
EDS_damage.frequency=damage_data.frequency;
EDS_damage.damage=damage_data.damage;
EDS_damage.Value=damage_data.Value;
EDS_damage.peril_ID=damage_data.peril_ID;
EDS_damage.ED=[];
DFC_damage=climada_EDS2DFC(EDS_damage);

% % experimental section to replace damage function
% [damagefunctions,dmf_info_str]=climada_damagefunctions_generate(0:5:120,15,1.3,1,'s-shape','TC',0,90); % fits globally well
% fprintf('replacing TC damagefunction with: %s\n',dmf_info_str);
% entity=climada_damagefunctions_replace(entity,damagefunctions);
    
% calculate the simulated EDS

if isfield(entity.assets,'Values') && exist('isimip_YDS_calc','file')
    [~,EDS]=isimip_YDS_calc(entity,hazard); % annual assets based calculation
else
    EDS=climada_EDS_calc(entity,hazard); % standard calculation (fixed assets)
end

DFC=climada_EDS2DFC(EDS); % DFC contains also damage_of_value, i.e. damage as % of value

title_str=strrep(DFC.annotation_name,'_',' ');

if params.log10
    label_damage_rep=sprintf('log10(damage) reported [%s]',entity.assets.Value_unit{1});
    label_damage_sim=sprintf('log10(damage) simulated [%s]',entity.assets.Value_unit{1});
    label_damage=sprintf('log10(damage) [%s]',entity.assets.Value_unit{1});
else
    label_damage_rep=sprintf('damage reported [%s]',entity.assets.Value_unit{1});
    label_damage_sim=sprintf('damage simulated [%s]',entity.assets.Value_unit{1});
    label_damage=sprintf('damage [%s]',entity.assets.Value_unit{1});
end

% minimum, we can compare the DFCs
figure('Name','DFC','Color',[1 1 1]);
plot(DFC_damage.return_period,log10(DFC_damage.damage),'-b');hold on
plot(DFC.return_period,log10(DFC.damage),'-g')
title(title_str);
xlabel('return period [years]');ylabel(label_damage);legend({label_damage_rep,label_damage_sim})

% if years are present, we can compare annual damage
if isfield(damage_data,'year')
    unique_years=unique([damage_data.year,hazard.yyyy]);
    damage_rep=unique_years*0;
    damage_sim=unique_years*0;
    for year_i=1:length(unique_years)
        damage_rep(year_i)=sum(damage_data.damage(damage_data.year==unique_years(year_i)));
        damage_sim(year_i)=sum(EDS.damage(hazard.yyyy==unique_years(year_i)));
    end % year_i
    figure('Name','annual view','Color',[1 1 1]);
    subplot(1,2,1)
    plot(unique_years,damage_rep,'-b'); hold on
    plot(unique_years,damage_sim,'-g')
    title(title_str);xlabel('years');legend({label_damage_rep,label_damage_sim})
    subplot(1,2,2)
    plot(damage_rep,damage_sim,'.r'); hold on
    max_damage=max(max(damage_rep),max(damage_sim));
    plot([0 max_damage],[0 max_damage],':k');
    title(title_str);xlabel(label_damage_rep);ylabel(label_damage_sim);
end % year

% if events do match, we can compare by event
if isfield(damage_data,'hazard_index')
    
    % % to double-check mapping:
    % for i=1:length(damage_data.ID_no)
    %     fprintf('%10.10f %s\n',damage_data.ID_no(i),...
    %         entity.hazard.name{damage_data.hazard_index(i)});
    % end
    
    damage_rep=damage_data.damage(damage_data.hazard_index>0); % all matched
    damage_sim=EDS.damage(damage_data.hazard_index);
    figure('Name','per event view','Color',[1 1 1]);
    plot(damage_rep,damage_sim,'.r'); hold on
    max_damage=max(max(damage_rep),max(damage_sim));
    plot([0 max_damage],[0 max_damage],':k');
    title(title_str);xlabel(label_damage_rep);ylabel(label_damage_sim);
end % year

end % climada_calibrate