function varargout = climada_demo_gui(varargin)
% CLIMADA_DEMO_GUI M-file for climada_demo_gui.fig
%      CLIMADA_DEMO_GUI, by itself, creates a new CLIMADA_DEMO_GUI or raises the existing
%      singleton*.
%
%      H = CLIMADA_DEMO_GUI returns the handle to a new CLIMADA_DEMO_GUI or the handle to
%      the existing singleton*.
%
%      CLIMADA_DEMO_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CLIMADA_DEMO_GUI.M with the given input
%      arguments.
%
%      CLIMADA_DEMO_GUI('Property','Value',...) creates a new CLIMADA_DEMO_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before climada_demo_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to climada_demo_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% david.bresch@gmail.com, 20140516, reverse_cb added
%
% Edit the above text to modify the response to help climada_demo_gui
%
% Last Modified by GUIDE v2.5 05-Aug-2015 17:49:27
%-

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @climada_demo_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @climada_demo_gui_OutputFcn, ...
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

% --- Executes just before climada_demo_gui is made visible.
function climada_demo_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to climada_demo_gui (see VARARGIN)

% Choose default command line output for climada_demo_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using climada_demo_gui.
if strcmp(get(hObject,'Visible'),'off')
    %plot(rand(5));
end

% put a nice name
set(handles.figure1,'Name','iAdap(p)t - interactive economics of climate adaptation');

global climada_demo_params
climada_demo_params.scenario              = 99;
climada_demo_params.growth                = get(handles.slider2, 'Value');
climada_demo_params.measures.mangroves    = 99;
climada_demo_params.measures.beachnourish = get(handles.slider4, 'Value');
climada_demo_params.measures.seawall      = get(handles.slider5, 'Value');
climada_demo_params.measures.quality      = get(handles.slider6, 'Value');
climada_demo_params.measures.reverse_cb   = get(handles.radiobutton_bc, 'Value');
climada_demo_params.discount_rate         = str2double(get(handles.edit3,'String'))/100;
    

% display the image
axes(handles.axes2);
cla;
global climada_global
image_file    = [climada_global.data_dir filesep 'system' filesep 'demo_illu1.png'];
image_present = imread(image_file); % read image from file
image(image_present); % display
axis off

% clear the bottom axes
axes(handles.axes1);
cla;
axis off

% clear the middle axes
axes(handles.axes3);
cla;
axis off

% color scenario sliders
set(handles.slider1, 'BackgroundColor',[238  64   0]/255); % climate scenario red; [155 205 155]/255); % climate
set(handles.slider2, 'BackgroundColor',[255 127   0]/255); % economic growth orange; [180 238 180]/255); % economic growth
% color measures sliders
set(handles.slider3, 'BackgroundColor',[ 39  64 139]/255); % mangroves
set(handles.slider4, 'BackgroundColor',[ 30 144 255]/255); % beachnourish
set(handles.slider5, 'BackgroundColor',[ 99 184 255]/255); % seawall
set(handles.slider6, 'BackgroundColor',[178 223 238]/255);%[162 181 205]/255); % quality


% color the sliders
% set(handles.text_mangroves,'BackgroundColor',[0.2 0.5 0.1]); % mangroves
% set(handles.text_beach_nourishment,'BackgroundColor',[1 1 0]); % beachnourish
% set(handles.text_seawall,'BackgroundColor',[0.6 0.4 0.1]); % seawall
% set(handles.text_building_code,'BackgroundColor',[0.1 0.9 0.1]); % quality
% set(handles.text_insurance_deductible,'BackgroundColor',[0.2 0.3 0.5]); % insurance_deductible

% % set these colors to white on PCs
% if strfind(computer,'PCWIN')
%     set(handles.text_beach_nourishment,'BackgroundColor',[1 1 1]); % beachnourish
%     set(handles.text_mangroves,'BackgroundColor',[1 1 1]); % mangroves
%     set(handles.text_seawall,'BackgroundColor',[1 1 1]); % seawall
%     set(handles.text_building_code,'BackgroundColor',[1 1 1]); % quality
%     set(handles.text_insurance_deductible,'BackgroundColor',[1 1 1]); % insurance_deductible
%     set(handles.pushbutton1,'BackgroundColor',[.8 .8 .8]); % insurance_deductible
%     set(handles.text13,'String','no        < measures >        full'); % insurance_deductible
% end

pushbutton1_Callback(hObject, eventdata, handles)

% UIWAIT makes climada_demo_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = climada_demo_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject,eventdata,handles,force_update)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

waterfall = 0;
if ~exist('force_update','var'),force_update=0;end
if force_update,waterfall = 1;end

global climada_demo_params

% climate scenario
if climada_demo_params.scenario ~= get(handles.slider1, 'Value');
    climada_demo_params.scenario = get(handles.slider1, 'Value');
    waterfall = 1;
end
% economic growth
if climada_demo_params.growth ~= get(handles.slider2, 'Value');
    climada_demo_params.growth = get(handles.slider2, 'Value');
    waterfall = 1;
end

nice_numbers = 1;
scaled_AED   = 1;

if waterfall
    cc_label = {'No' 'Middle' 'High'};
    set(handles.text1,'String', [cc_label{get(handles.slider1,'Value')+1} ' climate change'])
    set(handles.text2,'String', ['Economic growth ' num2str(get(handles.slider2,'Value')*100,'%1.0f') '%'])
    
    axes(handles.axes3);
    cla;
    climada_demo_waterfall_graph(climada_demo_params,0,nice_numbers);
    cost_curve = 1;
else
    cost_curve = 0;
end

% discount rate
string = get(handles.edit3,'String'); val = str2double(string)/100;
if climada_demo_params.discount_rate ~= val;
    climada_demo_params.discount_rate = val;
    cost_curve = 1;
end
if climada_demo_params.measures.mangroves ~= get(handles.slider3, 'Value');
    climada_demo_params.measures.mangroves = get(handles.slider3, 'Value');
    cost_curve = 1;
end
if climada_demo_params.measures.beachnourish ~= get(handles.slider4, 'Value');
    climada_demo_params.measures.beachnourish = get(handles.slider4, 'Value');
    cost_curve = 1;
end
if climada_demo_params.measures.seawall ~= get(handles.slider5, 'Value');
    climada_demo_params.measures.seawall = get(handles.slider5, 'Value');
    cost_curve = 1;
end
if climada_demo_params.measures.quality ~= get(handles.slider6, 'Value');
    climada_demo_params.measures.quality = get(handles.slider6, 'Value');
    cost_curve = 1;
end
if climada_demo_params.measures.reverse_cb ~= get(handles.radiobutton_bc, 'Value');
    climada_demo_params.measures.reverse_cb = get(handles.radiobutton_bc, 'Value');
    cost_curve = 1;
end
if cost_curve
    set(handles.text3,'String',['Mangroves '         num2str(get(handles.slider3, 'Value')*100,'%2.0f') '%'])
    set(handles.text4,'String',['Beach nourishment ' num2str(get(handles.slider4, 'Value')*100,'%2.0f') '%'])
    set(handles.text5,'String',['Seawall '           num2str(get(handles.slider5, 'Value')*100,'%2.0f') '%'])
    set(handles.text6,'String',['Building code '     num2str(get(handles.slider6, 'Value')*100,'%2.0f') '%'])

    axes(handles.axes1);
    cla;
    [impact_present,impact_future, insurance_benefit, insurance_cost] = ...
        climada_demo_adapt_cost_curve(climada_demo_params,0,scaled_AED, ...
        nice_numbers,climada_demo_params.measures.reverse_cb);
    % climada_demo_adapt_cost_curve(climada_demo_params,0); % until 20140516

    %display cost of measures
    if nice_numbers
        fct = 10^-8;
    else
        fct = 1;
    end
    if scaled_AED
        %%%global climada_global
        scale_factor = impact_future.ED(end) /impact_future.NPV_total_climate_risk;
        %delta_years = climada_global.future_reference_year - climada_global.present_reference_year;
        %fct_AED     = 1/delta_years;
    else
        fct_AED = 1;
    end
    
    set(handles.text30, 'String',num2str(impact_future.measures.cost(1)*fct*scale_factor,'%2.2f'));
    set(handles.text40, 'String',num2str(impact_future.measures.cost(2)*fct*scale_factor,'%2.2f'));
    set(handles.text50, 'String',num2str(impact_future.measures.cost(3)*fct*scale_factor,'%2.1f'));
    set(handles.text60, 'String',num2str(impact_future.measures.cost(4)*fct*scale_factor,'%2.1f'));
    set(handles.text70, 'String',num2str(insurance_cost*fct                             ,'%2.1f')); 
end



% total_adaptation_costs = sum(impact_future.measures.cost)+sum(impact_future.risk_transfer);
% string                 = sprintf('%2.0f',total_adaptation_costs);
% set(handles.text18, 'String',string);
% 
% total_adaptation_benefits = sum(impact_future.benefit);
% string                    = sprintf('%2.0f',total_adaptation_benefits);
% set(handles.text20, 'String',string);
% 
% CBR    = total_adaptation_costs/total_adaptation_benefits;
% string = sprintf('%2.2f',CBR);
% set(handles.text22, 'String',string);

title(''); % reset


% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% % asking to quit
% selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
%                      ['Close ' get(handles.figure1,'Name') '...'],...
%                      'Yes','No','Yes');
% if strcmp(selection,'No')
%     return;
% end

delete(handles.figure1)


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


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

set(hObject, 'String', {'plot(rand(5))', 'plot(sin(1:0.01:25))', 'bar(1:.5:10)', 'plot(membrane)', 'surf(peaks)'});


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

Value = get(handles.slider1,'Value');
a     = [get(handles.slider1,'Min') get(handles.slider1,'Max')];
a     = sort([a mean(a)]);
[C,I] = min(abs(Value-a));
Value = a(I);
set(handles.slider1,'Value',Value);

global climada_global % we need the global variable to access the path

if Value == 0
    image_file = [climada_global.data_dir filesep 'system' filesep 'demo_illu0.png'];
elseif Value == 1
    image_file = [climada_global.data_dir filesep 'system' filesep 'demo_illu1.png'];
else
    image_file = [climada_global.data_dir filesep 'system' filesep 'demo_illu2.png'];
end

% display the appropriate image
axes(handles.axes2);
cla;
image_present = imread(image_file); % read image from file
image(image_present); % display
axis off

pushbutton1_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider2_Callback(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% val           = get(hObject,'Value');
% slider_String = sprintf('%2.1f',val*100);
% set(handles.edit2,'String',slider_String);

Value = get(handles.slider2,'Value');
a     = [get(handles.slider2,'Min') get(handles.slider2,'Max')];
a     = sort([a mean(a)]);
[C,I] = min(abs(Value-a));
Value = a(I);
set(handles.slider2,'Value',Value);



pushbutton1_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% handles    structure with handles and user data (see GUIDATA)
% --- Executes on slider movement.
function slider3_Callback(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

Value = get(hObject,'Value');
a     = [get(hObject,'Min') get(hObject,'Max')];
a     = sort([a mean(a)]);
[C,I] = min(abs(Value-a));
Value = a(I);
set(hObject,'Value',Value);

pushbutton1_Callback(hObject, eventdata, handles)


% % --- Executes during object creation, after setting all properties.
function slider3_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to slider3 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: slider controls usually have a light gray background.
% if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor',[.9 .9 .9]);
% end
% set(hObject,'BackgroundColor',[1 1 0]); % beachnourish


% --- Executes on slider movement.
function slider4_Callback(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
Value = get(hObject,'Value');
a     = [get(hObject,'Min') get(hObject,'Max')];
a     = sort([a mean(a)]);
[C,I] = min(abs(Value-a));
Value = a(I);
set(hObject,'Value',Value);

pushbutton1_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function slider4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject,'BackgroundColor',[0.2 0.5 0.1]); % mangroves


% % --- Executes on slider movement.
function slider5_Callback(hObject, eventdata, handles)
% % hObject    handle to slider6 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: get(hObject,'Value') returns position of slider
% %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
Value = get(hObject,'Value');
a     = [get(hObject,'Min') get(hObject,'Max')];
a     = sort([a mean(a)]);
[C,I] = min(abs(Value-a));
Value = a(I);
set(hObject,'Value',Value);

pushbutton1_Callback(hObject, eventdata, handles)

 
% % --- Executes during object creation, after setting all properties.
function slider5_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to slider6 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: slider controls usually have a light gray background.
% if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor',[0.9 .9 .9]);
% end
% set(hObject,'BackgroundColor',[0.1 0.9 0.1]); % quality

% % --- Executes on slider movement.
function slider6_Callback(hObject, eventdata, handles)
% % hObject    handle to slider6 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: get(hObject,'Value') returns position of slider
% %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
Value = get(hObject,'Value');
a     = [get(hObject,'Min') get(hObject,'Max')];
a     = sort([a mean(a)]);
[C,I] = min(abs(Value-a));
Value = a(I);
set(hObject,'Value',Value);


pushbutton1_Callback(hObject, eventdata, handles)


% % --- Executes during object creation, after setting all properties.
% function slider6_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to slider6 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: slider controls usually have a light gray background.
% if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor',[.9 .9 .9]);
% end
% set(hObject,'BackgroundColor',[0.2 0.3 0.5]); % insurance_deductible

% % --- Executes on slider movement.
function slider7_Callback(hObject, eventdata, handles)
% % hObject    handle to slider5 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: get(hObject,'Value') returns position of slider
% %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% % --- Executes during object creation, after setting all properties.
function slider7_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to slider5 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: slider controls usually have a light gray background.
% if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor',[.9 .9 .9]);
% end
% set(hObject,'BackgroundColor',[0.6 0.4 0.1]); % seawall


function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
string = get(hObject,'String');
val    = str2double(string)/100;
if val>1, val=1; end
if val<0, val=0; end
if isempty(val)
    set(hObject,'String','xx');
else
    set(handles.slider2,'Value',val);
end

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
% % hObject    handle to edit3 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: get(hObject,'String') returns contents of edit3 as text
% %        str2double(get(hObject,'String')) returns contents of edit3 as a double
% 
% 
pushbutton1_Callback(hObject, eventdata, handles)

% % --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to edit3 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end



% function edit5_Callback(hObject, eventdata, handles)
% % hObject    handle to text29 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: get(hObject,'String') returns contents of text29 as text
% %        str2double(get(hObject,'String')) returns contents of text29 as a double


% --- Executes during object creation, after setting all properties.
function text29_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text29 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function text30_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% function edit6_Callback(hObject, eventdata, handles)
% % hObject    handle to text40 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: get(hObject,'String') returns contents of text40 as text
% %        str2double(get(hObject,'String')) returns contents of text40 as a double


% --- Executes during object creation, after setting all properties.
function text40_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text40 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% function edit7_Callback(hObject, eventdata, handles)
% % hObject    handle to text50 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: get(hObject,'String') returns contents of text50 as text
% %        str2double(get(hObject,'String')) returns contents of text50 as a double


% --- Executes during object creation, after setting all properties.
function text50_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text50 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% function edit8_Callback(hObject, eventdata, handles)
% % hObject    handle to text60 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: get(hObject,'String') returns contents of text60 as text
% %        str2double(get(hObject,'String')) returns contents of text60 as a double


% --- Executes during object creation, after setting all properties.
function text60_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text60 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% function edit9_Callback(hObject, eventdata, handles)
% % hObject    handle to text70 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: get(hObject,'String') returns contents of text70 as text
% %        str2double(get(hObject,'String')) returns contents of text70 as a double


% --- Executes during object creation, after setting all properties.
function text70_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text70 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% % --------------------------------------------------------------------
% function Untitled_1_Callback(hObject, eventdata, handles)
% % hObject    handle to Untitled_1 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on slider3 and none of its controls.
function slider3_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in radiobutton_bc.
function radiobutton_bc_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_bc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_bc
pushbutton1_Callback(hObject, eventdata, handles); % recalc, since vertical axis swapped


% --------------------------------------------------------------------
function ReinitMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to ReinitMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% added by david.bresch@gmail.com in order to allow the user to edit the
% underlying entity to experiment freely.
fprintf('Re-init ...\n');
pushbutton1_Callback(hObject,eventdata,handles,1) % force update, since new entity
