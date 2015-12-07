function varargout = climada_viewer(varargin)
% climada_viewer MATLAB code for climada_viewer.fig
%      climada_viewer, by itself, creates a new climada_viewer or raises the existing
%      singleton*.
%
%      H = climada_viewer returns the handle to a new climada_viewer or the handle to
%      the existing singleton*.
%
%      climada_viewer('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in climada_viewer.M with the given input arguments.
%
%      climada_viewer('Property','Value',...) creates a new climada_viewer or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before climada_viewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to climada_viewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% MODULE:
%   viewer
% NAME:
%   climada_viewer
% PURPOSE:
%   plots entities, assets and damage
% CALLING SEQUENCE:
%   climada_viewer
%EXAMPLE
%   climada_viewer
% INPUT:
%   (all inputs are asked for by the GUI)
%   entity: an entity structure, see e.g. climada_entity_load and climada_entity_read
%   measures_impact: a measures_impact structure, e.g. produced by salvador_calc_measures
%   type: must be specified from 'assets','benefits' and 'damage'
%   unit: must be specified from 'USD' or 'people'
%   timestamp: can be specified from
%                  1- current state
%                  2- economic growth
%                  3- moderate climate change
%                  4- extreme climate change
%                    (default is 1)
%  index_measures:  can be selected from a certain measure (see measure list in the measures_impactfile), default =1;
%  categories:      Select a certain category from the list
%
%
% OUTPUTS:
%   Graphical result
% OPTIONAL OUTPUTS:
%   A .mat file with the current selection
%   An excel with the curretn selection
%   A .kmz file with the current selection

% MODIFICATION HISTORY:
% Jacob Anz, j.anz@gmx.net, 20151106 init
%-

% Last Modified by GUIDE v2.5 03-Dec-2015 15:30:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
'gui_Singleton',  gui_Singleton, ...
'gui_OpeningFcn', @climada_viewer_OpeningFcn, ... 
'gui_OutputFcn',  @climada_viewer_OutputFcn, ...
'gui_LayoutFcn',  [] , ...
'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% gui varibale initialization
function climada_viewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to climada_viewer (see VARARGIN)

% Choose default command line output for climada_viewer
handles.output = hObject;

%climada picture
climada_logo(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

% put a nice name
set(handles.figure1,'Name','climada results viewer');

global container
global climada_global

%set all initial paramters
init_str = 'Load a measures_impact file';
set(handles.popupmenu5,'String',init_str); %scenarios
set(handles.listbox1,'String',init_str); %measures
set(handles.listbox4,'String',init_str); %perils
set(handles.listbox2,'String',init_str); %categories

set(handles.radiobutton2,'Value',0); %assets
set(handles.radiobutton1,'Value',1); %damage
set(handles.radiobutton3,'Value',0); %benefit

axes(handles.axes1);
cla(handles.axes1,'reset'); 
text(0.5, 0.5, {'Welcome to the climada results viewer:'; 'Please load a measures impact file (top right).'},...
    'fontsize',12,'horizontalalignment','center');


% get selected scenario
function is_scenario = get_scenario(hObject, eventdata, handles)
global container
% global climada_global 
if ~isempty(container.measures_impact)
    for i = 1:numel(container.measures_impact)
        scenario_list_lon{i} = container.measures_impact(i).scenario.name_simple;
    end
    scenario_list = get(handles.popupmenu5,'string');% scenario
    scenario_selected = scenario_list(get(handles.popupmenu5,'Value'));
    is_scenario = strcmp(scenario_selected,scenario_list_lon);   
else
    pushbutton1_Callback(hObject, eventdata, handles)
end

% get selected peril within scenario
function is_peril = get_peril(hObject, eventdata, handles)
global container
% global climada_global 
if ~isempty(container.measures_impact)
    % get selected scenarios
    is_scenario = get_scenario(hObject, eventdata, handles);
    peril_list_long = '';
    if ~isempty(container.measures_impact)
        peril_list_long = {container.measures_impact.peril_ID};
    end

    %peril_list = set_peril_list(hObject, eventdata, handles);
    peril_list = get(handles.listbox4,'string');% scenario
    peril_selected = peril_list(get(handles.listbox4,'Value'));
    if any(ismember(peril_selected,'All perils'));
        set(handles.listbox4,'Value',1);% set to 'All perils'
        peril_selected = peril_list(2:end);
    end
    is_peril = ismember(peril_list_long,peril_selected);   
    is_peril = is_peril.*is_scenario;
else
    pushbutton1_Callback(hObject, eventdata, handles)
end



% set popupmenu5: SCENARIOS
function [scenario_list is_selected]= set_scenario_list(hObject, eventdata, handles)
global container
% global climada_global 
if ~isempty(container.measures_impact)
    scenario_list = '';
    for i = 1:numel(container.measures_impact)
        scenario_list{i} = container.measures_impact(i).scenario.name_simple;
    end
    scenario_list = unique(scenario_list);
    set(handles.popupmenu5,'String',scenario_list);    
else
    pushbutton1_Callback(hObject, eventdata, handles)
end

% set listbox4: PERILS
function peril_list = set_peril_list(hObject, eventdata, handles)
global container
% global climada_global 
if ~isempty(container.measures_impact)
    is_scenario = get_scenario(hObject, eventdata, handles);
    peril_list = '';
    if ~isempty(container.measures_impact)
        peril_list = {container.measures_impact(is_scenario).peril_ID};
    end
    peril_list = {'All perils' peril_list{:}};
    set(handles.listbox4,'String',peril_list);
else
    pushbutton1_Callback(hObject, eventdata, handles)
end

% set listbox2: CATEGORIES
function category_list = set_category_list(hObject, eventdata, handles)
global container
% global climada_global 
category_list = '';
if ~isempty(container.measures_impact)
    if isfield(container.measures_impact(1).EDS(1).assets,'Category_name')
        category_list = container.measures_impact(1).EDS(1).assets.Category_name;
    else
        assets = climada_assets_category_ID(container.measures_impact(1).EDS(1).assets);
        container.measures_impact(1).EDS(1).assets = assets;
    end
    %entity_temp.assets.lon = container.measures_impact(1).EDS(1).assets.lon;
    %entity_temp.assets.lat = container.measures_impact(1).EDS(1).assets.lat;
    %entity_temp.assets.Category = container.measures_impact(1).EDS(1).assets.Category;
    %peril_criterum = ''; unit_criterium = ''; category_criterium = ''; silent_mode = 1;
    %[is_selected,peril_criterum,unit_criterium,category_list] = ...
    %    climada_assets_select(entity_temp,peril_criterum,unit_criterium,category_criterium,silent_mode);
else
    pushbutton1_Callback(hObject, eventdata, handles)
end
category_list = {'All categories' category_list{:}};
set(handles.listbox2,'Max',length(category_list));
set(handles.listbox2,'String',category_list);

% set listbox1: MEASURES
function measure_list = set_measure_list(hObject, eventdata, handles)
global container
% global climada_global 
if ~isempty(container.measures_impact)
    is_peril = get_peril(hObject, eventdata, handles);
    selection_index = find(is_peril);
   
    counter = 0; measure_list = '';
    for i = 1:numel(selection_index)
        for m_i = 1:numel(container.measures_impact(selection_index(i)).measures.name)
            counter = counter+1;
            measure_list{counter} = container.measures_impact(selection_index(i)).measures.name{m_i};
        end
    end
    measure_list = unique(measure_list,'stable');
    measure_list{end+1} = 'no measure';
    set(handles.listbox1,'String',measure_list);
    %set(handles.listbox1,'Value',numel(measure_list));
else
    pushbutton1_Callback(hObject, eventdata, handles)
end


function climada_logo(hObject, eventdata, handles)
global climada_global
set(handles.axes2,'visible','off')
try
    logo_file= [climada_global.root_dir filesep 'docs' filesep 'climada_logo.png'];
    axes(handles.axes2)
    hold on;
    imagesc(imread(logo_file));
    set(handles.axes2,'YDir','reverse');
    set(handles.axes2,'color','none')
    %uistack(handles.axes2,'bottom');
catch
    set(handles.axes2,'color','none')
end

% --- Outputs from this function are returned to the command line.
function varargout = climada_viewer_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- PERIL LISTBOX-------------------
% --- Executes on selection change in listbox4.
function listbox4_Callback(hObject, eventdata, handles)
% hObject    handle to listbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox4
pushbutton2_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function listbox4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- MEASURES LISTBOX-------------------
% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1
pushbutton2_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
set(hObject,'BackgroundColor','white');
end


% --- CATEGORIES LISTBOX-------------------
% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2
pushbutton2_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- VALUES TO PLOT: Annual expected damage----
% --- Executes on selection change in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.radiobutton1,'Value',1);% damage
set(handles.radiobutton2,'Value',0)
set(handles.radiobutton3,'Value',0)
pushbutton2_Callback(hObject, eventdata, handles)


% --- VALUES TO PLOT: Asset values----
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.radiobutton2,'Value',1);
set(handles.radiobutton1,'Value',0)
set(handles.radiobutton3,'Value',0)
pushbutton2_Callback(hObject, eventdata, handles)

% --- VALUES TO PLOT: Benefit----
function radiobutton3_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.radiobutton3,'Value',1);
set(handles.radiobutton2,'Value',0)
set(handles.radiobutton1,'Value',0)
pushbutton2_Callback(hObject, eventdata, handles)



% USD - NOT USED FOR NOW
function radiobutton4_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
set(hObject,'BackgroundColor','white');
end

% People - NOT USED FOR NOW
function radiobutton5_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% -------LOAD MEASURES IMPACT FILE---------------
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% prompt for file if not given
global container

%load measures impact file
container.measures_impact = climada_measures_impact_load('',1);

set_scenario_list(hObject, eventdata, handles);
set_peril_list(hObject, eventdata, handles);
set_category_list(hObject, eventdata, handles);
set_measure_list(hObject, eventdata, handles);
measure_list = get(handles.listbox1,'String');
set(handles.listbox1,'Value',numel(measure_list));



% --------------------------
% -----PLOT-----------------
% --------------------------
% plotting -> Main part
function pushbutton2_Callback(hObject, eventdata, handles)
    % hObject    handle to pushbutton2 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    global container
    global climada_global
    
    %get the listbox selections
    scenario_list = get(handles.popupmenu5,'string');% scenario
    scenario_selected = scenario_list(get(handles.popupmenu5,'Value'));
    
    set_measure_list(hObject, eventdata, handles);
    %is_selected = get_scenario(hObject, eventdata, handles);
    %is_peril = get_peril(hObject, eventdata, handles);
    
    %PERIL
    peril_list = get(handles.listbox4,'string');% peril
    peril_selected = peril_list(get(handles.listbox4,'Value'));
    if any(ismember(peril_selected,'All perils'));
        set(handles.listbox4,'Value',1);% set to 'All perils'
        peril_selected = peril_list(2:end);
    end
    
    %CATEGORY
    category_list = get(handles.listbox2,'String');% category
    category_selected = category_list(get(handles.listbox2,'Value'));
    if any(ismember(category_selected,'All categories'));
        set(handles.listbox2,'Value',1);% set to 'All categories'
        category_selected = '';
    end
    
    %MEASURE
    measure_list = get(handles.listbox1,'String');% measure
    measure_selected = measure_list(get(handles.listbox1,'Value'));
        
    % markersize from radiobuttons2,1,3
    markersize = str2double(get(handles.edit5,'String'));
    if isnan(markersize) 
        markersize = 5;
        set(handles.edit5,'String',markersize);
    end
    climada_global.markersize = markersize;
    
    % FIELDNAME_TO_PLOT from radiobuttons2,1,3
    if get(handles.radiobutton2,'Value');% assets
        fieldname_to_plot = 'Value';
        set(handles.radiobutton1,'Value',0);% damage
        set(handles.radiobutton3,'Value',0);% benefit
        
    elseif get(handles.radiobutton1,'Value');% damage
        fieldname_to_plot = 'ED_at_centroid';
        set(handles.radiobutton2,'Value',0);
        set(handles.radiobutton3,'Value',0);
        
    elseif get(handles.radiobutton3,'Value');% benefit
        fieldname_to_plot = 'benefit';
        set(handles.radiobutton1,'Value',0);
        set(handles.radiobutton2,'Value',0);
    end

    
    fprintf('\n\nScenario selected: %s\n', scenario_selected{1});
    fprintf('Peril selected: %s\n', peril_selected{1});
    if isempty(category_selected)
        fprintf('Category selected: %s\n', category_selected)
    else
        fprintf('Category selected: %s\n', category_selected{1});
    end
    fprintf('Value to plot: %s\n', fieldname_to_plot);
    
    
    % combine for selected perils
    silent_mode = 1;
    measures_impact_perils = climada_measures_impact_combine_scenario(container.measures_impact,'','',peril_selected,silent_mode);
    
    % SCENARIO
    % get all scenario
    for i = 1:numel(measures_impact_perils)
        scenario_list{i} = measures_impact_perils(i).scenario.name_simple;
    end
    is_selected = strcmp(scenario_list,scenario_selected);
    
    axes(handles.axes1);
    cla;
    
    if sum(is_selected)==1
        measures_impact_selected = measures_impact_perils(is_selected);
        
        % get the measures
        measures_list = {measures_impact_selected.EDS.annotation_name};
        is_measure = find(strcmp(measure_selected,measures_list));
        if strcmp(measure_selected,'no measure'), is_measure = numel(measures_list); end

        % special case for assets plot
        if strcmp(fieldname_to_plot,'Value')
            % create fake entity
            clear entity
            entity.assets = measures_impact_selected.EDS(is_measure).assets; entity.damagefunctions = ''; entity.measures = '';
            Value_unit = climada_global.Value_unit; 
            if isfield(measures_impact_perils,'Value_unit'), Value_unit = measures_impact_selected.Value_unit; end
            climada_global.Value_unit = Value_unit;
            measures_impact_selected = entity; is_measure = 1;
        end
        plot_method = 'plotclr';
        climada_map_plot(measures_impact_selected,fieldname_to_plot,plot_method,is_measure,category_selected);
    else
        text(0.5, 0.5, {'No data to plot'; 'please check your selection (hint: no measure does not produce benefit'},...
            'fontsize',12,'horizontalalignment','center');
    end
    


% dropdown menu select scenario
function popupmenu5_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu5
pushbutton2_Callback(hObject, eventdata, handles)

%create the entries from hazard and entity
%recognizer


% load shape files
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% global container climada_global
% open_path=[climada_global.data_dir filesep 'results'];
% [filename, pathname] = uigetfile({'*.mat'}, 'Select shape file:',open_path);
% filename_tot = fullfile(pathname,filename);
% container.shapes=open(filename_tot);

% --- Executes during object creation, after setting all properties.
function text1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function text2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function text3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% plot river
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% plot roads
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
set(hObject,'BackgroundColor','white');
end

function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
set(hObject,'BackgroundColor','white');
end

function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double

% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
set(hObject,'BackgroundColor','white');
end

function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double

% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
set(hObject,'BackgroundColor','white');
end


function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in checkbox3.
function checkbox3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox3


function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% % --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1

% --- Executes during object creation, after setting all properties.
function radiobutton9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiobutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

function popupmenu4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
set(hObject,'BackgroundColor','white');
end 

% --- Executes during object creation, after setting all properties.
function popupmenu5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
