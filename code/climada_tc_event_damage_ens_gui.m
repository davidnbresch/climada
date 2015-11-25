function varargout = climada_tc_event_damage_ens_gui(varargin)
% CLIMADA_TC_EVENT_DAMAGE_ENS_GUI MATLAB code for climada_tc_event_damage_ens_gui.fig
%      CLIMADA_TC_EVENT_DAMAGE_ENS_GUI, by itself, creates a new CLIMADA_TC_EVENT_DAMAGE_ENS_GUI or raises the existing
%      singleton*.
%
%      H = CLIMADA_TC_EVENT_DAMAGE_ENS_GUI returns the handle to a new CLIMADA_TC_EVENT_DAMAGE_ENS_GUI or the handle to
%      the existing singleton*.
%
%      CLIMADA_TC_EVENT_DAMAGE_ENS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CLIMADA_TC_EVENT_DAMAGE_ENS_GUI.M with the given input arguments.
%
%      CLIMADA_TC_EVENT_DAMAGE_ENS_GUI('Property','Value',...) creates a new CLIMADA_TC_EVENT_DAMAGE_ENS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before climada_tc_event_damage_ens_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to climada_tc_event_damage_ens_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help climada_tc_event_damage_ens_gui

% Last Modified by GUIDE v2.5 19-Oct-2015 18:56:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @climada_tc_event_damage_ens_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @climada_tc_event_damage_ens_gui_OutputFcn, ...
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


% --- Executes just before climada_tc_event_damage_ens_gui is made visible.
function climada_tc_event_damage_ens_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to climada_tc_event_damage_ens_gui (see VARARGIN)

% Choose default command line output for climada_tc_event_damage_ens_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes climada_tc_event_damage_ens_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);
get_UNISYS_name_list(hObject,eventdata,handles);



% --- Outputs from this function are returned to the command line.
function varargout = climada_tc_event_damage_ens_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenu_region.
function popupmenu_region_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_region (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_region contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_region
get_UNISYS_name_list(hObject,eventdata,handles);
set(handles.pushbutton_calculate,'Enable','off');
set(handles.popupmenu_year,'Enable','on'); % first a name region to be selected

% --- Executes during object creation, after setting all properties.
function popupmenu_region_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_region (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% UNISYS regions
global climada_tc_event_damage_ens_vars
climada_tc_event_damage_ens_vars.UNISYS_regis{1}='atlantic';
climada_tc_event_damage_ens_vars.UNISYS_regis{2}='e_pacific';
climada_tc_event_damage_ens_vars.UNISYS_regis{3}='w_pacific';
climada_tc_event_damage_ens_vars.UNISYS_regis{4}='s_pacific';
climada_tc_event_damage_ens_vars.UNISYS_regis{5}='s_indian';
climada_tc_event_damage_ens_vars.UNISYS_regis{6}='n_indian';
set(hObject,'String',climada_tc_event_damage_ens_vars.UNISYS_regis);
fprintf('popupmenu_region_CreateFcn\n');


% --- Executes on selection change in popupmenu_year.
function popupmenu_year_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_year (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_year contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_year
get_UNISYS_name_list(hObject,eventdata,handles)

% --- Executes during object creation, after setting all properties.
function popupmenu_year_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_year (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global climada_tc_event_damage_ens_vars
climada_tc_event_damage_ens_vars.UNISYS_years={}; % reset
climada_tc_event_damage_ens_vars.UNISYS_years{1}=datestr(today,'yyyy');
for year_i=1:10
    climada_tc_event_damage_ens_vars.UNISYS_years{end+1}=...
        sprintf('%i',str2double(climada_tc_event_damage_ens_vars.UNISYS_years{year_i})-1);
end
set(hObject,'String',climada_tc_event_damage_ens_vars.UNISYS_years);
set(hObject,'Enable','off'); % first a name region to be selected


% --- Executes on selection change in popupmenu_name.
function popupmenu_name_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_name contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_name
set(handles.pushbutton_calculate,'Enable','on');


% --- Executes during object creation, after setting all properties.
function popupmenu_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_ens_n_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ens_n (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ens_n as text
%        str2double(get(hObject,'String')) returns contents of edit_ens_n as a double


% --- Executes during object creation, after setting all properties.
function edit_ens_n_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ens_n (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_calculate.
function pushbutton_calculate_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_calculate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global climada_tc_event_damage_ens_vars

UNISYS_regi=climada_tc_event_damage_ens_vars.UNISYS_regis{get(handles.popupmenu_region,'Value')};
UNISYS_year=climada_tc_event_damage_ens_vars.UNISYS_years{get(handles.popupmenu_year,'Value')};
UNISYS_name=climada_tc_event_damage_ens_vars.UNISYS_names{get(handles.popupmenu_name,'Value')};

% get rid of all clutter
UNISYS_name=strrep(UNISYS_name,'Super ','');
UNISYS_name=strrep(UNISYS_name,'Tropical Depression','');
UNISYS_name=strrep(UNISYS_name,'Tropical Storm','');
UNISYS_name=strrep(UNISYS_name,'Typhoon-1','');
UNISYS_name=strrep(UNISYS_name,'Typhoon-2','');
UNISYS_name=strrep(UNISYS_name,'Typhoon-3','');
UNISYS_name=strrep(UNISYS_name,'Typhoon-4','');
UNISYS_name=strrep(UNISYS_name,'Typhoon-5','');
UNISYS_name=strrep(UNISYS_name,'Hurricane-1','');
UNISYS_name=strrep(UNISYS_name,'Hurricane-2','');
UNISYS_name=strrep(UNISYS_name,'Hurricane-3','');
UNISYS_name=strrep(UNISYS_name,'Hurricane-4','');
UNISYS_name=strrep(UNISYS_name,'Hurricane-5','');
UNISYS_name=strrep(UNISYS_name,'Cyclone-1','');
UNISYS_name=strrep(UNISYS_name,'Cyclone-2','');
UNISYS_name=strrep(UNISYS_name,'Cyclone-3','');
UNISYS_name=strrep(UNISYS_name,'Cyclone-4','');
UNISYS_name=strrep(UNISYS_name,'Cyclone-5','');
UNISYS_name=strrep(UNISYS_name,' ','');
UNISYS_name=strrep(UNISYS_name,' ','');

ens_n=str2double(get(handles.edit_ens_n,'String'));
fprintf('%s %s %s - %i\n',UNISYS_regi,UNISYS_year,UNISYS_name,ens_n);

call_from_GUI.axes_left=handles.axes_left;
call_from_GUI.axes_right=handles.axes_right;
damages=climada_tc_event_damage_ens(UNISYS_regi,UNISYS_year,UNISYS_name,ens_n,call_from_GUI);
fprintf('original track: %g [USD], min/max: %g/%g\n',damages(1),min(damages),max(damages));


function get_UNISYS_name_list(hObject,eventdata,handles)
% get the event names
global climada_tc_event_damage_ens_vars
UNISYS_REGI=climada_tc_event_damage_ens_vars.UNISYS_regis{get(handles.popupmenu_region,'Value')};
UNISYS_YEAR=climada_tc_event_damage_ens_vars.UNISYS_years{get(handles.popupmenu_year,'Value')};
% fetch the index of all events
url_str=['http://weather.unisys.com/hurricane/' UNISYS_REGI '/' UNISYS_YEAR '/index.php'];
fprintf('fetching %s\n',url_str);
[index_str,STATUS] = urlread(url_str);
if STATUS
    % kind of parse index_str to get names
    UNISYS_names={};
    for event_i=100:-1:1
        for black_red=1:2
            if black_red==1
                check_str=['<tr><td width="20" align="right" style="color:black;">' num2str(event_i) '</td><td width="250" style="color:black;">'];
            else
                check_str=['<tr><td width="20" align="right" style="color:red;">' num2str(event_i) '</td><td width="250" style="color:red;">'];
            end
            pos=strfind(index_str,check_str);
            if pos>0
                UNISYS_names{end+1}=index_str(pos+length(check_str):pos+length(check_str)+25);
            end
        end % black_red
    end % event_i
    set(handles.pushbutton_calculate,'Enable','off'); % first a name needs to be selected
else
    UNISYS_names{1}='no web access > press Calculate button';
    set(handles.pushbutton_calculate,'Enable','on');
end

climada_tc_event_damage_ens_vars.UNISYS_names=UNISYS_names;
set(handles.popupmenu_name,'String',climada_tc_event_damage_ens_vars.UNISYS_names);
