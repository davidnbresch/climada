function EDS=climada_EDS_calc_fast(entity,hazard,damagefunction,use_YDS,damage_only,annotation_name,do_checks,silent_mode)
% climada calculate event damage set very fast, with minimal checks
% NAME:
%   climada_EDS_calc_fast
% PURPOSE:
%   this is a fast version of climada_EDS_calc, only to be used by expert
%   users. Very few checks are being made and the function will return the
%   correct output only if
%   (1) the centroids of entity and hazard are the same (incl. same order),
%   (2) the damagefunction is the same for all centroids and provided as
%   input directly,
%   (3) entity.assets.Deductible is 0 and
%   entity.assets.Cover is equal to entity.assets.Value, or these two
%   fields do not exist (in other words, cover and deductibles are not
%   accounted for in the calculation).
%   Note that these criteria could be eliminated with a bit of further
%   coding (e.g., by spliting arrays of entities and hazard based on
%   entity.assets.DamageFunID to solve condition 2 above).
%   The code uses matrix computations and works with fixed or varying
%   assets as follows:
%   If use_YDS=0 (default), fixed assets (entity.assets.Value) are used and
%   in this case a requirement is size(entity.assets.Value,2)==size(hazard.intensity,2).
%   If use_YDS~=0, varying assets (entity.assets.Values) are used,
%   requiring all(size(entity.assets.Values)==size(hazard.intensity)).
%   By default only the field(s) 'damage' (and 'damage_at_centroid' if
%   climada_global.damage_at_centroid==1) are provided.
%
%   next (likely): climada_EDS_DFC or climada_EDS2DFC, climada_EDS_DFC_report
%   See climada_EDS_calc for a more complete but much slower version.
% CALLING SEQUENCE:
%   EDS=climada_EDS_calc_fast(entity,hazard,damagefunction,use_YDS,damage_only,annotation_name,do_checks,silent_mode)
% EXAMPLE:
%   entity = climada_entity_load('demo_today');
%   hazard = climada_hazard_load('TCNA_today_small');
%   damfunin = entity.damagefunctions.DamageFunID==1;
%   fldnames=fieldnames(entity.damagefunctions);
%   for i=2:length(fldnames)
%       damFun.(fldnames{i}) = entity.damagefunctions.(fldnames{i})(damfunin);
%   end
%   EDS=climada_EDS_calc_fast(entity,hazard,damFun);
%   EDS_full=climada_EDS_calc_fast(entity,hazard,damFun,0,0,'test climada_EDS_calc_fast',1,0);
% INPUTS:
%   entity: an entity structure.
%   hazard: a hazard set (struct). The only fields of hazard struct that is
%       absolutely required is: intensity
%   damagefunction: a damagefunction (struct), for instance as created by
%   	climada_damagefunctions_generate(0:10:120,20,3,1,'exp','TC'). The
%   	only fields of damagefunction struct that are absolutely required
%   	are intensity, MDD and PAA.
% OPTIONAL INPUT PARAMETERS:
%   use_YDS: if =0 (default), constant assets (entity.assets.Value) are
%       used for all events. If =1, entity.assets.Values is used and the
%       number of asset values per centroid must equal the number of
%       events.
%   damage_only: if =1 (default), only field 'damage' (and
%       'damage_at_centroid' if climada_global.damage_at_centroid==1) are
%       returned. Otherwise, all fields are returned.
%   annotation_name: a free text that will appear e.g. on plots for
%       annotation, default is ''.
%   do_checks: if =1, does a few basic checks on the data. Default=0
%   silent_mode: suppress any output to stdout (useful i.e. if called many times)
%       default=0 (output to stdout), =1: no output at all
% OUTPUTS:
%   EDS, the event damage set with (subset only if damage_only=1):
%       ED: the total expected annual damage (=EDS.damage*EDS.frequency')
%       reference_year: the year the damages are references to
%       event_ID(event_i): the unique ID for each event_i
%       damage(event_i): the damage amount for event_i (summed up over all
%           assets)
%       ED_at_centroid(centroid_i): expected damage at each centroid
%       Value: the sum of all Values used in the calculation (to e.g.
%           express damages in percentage of total Value)
%       frequency(event_i): the per occurrence event frequency for each event_i
%       orig_event_flag(event_i): whether an original event (=1) or a
%           probabilistic one (=0)
%       comment: a free comment, contains time for calculation
%       hazard: itself a structure, with:
%           filename: the filename of the hazard event set
%           comment: a free comment
%       assets.lat(asset_i): the latitude of each asset_i
%       assets.lon(asset_i): the longitude of each asset_i
%       assets.Value(asset_i): the Value of asset_i, i.e. used to show
%           ED_at_centroid in percentage of asset value.
%       assets.filename: the filename of the assets
%       assets.admin0_name: the admin0_name of the assets (optional)
%       assets.admin0_ISO3: the admin0_ISO3 code of the assets (optional)
%       assets.admin1_name: the admin1_name of the assets (optional)
%       assets.admin1_code: the admin1_code of the assets (optional)
%       damagefunctions.filename: the filename of the damagefunctions
%       annotation_name: a kind of default title (sometimes empty)
% MODIFICATION HISTORY:
% Benoit P. Guillod, benoit.guillod@env.ethz.ch, 20181122, initial based on climada_EDS_calc.m
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

EDS=[]; % init output

% poor man's version to check arguments
if ~exist('entity','var'),error('argument entity must be provided');end
if ~exist('hazard','var'),error('argument hazard must be provided');end
if ~exist('damagefunction','var'),error('argument damagefunction must be provided');end
if ~exist('use_YDS','var'),use_YDS=0;end
if ~exist('damage_only','var'),damage_only=1;end
if ~exist('annotation_name','var'),annotation_name='';end
if ~exist('do_checks','var'),do_checks=0;end
if ~exist('silent_mode','var'),silent_mode=0;end

% issue warning
if ~silent_mode,fprintf('** WARNING ** climada_EDS_calc_fast does not check your entity and hazard, read the function documentation and make sure you are doing the right thing by first comparing the output with that of climada_EDS_calc for a test case *****\n');end

%% pre-processing

n_events=size(hazard.intensity,1);

% checks if asked for: nb of events, nb of centroids, centroid_index
if do_checks
    if use_YDS
        assets_size = size(entity.assets.Values);
        % check that the number of events is the same in hazard and entity
        if assets_size(1) ~= n_events
            error('** ERROR ** use_YDS==1 but the number of events in entity does not match that of hazard *****')
        end
    else
        assets_size = [n_events size(entity.assets.Value,2)];
    end
    % check that the number of 'centroids' is the same in hazard and entity
    if assets_size(2) ~= size(hazard.intensity,2)
        error('** ERROR ** mismatch in the number of centroids in entity vs hazard *****')
    end
    % check that centroid_index in assets is as expected (if it exists)
    if isfield(entity.assets,'centroid_index')
        if ~all(entity.assets.centroid_index == 1:assets_size(2))
            error('** ERROR ** entity.assets.centroid_index exists but is not 1:max *****')
        end
    end
end

% use_YDS and related processing
if use_YDS
    if size(entity.assets.Values,1) ~= n_events
        error('** ERROR ** use_YDS==1 but the number of events in entity does not match that of hazard *****')
    end
    event_assets=entity.assets.Values;
else
    event_assets=repmat(entity.assets.Value,[n_events 1]);
end
if climada_global.damage_at_centroid || ~damage_only
    assets_size=size(event_assets);
end

% add a hazard.fraction field, if not provided (often not provided, no worries)
if ~isfield(hazard,'fraction')
    if silent_mode>0,fprintf('adding hazard.fraction ...');end
    hazard.fraction=spones(hazard.intensity); % fraction 100%
end

% initialize damage_at_centroid
if climada_global.damage_at_centroid
    % allocate the damage per centroid array (sparse, to manage memory)
    damage_at_centroid_density = 0.03; % 3% sparse damage per centroid array density (estimated)
    EDS.damage_at_centroid     = spalloc(assets_size(2), n_events,...
        ceil(n_events*assets_size(2)*damage_at_centroid_density));
end

% remove assets with nan or 0 values
keep_in=sum(event_assets,1)>0;
event_assets=event_assets(:,keep_in);
intensity=hazard.intensity(:,keep_in);
fraction=hazard.fraction(:,keep_in);

%% damage computation
% MDR
if ~damage_only,t0 = clock;end
MDD=climada_interp1(damagefunction.Intensity, damagefunction.MDD, full(intensity),'linear','extrap');
if (all(damagefunction.PAA==1))
    PAA=ones(size(MDD));
else
    PAA=climada_interp1(damagefunction.Intensity, damagefunction.PAA, full(intensity),'linear','extrap');
end
MDR=MDD.*PAA;
clear MDD PAA n_events;

% damage
exposed_val=event_assets.*fraction;
damage_at_centroid_sub = (exposed_val.*MDR)';
EDS.damage = full(sum(damage_at_centroid_sub,1));
if climada_global.damage_at_centroid
    EDS.damage_at_centroid(keep_in,:) = full(damage_at_centroid_sub);
elseif ~damage_only
    EDS.ED_at_centroid    = zeros(assets_size(2),1); % expected damage per centroid
    ED_at_centroid = full(damage_at_centroid_sub*hazard.frequency');
    EDS.ED_at_centroid(keep_in,:) = ED_at_centroid;
    clear ED_at_centroid;
end
clear damage_at_centroid_sub exposed_val;


%% initialize the event damage set (EDS) if desired
if ~damage_only
    t_elapsed = etime(clock,t0);
    msgstr    = sprintf('calculation took %3.2f sec (%1.4f sec/event)',t_elapsed,t_elapsed/assets_size(2));
    if isfield(hazard,'reference_year')
        EDS.reference_year=hazard.reference_year;
    else
        EDS.reference_year=climada_global.present_reference_year;
    end
    EDS.event_ID          = hazard.event_ID;
    if use_YDS
        EDS.Values        = sum(event_assets,1);
    else
        EDS.Value         = sum(entity.assets.Value(1,:),2);
    end
    EDS.frequency         = hazard.frequency;
    if isfield(hazard,'orig_event_flag'),EDS.orig_event_flag=hazard.orig_event_flag;end
    EDS.peril_ID          = char(hazard.peril_ID);
    EDS.hazard.peril_ID   = EDS.peril_ID; % backward compatibility
    if isfield(entity.assets,'Value_unit')
        EDS.Value_unit = entity.assets.Value_unit{1};
    else
        EDS.Value_unit     = climada_global.Value_unit; % in all cases until 20170626
    end
    if isfield(entity.assets,'currency_unit')
        EDS.currency_unit  = entity.assets.currency_unit;
    else
        EDS.currency_unit  = 1; % default
    end
    EDS.comment         = msgstr;
    if ~isfield(hazard,'filename'),hazard.filename='';end
    EDS.hazard.filename = strrep(char(hazard.filename),'\',filesep); % from PC
    EDS.hazard.filename = strrep(EDS.hazard.filename,'/',filesep); % from MAC
    if ~isfield(hazard,'refence_year'),hazard.refence_year=climada_global.present_reference_year;end
    EDS.hazard.refence_year = hazard.refence_year;
    if ~isfield(hazard,'scenario'),hazard.scenario='no climate change';end
    EDS.hazard.scenario = hazard.scenario;
    if ~isfield(hazard,'comment'),hazard.comment='';end
    EDS.hazard.comment=hazard.comment;
    EDS.assets.filename = entity.assets.filename;
    EDS.assets.lat = entity.assets.lat;
    EDS.assets.lon = entity.assets.lon;
    EDS.assets.Value = entity.assets.Value; % note EDS.Value is sum of...
    if isfield(entity.assets,'admin0_name'),EDS.assets.admin0_name=entity.assets.admin0_name;end
    if isfield(entity.assets,'admin0_ISO3'),EDS.assets.admin0_ISO3=entity.assets.admin0_ISO3;end
    if isfield(entity.assets,'admin1_name'),EDS.assets.admin1_name=entity.assets.admin1_name;end
    if isfield(entity.assets,'admin1_code'),EDS.assets.admin1_code=entity.assets.admin1_code;end
    if isfield(entity.assets,'Category'), EDS.assets.Category = entity.assets.Category; end
    if isfield(entity.assets,'Category_name'), EDS.assets.Category_name = entity.assets.Category_name; end
    if isfield(entity.assets,'Category_ID'), EDS.assets.Category_ID = entity.assets.Category_ID; end
    if isfield(entity.assets,'region'),EDS.assets.region=entity.assets.region;end
    if isfield(entity.assets,'reference_year')
        EDS.assets.reference_year=entity.assets.reference_year;
    else
        EDS.assets.reference_year=climada_global.present_reference_year;
    end
    EDS.damagefunctions.filename = entity.damagefunctions.filename;
    if isempty(annotation_name)
        [~,name]        = fileparts(EDS.hazard.filename);
        annotation_name = name;
    end
    EDS.annotation_name = annotation_name;
    EDS.ED              = EDS.damage*EDS.frequency';
    %EDS.ED              = full(sum(EDS.damage.*EDS.frequency)); % calculate annual expected damage
    if climada_global.damage_at_centroid
        EDS.ED_at_centroid = full(sum(bsxfun(@times, EDS.damage_at_centroid, EDS.frequency),2));
    end
    
end

end % climada_EDS_calc_fast