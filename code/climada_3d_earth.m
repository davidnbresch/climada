function climada_3d_earth(entity,plot_options)
% climada mapping
% NAME:
%	climada_3d_earth
% PURPOSE:
%	plot information on 3D globe (fancy)
%   some code bits are copied from earthmap.m
%
% CALLING SEQUENCE:
%	climada_3d_earth(entity,plot_options);
% EXAMPLE:
%   climada_3d_earth(climada_entity_load('demo_today'));
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   entity: an entity, prompted for if empty
%   plot_options: plot parameters
%       .cylinder_radius (in units of the earth's radius)
%       .cylinder_length
%       .cylinder_color: a MATLAB color, like 'r', 'g' or 'b'
% OUTPUTS:
%	graphics
% MODIFICATION HISTORY:
% David N. Bresch, david_bresch@gmail.com, 20021005 (catXos)
% David N. Bresch, david_bresch@gmail.com, 20200626, revamped for climada
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% PARAMETERS
%
% the file with the earth elevation data and the colormap
map_data=''; % map_data='climada_topo.mat';
map_image=[climada_global.system_dir filesep 'earth_-90_-90_270_90_.jpg'];
%
% define the cylinders radius, max length (in units of earth's radius) and color
cylinder_radius=0.005;
cylinder_length=0.5;
cylinder_color='y';
title_str='3D earth';

if ~exist('entity','var'),entity=[];end
if ~exist('plot_options','var')
    plot_options.cylinder_radius=cylinder_radius;
    plot_options.cylinder_length=cylinder_length;
    plot_options.cylinder_color=cylinder_color;
else
    if not(isfield(plot_options,'cylinder_radius')),plot_options.cylinder_radius=cylinder_radius;end
    if not(isfield(plot_options,'cylinder_length')),plot_options.cylinder_length=cylinder_length;end
    if not(isfield(plot_options,'cylinder_color')),plot_options.cylinder_color=cylinder_color;end
end

if isempty(entity) % ask for it
    fprintf('Select imported/encoded portfolio (Cancel to skip)\n');
    [filename, pathname] = uigetfile('*.mat', 'Select imported/encoded portfolio (Cancel to skip)');
    if isequal(filename,0) || isequal(pathname,0)
        return % cancel pressed
    else
        load([pathname filesep filename],'entity'); % loads entity
    end
end

pos_nonzero=find(entity.assets.Value~=0); % find non-empty asset records
if ~isempty(pos_nonzero)
    lon=   entity.assets.lon(pos_nonzero); % might speed up
    lat=   entity.assets.lat(pos_nonzero);
    values=entity.assets.Value(pos_nonzero);
else
    msgbox('no values >0 - nothing to be shown','CLIMADA special visualisation','warn');
    return
end

tic; % start timer

% set up the earth's sphere
% -------------------------
if exist(map_data,'file')
    load(map_data,'topo','topomap1');
else
    % try built-in MATLAB topography
    load topo
end

if exist(map_image,'file') % load high-res image
    %[high_res_image,high_res_cmap] = imread(map_image);
    high_res_image = imread(map_image);
    ix=size(high_res_image,1):-1:1; % flip North-South
    iy=1:size(high_res_image,2);shiftsize=size(high_res_image,2)/4;iy=[iy(shiftsize:end) iy(1:shiftsize-1)]; % adjust zero longitude
    topo=high_res_image(ix,iy,:);
    f.fig = figure('Tag',title_str,'Color',[1 1 1]); % no colormap, since truecolor RGB image
else
    f.fig = figure('Tag',title_str,'colormap',topomap1,'Color',[1 1 1]); % low-res, with colormap
end

% determine shading method
ButtonName=questdlg('Select the rendering method', ...
    'CLIMADA fly-through', ...
    'none (fast)','gouraud (light effects)','phong (perfect light effects, slow)','none (fast)');
switch ButtonName
    case 'none (fast)'
        FaceLighting='none';
        ValueFaceLighting='gouraud';
    case 'gouraud (light effects)'
        FaceLighting='gouraud';
        ValueFaceLighting='gouraud';
    case 'phong (perfect light effects, slow)'
        FaceLighting='phong';
        ValueFaceLighting='phong';
    otherwise
        FaceLighting='none';
end % switch ButtonName

[x,y,z] = sphere(100);

hg.axes2.Xtick = [0 60 120 180 240 300 360];
hg.axes2.DataAspectRatio = [1 1 1];
hg.axes2.PlotBoxAspectRatioMode = 'auto';
hg.axes2.Ytick = [-90 -60 -30 0 30 60 90];
hg.axes2.Xlim = [0 360];
hg.axes2.Ylim = [-90 90];
hg.axes2.box = 'on';
hg.axes2.NextPlot = 'add';

hg.axes3.DataAspectRatio = [1 1 1];
hg.axes3.PlotBoxAspectRatioMode = 'auto';

f.ax(3) = axes('Tag','3D','Visible','off', hg.axes3);

mat.dull.AmbientStrength = 0.1;
mat.dull.DiffuseStrength = 1;
mat.dull.SpecularColorReflectance = .5;
mat.dull.SpecularExponent = 20;
mat.dull.SpecularStrength = 1;

f.surf = surface(x,y,z, ...
    mat.dull, ...
    'FaceColor','texture',...
    'EdgeColor','none',...
    'FaceLighting',FaceLighting,... % 'phong' is slower than 'gouraud'
    'Cdata',topo,...
    'FaceAlpha',1,... % 0.5 makes the sphere transparent
    'Parent',f.ax(3));

% add light to scenery
% --------------------
f.lite(1) = light('position',[-1 0 1]);
f.lite(2) = light('position',[-1.5 0.5 -0.5], 'color', [.6 .2 .2]);

clear topo % free memory

if ~isempty(values)
    
    % add portfolio values
    % --------------------
    
    minval=0; % not minval=min(values)
    maxval=max(values);
    
    normalized_values=abs((values-minval)/(maxval-minval)*plot_options.cylinder_length); % normalize
    
    % make a tiny cylinder
    [cyl_x,cyl_y,cyl_z]=cylinder(plot_options.cylinder_radius,24);
    
    for point_i=1:length(lat)
        
        temp_cyl_z=(1+normalized_values(point_i))*cyl_z; % stretch
        
        % add the cylinder to the plot
        f.surf2 = surface(cyl_x,cyl_y,temp_cyl_z, ...
            mat.dull, ...
            'EdgeColor','none',...
            'FaceColor',plot_options.cylinder_color,...
            'FaceLighting',ValueFaceLighting,... % 'phong' is slower than 'gouraud'
            'Parent',f.ax(3));
        
        % next two lines rotate cylinder
        rotate(f.surf2,[1 0 0],90-lat(point_i),[0 0 0]); % rotate for latitude
        rotate(f.surf2,[0 0 1],lon(point_i)-90,[0 0 0]); % rotate for longitude
        
    end % loop over points
    
end % we show values

% define default view
% -------------------
%view(3); % MATLAB default view
%view(0,0); % to check that 0,0 is 0N, 90E
view(mean(lon)-90,mean(lat)-30); % start with central point of portfolio, a bit from south for better view

fprintf('3D rendering took %f seconds\n',toc);
fprintf('--> work with the mouse in the figure to move around and zoom (real flight mode disabled, see code)\n');

% if strcmp(questdlg('Would you like to use the 3D explorer to fly through the portfolio?','CLIMADA 3D explorer','Yes','No','No'),'Yes')
%     msgtxt{1}='CLIMADA 3D explorer commands:';
%     msgtxt{2}='';
%     msgtxt{3}='the arrow keys will allow you to steer upwards, down, left, and right';
%     msgtxt{4}='';
%     msgtxt{5}='f  - fly forward towards the earth';
%     msgtxt{6}='b  - fly backward away from the earth';
%     msgtxt{7}='l  - tilt view to the left';
%     msgtxt{8}='r  - tilt view to the right';
%     msgtxt{9}='a  - decrease your zooming step (for the "f" and "b" keys)';
%     msgtxt{10}='s  - increase your zooming step (for the "f" and "b" keys)';
%     msgtxt{11}='z  - decrease your angular step (for the arrow, "r", and "l" keys)';
%     msgtxt{12}='x  - increase your angular step (for the arrow, "r", and "l" keys)';
%     msgtxt{13}='';
%     msgtxt{14}='ESC - quit 3D explorer';
%     msgtxt{15}='';
%     msgtxt{16}='Enjoy the ride through the portfolio!';
%     uiwait(msgbox(msgtxt,'CLIMADA 3d explorer - manual'));
%     for line_i=1:length(msgtxt)
%         fprintf('%s\n',msgtxt{line_i});
%     end
%     %climada_explore3d(gca); % activate 3D explorer
% end

return
