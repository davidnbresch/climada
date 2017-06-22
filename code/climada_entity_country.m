function entity=climada_entity_country(admin0_name,high_res_flag)
% climada template
% MODULE:
%   core
% NAME:
%   climada_entity_country
% PURPOSE:
%   Construct an entity file based on mid-resolution (10km) night light
%   data for any country of the world.
%
%   just a simple wrapper for climada_nightlight_entity (only another name
%   to be found easily)
%
%   previous call: startup
%   next call: climada_entity_plot
% CALLING SEQUENCE:
%   entity=climada_entity_country(admin0_name)
% EXAMPLE:
%   entity=climada_entity_country('PRI')
%   climada_entity_plot(entity)
% INPUTS:
%   admin0_name: the country name, either full (like 'Puerto Rico')
%       or ISO3 (like 'PRI'). See climada_country_name for names/ISO3
%       > If empty, a list dialog lets the user select a country
% OPTIONAL INPUT PARAMETERS:
%   high_res_flag: if =1, generate high-res (1km) resolution instead of
%   default 10km. Needs country_risk module to be installed
% OUTPUTS:
%   entity: a climada entity structure, as described in e.g. climada_entity_read
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20170323, init, just a wrapper for climada_nightlight_entity
% David N. Bresch, david.bresch@gmail.com, 20170613, high_res_flag added
%-

if ~exist('admin0_name','var'),admin0_name=''; end
if ~exist('high_res_flag','var'),high_res_flag=0; end

if high_res_flag
    if length(which('country_risk_calc'))<2
        fprintf(['country risk module not found. Please download ' ...
            '<a href="https://github.com/davidnbresch/climada_module_country_risk">'...
            'climada_module_country_risk</a> from Github or see climada_git_pull_repositories.\n'...
            'or call %f without the high_res_flag\n'],mfilename);
        return
    end
    p.resolution_km=1;
    entity=climada_nightlight_entity(admin0_name,'',p);
else
    entity=climada_nightlight_entity(admin0_name);
end

end % climada_entity_country