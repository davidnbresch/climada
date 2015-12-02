function [input_structure, fig] = climada_map_plot(input_structure,fieldname_to_plot,plot_method,event_no,struct_no,category_criterium)
% Generate a map plot
% MODULE:
%   core/helper_functions
% NAME:
%   climada_map_plot
% PURPOSE:
%   create a map, for a selected input structure and a fieldname, i.e.
%   'elevation_m' of centroids, 'Value' of entity.assets, 'intensity' of
%   hazard
% PREVIOUS STEP:
%   multiple
% CALLING SEQUENCE:
%   [input_structure, fig] = climada_map_plot(input_structure,fieldname_to_plot,plot_method,event_no,struct_no)
% EXAMPLE:
%   [input_structure, fig] = climada_map_plot
%   hazard = climada_map_plot('TCNA_today_small','','contourf',7121);
%   climada_map_plot(entity,'Value')
%   climada_map_plot(centroids,{'elevation_m' 'slope_deg'})
%   climada_map_plot(EDS,'ED_at_centroid','',1,3) % plot EDS number 3
%   climada_map_plot('m_demotoday_TCNA2030highsmall',{'ED_at_centroid' 'benefit'},'',2,1) % plot AED and benefit for measure no 2
% INPUTS:
%   input_structure:  a climada stucture, i.e. centroids, entity,
%        entity.assets, hazard, EDS, can also be the filename of a saved
%        struct, i.e. TCNA_today_small
%   fieldname_to_plot: string or cell, i.e. 'Value', or {'elevation_m' 'slope_deg'}
% OPTIONAL INPUT PARAMETERS:
%   plot_method: a string, default is 'plotclr', can also be 'contourf'
%   event_no: an array, only important to select a specific event for
%   'intensity', or number of measure for measures_impact
%   struct_no: an array, only important to select a specific struct,i.e. 
%       if EDS holds more than one EDS, or measures_impact holds multiple structs
%   category_criterium: a string or cell, e.g. {'Agriculture' 'Residential
%       houses'} to select a subset of assets that will be shown
% OUTPUTS:
%   input_structure:  a climada stucture, i.e. centroids, entity,
%        entity.assets, hazard, EDS
%   fig: handle on the figure with a map displaying the selected field 
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151124, init
% Lea Mueller, muellele@gmail.com, 20151130, enhance to work with measures_impact and plot benefit
% Lea Mueller, muellele@gmail.com, 20151202, enhance to select only one or multiple categories (.assets.Category)
% -

fig = []; % init

global climada_global
if ~climada_init_vars, return; end

% check arguments
if ~exist('input_structure', 'var'), input_structure = []; end
if ~exist('fieldname_to_plot', 'var'), fieldname_to_plot = []; end
if ~exist('plot_method', 'var'), plot_method = []; end
if ~exist('event_no', 'var'), event_no = []; end
if ~exist('struct_no', 'var'), struct_no = []; end
if ~exist('category_criterium','var'), category_criterium = []; end

if isempty(plot_method), plot_method = 'plotclr'; end 
if isempty(event_no), event_no = 1; end 
if isempty(struct_no), struct_no = 1; end 
if isempty(category_criterium), category_criterium = ''; end 



struct_name = '';
if ischar(input_structure)  %isempty(input_structure) 
    [input_structure, struct_name] = climada_load(input_structure); 
    %fprintf('You have loaded a %s\n',struct_name);
end 
if isempty(input_structure), fprintf('No structure (centroids, hazard, entity) selected to plot on a map\n'); return, end

% take only first structure if it contains more than one (e.g. EDS)
multiple_struct_flag = 0;
if numel(input_structure)>1, input_structure = input_structure(struct_no);multiple_struct_flag = 1;end

% make sure fieldname_to_plot is a cell
if ischar(fieldname_to_plot) && ~isempty(fieldname_to_plot), fieldname_to_plot = {fieldname_to_plot}; end

% struct_names = {'entity' 'hazard' 'EDS' 'measures_impact'};

% get all fieldnames
names = fieldnames(input_structure);

%init
lon = []; lat = []; Category = []; ED_at_centroid_control = [];

% find fields that require benefit to plot and replace with ED_at_centroid
% and save benefit information in is_benefit
is_benefit = strcmp(fieldname_to_plot,'benefit');
if any(is_benefit)
    fieldname_to_plot{is_benefit} = 'ED_at_centroid';
end

climada_struct_names = {'measures_impact' 'EDS' 'assets' 'hazard' 'centroids'};
if ~any(strcmp(struct_name,climada_struct_names))
    struct_name = 'unknown struct';
end

scenario_name = '';
% special case if it is a measures_impact
required_names = {'EDS' 'benefit' 'cb_ratio' 'NPV_total_climate_risk'};
if sum(ismember(required_names,names))>=2 
    % extract measures_impact.EDS
    if isfield(input_structure,'EDS')
        if isfield(input_structure,'scenario'),scenario_name = input_structure.scenario.name_simple;end
        input_structure = getfield(input_structure,'EDS');
        names = fieldnames(input_structure);
        struct_name = 'measures_impact';
    else
        fprintf('No EDS found, although you seemed to load a measures_impact.\n')
        return
    end
end
    
    
% special case if it is an EDS
required_names = {'ED' 'annotation_name'};
required_fieldname_to_plot = {'ED_at_centroid'};
if sum(ismember(required_names,names))>=2 
    if isempty(fieldname_to_plot),fieldname_to_plot = required_fieldname_to_plot; end
    % extract longitudes, latitudes
    if isfield(input_structure,'assets')
        if event_no>numel(input_structure), event_no = numel(input_structure); end
        lon = getfield(input_structure(event_no).assets,'lon');
        lat = getfield(input_structure(event_no).assets,'lat');
        if isfield(input_structure(event_no).assets,'Category'), Category = getfield(input_structure(event_no).assets,'Category');end
    else
        fprintf('No assets found, although you seemed to load an EDS.\n')
        return
    end
    if numel(input_structure)>1 % we have more than one EDS
        % get control ED_at_centroid for benefit of a measure
        try, ED_at_centroid_control = input_structure(end).ED_at_centroid; end
        input_structure = input_structure(event_no);
        fprintf('You selected EDS event no %d (%s).\n',event_no, input_structure.annotation_name)
    end
    if ~strcmp(struct_name,'measures_impact'), struct_name = 'EDS'; end
else
    % special case, if it is an entity
    required_names = {'assets' 'damagefunctions' 'measures' 'discount'};
    required_fieldname_to_plot = {'Value'};
    if sum(ismember(required_names,names))>=2 
        % extract entity.assets
        if isempty(fieldname_to_plot),fieldname_to_plot = required_fieldname_to_plot; end
        %if ~strcmp(fieldname_to_plot,required_fieldname_to_plot),fieldname_to_plot = {'assets'};end
        if isfield(input_structure,'assets')
            input_structure = input_structure.assets;
            struct_name = 'assets';
        else
            fprintf('No assets found, although you seemed to load an entity.\n')
            return
        end      
    end
end

% find possible fieldname_to_plot if not given    
if isempty(fieldname_to_plot)
    names = fieldnames(input_structure);
    fieldname_to_plot = {'elevation_m' 'slope_deg' 'TWI' 'intensity' 'Value' 'ED_at_centroid'};
    has_fieldname = ismember(fieldname_to_plot,names);
    if any(has_fieldname)
        % we have found one or more fieldnames to plot
        fieldname_to_plot = fieldname_to_plot(has_fieldname);       
    end
end     

if isempty(fieldname_to_plot), return, end 

if any(strcmp(fieldname_to_plot,'intensity')), struct_name = 'hazard'; end
if any(strcmp(fieldname_to_plot,'elevation_m')), struct_name = 'centroids'; end

% make sure that we have .lon and .lat information
if isempty(lon)
    if ~isfield(input_structure,'lon') || ~isfield(input_structure,'lat')
        fprintf('This struct does not have .lon and .lat fields\n')
        return   
    else
        lon = input_structure.lon;lat = input_structure.lat;
        if isfield(input_structure,'Category'), Category = getfield(input_structure,'Category');end
    end
end
    

% select specific locations (based on categories, or units)
silent_mode = 0;
% if isfield(input_structure,'lon') && isfield(input_structure,'lat') && isfield(input_structure,'Value') && isfield(input_structure,'Category')
% entity.assets = input_structure;
if ~isempty(Category) 
    % create entity for input to climada_assets_select
    entity.assets.lon = lon;
    entity.assets.lat = lat;
    entity.assets.Category = Category;
    is_selected = climada_assets_select(entity,[],[],category_criterium,silent_mode);
else
    is_selected = true(size(lon));
end


% plot input_structure characteristics
% -----------
% parameters
% plot_method = 'contour'; %'plotclr';%
% plot_method = 'plotclr'; 
npoints = 2000; plot_centroids = 0;
interp_method = []; stencil_ext = [];
% caxis_range = '';

% create figures
% fieldnames_to_plot = {'elevation_m' 'slope_deg' 'TWI' 'aspect_deg'};
% title_strings = {'Elevation (m)' 'Slope (deg)' 'Topographical wetness index' 'Aspect (deg)'};
counter = 0;
for f_i = 1:numel(fieldname_to_plot)
    if isfield(input_structure,fieldname_to_plot{f_i})
        
        % get values
        values = full(getfield(input_structure,fieldname_to_plot{f_i}));
        
        % special case where values are in a matrix, and we want to
        % extract only one event
        [values_i, values_j] = size(values);
        if values_j == numel(lon) && values_i>1 % && values_j>1
            %if values_i>numel(lon) 
            if event_no > values_i; event_no = values_i;end % limit to maximum amount of events
            values = values(event_no,:);
        elseif values_i == numel(lon) && values_j>1 
            if event_no > values_j; event_no = values_j;end % limit to maximum amount of events
            values = values(:,event_no);
            %end
        end
        
        % special case for benefit, difference of AED control and AED measure
        if is_benefit(f_i)
            if ~isempty(ED_at_centroid_control)
                values = ED_at_centroid_control - values;
                fieldname_to_plot{f_i} = 'benefit';
            else
                values = '';
            end
        end
            
        if any(values) || ~isempty(values)            
            % select a subset of locations, based on categories
            values(~is_selected) = 0;
            
            if sum(values)>0
                counter = counter+1;
            
                % sum up values at every unique location
                [lon_unique, lat_unique, values_sum]= climada_location_sum(lon, lat, values);

                % special colormap for hazard intensities, benefit, asset Value, damage
                if strcmp(fieldname_to_plot{f_i},'intensity') && isfield(input_structure,'peril_ID')
                    cmap = climada_colormap(input_structure.peril_ID);
                elseif strcmp(fieldname_to_plot{f_i},'benefit')
                    cmap = climada_colormap('benefit');
                elseif strcmp(fieldname_to_plot{f_i},'Value')
                    cmap = climada_colormap('assets');
                elseif strcmp(fieldname_to_plot{f_i},'ED_at_centroid')
                    cmap = climada_colormap('damage');
                else
                    cmap = jet(64);
                end
                %caxis_range = [0 max(values)*0.8]; 
                caxis_range = [0 prctile(values_sum,99.5)];

                %title_str = title_strings{f_i};
                %title_str = strrep(fieldname_to_plot{f_i},'_',' ');
                [~, ~, result_str] = climada_digit_set(sum(values_sum));
                result_str = sprintf('%s %s',climada_global.Value_unit,result_str);
                fieldname_to_plot_str = strrep(fieldname_to_plot{f_i},'_',' ');
                title_str_1 = sprintf('%s (%s)',fieldname_to_plot_str,result_str);
                %title_str = sprintf('%s (%s), event %d',fieldname_to_plot_str,result_str,event_no);
                event_no_name = []; struct_no_name = [];
                if isfield(input_structure,'annotation_name'),event_no_name = strrep(input_structure.annotation_name,'_',' ');end
                %if isfield(input_structure,'scenario'),struct_no_name = input_structure.scenario.name_simple;end
                if isfield(input_structure,'peril_ID'),struct_no_name = sprintf('%s, %s',scenario_name,input_structure.peril_ID);end
                title_str_2 = ''; %init
                switch struct_name
                    case 'measures_impact'
                        title_str_2 = sprintf('\nMeasure %d: %s \n Scenario %d: %s', event_no,event_no_name,struct_no,struct_no_name);
                    case 'EDS'
                        title_str_2 = sprintf('\nEvent %d: %s', event_no,event_no_name);    
                    case 'assets'
                        region = ''; assets_year = '';
                        if isfield(input_structure,'region'),region = input_structure.region;end
                        if isfield(input_structure,'reference_year'),assets_year = input_structure.reference_year;end
                        title_str_2 = sprintf('\nAssets %s %d', region,assets_year);    
                    case 'hazard'
                        units = ''; peril_ID = '';
                        if isfield(input_structure,'units'),units = input_structure.units;end
                        if isfield(input_structure,'peril_ID'),peril_ID = input_structure.peril_ID;end
                        title_str_1 = sprintf('%s (%s %s)',fieldname_to_plot_str, peril_ID, units);
                        if isfield(input_structure,'name'),event_no_name = strrep(input_structure.name{event_no},'_',' ');end
                        title_str_2 = sprintf('\nEvent %d: %s', event_no,event_no_name);   
                    case 'centroids'
                end
                title_str = sprintf('%s %s',title_str_1,title_str_2);
                fig(counter) = climada_color_plot(values_sum,lon_unique,lat_unique,fieldname_to_plot{f_i},...
                                    title_str,plot_method,interp_method,npoints,plot_centroids,caxis_range,cmap,stencil_ext);

                values = []; values_sum = []; % reset      
            end
        end
    end
end






