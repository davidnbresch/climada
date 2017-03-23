function entity=climada_entity_country(admin0_name)
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
% OUTPUTS:
%   entity: a climada entity structure, as described in e.g. climada_entity_read
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20170323, init, just a wrapper for climada_nightlight_entity
%-

if ~exist('admin0_name','var'),admin0_name=''; end
entity=climada_nightlight_entity(admin0_name);

end % climada_entity_country