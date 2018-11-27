function [damagefunctions] = climada_damagefunctions_generate_from_fun(intensity,MDD_fun,MDD_pars,params,PAA_fun,PAA_pars)
% climada_damagefunctions_generate_from_fun
% MODULE:
%   core
% NAME:
%   climada_damagefunctions_generate_from_fun
% PURPOSE:
%   Generate damagefunctions based on a function
%
%   See also: climada_damagefunctions_map and _plot ...
% CALLING SEQUENCE:
%   damagefunction=climada_damagefunctions_generate_from_fun(intensity,MDD_fun,MDD_pars,params,PAA_fun,PAA_pars)
% EXAMPLE:
%   damagefunction=climada_damagefunctions_generate_from_fun(0:3:15,@(x,p) 1-exp(-p(1)*x),0.08)
%   damagefunction=climada_damagefunctions_generate_from_fun(0:3:15,@(x,~) x/15)
% INPUTS:
%   intensity: the hazard intensity scale, i.e. the horizontal axis of the
%       damage function. Any vector of intensities, ascending in value,
%       such as 1:10:100
%   MDD_fun: function handle describing the shape of MDD as a function of
%       intensity and parameters (e.g. @(x,p)exp(-p*x) ). If the function
%       does not have any parameter, use tilde (~), for instance @(x,~) x/15
% OPTIONAL INPUT PARAMETERS:
%   MDD_pars: parameter values to be used in MDD_fun (empty by default)
%   params: parameters for the damage function:
%       peril_ID: the 2-digit peril_ID, such as 'TC','EQ',... (default='NA')
%       DamageFunID: the damage function ID (default=1)
%       Intensity_unit: unit of the intensity scale (default='NA')
%       IntensityCap: =1 to put caps to MDD and PAA, corresponding to the
%           values at the min and max of intensity. This is done by adding
%           two values to intensity (one below min(intensity), one above
%           max(intensity)). Default=1 
%       name: added as field to damagefunction, default='damage function
%           from climada_damagefunctions_generate_from_fun'
%   PAA_fun: as MDD_fun but for PAA: function handle describing the shape
%       of PAA. By default, PAA is set to one for all intensities
%   PAA_pars: parameter values to be used in PAA_fun (empty by default)
% OUTPUTS:
%   damagefunction: a structure with
%       filename: just for information, here 'climada_damagefunctions_generate'
%       Intensity(i): the hazard intensity (a vector)
%       DamageFunID(i): =ones(1,length(Intensity)
%       peril_ID{i}: a cell array with peril_ID
%       Intensity_unit{i}: a cell array with the unit of intensity
%       MDD(i): the mean damage degree value for Intensity(i)
%       PAA(i): the percentage of affected assets for Intensity(i)
%       name(i): name of the damage function
%       datenum(i): date of the damage function creation
% MODIFICATION HISTORY:
% Benoit P. Guillod, benoit.guillod@env.ethz.ch, 20181127, initial
%-

damagefunctions=[]; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('intensity','var'),intensity=[];end
if ~exist('MDD_fun','var'),MDD_fun=[];end
if ~exist('MDD_pars','var'),MDD_pars=[];end
if ~exist('params','var'),params=[];end
if ~exist('PAA_fun','var'),PAA_fun=@(n,~)ones(size(n));end
if ~exist('PAA_pars','var'),PAA_pars=[];end

% PARAMETERS
%
% define all default parameters
if isempty(intensity),error('argument intensity must be provided');end
if isempty(MDD_fun),error('argument MDR_fun must be provided');end
if ~isfield(params,'peril_ID'),params.peril_ID='NA';end
if ~isfield(params,'DamageFunID'),params.DamageFunID=1;end
if ~isfield(params,'Intensity_unit'),params.Intensity_unit={'NA'};end
if ~isfield(params,'IntensityCap'),params.IntensityCap=1;end
if ~isfield(params,'name'),params.name='damage function from climada_damagefunctions_generate_from_fun';end

% dmf_info_str=sprintf('%s %s %3.3f*(i-%i)**%2.2f',peril_ID,dmf_shape,dmf_max,dmf_min_intens,dmf_exp);

% correctly position vectors
if size(intensity,1)>size(intensity,2),intensity=intensity';end

damagefunctions.filename=mfilename;
if params.IntensityCap
    % average intensity step
    di = range(intensity,'all')/(length(intensity)-1);
    damagefunctions.Intensity=[min(intensity)-di intensity max(intensity)+di];
else
    damagefunctions.Intensity=[intensity];
end
damagefunctions.DamageFunID=params.DamageFunID*ones(size(damagefunctions.Intensity));
damagefunctions.peril_ID=cellstr(repmat(params.peril_ID,length(damagefunctions.Intensity),1))';
damagefunctions.Intensity_unit=repmat(params.Intensity_unit',size(damagefunctions.Intensity));
damagefunctions.MDD = MDD_fun(damagefunctions.Intensity, MDD_pars);
damagefunctions.PAA = PAA_fun(damagefunctions.Intensity, PAA_pars);
if params.IntensityCap
    % set caps to MDD and PAA
    damagefunctions.MDD(end) = damagefunctions.MDD(end-1);
    damagefunctions.MDD(1) = damagefunctions.MDD(2);
    damagefunctions.PAA(end) = damagefunctions.PAA(end-1);
    damagefunctions.PAA(1) = damagefunctions.PAA(2);
end
damagefunctions.name = repmat({params.name},size(damagefunctions.Intensity));
damagefunctions.datenum = zeros(size(damagefunctions.Intensity))+ now;

end