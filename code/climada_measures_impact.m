function measures_impact=climada_measures_impact(entity,hazard,measures_impact_reference,measures,map_risk_premium,sanity_check)
% climada
% NAME:
%   climada_measures_impact
% PURPOSE:
%   calculate the impact of a series of measures on a given set of assets
%   under a given hazard, main functions called are climada_EDS_calc and
%   climada_measures_impact_discount
%
%   next step: climada_adaptation_cost_curve or
%   climada_adaptation_event_view
%
%   Note: the risk premiums show need to be handled with UTMOST care, as
%   they are proxies of real risk premiums. First, the total climate risk
%   premium is calculated as NPV of total climate risk divided by the sum
%   of all assets (that simple), hence it does not really reperesent a
%   premium that one would i.e. charge to cover these risks over the course
%   of a year (since it's the NPV...). The total climate risk premium
%   reduction provides an upper bound of the risk premium reduction due to
%   the cost-effective measures, since any further csosts, such as
%   distribution, claims handling and capital costs are not considered at
%   all. Second, the risk premiums mapped (if map_risk_premium=1) are calculated
%   as the expected damage at each centroid divided by the asset value at
%   this centroid, hence are again a CRUDE PROXY. Again, the difference of
%   the fgu and net values is more telling than the absolute numbers.
% CALLING SEQUENCE:
%   measures_impact=climada_measures_impact(entity,hazard,measures_impact_reference,measures)
% EXAMPLE:
%   measures_impact=climada_measures_impact % all prompted for
%   hazard_set_file='...\climada\data\hazards\TCNA_A_Probabilistic.mat';
%   measures_impact=climada_measures_impact(climada_entity_read('',hazard_set_file),hazard_set_file,'no')
%   measures_impact=climada_measures_impact('','','','',1) % all interactive, show risk premium map
% INPUTS:
%   entity: a read and encoded assets and damagefunctions file, see climada_assets_encode(climada_assets_read)
%       > promted for if not given
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a struct)
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   measures_impact_reference: reference measures (e.g. portfolio today and
%       measures today). Used to properly calculate the net present values
%       of future impacts
%       set to 'no' if you would not like to be asked for a reference
%   measures: either a struct containing the measures or a measures set file (.mat with a struct)
%       see climada_measures_read.
%       A bit complex:
%       If measures is empty (not provided), it is taken from entity.measures (in case entity
%           contains measures). If entity does not contain measures, user gets prompted for.
%       If user provides measures, these measures are used
%       If user set measures to 'ASK', he gets prompted for and these are used
%   map_risk_premium: whether we show a plot (=1) of risk premium at each
%       centroid using a contour plot on a map, with cost-effective
%       measures and without any measures(fgu). Default=0 
%       Please note that this risk premium is a proxy for a real premium,
%       as it just consistes of the expected damage at each centroid.
% OUTPUTS:
%   measures_impact: a structure with
%       EDS(measure_i): the event damage set for each measure, last one EDS(end) for no measures
%       ED(measure_i): the annual expected damage to the assets under measure_i,
%           last one ED(end) for no measures
%       benefit(measure_i): the benefit of measure_i
%       cb_ratio(measure_i): the cost/benefit ratio of measure_i
%       measures: just a copy of measures, so we have all we need together
%       title_str: a meaningful title, of the format: measures @ assets | hazard
%       NOTE: currently measures_impact is also stored (with a lengthy filename)
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091228
% David N. Bresch, david.bresch@gmail.com, 20130316, ELS->EDS...
% David N. Bresch, david.bresch@gmail.com, 20130328, vuln_MDD_impact -> MDD_impact...
% David N. Bresch, david.bresch@gmail.com, 20130623, hazard set switch added
% David N. Bresch, david.bresch@gmail.com, 20140509, non-linear damage time dependency implemented
% David N. Bresch, david.bresch@gmail.com, 20140509, risk premium calc added
% David N. Bresch, david.bresch@gmail.com, 20140510, risk premium map added
% David N. Bresch, david.bresch@gmail.com, 20141220, re-encoding check added
% David N. Bresch, david.bresch@gmail.com, 20150101, cleanup
% Gilles Stassen, gillesstassen@hotmail.com, 20150626, if exist(hazard_file,'var') -> exist('hazard_file','var')
% Lea Mueller, muellele@gmail.com, 20150831, introduce measures_impact.Value_unit
% Lea Mueller, muellele@gmail.com, 20150902, rename to hazard_intensity_impact_b from hazard_intensity_impact
% Lea Mueller, muellele@gmail.com, 20150902, call climada_measures_impact_discount in an separate function
% David N. Bresch, david.bresch@gmail.com, 20150907, hazard_intensity_impact_a and hazard_intensity_impact_b properly implemented
% Lea Mueller, muellele@gmail.com, 20150907, add variable sanity_check to perform a safety check within climada_EDS_calc, add climada_measures_check
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

measures_impact=[];

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('hazard','var'),hazard=[];end
if ~exist('measures_impact_reference','var'),measures_impact_reference=[];end
if ~exist('measures','var'),measures='';end
if ~exist('map_risk_premium','var'),map_risk_premium=0;end
if ~exist('sanity_check','var'),sanity_check=0;end


% PARAMETERS
%
% to debug one measure, set debug_measure_i to its number
debug_measure_i=0; % default=0 (switched off, no debugging)


% prompt for entity if not given
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
    vars = whos('-file', entity_file);
    load(entity_file);
    if ~strcmp(vars.name,'entity')
        entity = eval(vars.name);
        clear (vars.name)
    end
end

% prompt for hazard if not given
if isempty(hazard) % local GUI
    hazard=[climada_global.data_dir filesep 'hazards' filesep '*.mat'];
    [filename, pathname] = uigetfile(hazard, 'Select hazard event set for EDS calculation:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard=fullfile(pathname,filename);
    end
end
% load the hazard, if a filename has been passed
if ~isstruct(hazard)
    hazard_file=hazard;hazard=[];
    vars = whos('-file', hazard_file);
    load(hazard_file);
    if ~strcmp(vars.name,'hazard')
        hazard = eval(vars.name);
        clear (vars.name)
    end
end
hazard=climada_hazard2octave(hazard); % Octave compatibility for -v7.3 mat-files

% prompt for reference result if not given
if isempty(measures_impact_reference)
    measures_impact_reference=[climada_global.data_dir filesep 'results' filesep '*.mat'];
    [filename, pathname] = uigetfile(measures_impact_reference, 'Select reference results (skip if not future):');
    if isequal(filename,0) || isequal(pathname,0)
        measures_impact_reference=''; % re-set to empty
    else
        measures_impact_reference = fullfile(pathname,filename);
    end
end

if ~isempty(measures_impact_reference)
    % load if a filename has been passed
    if ~isstruct(measures_impact_reference)
        if strcmp(measures_impact_reference,'no')
            %measures_impact_reference = '';
        else
            measures_impact_reference_file = measures_impact_reference; measures_impact_reference = [];
            vars = whos('-file', measures_impact_reference_file);
            load(measures_impact_reference_file);
            if ~strcmp(vars.name,'measures_impact_reference')
                measures_impact_reference = eval(vars.name);
                clear (vars.name)
            end
        end
    end
    if ~isempty(measures_impact_reference) & ~strcmp(measures_impact_reference,'no')
        % reference is aleays today, warn if not
        reference_year = measures_impact_reference.EDS(end).reference_year;
        if reference_year ~= climada_global.present_reference_year
            %fprintf('WARNING: reference year for reference results is %i (should be %i)\n',reference_year,climada_global.present_reference_year);
        end
    end
end

if isfield(entity,'measures')
    if isempty(measures)
        measures = entity.measures;
    end
elseif isempty(measures)
    measures = 'ASK';
end
% prompt for measures if not given
if ~isstruct(measures)
    if strcmp(measures,'ASK')
        measures = [climada_global.data_dir filesep 'measures' filesep '*.mat'];
        [filename, pathname] = uigetfile(measures, 'Select measures:');
        if isequal(filename,0) || isequal(pathname,0)
            return; % cancel
        else
            measures = fullfile(pathname,filename);
        end
    end
end
% load the measures, if a filename has been passed
if ~isstruct(measures)
    measures_file=measures;measures=[];
    vars = whos('-file', measures_file);
    load(measures_file);
    if ~strcmp(vars.name,'measures')
        measures = eval(vars.name);
        clear (vars.name)
    end
end

% check for correct encoding to the hazard
if ~isfield(entity.assets,'hazard')
    force_re_encode=1; % entity not encoded yet
else
    % assets have been encoded, check whether for same hazard
    if ~strcmp(entity.assets.hazard.filename,hazard.filename)
        % not the same hazard set, force re-encoding to be on the safe side
        % (it's likely that the climate scenario hazard event set is valid at
        % the exact same centroids, but encoding is much faster than any later
        % troubleshooting ;-)
        force_re_encode=1;
    else
        force_re_encode=0; % entity encoded
    end
end

if force_re_encode
    entity=climada_assets_encode(entity,hazard);
end

% loop over all measures and calculate the corresponding EDSs
% -----------------------------------------------------------

% make (backup) copies of the original data in entity:
entity_orig_damagefunctions = entity.damagefunctions;
orig_assets_DamageFunID     = entity.assets.DamageFunID;

if isfield(measures,'damagefunctions') % append measure's vulnerabilities
    entity.damagefunctions.DamageFunID = measures.damagefunctions.DamageFunID;
    entity.damagefunctions.Intensity   = measures.damagefunctions.Intensity;
    entity.damagefunctions.MDD         = measures.damagefunctions.MDD;
    entity.damagefunctions.PAA         = measures.damagefunctions.PAA;
    
    %entity.damagefunctions.DamageFunID = [entity.damagefunctions.DamageFunID,measures.damagefunctions.DamageFunID];
    %entity.damagefunctions.Intensity   = [entity.damagefunctions.Intensity,measures.damagefunctions.Intensity];
    %entity.damagefunctions.MDD         = [entity.damagefunctions.MDD,measures.damagefunctions.MDD];
    %entity.damagefunctions.PAA         = [entity.damagefunctions.PAA,measures.damagefunctions.PAA];
end

orig_damagefunctions = entity.damagefunctions; % copy of this table for speedup
n_measures           = length(measures.cost);

climada_measures_check(entity.measures)

%fprintf('assessing impacts of %i measures:\n',n_measures);

risk_transfer = zeros(1,n_measures+1); % allocate
hazard_switched  = 0; % indicated whether a special hazard set for a given measure is used

for measure_i = 1:n_measures+1 % last with no measures
    if measure_i <= n_measures
        
        %fprintf('assessing impact of measure %i\n',measure_i); % TEST
        
        % special treatment if an alternate hazard set is given
        if isfield(measures,'hazard_event_set')
            measures_hazard_set_name = measures.hazard_event_set{measure_i};
            if ~strcmp(measures_hazard_set_name,'nil')
                orig_hazard = hazard;
                if ~exist(measures_hazard_set_name,'file')
                    % only filename given in measures tab, add path:
                    if exist('hazard_file','var') % <- exist(hazard_file,'var') fixed 20150626 GS
                        [hazard_dir] = fileparts(hazard_file);
                    else
                        hazard_dir = [climada_global.data_dir filesep 'hazards']; % default
                    end
                    measures_hazard_file = [hazard_dir filesep measures_hazard_set_name];
                else
                    % contains path already
                    measures_hazard_file = measures_hazard_set_name;
                end
                [fP,fN,fE] = fileparts(measures_hazard_file);
                if isempty(fE),measures_hazard_file = [fP filesep fN '.mat'];end % append .mat
                if exist(measures_hazard_file,'file')
                    orig_hazard = hazard; % backup
                    fprintf('NOTE: measure %i, switched hazard to %s\n',measure_i,measures_hazard_file);
                    load(measures_hazard_file);
                    hazard_switched = 1;
                    % some basic consistency checks to make sure switched
                    % hazard is reasonable
                    try
                        hazard_checksum = abs(sum(hazard.centroid_ID-orig_hazard.centroid_ID + ...
                            hazard.lon-orig_hazard.lon + ...
                            hazard.lat-orig_hazard.lat));
                        if hazard_checksum>0
                            fprintf('WARNING: hazard might not be fully compatible with encoded assets\n');
                        end
                    catch
                        % if array dimension do not match, above check fails
                        fprintf('WARNING: hazard might not at all be compatible with encoded assets\n');
                    end % try
                    % hazard=climada_hazard2octave(hazard); % Octave compatibility for -v7.3 mat-files
                    % if abs(numel(hazard.intensity)-numel(hazard.intensity))
                    %     fprintf('WARNING: hazard might not be fully compatible with EDS\n');
                    % end
                else
                    fprintf('ERROR: measure %i, hazard NOT switched, hazard set %s not found\n',measure_i,measures_hazard_file);
                end
            else
                hazard_switched = 0; % no hazard switched
            end % measures_hazard_set_name
        end % isfield(measures,'hazard_event_set')
        
        
        for map_i = 1:length(measures.damagefunctions_mapping(measure_i).map_from)
            % damagefunctions mapping
            pos = orig_assets_DamageFunID==measures.damagefunctions_mapping(measure_i).map_from(map_i);
            entity.assets.DamageFunID(pos) = measures.damagefunctions_mapping(measure_i).map_to(map_i);
            %fprintf('mapping DamageFunID %i to %i ',...
            %    measures.damagefunctions_mapping(measure_i).map_from(map_i),...
            %    measures.damagefunctions_mapping(measure_i).map_to(map_i));
        end % map_i
        
        if measure_i==debug_measure_i,plot(orig_damagefunctions.Intensity,orig_damagefunctions.MDD.*orig_damagefunctions.PAA,'--b');end
        
        entity.damagefunctions.Intensity = max(orig_damagefunctions.Intensity - measures.hazard_intensity_impact_b(measure_i),0);
        entity.damagefunctions.MDD       = max(orig_damagefunctions.MDD*measures.MDD_impact_a(measure_i)+measures.MDD_impact_b(measure_i),0);
        entity.damagefunctions.PAA       = max(orig_damagefunctions.PAA*measures.PAA_impact_a(measure_i)+measures.PAA_impact_b(measure_i),0);
        annotation_name                  = measures.name{measure_i};
       
        if isfield(measures,'hazard_intensity_impact_a')
            % for BACKWARD COMPATIBILITY: the following line was used until 20150907
            %%entity.damagefunctions.Intensity = max(entity.damagefunctions.Intensity*(1-measures.hazard_intensity_impact_a(measure_i)),0);
            if ~(measures.hazard_intensity_impact_a(measure_i)==0)
                entity.damagefunctions.Intensity = max(entity.damagefunctions.Intensity/measures.hazard_intensity_impact_a(measure_i),0);
            end
        end
    else
        entity.damagefunctions = entity_orig_damagefunctions; % back to original
        annotation_name        = 'control';
    end
    
    if measure_i==debug_measure_i,hold on;plot(entity.damagefunctions.Intensity,entity.damagefunctions.MDD.*entity.damagefunctions.PAA,'-g');legend('orig','impact');end
       
    EDS(measure_i)            = climada_EDS_calc(entity,hazard,annotation_name,'',0,sanity_check);
    entity.assets.DamageFunID = orig_assets_DamageFunID; % reset damagefunctions mapping
    
    if measure_i<=n_measures % not for the control run (last one)
        
        if measures.hazard_high_frequency_cutoff(measure_i)>0
            % apply frequency cutoff
            [~,exceedence_freq,~,~,event_index_out] =...
                climada_damage_exceedence(EDS(measure_i).damage,EDS(measure_i).frequency,EDS(measure_i).event_ID);
            cutoff_pos      = exceedence_freq>measures.hazard_high_frequency_cutoff(measure_i);
            event_index_out = event_index_out(cutoff_pos);
            %%fprintf('cutoff %i events\n',length(event_index_out));
            [~,pos] = ismember(event_index_out,EDS(measure_i).event_ID);
            EDS(measure_i).damage(pos) = 0;
            % previous two lines do the same as (but much faster)
            % for index_i=1:length(event_index_out)
            %     EDS_index_i=find(EDS(measure_i).event_ID==event_index_out(index_i));
            %     EDS(measure_i).damage(EDS_index_i)=0;
            % end % index_i
        end
        
        % apply risk transfer
        if measures.risk_transfer_attachement(measure_i)+measures.risk_transfer_cover(measure_i)>0
            damage_in_layer = min(max(EDS(measure_i).damage-measures.risk_transfer_attachement(measure_i),0),...
                measures.risk_transfer_cover(measure_i));
            risk_transfer(measure_i) = full(sum(damage_in_layer.*EDS(measure_i).frequency)); % ED in layer
            EDS(measure_i).damage       = max(EDS(measure_i).damage-damage_in_layer,0); % remaining damage after risk transfer
        end % apply risk transfer
        
    end % all except last run
    
    if hazard_switched
        % always switch back, to avoid troubles if hazard passed as struct
        hazard = orig_hazard; % restore
        fprintf('NOTE: switched hazard back\n');
        orig_hazard=[]; % free up memory
    end
    
end % measure_i

% store useful hazard and EDS information into measures_impact
measures_impact.EDS = EDS; 
measures_impact.risk_transfer = risk_transfer;
measures_impact.measures = measures; % store measures into res, so we have a complete set
measures_impact.peril_ID = hazard.peril_ID;
if isfield(EDS,'Value_unit')
    measures_impact.Value_unit   = EDS(1).Value_unit;
else
    measures_impact.Value_unit   = climada_global.Value_unit;
end

% calculate the cost/benefit ratio also here (so we have all results in one)
measures_impact = climada_measures_impact_discount(entity,measures_impact,measures_impact_reference);


% last but not least, calculate risk premium
measures_impact.risk_premium_fgu = measures_impact.NPV_total_climate_risk/measures_impact.EDS(1).Value;
fprintf('total climate risk premium (fgu - only a proxy): %f%%\n',...
measures_impact.risk_premium_fgu*100);
measures_impact.risk_premium_net = (measures_impact.NPV_total_climate_risk-...
sum(measures_impact.ED_benefit(measures_impact.cb_ratio<1)))/measures_impact.EDS(1).Value;
fprintf('total climate risk premium (net of effective measures): %f%%\n',...
measures_impact.risk_premium_net*100);
fprintf('total climate risk premium reduction (relative) %2.2f%%\n',...
-(measures_impact.risk_premium_net/measures_impact.risk_premium_fgu-1)*100);
measures_impact.risk_premium_comment = 'total climate risk divided by the total value of assets';

% prepare annotation (title_str) and filename
[~,hazard_name]   = fileparts(EDS(1).hazard.filename);
[~,assets_name]   = fileparts(EDS(1).assets.filename);
[~,measures_name] = fileparts(measures.filename);
if strcmp(measures_name,assets_name),measures_name='m';end
measures_impact.title_str = sprintf('%s @ %s | %s',measures_name,assets_name,hazard_name);

save_filename = strrep(measures_impact.title_str,' ',''); % for filename
save_filename = strrep(save_filename,'_',''); % for filename
save_filename = strrep(save_filename,'@','_'); % for filename
save_filename = strrep(save_filename,'|','_'); % for filename
save_filename = [climada_global.data_dir filesep 'results' filesep save_filename];

measures_impact.filename = save_filename;

save(save_filename,'measures_impact')
fprintf('results written to %s\n',save_filename);

if map_risk_premium
    % plot the total climate risk premium
    
    % risk premium fgu at each centroid
    centroid_risk_premium_fgu=measures_impact.EDS(end).ED_at_centroid;
    
    % risk premium net of effective measures at each centroid
    d_risk_premium_net=centroid_risk_premium_fgu*0; % init
    effective_measures_pos=find(measures_impact.cb_ratio<1);
    for i=1:length(effective_measures_pos) % sum over all benefits with c/b <1
        d_risk_premium_net=d_risk_premium_net+(centroid_risk_premium_fgu-...
            measures_impact.EDS(effective_measures_pos(i)).ED_at_centroid);
    end % i
    centroid_risk_premium_net=centroid_risk_premium_fgu-d_risk_premium_net;
    % divide by total Value ast each centroid (to obtain risk premium)
    centroid_risk_premium_fgu=centroid_risk_premium_fgu./measures_impact.EDS(end).assets.Value*100;
    centroid_risk_premium_net=centroid_risk_premium_net./measures_impact.EDS(end).assets.Value*100;
    
    % define a common color axis
    caxis_range=[min(min(centroid_risk_premium_fgu),min(centroid_risk_premium_net)) ...
        max(max(centroid_risk_premium_fgu),max(centroid_risk_premium_net))];
    
    % plot on two panes, figure whether wider extent in lon or lat
    dlon=max(measures_impact.EDS(end).assets.lon)-min(measures_impact.EDS(end).assets.lon);
    dlat=max(measures_impact.EDS(end).assets.lat)-min(measures_impact.EDS(end).assets.lat);
    if dlat>dlon,subplot(1,3,1),else subplot(3,1,1);end
    climada_color_plot(centroid_risk_premium_fgu,...
        measures_impact.EDS(end).assets.lon,...
        measures_impact.EDS(end).assets.lat,'none','risk premium fgu [%]',...
        'pcolor','linear',199,1,caxis_range);
    if dlat>dlon,subplot(1,3,2),else subplot(3,1,2);end
    climada_color_plot(centroid_risk_premium_net,...
        measures_impact.EDS(end).assets.lon,...
        measures_impact.EDS(end).assets.lat,'none','risk premium net [%]',...
        'pcolor','linear',199,1,caxis_range);
    set(gcf,'Color',[1 1 1]);
    if dlat>dlon,subplot(1,3,3),else subplot(3,1,3);end
    climada_color_plot(-(centroid_risk_premium_net./centroid_risk_premium_fgu-1)*100,...
        measures_impact.EDS(end).assets.lon,...
        measures_impact.EDS(end).assets.lat,'none','risk premium reduction [rel %]',...
        'pcolor','linear',199,1);
    set(gcf,'Color',[1 1 1]);
        
end % map_risk_premium

return
