function climada_hazard2ge(hazard,google_earth_save,schematic_tag)
% climada
% MODULE:
%   core cliamda
% NAME:
%   climada_hazard2ge
% PURPOSE:
%   hazard footprints visualisation in google earth
% CALLING SEQUENCE:
%   climada_hazard2ge(hazard,google_earth_save,schematic_tag)
% EXAMPLE:
%   climada_hazard2ge
% INPUTS:
%   hazard: structure
%       > promted for if not given
%   google_earth_save: the filename of the resulting .kmz google earth file
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   schematic_tag: set to 1 if schematic plot (no colorbar, indicative
%   colorscale). if set to 0, e.g. tc wind color scale is yellow
%   (20-30 m/s), orange (30-40 m/s), dark orange (40-50 m/s), etc...
% OUTPUTS:
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150313, initial
%-

% res=[]; % init output
close all % not really necessary, but speeds things up

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('hazard','var'),hazard ='';end
if ~exist('google_earth_save','var'), google_earth_save = []; end
if ~exist('schematic_tag','var'),schematic_tag  ='';end
if isempty(schematic_tag), schematic_tag = 0; end

% PARAMETERS
% % the scale for plots, such that max_damage=max(entity.assets.Value)*damage_scale
% damage_scale = 1/3; % defaul =1/2

% % the rect to plot (default is are as in hazard.lon/lat, =[], in which case it is automatically determined)
% focus_region=[]; % default=[], [minlon maxlon minlat maxlat]

% % load colormap
% colormap_file=[climada_global.data_dir filesep 'system' filesep 'colormap_gray_blue.mat'];
% if exist(colormap_file,'file'),load(colormap_file);end

% intensity plot parameters
npoints       = 199;
interp_method = 'linear';

% the range (in degree) around the tc_track (to show a bit a wider area in plots)
%dX=1;dY=1; % default=1
dX=0;dY=0; % default=1


%% prompt for hazard if not given
if isempty(hazard) % local GUI
    hazard=climada_hazard_load;
end


%% prompt for google_earth_save file
if isempty(google_earth_save) % local GUI
    google_earth_save = [climada_global.data_dir filesep 'results' filesep 'Select name to save google earth visualiation tc_tracks_counrty.kmz'];
    [filename, pathname] = uiputfile(google_earth_save, 'Save google earth animation of event damage as:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        google_earth_save = fullfile(pathname,filename);
    end
end

[pathstr, name, ext] = fileparts(google_earth_save);
if ~strcmp(ext,'kmz')
    ext = '.kmz';
end
if strcmp(pathstr,'')
    pathstr = [climada_global.data_dir filesep 'results'];
end
google_earth_save = [fullfile(pathstr,name) ext];

% save kmz file
fprintf('saving google earth damage animation as\n %s\n',google_earth_save); 
k = kml(google_earth_save);


%%
% load(animation_data_file);
% 
% if ~isempty(hazard_TS)
%     fprintf('animation data also for TS\n');
%     %hazard=hazard_TS;
% end

c_ax = []; %init
if schematic_tag
    % create schematic colormap (gray red)
    [cmap c_ax]= climada_colormap('schematic');
    %if exist([climada_global.system_dir filesep 'colormap_gray_red.mat'],'file')
        %load([climada_global.system_dir filesep 'colormap_gray_red'])
        %cmap = gray_red;
        %%colormap(cmap)
    %end
else
    % color range for hazard intensity
    [cmap c_ax]= climada_colormap(hazard.peril_ID);
    cmap = brighten(cmap,0.2);
end
if isempty (c_ax)
    c_ax = [0 full(max(max(hazard.intensity)))];
end


intensity_units = [char(hazard.peril_ID) ' intensity'];
if isfield(hazard,'units'),intensity_units = [intensity_units ' [' hazard.units ']'];end

n_steps = hazard.event_count;

% define grid
npoints = abs(npoints); % force positive
xx      = linspace(min(hazard.lon)-dX, max(hazard.lon)+dX, npoints);
yy      = linspace(min(hazard.lat)-dY, max(hazard.lat)+dY, npoints);
[X,Y]   = meshgrid(xx,yy); % construct regular grid

% damage_min_value = full(min(min(hazard.damage(hazard.damage>0))));
% damage_max_value = full(max(max(hazard.damage)))*damage_scale;
% max_damage_str   = sprintf('%g',damage_max_value);
% 
% max_damage_at_centroid=[]; % init

    



%% plot hazard intensity
% -----------
% set intensity color scale
% [cmap c_ax]= climada_colormap('TC');
cmap_ori = cmap;
c_ax_ori = c_ax;
% do show wind speeds/intensities only after reaching a certain level
if c_ax(1)==0
    levels = linspace(c_ax(1), c_ax(2), length(cmap)+1);
    c_ax(1) = levels(2);
    cmap(1,:)=[];
end
delta_t = diff(hazard.datenum(1:2));

  
kk = k.newFolder('Hazard intensity');
for step_i = 1:n_steps   
    % plot hazard intensity
    % ---------------------
    %node_i = hazard.tc_track_node(step_i);   
    values = full(hazard.intensity(step_i,:));
    %%values(values<10) = NaN; % mask low intensities
    %values(values<10) = 0; % mask low intensities, not needed for flood
    %if sum(values(:)>10)>0  
    if sum(values(:)>0)>0 
        gridded_VALUE = griddata(hazard.lon,hazard.lat,values,X,Y,interp_method); % interpolate to grid 'linear'    
        gridded_VALUE(gridded_VALUE<0) = 0;
        kkk = kk.newFolder(datestr(hazard.datenum(step_i),'dd mmm yyyy, HHpm'));
        kkk.contourf(X,Y,gridded_VALUE,...
             'name',hazard.name{step_i}, ... %'description','test',
             'colorMap',cmap, 'lineColor','00FFFFFF', 'transparency',0.5,...
             'caxis',c_ax,...
             'timeSpanBegin',datestr(hazard.datenum(step_i)  ,'yyyy-mm-ddTHH:MM:SSZ'),...
             'timeSpanEnd',datestr(hazard.datenum(step_i)+delta_t,'yyyy-mm-ddTHH:MM:SSZ'));
    end
end

%% open visualition in google earth
k.run  


%% plot assets
% -----------
% values    = hazard.assets.Value;
% min_value = min(values(values>0));
% max_value = max(values);
% pos_indx  = find(values>0); 
% tp        = linspace(0,360,20);

% % set assets color scale
% exp_max   = ceil(log10(max_value));
% exp_min   = floor(log10(min_value));
% no_levels = 15;
% val_categories  = linspace(exp_min,exp_max,no_levels-1);
% colors_ = jet(no_levels);
% transp  = 0.85;
% for i = 1:no_levels
%     colorHex(i,:) = kml.color2kmlHex([colors_(i,:) transp]);
% end
 
% % plot assets
% kk = k.newFolder('Assets');
% res_deg   = max(diff(hazard.assets.lon(1:2)), diff(hazard.assets.lat(1:2)))/2;
% val_log10 = log10(hazard.assets.Value);
% for i = 1:length(val_categories)-1
%     indx = val_log10>= val_categories(i) & val_log10<val_categories(i+1); 
%     %if any(indx)
%     %    kk.point(hazard.assets.lon(indx), hazard.assets.lat(indx), ones(1,sum(indx))*100, ...
%     %         'description','test',...
%     %         'iconURL','http://maps.google.com/mapfiles/kml/shapes/donut.png',...
%     %         'iconScale',0.5,...
%     %         'iconColor',colorHex(i,:));
%     %end
%     pos_indx = find(indx); 
%     for ii =1:length(pos_indx)
%         kk.poly(hazard.assets.lon(pos_indx(ii))+res_deg*sind(tp), hazard.assets.lat(pos_indx(ii))+res_deg*cosd(tp), ...
%            'altitude', 100,... %hazard.assets.Value(i)/max_value*100
%            'altitudeMode','clampToGround', ...
%            'description','asset',...
%            'lineWidth',0,...
%            'polyColor',colorHex(i,:));
%     end
% end

% figure
% climada_plot_entity_assets(entity,centroids) .
% climada_plot_entity_assets(hazard) 


%% plot damage
% % -----------
% % set damage color scale
% % no_levels = 10;
% colors_   = climada_colormap('damage');
% no_levels = length(colors_);
% min_damage_exp = floor(min(log10(nonzeros(hazard.damage))));
% max_damage_exp = ceil(max(log10(nonzeros(hazard.damage))));
% val_categories  = linspace(min_damage_exp,max_damage_exp,no_levels-1);
% transp  = 0.5;
% for i = 1:no_levels
%     colorHex(i,:) = kml.color2kmlHex([colors_(i,:) transp]);
% end
% 
% kk = k.newFolder('Damage');
% % plot damage
% for step_i = 1:n_steps   
%     node_i = hazard.tc_track_node(step_i);
%     kkk = kk.newFolder(datestr(hazard.tc_track.datenum(node_i),'dd mmm yyyy HHpm'));
%     
%     if isempty(max_damage_at_centroid)
%         max_damage_at_centroid = full(hazard.damage(step_i,:));
%     else
%         max_damage_at_centroid = max(max_damage_at_centroid,full(hazard.damage(step_i,:)));
%     end
%     values = max_damage_at_centroid;
%     values = values(hazard.assets.centroid_index);
%     %pos_indx = find(values);
%     
%     val_log10 = log10(values);
%     %val_log10(isinf(val_log10)) = 0;
%     %val_log10(isnan(val_log10)) = 0;
%     for i = 1:length(val_categories)-1
%         pos_indx = find(val_log10>= val_categories(i) & val_log10< val_categories(i+1)); 
%         %fprintf('step %d: %d damaged assets\n',i,numel(pos_indx));
%         for ii =1:length(pos_indx)
%             kkk.poly(hazard.assets.lon(pos_indx(ii))+res_deg*sind(tp), hazard.assets.lat(pos_indx(ii))+res_deg*cosd(tp), ...
%                 'altitude', 100,... %hazard.assets.Value(i)/max_value*100
%                 'altitudeMode','clampToGround', ...
%                 'description','Damage',...
%                 'lineWidth',0,...
%                 'polyColor',colorHex(i,:),...
%                 'timeSpanBegin',datestr(hazard.tc_track.datenum(node_i),'yyyy-mm-ddTHH:MM:SSZ'),...
%                 'timeSpanEnd',  datestr(hazard.tc_track.datenum(end)+5,'yyyy-mm-ddTHH:MM:SSZ'));
%         end
%     end
% end

%% visualize track lines and nodes
% % colors according to saffir-simpson scale
% v_categories = [34 64 83 96 113 135 1000];
% colors_      = [ 'ffffaa00' ; %blue
%                  'ff00aa55' ; %green
%                  'ff00ffff' ; %yellow
%                  'ff00aaff' ; %dark yellow  
%                  'ff0055ff' ; %orange  
%                  'ff0000ff' ; %red
%                  'ff000079' ; %dark red
%                 ];
% kk = k.newFolder('Track');
% description_str = sprintf('%s, %s - %s', hazard.tc_track.name, ...
%                     datestr(hazard.tc_track.datenum(1),'dd mmm yyyy'), ...
%                     datestr(hazard.tc_track.datenum(end),'dd mmm yyyy'));
% for node_i = 1:length(hazard.tc_track.lon)
%     v       = hazard.tc_track.MaxSustainedWind(node_i);
%     v_color = find (v < v_categories);
%     v_color = v_color(1);
% 
%     if node_i<length(hazard.tc_track.lon)
%         kk.plot(hazard.tc_track.lon(node_i:node_i+1), hazard.tc_track.lat(node_i:node_i+1),...
%              'name',hazard.tc_track.name, 'description',description_str,...
%              'lineColor',colors_(v_color,:),...
%              'timeSpanBegin',datestr(hazard.tc_track.datenum(node_i),'yyyy-mm-ddTHH:MM:SSZ'),...
%              'timeSpanEnd' ,datestr(hazard.tc_track.datenum(end)+6/24,'yyyy-mm-ddTHH:MM:SSZ'));
%     end
% 
%     %kk.point(hazard.tc_track.lon(node_i), hazard.tc_track.lat(node_i),100,...
%     %     'description',description_str,...
%     %     'iconURL','http://maps.google.com/mapfiles/kml/shapes/donut.png',...
%     %     'iconScale',0.5,...
%     %     'iconColor',colors_(v_color,:),...
%     %     'timeSpanBegin',datestr(hazard.tc_track.datenum(node_i),'yyyy-mm-ddTHH:MM:SSZ'),...
%     %     'timeSpanEnd' ,datestr(hazard.tc_track.datenum(end)+6/24,'yyyy-mm-ddTHH:MM:SSZ')); 
% end    

%% open visualition in google earth
% k.run    
    



    
    
    

