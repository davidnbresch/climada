function EDS=climada_EDS_calc(entity,hazard,annotation_name)
% climada calculate event damage set
% NAME:
%   climada_EDS_calc
% PURPOSE:
%   given an encoded entity (portfolio) and a hazard event set, calculate
%   the event damage set (EDS)
%
%   Note that the waitbar consumes quite some time, so switch it off by
%   using the climada_code_optimizer, which removes all slowing code...
% CALLING SEQUENCE:
%   EDS=climada_EDS_calc(entity,hazard,annotation_name)
% EXAMPLE:
%   EDS=climada_EDS_calc(climada_assets_encode(climada_assets_read))
% INPUTS:
%   entity: a read and encoded assets file, see climada_assets_encode(climada_assets_read)
%       > promted for if not given
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   annotation_name: a free text that will appear e.g. on plots for
%       annotation, default=''
% OUTPUTS:
%   EDS, the event damage set with:
%       reference_year: the year the damages are references to
%       event_ID(event_i): the unique ID for each event_i
%       damage(event_i): the damage amount for event_i
%       Value: the sum of allValues used in the calculation (to e.g. express
%           damages in percentage of total Value)
%       frequency(event_i): the per occurrence event frequency for each event_i
%       orig_event_flag(event_i): whether an original event (=1) or a
%           probabilistic one (=0)
%       comment: a free comment, contains time for calculation
%       hazard: itself a structure, with:
%           filename: the filename of the hazard event set
%           comment: a free comment
%       assets.filename: the filename of the assets
%       damagefunctions.filename: the filename of the damagefunctions
%       annotation_name: a kind of default title (sometimes empty)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091228
% David N. Bresch, david.bresch@gmail.com, 20130316, ELS->EDS...
% David N. Bresch, david.bresch@gmail.com, 20130623, re-encoding optional
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

global interp_x_table % see climada_sparse_interp
global interp_y_table % see climada_sparse_interp

EDS=[]; % init output

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('hazard','var'),hazard=[];end
if ~exist('annotation_name','var'),annotation_name='';end

% PARAMETERS
%
% TEST settings
%%load([climada_global.data_dir filesep 'assets' filesep 'TEST_long_TC_assets.mat']); % entity
%%hazard_set=[climada_global.data_dir filesep 'hazards' filesep 'TCNA_TEST_atl_ens_hazard.mat']; % hazard
%%hazard_set=[climada_global.data_dir filesep 'hazards' filesep 'TCNA_atl_ens_hazard.mat']; % hazard

% prompt for hazard_set if not given
if isempty(entity) % local GUI
    entity=[climada_global.data_dir filesep 'entities' filesep '*.mat'];
    [filename, pathname] = uigetfile(entity, 'Select encoded entity:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity=fullfile(pathname,filename);
    end
end
% load the entity, if a filename has been passed
if ~isstruct(entity)
    entity_file=entity;entity=[];
    load(entity_file);
end

% prompt for hazard_set if not given
if isempty(hazard) % local GUI
    hazard=[climada_global.data_dir filesep 'hazards' filesep '*.mat'];
    [filename, pathname] = uigetfile(hazard, 'Select hazard event set for EDS calculation:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard=fullfile(pathname,filename);
    end
end
% load the hazard set, if a filename has been passed
if ~isstruct(hazard)
    hazard_file=hazard;hazard=[];
    load(hazard_file);
end

% check for consistency of entity and the hazard set it has been encoded to
% but: one might have used the same centroids for different hazard sets, so
% it's only a WARNING, not an error
% if isempty(strmatch(entity.assets.hazard.comment,hazard.comment))
%     fprintf('WARNING: encoded entity and hazard set centroids might not match\n');
% end

% encode assets of entity once more, just to be sure
if ~isfield(entity.assets,'centroid_index')
    fprintf('Entity assets yet to be encoded to hazard.\n')
    [entity.assets hazard] = climada_assets_encode(entity.assets, hazard);
elseif ~all(diff(entity.assets.centroid_index) == 1) && climada_global.re_check_encoding
    fprintf('Encode entity assets once more.\n')
    [entity.assets hazard] = climada_assets_encode(entity.assets, hazard);
end

% initialize the event damage set (EDS)
if isfield(hazard,'reference_year')
    EDS.reference_year=hazard.reference_year;
else
    EDS.reference_year=climada_global.present_reference_year;
end
EDS.event_ID          = hazard.event_ID;
EDS.damage            = zeros(1,size(hazard.arr,1));
n_assets              = length(entity.assets.centroid_index);
EDS.ED_at_centroid   = zeros(n_assets,1); % expected damage per centroid
EDS.Value             = 0;
EDS.frequency         = hazard.frequency;
EDS.orig_event_flag   = hazard.orig_event_flag;
EDS.hazard.peril_ID   = hazard.peril_ID;
if climada_global.EDS_at_centroid
    % allocate the damage per centroid array (sparse, to manage memory)
    damage_at_centroid_density = 0.03; % 3% sparse damage per centroid array density (estimated)
    EDS.damage_at_centroid     = spalloc(n_assets, hazard.event_count,...
        ceil(hazard.event_count*n_assets*damage_at_centroid_density));
    [i,j,x]           = find(EDS.damage_at_centroid);
end

% start the calculation
% THIS CODE MIGHT NEED FUTURE OPTIMIZATION
% see also climada_code_optimizer, which removes all slowing code...

% follows the calculation of the event damage set (EDS), outer loop explicit for clarity
% innermost loop (over hazard events) by matrix calc
t0 = clock;
msgstr=sprintf('processing %i assets and %i events, ',n_assets,length(hazard.frequency));
%fprintf('%s',msgstr);
if climada_global.waitbar,h = waitbar(0,msgstr,'name','Calculating damage for assets');end % CLIMADA_OPT
mod_step=2; % first time estimate after 2 calcs, then every 100

for asset_i=1:n_assets
    
    % the index of the centroid for given asset in the hazard set
    asset_hazard_pos = entity.assets.centroid_index(asset_i);
    
    % find the damagefunctions for the asset under consideration
    asset_damfun_pos = find(entity.damagefunctions.DamageFunID == entity.assets.DamageFunID(asset_i));
    
    % convert hazard intensity into MDD
    % we need a trick to apply interp1 to the SPARSE hazard matrix: we evaluate only at non-zero elements, but therefore need a function handle
    interp_x_table = entity.damagefunctions.Intensity(asset_damfun_pos); % to pass damagefunctions to climada_sparse_interp
    interp_y_table = entity.damagefunctions.MDD(asset_damfun_pos); % to pass damagefunctions to climada_sparse_interp
    MDD            = spfun(@climada_sparse_interp,hazard.arr(:,asset_hazard_pos)); % apply to non-zero elements only
    % OPTIMIZATION HINT: see climada_sparse_interp, would interp_x_table be uniformly spaced...
    

    % figure
    % plot(interp_x_table, interp_y_table,':')
    % hold on
    % plot(hazard.arr(:,asset_hazard_pos), MDD,'o')

    % similarly, convert hazard intensity into PAA
    interp_y_table = entity.damagefunctions.PAA(asset_damfun_pos); % to pass damagefunctions to climada_sparse_interp
    PAA            = spfun(@climada_sparse_interp,hazard.arr(:,asset_hazard_pos)); % apply to non-zero elements only
        

    % figure
    % plot(interp_x_table, interp_y_table,':k')
    % hold on
    % plot(hazard.arr(:,asset_hazard_pos), PAA,'ok')

    % calculate the from ground up (fgu) damage
    temp_damage      = entity.assets.Value(asset_i)*MDD.*PAA; % damage=value*MDD*PAA

    if any(full(temp_damage)) % if at least one damage>0
        if entity.assets.Deductible(asset_i)>0 || entity.assets.Cover(asset_i) < entity.assets.Value(asset_i)
            % apply Deductible and Cover
            temp_damage=min(max(temp_damage-entity.assets.Deductible(asset_i)*PAA,0),entity.assets.Cover(asset_i));
        end
        EDS.damage = EDS.damage+temp_damage'; % add to the EDS
        
        if climada_global.EDS_at_centroid
            %EDS.damage_at_centroid(:,asset_i) = temp_damage'; % add to EDS damage at centroids
            index_ = j == asset_i; %index_ = i == asset_i;
            i(index_) = [];
            j(index_) = [];
            x(index_) = [];

            i = [i; find(temp_damage)];
            j = [j; zeros(nnz(temp_damage),1)+asset_i]; 
            x = [x; nonzeros(temp_damage)];
        else
            EDS.ED_at_centroid(asset_i,1) = full(sum(temp_damage' .* EDS.frequency));
        end 
        
    end 
    EDS.Value   = EDS.Value+entity.assets.Value(asset_i);
    
    % TEST output
    %%fprintf('%i, max MDD %f, PAA %f, ED %f\n',asset_i,max(full(MDD)),max(full(PAA)),full(sum(temp_damage'.*EDS.frequency)));
    
    if climada_global.waitbar % CLIMADA_OPT
        if mod(asset_i,mod_step)==0 % CLIMADA_OPT
            mod_step         = 100; % CLIMADA_OPT
            t_elapsed_calc   = etime(clock,t0)/asset_i; % CLIMADA_OPT
            calcs_remaining  = n_assets-asset_i; % CLIMADA_OPT
            t_projected_calc = t_elapsed_calc*calcs_remaining; % CLIMADA_OPT
            msgstr           = sprintf('est. %i seconds left (%i/%i assets)',ceil(t_projected_calc),asset_i,n_assets); % CLIMADA_OPT
            waitbar(asset_i/n_assets,h,msgstr); % update waitbar % CLIMADA_OPT
        end % CLIMADA_OPT
    end % CLIMADA_OPT
    
end % asset_i
if climada_global.waitbar,close(h);end % dispose waitbar % CLIMADA_OPT

t_elapsed = etime(clock,t0);
msgstr    = sprintf('calculation took %3.1f sec (%1.4f sec/event)',t_elapsed,t_elapsed/n_assets);
%fprintf('%s\n',msgstr);
EDS.comment         = msgstr;
EDS.hazard.filename = hazard.filename;
if strfind(computer,'MAC')
    EDS.hazard.filename = strrep(EDS.hazard.filename,'\',filesep); % switch filesep
elseif strfind(computer,'PCWIN')
    EDS.hazard.filename = strrep(EDS.hazard.filename,'/',filesep); % switch filesep
end
EDS.hazard.comment  = hazard.comment;
EDS.assets.filename = entity.assets.filename;
EDS.assets.Latitude = entity.assets.Latitude;
EDS.assets.Longitude = entity.assets.Longitude;
EDS.assets.Value = entity.assets.Value; % note EDS.Value is sum of...
EDS.damagefunctions.filename = entity.damagefunctions.filename;
if isempty(annotation_name)
    [fP,name]       = fileparts(EDS.hazard.filename);
    annotation_name = name;
end
EDS.annotation_name = annotation_name;
EDS.ED              = full(sum(EDS.damage.*EDS.frequency)); % calculate annual expected damage
if climada_global.EDS_at_centroid
    EDS.damage_at_centroid = sparse(i,j,x,hazard.event_count,n_assets);
    EDS.damage_at_centroid = EDS.damage_at_centroid';
    EDS.ED_at_centroid     = full(sum(bsxfun(@times, EDS.damage_at_centroid, EDS.frequency),2));
end

return
