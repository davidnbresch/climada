function res=climada_calibrate(entity,hazard,damage_data,params)
% climada template
% MODULE:
%   module name
% NAME:
%   climada_template
% PURPOSE:
%   calibrate one single peril for a given set of assets and a set of
%   reported damages
%
%   previous call: many
%   next call: climada_EDS_calc
% CALLING SEQUENCE:
%   res=climada_calibrate(entity,hazard,damage_data,params)
% EXAMPLE:
%   p.hazard_file='GLB_0360as_TC_hist';entity=isimip_gdp_entity('USA',p);
%   entity=climada_entity_load('USA_0360as_entity');
%   damage_data=isimip_damage_read(damage_data_file,price_deflator_file,hazard.ID_no);
%   res=climada_calibrate(entity,[],damage_data,params);
%   params=climada_calibrate('params'); % return default parameters
% INPUTS:
%   entity: an entity structure or an entity .mat file, see climada_assets_encode(climada_assets_read)
%       If a file and no path provided, default path ../data/entities is
%       used (and name can be without extension .mat)
%       > promted for if not given
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       If a file and no path provided, default path ../data/hazards is
%       used (and name can be without extension .mat). If hazard is empty
%       and entity contains hazard in entity.hazard, this hazard is used.
%       > promted for if not given
%       Minimum fileds of hazard struct are: 
%       peril_ID, event_ID, centroid_ID, intensity and frequency 
%   damage_data: a structure with damage data, mapped onto single events to
%       match with hazard, such as:
%       damage_data.damage(event_i): the reported dmage for event:i, which
%       corresponds to event_i in the hazard, i.e. to hazard.event_ID(event_i) etc. 
%       OR just a set of damages and their frequency, i.e.
%       damage_data.damage(i): damage of damage event i
%       damage_data.frequency(i): occurence frequency of damage event i
%   params: a structure with the fields:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   res: the output, empty if not successful
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20170305, initial
%-

res=[]; % init output

global climada_global
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
% define all parameters here - no parameters to be defined in code below
%
% if we want to pass all parameters via the first argument, we can do so:
if isstruct(params)
    if ~isfield(params,'field1'),params.field1='';end
end

entity=climada_entity_load(entity);
if isempty(entity),return;end

if ~isempty(damage_data)
    if isfield(entity,'damage_data')
        damage_data=entity.damage_data;
    end
end

if ~isfield(damage_data,'Value'),damage_data.Value=[];end
if ~isfield(damage_data,'peril_ID'),damage_data.peril_ID='';end
if ~isfield(damage_data,'ED'),damage_data.ED=[];end
if ~isfield(damage_data,'frequency')
    if isfield(damage_data,'n_years')
        damage_data.frequency=(damage_data.damage*0+1)/n_years;
    end
else
    fprintf('ERROR: damage does neither have frequency nor n_years, aborted\n');
    return
end

% construct the damage data DFC
EDS_damage.frequency=damage_data.frequency;
EDS_damage.damage=damage_data.damage;
EDS_damage.Value=damage_data.Value;
EDS_damage.peril_ID=damage_data.peril_ID;
DFC_damage=climada_EDS2DFC(EDS_damage);

% calculate the simulaed EDS
if isempty(hazard) && isfield(entity,'hazard')
    EDS=climada_EDS_calc(entity,entity.hazard);
else
    EDS=climada_EDS_calc(entity,hazard);
end

DFC=climada_EDS2DFC(EDS);
%DFC contains also damage_of_value, i.e. damage as % of value

plot(DFC.return_period,DFC.damage)
plot(DFC_damage.return_period,DFC_damage.damage)
title(DFC.annotation_name);
xlabel('return period [years]');
legend({'simulated','reported'})

end % climada_calibrate