function measures = climada_measures_check(measures, assets)
% climada_measures_check
% NAME:
%   climada_measures_check
% PURPOSE:
%   Check measures (just a check, but no changes/improvements) to be aware
%   if the measures decrease or (accidentally) increase the damage
%   can be called from: climada_measures_read
%
%   See climada_measures_complete not only to check but also to complete a
%   measures structure, then call climada_measures_encode to convert some
%   of the human-readable fields (such as damagefunction mapping '1to3').
% CALLING SEQUENCE:
%   climada_measures_check(measures)
% EXAMPLE:
%   climada_measures_check(measures)
% INPUTS:
%   measures: a measures structure 
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   none, just stdout information
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150907, init
% Lea Mueller, muellele@gmail.com, 20150909, check if a measure implies to use a differerent assets file
% Lea Mueller, muellele@gmail.com, 20150915, check that regional_scope matrix has the correct dimension 
% Lea Mueller, muellele@gmail.com, 20150916, shorten or enlarge regional_scope if needed 
% Lea Mueller, muellele@gmail.com, 20150921, hand back corrected measures
% Lea Mueller, muellele@gmail.com, 20151117, correct fprintf
%-

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('measures','var'), measures = [];end
if ~exist('assets','var'), assets = [];end

% PARAMETERS
if isempty(measures), fprintf('No measures given.\n'), return, end

% check measures_impact
if isfield(measures, 'cost')
    if any(isnan(measures.cost))
        fprintf('WARNING: There are NaN-values in your costs. You might want to check.\n')
    end
    if any(measures.cost<=0)
        fprintf('WARNING: Costs are 0 or negative. You might want to check.\n')
    end
end
if isfield(measures, 'hazard_intensity_impact_a')
    if any(isnan(measures.hazard_intensity_impact_a))
        fprintf('WARNING: There are NaN-values in your hazard_intensity_impact_a. You might want to check.\n')
    end
    if any(measures.hazard_intensity_impact_a>1)
        fprintf('WARNING: %d measures increase the hazard intensity by a percentage factor. You might want to check hazard_intensity_impact_a.\n',...
            sum(measures.hazard_intensity_impact_a>1))
    end
    if any(measures.hazard_intensity_impact_a<1)
        fprintf('%d measures decrease the hazard intensity by a percentage factor. \n',sum(measures.hazard_intensity_impact_a<1))
    end
end
if isfield(measures, 'hazard_intensity_impact_b')
    if any(isnan(measures.hazard_intensity_impact_b))
        fprintf('WARNING: There are NaN-values in your hazard_intensity_impact_b. You might want to check.\n')
    end
    if any(measures.hazard_intensity_impact_b>0)
        fprintf('WARNING: %d measures increase the hazard intensity by an absolute factor. You might want to check hazard_intensity_impact_b.\n',...
            sum(measures.hazard_intensity_impact_b>0))
    end
    if any(measures.hazard_intensity_impact_b<0)
        fprintf('%d measures decrease the hazard intensity by an absolute factor. \n',sum(measures.hazard_intensity_impact_b<0))
    end
end
if isfield(measures, 'MDD_impact_a')
    if any(isnan(measures.MDD_impact_a))
        fprintf('WARNING: There are NaN-values in your MDD_impact_a. You might want to check.\n')
    end
    if any(measures.MDD_impact_a>1)
        fprintf('WARNING: %d measures increase the MDD by a percentage factor. You might want to check MDD_impact_a.\n',...
            sum(measures.MDD_impact_a>1))
    end
    if any(measures.MDD_impact_a<1)
        fprintf('%d measures decrease the MDD by a percentage factor. \n',sum(measures.MDD_impact_a<1))
    end
end
if isfield(measures, 'MDD_impact_b')
    if any(isnan(measures.MDD_impact_b))
        fprintf('WARNING: There are NaN-values in your MDD_impact_b. You might want to check.\n')
    end
    if any(measures.MDD_impact_b>0)
        fprintf('WARNING: %d measures increase the MDD by an absolute factor. You might want to check MDD_impact_b.\n',...
            sum(measures.MDD_impact_b>0))
    end
    if any(measures.MDD_impact_b<0)
        fprintf('%d measures decrease the MDD by an absolute factor. \n',sum(measures.MDD_impact_b<0))
    end
end
if isfield(measures, 'PAA_impact_a')
    if any(isnan(measures.PAA_impact_a))
        fprintf('WARNING: There are NaN-values in your PAA_impact_a. You might want to check.\n')
    end
    if any(measures.PAA_impact_a>1)
        fprintf('WARNING: %d measures increase the PAA by a percentage factor. You might want to check PAA_impact_a.\n',...
            sum(measures.PAA_impact_a>1))
    end
    if any(measures.PAA_impact_a<1)
        fprintf('%d measures decrease the PAA by a percentage factor. \n',sum(measures.PAA_impact_a<1))
    end
end
if isfield(measures, 'PAA_impact_b')
    if any(isnan(measures.PAA_impact_b))
        fprintf('WARNING: There are NaN-values in your PAA_impact_b. You might want to check.\n')
    end
    if any(measures.PAA_impact_b>0)
        fprintf('WARNING: %d measures increase the PAA by an absolute factor. You might want to check PAA_impact_b.\n',...
            sum(measures.PAA_impact_b>0))
    end
    if any(measures.PAA_impact_b<0)
        fprintf('%d measures decrease the hazard the PAA by an absolute factor. \n',sum(measures.PAA_impact_b<0))
    end
end
if isfield(measures, 'assets_file')
    if any(~strcmp(measures.assets_file,'nil'))
        fprintf('%d measures use a different asset file. \n',sum(~strcmp(measures.assets_file,'nil')))
    end
end
if isfield(measures, 'hazard_event_set')
    if any(~strcmp(measures.hazard_event_set,'nil'))
        fprintf('%d measures use a different hazard event set. \n',sum(~strcmp(measures.hazard_event_set,'nil')))
    end
end


n_measures = size(measures.name,1);

if isfield(measures,'regional_scope')
    if ~isempty(assets)
    % check that regional_scope matrix has the correct dimension 
        if size(measures.regional_scope,1) > numel(assets.Value)
            fprintf('Regional scope of measures does not match with number of assets. Data will be shortened./n')
            measures.regional_scope(numel(assets.Value)+1:end,:) = [];
            measures.regional_scope = logical(measures.regional_scope);
        end
        if size(measures.regional_scope,1) < numel(assets.Value)
            fprintf('Regional scope of measures does not match with number of assets. Data will be enlarged./n')
            measures.regional_scope(end+1:numel(assets.Value),:) = 1;
            measures.regional_scope = logical(measures.regional_scope);
        end
    end
    
    n_assets = size(measures.regional_scope,1);
    for m_i = 1:n_measures
        if any(~measures.regional_scope(:,m_i))        
            fprintf('Measure %d impacts %d of %d assets (%s)\n',m_i,...
                sum(measures.regional_scope(:,m_i)),n_assets,measures.name{m_i})
        end
    end 
end % climada_measures_check