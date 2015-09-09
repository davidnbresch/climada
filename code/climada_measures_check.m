function climada_measures_check(measures)
% climada_measures_check
% NAME:
%   climada_measures_check
% PURPOSE:
%   Check measures (just a check, but no changes/improvements) to be aware
%   if the measures decrease or (accidentally) increase the damage
%   can be called from: climada_measures_read
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
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('measures','var'),measures = [];end

% PARAMETERS
if isempty(measures), fprintf('No measures given.\n'), return, end

% check measures_impact
if isfield(measures, 'cost')
    if any(isnan(measures.cost))
        fprintf('WARNING: There are nan-values in your costs. You might want to check.\n')
    end
    if any(measures.cost<=0)
        fprintf('WARNING: Costs are 0 or negative. You might want to check.\n')
    end
end
if isfield(measures, 'hazard_intensity_impact_a')
    if any(isnan(measures.hazard_intensity_impact_a))
        fprintf('WARNING: There are nan-values in your hazard_intensity_impact_a. You might want to check.\n')
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
        fprintf('WARNING: There are nan-values in your hazard_intensity_impact_b. You might want to check.\n')
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
        fprintf('WARNING: There are nan-values in your MDD_impact_a. You might want to check.\n')
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
        fprintf('WARNING: There are nan-values in your MDD_impact_b. You might want to check.\n')
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
        fprintf('WARNING: There are nan-values in your PAA_impact_a. You might want to check.\n')
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
        fprintf('WARNING: There are nan-values in your PAA_impact_b. You might want to check.\n')
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




