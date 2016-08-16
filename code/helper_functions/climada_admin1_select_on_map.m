function listbox = climada_admin1_select_on_map(admin0_name,admin0_shapes,admin1_shapes)
% climada select admin1 on a map
% MODULE:
%   climada/code/helper_functions
% NAME:
%   climada_admin1_select_on_map
% PURPOSE:
%   Select admin1 or a multiple admin1 on a map for a given admin0_name
% CALLING SEQUENCE:
%   listbox = climada_admin1_select_on_map(admin0_name)
% EXAMPLE:
%   listbox = climada_admin1_select_on_map;
%   listbox = climada_admin1_select_on_map('Vietnam');
%   admin1_name = get(listbox,'UserData'); % use to identify the selected admin1_name
% INPUTS:
%   admin0_name: admin0_name, e.g. 'Switzerland', 'Vietnam', prompted for
%       if empty
% OPTIONAL INPUT PARAMETERS:
%   none
% OUTPUTS:
%   listbox: a listbox handle, from where we can identify the selected
%   admin1_name using
%   admin1_name = get(listbox,'UserData')
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20160224, init
% Lea Mueller, muellele@gmail.com, 20160229, move to climada/helper_functions, rename to climada_admin1_select_on_map
% Lea Mueller, muellele@gmail.com, 20160426, loop over single segments of polygons divided by nan
% Lea Mueller, muellele@gmail.com, 20160601, horizontal alignment of text in center
%-

listbox = []; %init

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('admin0_name','var'),admin0_name=[];end
if ~exist('admin0_shapes','var'),admin0_shapes=[];end
if ~exist('admin1_shapes','var'),admin1_shapes=[];end

% locate the module's data
module_data_dir = [fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];
module_data_dir = [climada_global.modules_dir filesep 'country_risk' filesep 'data'];

% admin0 and admin1 shap files (in climada module country_risk):
if isempty(admin0_shapes)
    admin0_shape_file = climada_global.map_border_file; % as we use the admin0 as in next line as default anyway
    if ~exist(admin0_shape_file,'file')
        fprintf('Admin0 file not found. Please check.\n \t%s\n', admin0_shape_file);
        return
    end 
    % read admin0 (country) shape file (we need this in any case)
    admin0_shapes = climada_shaperead(admin0_shape_file);
end

if isempty(admin1_shapes)
    admin1_shape_file = [module_data_dir filesep 'ne_10m_admin_1_states_provinces' filesep 'ne_10m_admin_1_states_provinces.shp'];
    if ~exist(admin1_shape_file,'file')
        fprintf('Admin1 file not found. Please check.\n \t%s\n', admin1_shape_file);
        return
    end
    admin1_shapes = climada_shaperead(admin1_shape_file); % read admin1 shape file
end

% we ask for admin0
if isempty(admin0_name); [admin0_name,admin0_code] = climada_ask_country_name('single'); end % 'multiple not allowed'

% check admin0_name
[admin0_name,admin0_code] = climada_country_name(admin0_name);

% find the country in the shape file
list_admin0_name = {admin0_shapes.NAME};
is_selected_admin0 = strcmp(list_admin0_name,admin0_name);

% find the shapes that belong to the selected admin0_name
list_admin0_adm_a3 = {admin0_shapes.ADM0_A3};
list_admin1_adm_a3 = {admin1_shapes.adm0_a3};
adm0_a3_name = admin0_shapes(is_selected_admin0).ADM0_A3;
is_selected_admin1 = find(strcmp(list_admin1_adm_a3,adm0_a3_name)); %admin1_shape_i

% compile list of admin1 names
list_admin1_name = {admin1_shapes(is_selected_admin1).name}; %admin1_name_list
list_admin1_code = {admin1_shapes(is_selected_admin1).adm1_code}; 
list_admin1_code = strcat(list_admin1_name,{' | '},list_admin1_code); %admin1_name_code_list
% show list dialog to select admin1 (now easy as names shown on plot)
[liststr,sort_index] = sort(list_admin1_code); 
liststr = {'All admin1' liststr{:}};
sort_index = [0 sort_index];

f = climada_figuresize(0.6,0.8); set(f,'Name','Select admin1 on map');
set(gca,'position',[0.4 0.11 0.5 0.815]);
% plot admin0 (country) shape
plot(admin0_shapes(is_selected_admin0).X,admin0_shapes(is_selected_admin0).Y,'-r','LineWidth',2);
hold on; axis equal
title(admin0_shapes(is_selected_admin0).NAME)

for admin1_i = 1:length(is_selected_admin1)
    plot(admin1_shapes(is_selected_admin1(admin1_i)).X,admin1_shapes(is_selected_admin1(admin1_i)).Y,'-r','LineWidth',1);
    text(admin1_shapes(is_selected_admin1(admin1_i)).longitude,admin1_shapes(is_selected_admin1(admin1_i)).latitude,...
         admin1_shapes(is_selected_admin1(admin1_i)).name,'Horizontalalignment','center');     
end
   
% Create listbox menu
listbox = uicontrol('Style','listbox','userdata',[],...
       'Position', [20 60 200 500],'units','normalized',...
       'String',liststr,'Min',1,'Max',50,'Callback',@setmap);    

% Add a text uicontrol to label the listbox
txt = uicontrol('Style','text',...
    'Position',[20 570 120 20],...
    'String','Admin1 list','fontsize',12);

% Make figure visble after adding all components
set(f,'Visible','on');% For R2014a and earlier:
%f.Visible = 'on';
g = [];

% admin1_name = get(listbox,'UserData');
% value_ = get(listbox,'Value');


function admin1_name = setmap(source,callbackdata)
    val = get(source,'Value'); % For R2014a and earlier
    val = sort_index(val);
    % maps = get(source,'String'); 
    % val = source.Value; maps = source.String;
    if val == 0, val = sort_index(2:end); end
    delete(g); g = []; counter = 0; %reinit
    for val_i = 1:numel(val)
        X = admin1_shapes(is_selected_admin1(val(val_i))).X; 
        Y = admin1_shapes(is_selected_admin1(val(val_i))).Y;
        %X(isnan(X)) = []; Y(isnan(Y)) = [];
        %g(val_i) = fill(X,Y,'-b','LineWidth',1);
        
        nan_position = find(isnan(X));
        if ~isempty(nan_position)
           nan_position = [0 nan_position];
        else
           nan_position = [0 numel(X)+1];
        end
        
        % create indx for area
        % loop over different segments, divided by nans
        for pos_i = 1:numel(nan_position)-1
            counter = counter+1;
            g(counter) = fill(X(nan_position(pos_i)+1:nan_position(pos_i+1)-1),Y(nan_position(pos_i)+1:nan_position(pos_i+1)-1),...
               '-b','LineWidth',1);
        end   
    end
    %h = plot(admin1_shapes(is_selected_admin1(val)).X,admin1_shapes(is_selected_admin1(val)).Y,'-b','LineWidth',2);    
    admin1_name = list_admin1_name(val);
    set(source,'UserData' ,admin1_name)
end


end