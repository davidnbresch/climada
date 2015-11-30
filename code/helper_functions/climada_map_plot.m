function [input_structure, fig] = climada_map_plot(input_structure,fieldname_to_plot,plot_method,event_no,struct_no)
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
% OUTPUTS:
%   input_structure:  a climada stucture, i.e. centroids, entity,
%        entity.assets, hazard, EDS
%   fig: handle on the figure with a map displaying the selected field 
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151124, init
% Lea Mueller, muellele@gmail.com, 20151130, enhance to work with measures_impact and plot benefit
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
  
if isempty(plot_method), plot_method = 'plotclr'; end 
if isempty(event_no), event_no = 1; end 
if isempty(struct_no), struct_no = 1; end 

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
lon = []; lat = []; ED_at_centroid_control = [];

% find fields that require benefit to plot and replace with ED_at_centroid
% and save benefit information in is_benefit
is_benefit = strcmp(fieldname_to_plot,'benefit');
fieldname_to_plot{is_benefit} = 'ED_at_centroid';


% special case if it is a measures_impact
required_names = {'EDS' 'benefit' 'cb_ratio' 'NPV_total_climate_risk'};
if sum(ismember(required_names,names))>=2 
    % extract measures_impact.EDS
    if isfield(input_structure,'EDS')
        input_structure = getfield(input_structure,'EDS');
        names = fieldnames(input_structure);
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
    else
        fprintf('No assets found, although you seemed to load an entity.\n')
        return
    end
    if numel(input_structure)>1 % we have more than one EDS
        % get control ED_at_centroid for benefit of a measure
        try, ED_at_centroid_control = input_structure(end).ED_at_centroid; end
        input_structure = input_structure(event_no);
        fprintf('You selected EDS event no %d (%s).\n',event_no, input_structure.annotation_name)
    end
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
        else
            fprintf('No assets found, although you seemed to load an entity.\n')
            return
        end        
    end
end

    
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


% make sure that we have .lon and .lat information
if isempty(lon)
    if ~isfield(input_structure,'lon') || ~isfield(input_structure,'lat')
        fprintf('This struct does not have .lon and .lat fields\n')
        return   
    else
        lon = input_structure.lon;lat = input_structure.lat;
    end
end
    

% plot centroids characteristics
% -----------
% parameters
% plot_method = 'contour'; %'plotclr';%
% plot_method = 'plotclr'; 
npoints = 2000; plot_centroids = 0;
interp_method = []; stencil_ext = [];
caxis_range = '';

% create figures
% fieldnames_to_plot = {'elevation_m' 'slope_deg' 'TWI' 'aspect_deg'};
% title_strings = {'Elevation (m)' 'Slope (deg)' 'Topographical wetness index' 'Aspect (deg)'};
counter = 0;
for f_i = 1:numel(fieldname_to_plot)
    if isfield(input_structure,fieldname_to_plot{f_i})
        values = full(getfield(input_structure,fieldname_to_plot{f_i}));
        
        [values_i, values_j] = size(values);
        if values_i>numel(lon) %values_i>1 && values_j>1
            %if values_i>numel(lon) 
                if event_no > values_i; event_no = values_i;end % limit to maximum amount of events
                values = values(event_no,:);
        elseif values_j>numel(lon) % values_j>1 
                if event_no > values_j; event_no = values_j;end % limit to maximum amount of events
                values = values(:,event_no);
            %end
        end
        
        % special case for benefit
        if is_benefit(f_i)
            if ~isempty(ED_at_centroid_control)
                values = ED_at_centroid_control - values;
                fieldname_to_plot{f_i} = 'benefit';
            else
                values = '';
            end
        end
            
        if any(values) || ~isempty(values)
            counter = counter+1;
            % special colormap for hazard intensities
            if strcmp(fieldname_to_plot{f_i},'intensity') && isfield(input_structure,'peril_ID')
                cmap = climada_colormap(input_structure.peril_ID);
            else
                cmap = jet(64);
            end
            %caxis_range = [0 max(values)*0.8]; 
            caxis_range = [0 prctile(values,99.5)];
            
            %title_str = title_strings{f_i};
            %title_str = strrep(fieldname_to_plot{f_i},'_',' ');
            title_str = sprintf('%s, event %d',strrep(fieldname_to_plot{f_i},'_',' '), event_no);
            event_no_name = []; struct_no_name = [];
            if isfield(input_structure,'annotation_name'),event_no_name = input_structure.annotation_name;end
            if isfield(input_structure,'scenario'),struct_no_name = input_structure.scenario.name_simple;end
            if ~isempty(event_no_name) && ~isempty(struct_no_name)
                title_str = sprintf('%s, \n Measure %d %s, \n struct %d, %s',...
                    strrep(fieldname_to_plot{f_i},'_',' '), event_no,event_no_name,struct_no,struct_no_name);
            end
            if ~isempty(event_no_name) %&& isempty(struct_no_name)
                title_str = sprintf('%s, \n Measure %d %s',...
                    strrep(fieldname_to_plot{f_i},'_',' '), event_no,event_no_name);
            end
            if isempty(event_no_name) && ~isempty(struct_no_name)
                title_str = sprintf('%s, Measure %d, struct %d,%s',...
                    strrep(fieldname_to_plot{f_i},'_',' '), event_no,struct_no,struct_no_name);
            end
            
            %if event_no>=1 && struct_no>=1
            %    title_str = sprintf('%s, event %d, %s, struct %d, %s',...
            %        strrep(fieldname_to_plot{f_i},'_',' '), event_no,event_no_name,struct_no,struct_no_name);
            %end
            %if event_no>=1 && struct_no<=1
            %    title_str = sprintf('%s, event %d',strrep(fieldname_to_plot{f_i},'_',' '), event_no);
            %end
            %if event_no<=1 && struct_no>1
            %    title_str = sprintf('%s, struct %d',strrep(fieldname_to_plot{f_i},'_',' '), struct_no);
            %end
            %if event_no<=1 && struct_no>=1
            %    title_str = sprintf('%s',strrep(fieldname_to_plot{f_i},'_',' '));
            %end
            fig(counter) = climada_color_plot(values,lon,lat,fieldname_to_plot{f_i},...
                                title_str,plot_method,interp_method,npoints,plot_centroids,caxis_range,cmap,stencil_ext);
        end
    end
end






