function assets = climada_measures_assets_change(measures,measure_i)
% climada
% NAME:
%   climada_measures_assets_change
% PURPOSE:
%   Read new assets from excel if defined so in measures.assets_file
%   If measures.assets_file{measure_i} is 'nil', assets remains empty
%   Note: assets are not yet encoded
%   to be called in climada_measures_impact
% CALLING SEQUENCE:
%   assets = climada_measures_assets_change(measures,measure_i)
% EXAMPLE:
%   assets = climada_measures_assets_change(measures,measure_i)
% INPUTS:
%   measures: a measures structure
%   measire_i: an array between 1 and n_measures
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   assets: an asset structure with
%       .lon, .lat, .Value, etc. not encoded
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150908, init
% Lea Mueller, muellele@gmail.com, 20150930, save assets.filename with .mat as extension
% Lea Mueller, muellele@gmail.com, 20151117, call climada_assets_read instead of climada_entity_read
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

if ~exist('measures','var'),measures='';end
if ~exist('measure_i','var'),measure_i='';end
        
assets = []; % init

if isempty(measure_i); measure_i = 1; end

% prompt for measures if not given
if isempty(measures) % local GUI
    measures=[climada_global.data_dir filesep 'entities' filesep '*.mat'];
    [filename, pathname] = uigetfile(measures, 'Select encoded entity:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        measures=fullfile(pathname,filename);
    end
end
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


% special treatment if alternate assets are provided
if isfield(measures,'assets_file')
    measures_assets_name = measures.assets_file{measure_i};
    if strcmp(measures_assets_name,'nil')
        return
    elseif ~exist(measures_assets_name,'file')        
        % only filename given in measures tab, add path:
        if isfield(measures,'filename')
            measures_dir = fileparts(measures.filename);
        else
            measures_dir = [climada_global.data_dir filesep 'entities']; % default
        end
        measures_assets_file = [measures_dir filesep measures_assets_name];
    else
        % contains path already
        measures_assets_file = measures_assets_name;
    end
    [fP,fN,fE] = fileparts(measures_assets_file);
    if isempty(fE),measures_assets_file = [fP filesep fN '.mat'];end % append .mat
    if exist(measures_assets_file,'file')
        cprintf([0 0 1],'NOTE: measure %i, switched assets according to %s\n',measure_i,measures_assets_file);
        %entity = climada_entity_read(measures_assets_file,'NOENCODE');
        %assets = entity.assets;
        assets = climada_assets_read(measures_assets_file,'NOENCODE');
        assets.filename = [fP filesep fN '.mat'];
    else
        cprintf([1 0 0],'ERROR: measure %i, assets NOT switched, assets %s not found\n',measure_i,measures_assets_file);
    end
end % measures_assets_name


        

