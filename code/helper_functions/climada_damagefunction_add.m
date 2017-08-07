function damagefunctions=climada_damagefunction_add(damagefunctions,Intensity,MDD,PAA,DamageFunID,peril_ID,Intensity_unit,name)
% climada
% NAME:
%   climada_damagefunction_add
% PURPOSE:
%   Given an encoded entity, add one damagefunction
%
%   See also climada_damagefunctions_read, climada_damagefunctions_generate
%   climada_damagefunctions_replace and climada_damagefunctions_plot
% CALLING SEQUENCE:
%   damagefunctions=climada_damagefunction_add(damagefunctions,Intensity,MDD,PAA,DamageFunID,peril_ID,Intensity_unit,name)
% EXAMPLE:
%   damagefunctions=climada_damagefunction_add(damagefunctions,[1:100],[1:100].^2/10000,[1:100].^2/10000,99,'TC','m/s','TC test');
% INPUTS:
%   entity: an entity, see climada_entity_read
%       > promted for if not given (calling climada_entity_load, not
%       climada_entity_read)
%   Intensity: the intensity vector
%   MDD: the mean damage degree vector, same size as Intensity
%   PAA: the percentage of affected assets vector (in decimal), same size as Intensity
%   DamageFunID: the damage function ID, the code warns if the same ID for
%       the given peril (see peril_ID) does already exist)
%       Can either be a scaler or same size as Intensity
%   peril_ID: the (2-digit) peril ID, such as 'TC' or 'EQ'
%       Can either be a char scalar, like 'TC' or cell same size as Intensity {'TC' .. 'TC'}
% OPTIONAL INPUT PARAMETERS:
%   Intensity_unit: the unit for the intensity, default='undef'
%       Can either be a char scalar like 'm' or cell same size as Intensity
%   name: the name of the damage function, default='undef'
%       Can either be a char scalar like 'def' or cell same size as Intensity
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20170806, initial
% David N. Bresch, david.bresch@gmail.com, 20170807, allow for scalars or vectors
%-

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('damagefunctions','var'),damagefunctions=[];end
if ~exist('Intensity','var'),return;end
if ~exist('MDD','var'),return;end
if ~exist('PAA','var'),return;end
if ~exist('DamageFunID','var'),return;end
if ~exist('peril_ID','var'),return;end
if ~exist('Intensity_unit','var'),Intensity_unit='undef';end
if ~exist('name','var'),name='undef';end

% PARAMETERS
%

n_entries=length(Intensity);
if length(MDD)~=n_entries,fprintf('MDD not the same size as Intensity, aborted\n');end
if length(PAA)~=n_entries,fprintf('PAA not the same size as Intensity, aborted\n');end

if ~isfield(damagefunctions,'filename')
    damagefunctions.filename=mfilename;
end

if length(DamageFunID)==1,DamageFunID = repmat(DamageFunID,1,n_entries);end
if isfield(damagefunctions,'DamageFunID')
    damagefunctions.DamageFunID=[damagefunctions.DamageFunID DamageFunID];
else
    damagefunctions.DamageFunID=DamageFunID;
end

if size(Intensity,2)<size(Intensity,1),Intensity=Intensity';end
if isfield(damagefunctions,'Intensity')
    damagefunctions.Intensity=[damagefunctions.Intensity Intensity];
else
    damagefunctions.Intensity=Intensity;
end

if size(MDD,2)<size(MDD,1),MDD=MDD';end
if isfield(damagefunctions,'MDD')
    damagefunctions.MDD=[damagefunctions.MDD MDD];
else
    damagefunctions.MDD=MDD;
end

if size(PAA,2)<size(PAA,1),PAA=PAA';end
if isfield(damagefunctions,'PAA')
    damagefunctions.PAA=[damagefunctions.PAA PAA];
else
    damagefunctions.PAA=PAA;
end

if size(peril_ID,2)==1,peril_ID = repmat({peril_ID},1,n_entries);end
if isfield(damagefunctions,'peril_ID')
    damagefunctions.peril_ID=[damagefunctions.peril_ID peril_ID];
else
    damagefunctions.peril_ID=peril_ID;
end

if size(Intensity_unit,2)==1,Intensity_unit = repmat({Intensity_unit},1,n_entries);end
if isfield(damagefunctions,'Intensity_unit')
    damagefunctions.Intensity_unit=[damagefunctions.Intensity_unit Intensity_unit];
else
    damagefunctions.Intensity_unit=Intensity_unit;
end

if size(name,2)==1,name = repmat({name},1,n_entries);end
if isfield(damagefunctions,'name')
    damagefunctions.name=[damagefunctions.name name];
else
    damagefunctions.name=name;
end

datenum_ = repmat(now,1,n_entries); % add datenum
if isfield(damagefunctions,'datenum')
    damagefunctions.datenum=[damagefunctions.datenum datenum_];
else
    damagefunctions.datenum=datenum_;
end

end % climada_damagefunction_add