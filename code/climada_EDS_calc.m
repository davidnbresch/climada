function EDS=climada_EDS_calc(entity,hazard,annotation_name,force_re_encode,silent_mode,sanity_check)
% climada calculate event damage set
% NAME:
%   climada_EDS_calc
% PURPOSE:
%   given an encoded entity (assets and damage functions) and a hazard
%   event set, calculate the event damage set (EDS). The event damage set
%   contains the event damage for each hazard event. In case you set
%   climada_global.damage_at_centroid=1, the damage is also stored for each
%   event at each centroids (be aware of memory implications). The exepcted
%   damage is always stored at each centroid, see EDS.ED_at_centroid.
%
%   Note that the waitbar consumes quite some time, so switch it off by
%   setting climada_global.waitbar=0 or by
%   using the climada_code_optimizer, which removes all slowing code, i.e.
%   all code lines marked by % CLIMADA_OPT - but by now, the code is pretty
%   fast, hence climada_code_optimizer does usually not bring huge
%   improvements (i.e. less than 4% speedup).
%
%   Search for 'TEST output' in code to show output for VERY SMALL entities
%
%   next (likely): climada_EDS_DFC or climada_EDS2DFC, climada_EDS_DFC_report
%   See also climada_EDS_calc_parfor for a parallelized version (beta)
% CALLING SEQUENCE:
%   EDS=climada_EDS_calc(entity,hazard,annotation_name,force_re_encode,silent_mode,sanity_check)
% EXAMPLE:
%   EDS=climada_EDS_calc(climada_assets_encode(climada_assets_read))
%   EDS=climada_EDS_calc('demo_today','TCNA_today_small','TC today')
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
% OPTIONAL INPUT PARAMETERS:
%   annotation_name: a free text that will appear e.g. on plots for
%       annotation, default is the name of the hazard set
%   force_re_encode: if =1, force re-encoding (either to be on the safe
%       side, or if the entity has been encoded to a different hazard event
%       set). Default=0
%   silent_mode: suppress any output to stdout (useful i.e. if called many times)
%       default=0 (output to stdout), =1: no output and no waitbar at all
%       command-line progress output is still shown with silent_mode=1, but
%       suppressed if =2. 
%   sanity_check: perform climada_damagefunctions_check to make sure all
%       damagefunctions map correctly and ranges do cover occurring hazard
%       intensities. Default=0
% OUTPUTS:
%   EDS, the event damage set with:
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
% David N. Bresch, david.bresch@gmail.com, 20091228
% David N. Bresch, david.bresch@gmail.com, 20130316, ELS->EDS...
% David N. Bresch, david.bresch@gmail.com, 20130623, re-encoding optional
% David N. Bresch, david.bresch@gmail.com, 20141025, peril_ID added to waitbar title
% David N. Bresch, david.bresch@gmail.com, 20141103, entity.damagefunctions.peril_ID
% David N. Bresch, david.bresch@gmail.com, 20141127, force_re_encode
% David N. Bresch, david.bresch@gmail.com, 20141218, Cover checks added
% David N. Bresch, david.bresch@gmail.com, 20141230, only assets.Value>0 prcocessed for speedup
% David N. Bresch, david.bresch@gmail.com, 20150101, annotation check for 'MAC' and 'APPLE'
% David N. Bresch, david.bresch@gmail.com, 20150103, check Octave compatibility of (large) hazard event sets
% David N. Bresch, david.bresch@gmail.com, 20150105, filesep conversion (from either PC or MAC) solved
% David N. Bresch, david.bresch@gmail.com, 20150106, add Cover and/or Deductible if missing
% David N. Bresch, david.bresch@gmail.com, 20150106, Octave issue with hazard saved as -v7.3 solved
% David N. Bresch, david.bresch@gmail.com, 20150114, EDS.peril_ID (was EDS.hazard.peril_ID)
% David N. Bresch, david.bresch@gmail.com, 20150320, spfun replaced with explicit call, turns out to be >50% faster. Further speedup, see loop_mod_step
% Gilles Stassen, gillesstassen@hotmail.com, 20150622, use complete peril_ID in asset_damfun_pos refinement (1:2) -> (:), MDD, PAA  explicitly capped at max value
% David N. Bresch, david.bresch@gmail.com, 20150804, allow for filename without path for entoity and hazard set name on input
% Lea Mueller, muellele@gmail.com, 20150805, allow centroid_index to be zero, do not integrate such assets in valid_asset_pos, no damage will be calculated
% Lea Mueller, muellele@gmail.com, 20150819, use only unique values in interp_x_table, so that interp1 works (interp_x_table is monotonically increasing)
% Lea Mueller, muellele@gmail.com, 20150819, set minimum damage to min defined in damage function (probably 0)
% Lea Mueller, muellele@gmail.com, 20150831, EDS.ED, EDS.damage, EDS.Value is the sum only of the first Value_unit encountered, all other units are not included
% David N. Bresch, david.bresch@gmail.com, 20150907, ...errant extrapolation leads to WRONG behaviour in case of hazard_intensity_impact_b, commented
% Lea Mueller, muellele@gmail.com, 20150907, add sanity_check variable to call climada_damagefunctions_check
% Lea Mueller, muellele@gmail.com, 20150910, set sanity_check to silent_mode
% Lea Mueller, muellele@gmail.com, 20151117, replace output string to "Calculating damage" instead of "processing"
% Lea Mueller, muellele@gmail.com, 20151127, add EDS.scenario, EDS.assets.reference_year and EDS.assets.region, add EDS.hazard.refence_year and EDS.hazard.scenario
% Lea Mueller, muellele@gmail.com, 20151127, add EDS.assets.Category
% Lea Mueller, muellele@gmail.com, 20151127, invoke climada_assets_category_ID, add EDS.assets.Category_name and EDS.assets.Category_ID
% David N. Bresch, david.bresch@gmail.com, 20160202, cleanup
% David N. Bresch, david.bresch@gmail.com, 20160210, is_unit removed and substantial speedup (damagefunctions made unique before calc)
% Lea Mueller, muellele@gmail.com, 20160303, bugfix if damage_at_centroid and state ED in fprintf command line output
% David N. Bresch, david.bresch@gmail.com, 20160306, EDS.ED=EDS.damage*EDS.frequency'
% David N. Bresch, david.bresch@gmail.com, 20160308, no printing of ED to stdout, some silent_mode checks slow down too much, removed
% David N. Bresch, david.bresch@gmail.com, 20161008, hazard.fraction added
% David N. Bresch, david.bresch@gmail.com, 20161023, silent_mode=2
% David N. Bresch, david.bresch@gmail.com, 20170225, allow for minimal fields in hazard
% David N. Bresch, david.bresch@gmail.com, 20170305, allow for entity.hazard
% David N. Bresch, david.bresch@gmail.com, 20170313, any(abs(full(temp_damage))) allow for negative damage (i.e. profit)
% David N. Bresch, david.bresch@gmail.com, 20170626, entity.assets.Value_unit used for EDS.Value_unit
% David N. Bresch, david.bresch@gmail.com, 20170715, small fix if no valid asset for EDS.Value_unit
% David N. Bresch, david.bresch@gmail.com, 20170721, currency_unit added
% David N. Bresch, david.bresch@gmail.com, 20170828, try/catch in full_unique for Octave compatibility
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

EDS=[]; % init output

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('hazard','var'),hazard=[];end
if ~exist('annotation_name','var'),annotation_name='';end
if ~exist('force_re_encode','var'),force_re_encode=0;end
if ~exist('silent_mode','var'),silent_mode=0;end
if ~exist('sanity_check','var'),sanity_check=0;end

% PARAMETERS
%

% check/process input
entity = climada_entity_load(entity); % prompt for entity if not given
if isempty(entity),return;end
if isempty(hazard) && isfield(entity,'hazard') % try hazard within entity
    hazard=entity.hazard;
    if silent_mode<2,fprintf('hazard set from entity.hazard\n');end
elseif isempty(hazard) && isfield(entity.assets,'hazard') % try hazard within entity
    hazard=entity.assets.hazard.filename;
    if silent_mode<2,fprintf('hazard set from entity.assets.hazard.filename\n');end
end
hazard = climada_hazard_load(hazard); % prompt for hazard_set if not given
if isempty(hazard),return;end
hazard = climada_hazard2octave(hazard); % Octave compatibility for -v7.3 mat-files

% check for consistency of entity and the hazard set it has been encoded to
% but: one might have used the same centroids for different hazard sets, so
% it's only a WARNING, not an error
% if isempty(strmatch(entity.assets.hazard.comment,hazard.comment))
%     fprintf('WARNING: encoded entity and hazard set centroids might not match\n');
% end

% encode assets of entity once more, just to be sure
if ~isfield(entity.assets,'centroid_index')
    if ~silent_mode,fprintf('Encoding entity assets to hazard... ');end
    entity = climada_assets_encode(entity,hazard);
    if ~silent_mode,fprintf('done\n');end
    force_re_encode=0;
elseif ~all(diff(entity.assets.centroid_index) == 1) && climada_global.re_check_encoding
    if ~silent_mode,fprintf('Encode entity assets once more...');end
    entity = climada_assets_encode(entity,hazard);
    if ~silent_mode,fprintf('done\n');end
    force_re_encode=0;
end

if force_re_encode % re-encode entity to hazard
    if ~silent_mode,fprintf('Encoding (forced) entity assets to hazard... ');end
    entity = climada_assets_encode(entity,hazard);
    if ~silent_mode,fprintf('done\n');end
end

if ~isfield(entity.assets,'Deductible'),...
        entity.assets.Deductible=entity.assets.Value*0;
end

if isfield(entity.assets,'Cover')
    if sum(entity.assets.Cover)==0
        entity.assets.Cover=entity.assets.Value;
        if ~silent_mode,fprintf('Warning: Cover was zero for all assets, ignored\n');end
    end
else
    entity.assets.Cover=entity.assets.Value;
end

if sum(min(entity.assets.Cover-(entity.assets.Value),0))<0
    if ~silent_mode,fprintf('Note: At least some assets have Cover limiting the damage\n');end
end

if sanity_check ~=0
    entity = climada_damagefunctions_check(entity,hazard); % silent_mode as default
end

% initialize the event damage set (EDS)
if isfield(hazard,'reference_year')
    EDS.reference_year=hazard.reference_year;
else
    EDS.reference_year=climada_global.present_reference_year;
end
EDS.event_ID          = hazard.event_ID;
EDS.damage            = zeros(1,size(hazard.intensity,1));
n_assets              = length(entity.assets.centroid_index);
EDS.ED_at_centroid    = zeros(n_assets,1); % expected damage per centroid
EDS.Value             = 0;
EDS.frequency         = hazard.frequency;
if isfield(hazard,'orig_event_flag'),EDS.orig_event_flag=hazard.orig_event_flag;end
hazard_peril_ID       = char(hazard.peril_ID); % used below
EDS.peril_ID          = hazard_peril_ID;
EDS.hazard.peril_ID   = EDS.peril_ID; % backward compatibility

if climada_global.damage_at_centroid
    % allocate the damage per centroid array (sparse, to manage memory)
    damage_at_centroid_density = 0.03; % 3% sparse damage per centroid array density (estimated)
    EDS.damage_at_centroid     = spalloc(n_assets, hazard.event_count,...
        ceil(hazard.event_count*n_assets*damage_at_centroid_density));
    [i_index,j_index,x_index] = find(EDS.damage_at_centroid);
end

% temp variables
MDD_0 = zeros(size(hazard.intensity,1),1);
PAA_0 = zeros(size(hazard.intensity,1),1);

% only process Value>0 and centroid_index>0, since otherwise no damage anyway
valid_assets_pos=find(entity.assets.Value>0 & entity.assets.centroid_index>0);
nn_assets=length(valid_assets_pos);
if isfield(entity.assets,'Value_unit')
    if nn_assets>0
        EDS.Value_unit = entity.assets.Value_unit{valid_assets_pos(1)};
    else
        EDS.Value_unit = entity.assets.Value_unit{1};
    end
else
    EDS.Value_unit     = climada_global.Value_unit; % in all cases until 20170626
end
if isfield(entity.assets,'currency_unit')
    EDS.currency_unit  = entity.assets.currency_unit;
else
    EDS.currency_unit  = 1; % default
end

% restrict damage functions to what we need
% Note: quite some effort, but results in speedup
%       (no need to carefully study this to understand basic EDS calc)
if isfield(entity.damagefunctions,'peril_ID') % refine for peril
    % only keep single peril specific damage functions (speedup)
    peril_damfun_pos=strcmp(entity.damagefunctions.peril_ID,hazard_peril_ID);
else
    peril_damfun_pos=1:length(entity.damagefunctions.DamageFunID); % all
end
entity_damagefunctions_DamageFunID = entity.damagefunctions.DamageFunID(peril_damfun_pos);
entity_damagefunctions_Intensity   = entity.damagefunctions.Intensity(peril_damfun_pos);
entity_damagefunctions_MDD         = entity.damagefunctions.MDD(peril_damfun_pos);
entity_damagefunctions_PAA         = entity.damagefunctions.PAA(peril_damfun_pos);
% make entries unique (for speedup in interp1)
DamageFunID=unique(entity_damagefunctions_DamageFunID);
full_unique=[];
for i = 1:length(DamageFunID)
    damfun_pos    = find(entity_damagefunctions_DamageFunID == DamageFunID(i));
    [~,is_unique] = unique(entity_damagefunctions_Intensity(damfun_pos));
    try
        full_unique   = [full_unique;is_unique+damfun_pos(1)-1]; % MATLAB
    catch
        full_unique   = [full_unique is_unique+damfun_pos(1)-1]; % Octave
    end
end % i
full_unique=sort(full_unique);
entity_damagefunctions_DamageFunID=entity_damagefunctions_DamageFunID(full_unique);
entity_damagefunctions_Intensity=entity_damagefunctions_Intensity(full_unique);
entity_damagefunctions_MDD=entity_damagefunctions_MDD(full_unique);
entity_damagefunctions_PAA=entity_damagefunctions_PAA(full_unique);
% now, we only have the single-peril damagefunctions with no double entries

% % add a hazard.fraction field, if not provided (often not provided, no worries)

if ~isfield(hazard,'fraction')
    fprintf('adding hazard.fraction ...');
    hazard.fraction=spones(hazard.intensity); % fraction 100%
    fprintf(' done\n');
end

% follows the calculation of the event damage set (EDS), outer loop explicit for clarity
% innermost loop (over hazard events) by matrix calc
t0 = clock;
msgstr=sprintf('Calculating damage for %i assets (>0) and %i events ',nn_assets,length(hazard.frequency));

format_str='%s'; % CLIMADA_OPT
if ~silent_mode % CLIMADA_OPT
    if climada_global.waitbar % CLIMADA_OPT
        fprintf('%s (updating waitbar with estimation of time remaining every 100th event)\n',msgstr); % CLIMADA_OPT
        h = waitbar(0,msgstr,'Name',sprintf('Calculating %s damage for assets',hazard.peril_ID)); % CLIMADA_OPT
    else % CLIMADA_OPT
        fprintf('%s\n',msgstr); % CLIMADA_OPT
    end % CLIMADA_OPT
end % CLIMADA_OPT

mod_step = 2; % first time estimate after 2 calcs, then every 100
loop_mod_step = max(ceil(nn_assets/20),100);

% start the calculation
% ---------------------
% see also climada_code_optimizer, which removes all slowing code...

for asset_ii=1:nn_assets
    
    asset_i=valid_assets_pos(asset_ii);
    
    % the index of the centroid for given asset in the hazard set
    asset_hazard_pos = entity.assets.centroid_index(asset_i);
    
    % find the damagefunctions for the asset under consideration
    asset_damfun_pos = find(entity_damagefunctions_DamageFunID == entity.assets.DamageFunID(asset_i));
    
    if ~isempty(asset_damfun_pos)
        
        % convert hazard intensity into MDD
        interp_x_table = entity_damagefunctions_Intensity(asset_damfun_pos);
        interp_y_table = entity_damagefunctions_MDD(asset_damfun_pos);
        [rows,~,intensity] = find(hazard.intensity(:  ,asset_hazard_pos));
        if ~isempty(rows) % if at least one event hits the centroid
            fraction =                hazard.fraction(rows,asset_hazard_pos); % get fraction for same events, added 20161008
            % note that for speedup reasons, intensity is a vectors containing
            % only the non-zero elements of hazard.intensity at the given
            % centroid and fraction the corresponding elements of hazard.fraction
            MDD=MDD_0;
            if climada_global.octave_mode % CLIMADA_OPT
                MDD(rows) = interp1(interp_x_table,interp_y_table,intensity,'linear','extrap'); % CLIMADA_OPT
            else % CLIMADA_OPT
                MDD(rows) = climada_interp1(interp_x_table,interp_y_table,intensity,'linear','extrap');
            end % CLIMADA_OPT
            
            % figure % TEST output
            % plot(interp_x_table, interp_y_table,':')
            % hold on
            % plot(hazard.intensity(:,asset_hazard_pos), MDD,'o')
            
            % convert hazard intensity into PAA
            interp_y_table = entity_damagefunctions_PAA(asset_damfun_pos);
            PAA = PAA_0;
            if climada_global.octave_mode % CLIMADA_OPT
                PAA(rows) = interp1(interp_x_table,interp_y_table,intensity,'linear','extrap'); % CLIMADA_OPT
            else % CLIMADA_OPT
                PAA(rows) = climada_interp1(interp_x_table,interp_y_table,intensity,'linear','extrap');
            end % CLIMADA_OPT
            PAA(rows)=PAA(rows).*fraction;
            
            % figure % TEST output
            % plot(interp_x_table, interp_y_table,':k')
            % hold on
            % plot(hazard.intensity(:,asset_hazard_pos), PAA,'ok')
            
            % calculate the from ground up (fgu) damage
            temp_damage      = entity.assets.Value(asset_i)*MDD.*PAA; % damage=value*MDD*PAA
            
            if any(abs(full(temp_damage))) % if at least one damage>0, 20170313 abs(.)
                if entity.assets.Deductible(asset_i)>0 || entity.assets.Cover(asset_i) < entity.assets.Value(asset_i)
                    % apply Deductible and Cover
                    temp_damage = min(max(temp_damage-entity.assets.Deductible(asset_i)*PAA,0),entity.assets.Cover(asset_i));
                end
                EDS.damage = EDS.damage+temp_damage'; % add to the EDS
                
                if climada_global.damage_at_centroid % CLIMADA_OPT
                    %EDS.damage_at_centroid(:,asset_i) = temp_damage'; % add to EDS damage at centroids % CLIMADA_OPT
                    index_ = j_index == asset_i; %index_ = i == asset_i; % CLIMADA_OPT
                    i_index(index_) = []; % CLIMADA_OPT
                    j_index(index_) = []; % CLIMADA_OPT
                    x_index(index_) = []; % CLIMADA_OPT
                    
                    i_index = [i_index; find(temp_damage)]; % CLIMADA_OPT
                    j_index = [j_index; zeros(nnz(temp_damage),1)+asset_i]; % CLIMADA_OPT
                    x_index = [x_index; nonzeros(temp_damage)]; % CLIMADA_OPT
                else % CLIMADA_OPT
                    EDS.ED_at_centroid(asset_i,1) = temp_damage'*EDS.frequency';
                end % CLIMADA_OPT
                
            end
        end % ~isempty(rows)
        EDS.Value   = EDS.Value+entity.assets.Value(asset_i);
        
        % TEST output
        %%fprintf('%i, max MDD %f, PAA %f, ED %f\n',asset_i,max(full(MDD)),max(full(PAA)),full(sum(temp_damage'.*EDS.frequency)));
        
        if mod(asset_ii,mod_step)==0 % CLIMADA_OPT
            mod_step         = loop_mod_step; % CLIMADA_OPT
            t_elapsed_calc   = etime(clock,t0)/asset_ii; % CLIMADA_OPT
            calcs_remaining  = nn_assets-asset_ii; % CLIMADA_OPT
            t_projected_calc = t_elapsed_calc*calcs_remaining; % CLIMADA_OPT
            msgstr           = sprintf('est. %i seconds left (%i/%i assets>0)',ceil(t_projected_calc),asset_ii,nn_assets); % CLIMADA_OPT
            
            if climada_global.waitbar % CLIMADA_OPT
                waitbar(asset_ii/nn_assets,h,msgstr); % update waitbar % CLIMADA_OPT
            else % CLIMADA_OPT
                if silent_mode<2,fprintf(format_str,msgstr);end % write progress to stdout % CLIMADA_OPT
                format_str=[repmat('\b',1,length(msgstr)) '%s']; % back to begin of line % CLIMADA_OPT
            end % CLIMADA_OPT
            
        end % CLIMADA_OPT
        
    end % ~isempty(asset_damfun_pos)
    
end % asset_ii

if climada_global.waitbar % CLIMADA_OPT
    close(h) % dispose waitbar % CLIMADA_OPT
else % CLIMADA_OPT
    if silent_mode<2,fprintf(format_str,'');end % move carriage to begin of line % CLIMADA_OPT
end % CLIMADA_OPT

t_elapsed = etime(clock,t0);
msgstr    = sprintf('calculation took %3.2f sec (%1.4f sec/event)',t_elapsed,t_elapsed/n_assets);
%fprintf('%s\n',msgstr);
EDS.comment         = msgstr;
% since a hazard event set might have been created on another Machine, make
% sure it can later be referenced (with filesep and hence fileparts):
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
    EDS.damage_at_centroid = sparse(i_index,j_index,x_index,hazard.event_count,n_assets);
    EDS.damage_at_centroid = EDS.damage_at_centroid';
    EDS.ED_at_centroid = full(sum(bsxfun(@times, EDS.damage_at_centroid, EDS.frequency),2));
end

end % climada_EDS_calc