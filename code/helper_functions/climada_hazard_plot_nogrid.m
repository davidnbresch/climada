function [res,params]=climada_hazard_plot_nogrid(hazard,event_i,markersize,params)
% climada template
% MODULE:
%   core
% NAME:
%   climada_hazard_plot_nogrid
% PURPOSE:
%   just a caller for climada_hazard_plot, as this code was formerly known
%   as climada_hazard_plot_nogrid
% CALLING SEQUENCE:
%   [res,params]=climada_hazard_plot_nogrid(hazard,event_i,markersize,params)
% EXAMPLE:
%   see climada_hazard_plot
% INPUTS:
%   see climada_hazard_plot
% OPTIONAL INPUT PARAMETERS:
%   see climada_hazard_plot
% OUTPUTS:
%   see climada_hazard_plot
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20171231, as we renamed climada_hazard_plot
%-

res=[]; % init

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('hazard','var'),     hazard=[];end
if ~exist('event_i','var'),    event_i=-1;end
if ~exist('markersize','var'), markersize=[];end
if ~exist('params','var'),     params=struct;end

[res,params]=climada_hazard_plot(hazard,event_i,markersize,params);

end % climada_hazard_plot_nogrid