function climada_viewer(varargin)
% climada_measure_viewer MATLAB code for climada_measure_viewer.fig
%      climada_measure_viewer, by itself, creates a new climada_measure_viewer or raises the existing
%      singleton*.
%
%      H = climada_measure_viewer returns the handle to a new climada_measure_viewer or the handle to
%      the existing singleton*.
%
%      climada_measure_viewer('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in climada_measure_viewer.M with the given input arguments.
%
%      climada_measure_viewer('Property','Value',...) creates a new climada_measure_viewer or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before climada_measure_viewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to climada_measure_viewer_OpeningFcn via varargin.
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
% 
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151203, init based on climada_measures_viewer
%-

% Last Modified by GUIDE v2.5 30-Nov-2015 10:28:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
'gui_Singleton',  gui_Singleton, ...
'gui_OpeningFcn', @climada_measure_viewer_OpeningFcn, ...
'gui_OutputFcn',  @climada_measure_viewer_OutputFcn, ...
'gui_LayoutFcn',  [] , ...
'gui_Callback',   []);
if nargin && ischar(varargin{1})
gui_State.gui_Callback = str2func(varargin{1});
end

% if nargout
%     [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
% else
    gui_mainfcn(gui_State, varargin{:});
% end
% End initialization code - DO NOT EDIT
% gui varibale initialization
function climada_measure_viewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to climada_measure_viewer (see VARARGIN)
global container
%global climada_global
% Choose default command line output for climada_viewer
handles.output = hObject;
%global container
%climada_global = evalin('base', 'climada_global');
%if ~climada_init_vars,return;end % init/import global variables

%climada picture
climada_logo(hObject, eventdata, handles)

% Update handles structure
%set all initial paramters
%set(handles.checkbox3,'Value',1);
container.set_axis=0;
%set(handles.radiobutton9,'Value',1);
container.timestamp=1;
set(handles.radiobutton2,'Value',1);
container.rb2=1;container.rb1=0;container.rb3=0;
%imagesc(uipanel8
guidata(hObject, handles);

function climada_logo(hObject, eventdata, handles)

try
module_data_dir = [fileparts(fileparts(mfilename('fullpath'))) filesep 'docs'];
logo_path= [module_data_dir filesep 'climada_sign.png'];
axes(handles.axes2)
set(handles.axes2,'visible','off')
hold on;
imagesc(imread(logo_path));
set(handles.axes2,'YDir','reverse');
set(handles.axes2,'color','none')
%uistack(handles.axes2,'bottom');
catch
set(handles.axes2,'color','none')
set(handles.axes2,'visible','off')

end

% --- Outputs from this function are returned to the command line.
function varargout = climada_viewer_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1
global container


%only after startup
if ~isfield(container, 'measures_impact'),
    set(handles.text15,'String','Please load a file first');
    return
elseif isfield(container, 'measures_impact') && isempty(container.measures_impact)
    set(handles.text15,'String','Please load a file first');
    return
end
   

if length(container.measures_impact)>1
for i=1:length(container.measures_impact(container.timestamp).EDS)
measures{i,1}=container.measures_impact(container.timestamp).EDS(i).annotation_name;
end
else
for i=1:length(container.measures_impact.EDS)
measures{i,1}=container.measures_impact.EDS(i).annotation_name;
end
end

set(handles.listbox1,'String',measures);
container.index_measures = get(hObject,'Value'); 
container.measures_list=measures;
assignin('base','container',container);
assignin('base','index_measures',container.index_measures);

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

% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2
global container

%only after startup
if ~isfield(container, 'measures_impact'),
    set(handles.text15,'String','Please load a file first')
    return
    elseif isfield(container, 'measures_impact') && isempty(container.measures_impact)
    set(handles.text15,'String','Please load a file first');
    return
end

categories=unique(container.measures_impact(container.timestamp).entity.assets.Category);
%if categories are numbers
try 
    categories(length(categories)+1)=length(categories)+1;
    for i=1:length(categories)
        cat{i}=num2str(categories(i));
    end
catch
    categories{length(categories)+1}='all categories';
    cat=categories;
end
    
set(handles.listbox2,'Max',length(cat));
set(handles.listbox2,'String',cat);

contents = cellstr(get(hObject,'String'));
select= contents{get(hObject,'Value')};
if iscell(contents);
    container.index_categories=select;  
else
    container.index_categories=str2double(select);
end

%check if categories are numbers or words
if isstrprop(container.index_categories, 'digit')
    container.index_categories=str2num(container.index_categories);
end

assignin('base','container',container);
assignin('base','index_categories',container.index_categories);

%automatical detection of value_unit: USD or people
%check if Value_unit exists
if ~isfield(container.measures_impact(container.timestamp).entity.assets,'Value_unit')
    for p=1:length(container.measures_impact(container.timestamp).entity.assets.lon)
    container.measures_impact(container.timestamp).entity.assets.Value_unit{p}='USD'; 
    end                                                                    %get the currency! for bangladesh bdt
end
for i=1:length(cat)-1
    if ~iscell(container.measures_impact(container.timestamp).entity.assets.Category)
        for k=1:length(cat);cat_(k)=str2num(cat{k});end
        pos=find(container.measures_impact(container.timestamp).entity.assets.Category==cat_(i));
    else
        pos=find(strcmp(container.measures_impact(container.timestamp).entity.assets.Category,cat{i}));
    end    
position{i}=container.measures_impact(container.timestamp).entity.assets.Value_unit{pos(1)};
end
position{length(position)+1}='all categories with same unit';
for i=1:length(categories)
string_vec{i}=[cat{i} ' - ' position{i}];
end

for i=1:length(string_vec)-1
if findstr(string_vec{i},'USD')>=1
index_USD(i)=i;
elseif findstr(string_vec{i},'people')>=1
index_people(i)=i;
else
   index_USD=0; index_people=0;
end
end
if exist('index_USD','var');
    index_USD(index_USD==0)=[];
    container.category_list_usd=categories(index_USD)';
    if ~exist('index_people','var'); container.category_list_people=[];end
end
if exist('index_people','var');
    index_people(index_people==0)=[];
    container.category_list_people=categories(index_people)';
end

set(handles.listbox2,'String',string_vec);

% if ischar(container.index_categories)
%     ismember(container.index_categories,container.category_list_usd);
if ismember(container.index_categories,container.category_list_usd)
container.rb5=0;
container.rb4=0;
set(handles.radiobutton4,'Value',1);    %USD
set(handles.radiobutton5,'Value',0);
container.rb4=1;
elseif ismember(container.index_categories,container.category_list_people)
container.rb5=0;
container.rb4=0;
set(handles.radiobutton4,'Value',0);
set(handles.radiobutton5,'Value',1);
container.rb5=1;
end

%disable people or USD selection button if only one of both exists
if isempty(container.category_list_people)
    set(handles.radiobutton5,'visible','off');
elseif isempty(container.category_list_usd)
    set(handles.radiobutton4,'visible','off');
end


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

% --- category: Damage.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global container
container.rb1=get(hObject,'Value');
if container.rb1==1
set(handles.radiobutton2,'Value',0);
set(handles.radiobutton3,'Value',0);
container.rb2=0;
container.rb3=0;
container.type='damage';
end

% --- category: Assets
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global container
container.rb2=get(hObject,'Value');
if container.rb2==1
set(handles.radiobutton1,'Value',0);
set(handles.radiobutton3,'Value',0);
container.rb1=0;
container.rb3=0;
container.type='assets';
end

% --- category: Entity
function radiobutton3_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global container
container.rb3=get(hObject,'Value');
%calculate the benefit
for i=1:length(container.measures_impact(container.timestamp).EDS)
container.benefit{i}=container.measures_impact(container.timestamp).EDS(length(container.measures_impact(container.timestamp).EDS)).ED_at_centroid-container.measures_impact(container.timestamp).EDS(i).ED_at_centroid;
end
if container.rb3==1
set(handles.radiobutton2,'Value',0);
set(handles.radiobutton1,'Value',0);
container.rb2=0;
container.rb1=0;
container.type='benefit';
end

% USD
function radiobutton4_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global container
container.rb4=get(hObject,'Value');
if container.rb4==1
set(handles.radiobutton5,'Value',0);
container.rb5=0;
end

% People
function radiobutton5_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global container
container.rb5=get(hObject,'Value');
if container.rb5==1
set(handles.radiobutton4,'Value',0);
container.rb4=0;
end


%load measure impact file
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% prompt for file if not given
global container
%load measures impact file
set(handles.figure1, 'pointer', 'watch')
drawnow;
% [filename, pathname] = uigetfile({'*.mat'}, 'Select measures_impact file:');
% filename_tot = fullfile(pathname,filename);
% 
% temp=open(filename_tot);
%container.measures_impact=temp.measures_impact;
container.measures_impact=climada_measures_impact_load('',1);

clear filename pathname filename_tot

%load entity if not included in measures_impact

if ~isfield(container.measures_impact,'entity')
container.entity = climada_entity_load;
else
   % default entity
%container.entity=container.measures_impact(1).entity;   
end
% [filename, pathname] = uigetfile({'*.mat'}, 'Select entity file:');
% filename_tot = fullfile(pathname,filename);
% container.entity=open(filename_tot);

%recognize peril_ID
for i=1:length(container.measures_impact)
    peril_list{i}=container.measures_impact(i).peril_ID;
end
container.peril_list=unique(peril_list);

list=[];list_tot=[];
for k=1:length(container.peril_list);list=container.peril_list{k};list_tot=[list ', ' list_tot];end
    
message=sprintf('recognized: %s perils',list_tot);
if isfield(container, 'peril_name')
    index=length(container.peril_name)+1;
else
    index=1;
end

% if strcmp(container.rb_peril,'FL')
%     if isfield(container, 'peril_name')
%         for l=1:length(container.peril_name)
%             if strcmp(container.peril_name(l),'flood')
%                 button = questdlg('Flood peril already exists, overwrite it?','Peril recognition','Yes','No','Yes');
%                 if strcmp(button,'Yes')
%                     display('Flood peril overwritten') 
%                 else
%                     return
%                 end
%             end
%         end
%     end
%             container.measures_impact_FL=container.measures_impact;
%             container.entity_FL=container.entity;
% %            set(handles.radiobutton6,'Value',1);set(handles.radiobutton7,'Value',0);set(handles.radiobutton8,'Value',0);
%             container.axis_ur=-89.15; container.axis_ul=-89.25;
%             container.axis_ol=13.67;  container.axis_or=13.7;
%             container.peril_name{index}='flood';    
% 
% elseif strcmp(container.rb_peril,'TC')
%     if isfield(container, 'peril_name')
%         for l=1:length(container.peril_name)
%             if strcmp(container.peril_name(l),'tropical cyclone')
%                 msgbox('tropical cyclone peril already exists')
%                 return
%             end
%         end
%     end
%     container.measures_impact_TC=container.measures_impact;
%     container.entity_TC=container.entity;
% %    set(handles.radiobutton7,'Value',1);set(handles.radiobutton6,'Value',0);set(handles.radiobutton8,'Value',0);
%     container.axis_ur=-89; container.axis_ul=-89.35;
%     container.axis_ol=13.6;  container.axis_or=13.85;
%     container.peril_name{index}='tropical cyclone';
% elseif strcmp(container.rb_peril,'LS')
%     if isfield(container, 'peril_name')
%         for l=1:length(container.peril_name)
%             if strcmp(container.peril_name(l),'landslide')
%                 msgbox('landslide peril already exists')
%                 return
%             end
%         end
%     end    
%     container.measures_impact_LS=container.measures_impact;
%     container.entity_LS=container.entity;
% %    set(handles.radiobutton8,'Value',1);set(handles.radiobutton6,'Value',0);set(handles.radiobutton7,'Value',0);
%     container.axis_ur=-89.1; container.axis_ul=-89.145;
%     container.axis_ol=13.69;  container.axis_or=13.725;
%     container.peril_name{index}='landslide';
% elseif strcmp(container.rb_peril,'TS')
%     container.peril_name{index}='storm surge';
% elseif strcmp(container.rb_peril,'EQ')
%     container.peril_name{index}='earth quake';   
% end
msgbox(message);

listbox1_Callback(hObject, eventdata, handles);
listbox2_Callback(hObject, eventdata, handles);
display(' loading sucessfull');
set(handles.figure1, 'pointer', 'arrow')

%execute each function to return the current state
radiobutton4_Callback(hObject, eventdata, handles)
radiobutton5_Callback(hObject, eventdata, handles)
%peril list
popupmenu4_Callback(hObject, eventdata, handles)

% function check_peril(hObject, eventdata, handles)
% %Selection of peril
% global container
% % if strcmp(container.rb_peril,'FL')
% % container.measures_impact=container.measures_impact_FL;
% % container.entity=container.entity_FL;
% % elseif strcmp(container.rb_peril,'TC')
% % container.measures_impact=container.measures_impact_TC;
% % container.entity=container.entity_TC;
% % elseif strcmp(container.rb_peril,'LS')
% % container.measures_impact=container.measures_impact_LS;
% % container.entity=container.entity_LS;
% % elseif strcmp(container.rb_peril,'EQ')
% % container.measures_impact=container.measures_impact_EQ;
% % container.entity=container.entity_EQ;
% % elseif strcmp(container.rb_peril,'TS')
% % container.measures_impact=container.measures_impact_TS;
% % container.entity=container.entity_TS;
% % end
% 
% listbox1_Callback(hObject, eventdata, handles);
% listbox2_Callback(hObject, eventdata, handles);
% radiobutton4_Callback(hObject, eventdata, handles)
% radiobutton5_Callback(hObject, eventdata, handles)
% display('Peril loaded');

% plotting -> Main part
function pushbutton2_Callback(hObject, eventdata, handles)
    % hObject    handle to pushbutton2 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    global container
    
    %get the listbox selections
   % listbox2_Callback
    container.index_measures    = get(handles.listbox1,'Value');
    %container.index_categories  = get(handles.listbox2,'Value');
    %default values=
    container.unit_criterium='';
    %checkbox3_Callback(hObject, eventdata, handles); %set_axis

    set(handles.figure1, 'pointer', 'watch')
    drawnow;
    cla reset
    clear cbar
    cla (handles.axes1,'reset')
    axes(handles.axes1);
    %set(handles.axes1,'layer','top')

    % markersize=2;
    edit5_Callback(hObject, eventdata, handles);
    miv=0.1;

    %select for USD or people
    if container.rb4 ==1 && container.rb5 ==1
        container.unit_criterium='';
        set(handles.text15,'String','Please select either USD or People');

    elseif container.rb4 ==1
        container.unit_criterium='USD';
        if container.index_categories==length(unique(container.measures_impact(container.timestamp).entity.assets.Category))+1;
            temp_ind_cat=container.category_list_usd;
        else

        end
    elseif container.rb5 ==1
        container.unit_criterium='people';
        if container.index_categories==length(unique(container.measures_impact(container.timestamp).entity.assets.Category))+1;
            temp_ind_cat=container.category_list_people;
        else
            %        container.index_categories='';                                      %deaktiviert categories selection
        end
    elseif container.rb4 ==0 && container.rb5 ==0
        container.unit_criterium='USD';
    end

    %check if Peril id matches selection
    if ~isfield(container,'rb_peril')
        set(handles.text15,'String','Please select a peril');

    elseif ~strcmp(container.measures_impact(container.timestamp).peril_ID,container.rb_peril)
        set(handles.text15,'String','Selected peril does not match measures impact file, please select a different peril');
        return
    end

    %special case to get sum over all categories (USD/people) (artificial last category)
    if strcmp(container.index_categories,'all categories') | container.index_categories==length(unique(container.measures_impact(container.timestamp).entity.assets.Category))+1;
        selection= climada_value_sum(container.measures_impact(container.timestamp).entity,container.measures_impact,container.type,container.unit_criterium,container.timestamp,container.index_measures,handles);
    end

    is_selected = climada_assets_select(container.measures_impact(container.timestamp).entity,container.rb_peril,container.unit_criterium,container.index_categories);
    container.is_selected=is_selected;

    %Message if no entity selected
    if ~isfield(container, 'rb1') && ~isfield(container, 'rb2') && ~isfield(container, 'rb3')
        message='Please select an entity';
        set(handles.text15,'String',message);
    else
        %check for small values <1 that make problems if plotting on exponential scale and miv is set

        %damage
        if container.rb1==1;
            if strcmp(container.rb_peril,'FL'); container.peril_color='FL';
            elseif strcmp(container.rb_peril,'TC'); container.peril_color='TC';
            elseif strcmp(container.rb_peril,'TC'); container.peril_color='MS';
            end
            if container.index_categories==length(unique(container.measures_impact(container.timestamp).entity.assets.Category))+1;
                if max(selection.point_value)<2;miv=[]; end
                container.plot_lon=selection.point_lon;container.plot_lat=selection.point_lat;container.plot_value=selection.point_value;
                set(handles.text1,'String',sum(selection.point_value));
            else
                if max(container.measures_impact(container.timestamp).EDS(container.index_measures).ED_at_centroid(is_selected))<1;miv=[];end
                container.plot_lon=container.measures_impact(container.timestamp).EDS(container.index_measures).assets.lon(is_selected);
                container.plot_lat=container.measures_impact(container.timestamp).EDS(container.index_measures).assets.lat(is_selected);
                container.plot_value=container.measures_impact(container.timestamp).EDS(container.index_measures).ED_at_centroid(is_selected);
                 [~, ~,num_str] = climada_digit_set(sum(container.measures_impact(container.timestamp).EDS(container.index_measures).ED_at_centroid(is_selected)),'',1);
                set(handles.text1,'String',num_str)% sum(container.measures_impact(container.timestamp).EDS(container.index_measures).ED_at_centroid(is_selected)));
            end

            %assets
        elseif  container.rb2==1;
            container.peril_color='assets';
            if container.index_categories==length(unique(container.measures_impact(container.timestamp).entity.assets.Category))+1;
                if max(selection.point_value)<1;miv=[]; end
                container.plot_lon=selection.point_lon;container.plot_lat=selection.point_lat;container.plot_value=selection.point_value;

                set(handles.text2,'String',sum(selection.point_value));

            else
                if max(container.measures_impact(container.timestamp).EDS(container.index_measures).assets.Value(is_selected))<1;miv=[];end
                container.plot_lon=container.measures_impact(container.timestamp).EDS(container.index_measures).assets.lon(is_selected);
                container.plot_lat=container.measures_impact(container.timestamp).EDS(container.index_measures).assets.lat(is_selected);
                container.plot_value=container.measures_impact(container.timestamp).EDS(container.index_measures).assets.Value(is_selected);
                [~, ~,num_str] = climada_digit_set(sum(container.measures_impact(container.timestamp).EDS(container.index_measures).assets.Value(is_selected)),'',1);
%                 digit_num=sum(container.measures_impact(container.timestamp).EDS(container.index_measures).assets.Value(is_selected));
%                 num_str=sprintf('%.2f''%s',digit_num/10^digit,digit_str);
                set(handles.text2,'String',num_str) %sum(container.measures_impact(container.timestamp).EDS(container.index_measures).assets.Value(is_selected)));
            end

            %benefit
        elseif container.rb3==1;
            radiobutton3_Callback(hObject, eventdata, handles);
            container.peril_color='benefit';
            if container.index_categories==length(unique(container.measures_impact(container.timestamp).entity.assets.Category))+1;
                if max(selection.point_value)<1;miv=[]; end
                container.plot_lon=selection.point_lon;container.plot_lat=selection.point_lat;container.plot_value=selection.point_value;
                set(handles.text3,'String',sum(selection.point_value));
            else
                if max(container.benefit{1,container.index_measures}(is_selected))<1;miv=[]; end
                container.plot_lon=container.measures_impact(container.timestamp).EDS(container.index_measures).assets.lon(is_selected);
                container.plot_lat=container.measures_impact(container.timestamp).EDS(container.index_measures).assets.lat(is_selected);
                container.plot_value=container.benefit{1,container.index_measures}(is_selected);
                [~, ~,num_str] = climada_digit_set(sum(container.benefit{1,container.index_measures}(is_selected)),'',1);
                set(handles.text3,'String',num_str) %sum(container.benefit{1,container.index_measures}(is_selected)));
            end

        end
        if sum(container.plot_value)==0;
            message='no values to plot, all selected values are 0';
        else
            %final plotting
            cbar=plotclr(container.plot_lon,container.plot_lat,container.plot_value,'s',container.markersize,1,miv,[],climada_colormap(container.peril_color),[],1);
            set(get(cbar,'ylabel'),'String', 'value per pixel (exponential scale)' ,'fontsize',12);
            message='values plotted';
        end
        set(handles.text15,'String',message);
        set(gcf,'toolbar','figure');
        set(gcf,'menubar','figure');
        climada_figure_scale_add
        title(container.measures_impact(container.timestamp).EDS(container.index_measures).annotation_name);

        if container.set_axis==1
            if isfield(container, 'axis_ol') && isfield(container, 'axis_or') && isfield(container, 'axis_ul') && isfield(container, 'axis_ur')

                climada_figure_axis_limits_equal_for_lat_lon([container.axis_ul container.axis_ur container.axis_ol container.axis_or])
            else
                set(handles.text15,'String','Please enter axis limits');
                edit1_Callback(hObject, eventdata, handles);edit2_Callback(hObject, eventdata, handles);
                edit3_Callback(hObject, eventdata, handles);edit4_Callback(hObject, eventdata, handles);
                if isfield(container, 'axis_ol')
                    pushbutton2_Callback(hObject, eventdata, handles)
                end
            end
        end
        hold on
    end

    if ~isfield(container, 'plot_river')&& get(handles.checkbox1,'Value')==1;
        set(handles.text15,'String','Please load a shape file first');

    elseif isfield(container, 'plot_river')&& container.plot_river==1 && isfield(container, 'shapes');
        shape_plotter(container.shapes.shape_rivers)
    end

    if ~isfield(container, 'plot_roads') && get(handles.checkbox2,'Value')==1;
        set(handles.text15,'String','Please load a shape file first');
    elseif isfield(container, 'plot_roads')&& container.plot_roads==1 && isfield(container, 'shapes');
        shape_plotter(container.shapes.shape_roads)
    end
    set(handles.figure1, 'pointer', 'arrow');
    climada_logo(hObject, eventdata, handles);

%shapes
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global container climada_global

open_path=[climada_global.data_dir filesep 'results'];
[filename, pathname] = uigetfile({'*.mat'}, 'Select shape file:',open_path);
filename_tot = fullfile(pathname,filename);
container.shapes=open(filename_tot);

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
global container
container.plot_river=get(hObject,'Value') ;

% plot roads
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global container
container.plot_roads=get(hObject,'Value');

%Save matlab selection in .mat file
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global container
answer=inputdlg('Enter a filename','save to matfile');

matfile.lon=container.plot_lon;
matfile.lat=container.plot_lat;
matfile.value=container.plot_value;
container.matfile=matfile;

save(answer{1},'matfile')

% Export to excel
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

pushbutton6_Callback(hObject, eventdata, handles)

global container
filename=inputdlg('Enter a filename','Export to excel');
filename=filename{1};
sheet = 1;

xlRange = 'A1';
category{1}='longitude';
xlswrite(filename,category,sheet,xlRange)

xlRange = 'A2';
xlswrite(filename,container.matfile.lon,sheet,xlRange)

xlRange = 'B1';
category{1}='latitude';
xlswrite(filename,category,sheet,xlRange)

xlRange = 'B2';
xlswrite(filename,container.matfile.lat,sheet,xlRange)

xlRange = 'C1';
category{1}='value';
xlswrite(filename,category,sheet,xlRange)

xlRange = 'C2';
xlswrite(filename,container.matfile.value,sheet,xlRange)

% google earth
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global climada_global container
container.set_axis=1;

%manually adjust the kml output to the topography (E.g. rivers) as the default is dislocated
%west, east, south, north extension and layer angle (rotation) can be set
if strcmp(container.rb_peril,'FL')
kml_offset.west=+0.019; %+0.020;        +0.013      +0.020;                     display setting:    oly- 13.7
kml_offset.east=+0.0145; %0.016          +0.013      +0.015;                                        uly- 13.67
kml_offset.south=+0.065; %+0.05;        +0.065      +0.065;                                         ulx- -89.25
kml_offset.north=-0.006; %-0.0025;     -0.0045     -0.0045;                                         urx- -89.15
set(handles.edit1,'String','13.67');set(handles.edit2,'String','13.7');      
set(handles.edit3,'String','-89.25');set(handles.edit4,'String','-89.15');         
container.axis_ur=-89.15; container.axis_ul=-89.25;
container.axis_ol=13.67;  container.axis_or=13.7;
elseif strcmp(container.rb_peril,'TC')
kml_offset.west=+0.06;
kml_offset.east=+0.046;
kml_offset.south=+0.19;
kml_offset.north=+0.04;
set(handles.edit1,'String','13.6');set(handles.edit2,'String','13.85');      
set(handles.edit3,'String','-89.35');set(handles.edit4,'String','-89');
container.axis_ur=-89; container.axis_ul=-89.35;
container.axis_ol=13.6;  container.axis_or=13.85;
elseif strcmp(container.rb_peril,'LS')    
kml_offset.west=+0.005;
kml_offset.east=+0.003;
kml_offset.south=+0.018;
kml_offset.north=+0.007;
set(handles.edit1,'String','13.69');set(handles.edit2,'String','13.725');      
set(handles.edit3,'String','-89.145');set(handles.edit4,'String','-89.1');
container.axis_ur=-89.1; container.axis_ul=-89.145;
container.axis_ol=13.69;  container.axis_or=13.725;
else 
kml_offset.west=+0.048;
kml_offset.east=+0.042;
kml_offset.south=+0.04;
kml_offset.north=+0.040; 
end

pushbutton2_Callback(hObject, eventdata, handles);

scenario_names={'currentstate';'econgrowth';'modcc';'extrcc'};
plot_name = [container.rb_peril '_' container.unit_criterium '_' container.type '_' container.measures_impact(container.timestamp).scenario.name_simple ...
'_' container.measures_list{container.index_measures} '_category_' ...
num2str(container.index_categories)];
google_earth_save = [climada_global.data_dir filesep 'results' filesep plot_name '.kmz'];
% save kmz file
k = kml(google_earth_save);    
k.transfer(handles.axes1,kml_offset,'rotation',+0) %+3
k.run

% Load file
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global container

pos=get(hObject,'Value');
contents = cellstr(get(hObject,'String')); %returns popupmenu1 contents as cell array

%load selected file

[filename, pathname] = uigetfile({'*.mat','Please select a MAT-file (*.mat)';'*.xls','Please select an Excel-File (*.xls)';'*.xlsx','Please select an Excel-File (*.xlsx)'});
filename_tot = fullfile(pathname,filename);

if pos==2
if filename==0; filename_tot='entity_flood_file.xls';end
if regexp(filename,'.xls','once') ||regexp(filename,'.xlsx','once')
file = climada_entity_read(filename_tot);
elseif regexp(filename,'.mat','once')
file = load(filename_tot);
else
msgbox('Invalid file format');
end
container.assets=file;container.assets.filepath=filename_tot;
set(handles.text8,'String',filename);
elseif pos==3
if filename==0; filename_tot='Salvador_hazard_FL_2015.mat';end
if regexp(filename,'.mat','once')
file = load(filename_tot);
else
msgbox('Invalid file format');
end
container.hazard=file;container.hazard.filepath=filename_tot;
set(handles.text10,'String',filename);
elseif pos==4
if filename==0; filename_tot='Damage_function_file.xlsx';end
if regexp(filename,'.xls','once') ||regexp(filename,'.xlsx','once')
file=climada_damagefunctions_read(filename_tot);
elseif regexp(filename,'.mat','once')
file = load(filename_tot);
else
msgbox('Invalid file format');
end
container.dam_fun=file;container.dam_fun.filepath=filename_tot;
set(handles.text12,'String',filename);
elseif pos==5
if filename==0; filename_tot='Measures_file.xlsx';end
if regexp(filename,'.xls','once') ||regexp(filename,'.xlsx','once')
file= climada_measures_read(filename_tot);
elseif regexp(filename,'.mat','once')
file = load(filename_tot);
else
msgbox('Invalid file format');
end
container.measures=file;container.measures.filepath=filename_tot;
set(handles.text14,'String',filename);
end

assignin('base','ent',file);

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

% Plot object
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2
global container
markersize=2;
pos=get(hObject,'Value');
cla reset
axes(handles.axes1);

if pos==1
set(handles.text15,'String','Please select an object from the list');
elseif pos==2
cbar=plotclr(container.assets.assets.lon,container.assets.assets.lat,container.assets.assets.Value,'s',markersize,1,[],[],[],[],1);
elseif pos==3 %damage
if length(full(container.hazard.hazard.intensity(:,1)))>1
event=inputdlg('Enter an event number');
event=str2num(event{1});
if event>0 && length(full(container.hazard.hazard.intensity(:,1)) )>event
cbar=plotclr(container.hazard.hazard.lon,container.hazard.hazard.lat,full(container.hazard.hazard.intensity(event,:)),'s',markersize,1,[],[],[],[],1);
pit=1;
else
mes=sprintf('Select a valid event number between 1 and %d',length(full(container.hazard.hazard.intensity(:,1))));
set(handles.text15,'String',mes);
pit=0;
end
else
event=1;
end

elseif pos==4  %damage functions
description=unique(container.dam_fun.Description,'stable');
damfun_id=unique(container.dam_fun.DamageFunID);
[choice,OK] = listdlg('PromptString','Select a damage function:','ListString',description);
select=find(container.dam_fun.DamageFunID ==damfun_id(choice));

plot(container.dam_fun.Intensity(select),container.dam_fun.MDD(select),'b')
hold on
plot(container.dam_fun.Intensity(select),container.dam_fun.PAA(select),'r')

end
set(gcf,'toolbar','figure');
set(gcf,'menubar','figure');
if pos==2 || pos==3 && pit==1 ||pos==5
climada_figure_scale_add;
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

% Open object
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3
global container
pos=get(hObject,'Value');

if pos==1
set(handles.text15,'String','Please select an object from the list');
elseif pos==2
if regexp(container.assets.filepath,'.xls','once') ||regexp(container.assets.filepath,'.xlsx','once')
winopen(container.assets.filepath);
elseif regexp(container.assets.filepath,'.mat','once')
open(container.assets.filepath);
else
msgbox('Invalid file format');
end
elseif pos==3
if regexp(container.hazard.filepath,'.mat','once')
open(container.hazard.filepath);
elseif regexp(container.hazard.filepath,'.xls','once') ||regexp(container.hazard.filepath,'.xlsx','once')
winopen(container.hazard.filepath);
else
msgbox('Invalid file format');
end
elseif pos==4
if regexp(container.dam_fun.filepath,'.xls','once') ||regexp(container.dam_fun.filepath,'.xlsx','once')
winopen(container.dam_fun.filepath);
elseif regexp(container.dam_fun.filepath,'.mat','once')
open(container.dam_fun.filepath);
else
msgbox('Invalid file format');
end
elseif pos==5
if regexp(container.measures.filepath,'.xls','once') ||regexp(container.measures.filepath,'.xlsx','once')
winopen(container.measures.filepath);
elseif regexp(container.measures.filepath,'.mat','once')
open(container.measures.filepath);
else
msgbox('Invalid file format');
end
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
global container
container.axis_ol=str2double(get(hObject,'String'));

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
global container
container.axis_or=str2double(get(hObject,'String'));

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
global container
container.axis_ul=str2double(get(hObject,'String'));

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
global container
container.axis_ur=str2double(get(hObject,'String'));

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
global container
container.set_axis=get(hObject,'Value');

% --- timestamp now.
function radiobutton9_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton9
global container
container.rb_9=get(hObject,'Value');
if container.rb_9==1
%container.timestamp=1;
set(handles.radiobutton10,'Value',0);
set(handles.radiobutton11,'Value',0);
set(handles.radiobutton12,'Value',0);
container.rb10=0;
container.rb11=0;
container.rb12=0;
end

% --- timestamp economic growth
function radiobutton10_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton10
global container
container.rb_10=get(hObject,'Value');
if container.rb_10==1
%container.timestamp=2;
set(handles.radiobutton9,'Value',0);
set(handles.radiobutton11,'Value',0);
set(handles.radiobutton12,'Value',0);
container.rb9=0;
container.rb11=0;
container.rb12=0;
end

% --- timestamp moderate climate change
function radiobutton11_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton11
global container
container.rb_11=get(hObject,'Value');
if container.rb_11==1
%container.timestamp=3;
set(handles.radiobutton9,'Value',0);
set(handles.radiobutton10,'Value',0);
set(handles.radiobutton12,'Value',0);
container.rb9=0;
container.rb10=0;
container.rb12=0;
end

% --- timestep extreme climate change
function radiobutton12_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton12
global container
container.rb_12=get(hObject,'Value');
if container.rb_12==1
%container.timestamp=4;
set(handles.radiobutton9,'Value',0);
set(handles.radiobutton11,'Value',0);
set(handles.radiobutton10,'Value',0);
container.rb9=0;
container.rb11=0;
container.rb10=0;
end


function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double
global container
container.markersize=str2double(get(handles.edit5,'String'));

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

% Peril selection
function popupmenu4_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu4

% --- Executes during object creation, after setting all properties.
global container
set(handles.popupmenu5,'Value',1);

% for i=1:length(container.measures_impact)
%     peril_list{i}=container.measures_impact(i).peril_ID;
% end
% container.peril_list=unique(peril_list);

set(handles.popupmenu4,'String',container.peril_list);
contents = cellstr(get(hObject,'String'));
selection=contents{get(hObject,'Value')};

if strcmp('flood',selection)
    container.rb_peril='FL';
elseif strcmp('tropical cyclone',selection)
    container.rb_peril='TC';
elseif strcmp('landslide',selection)
    container.rb_peril='LS';
elseif strcmp('storm surge',selection)
    container.rb_peril='LS';
elseif strcmp('earthquake',selection)
    container.rb_peril='EQ';
end
container.rb_peril=selection;

popupmenu5_Callback(hObject, eventdata, handles)
%listbox1_Callback(container.hobj, eventdata, handles);
%check_peril(hObject, eventdata, handles)
  
function popupmenu4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
set(hObject,'BackgroundColor','white');
end


% Scenario selection
function popupmenu5_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu5
global container
container.hobj = gcbo;
contents = cellstr(get(handles.popupmenu4,'String'));container.rb_peril=contents{get(handles.popupmenu4,'Value')};

%create the entries from hazard and entity
%recognizer
j=0;
for i=1:length(container.measures_impact)
    if strcmp(container.measures_impact(i).peril_ID,container.rb_peril)
    j=j+1;
    scenario_list{j,1}=container.measures_impact(i).scenario.name_simple;
    end
end
scenario_list=unique(scenario_list);

%select only scenarios that match the peril_ID chosen
container.rb_peril; 

%find position in combination with peril_ID
% selection_str
% rb_peril

set(handles.popupmenu5,'String',scenario_list);
contents = cellstr(get(handles.popupmenu5,'String'));
selection=contents{get(hObject,'Value')};

% if strcmp('flood',selection)
%     container.rb_peril='FL';
% elseif strcmp('tropical cyclone',selection)
%     container.rb_peril='TC';
% elseif strcmp('landslide',selection)
%     container.rb_peril='LS';
% elseif strcmp('storm surge',selection)
%     container.rb_peril='LS';
% elseif strcmp('earthquake',selection)
%     container.rb_peril='EQ';
% end

%check for peril_ID

for i=1:length(container.measures_impact)
    if strcmp(container.measures_impact(i).scenario.name_simple,selection) && strcmp(container.measures_impact(i).peril_ID,container.rb_peril)
        container.timestamp=i;
    end
end
    %update the selection from the listboxes
    %container.index_measures    = get(handles.listbox1,'Value');
    %container.index_categories  = get(handles.listbox2,'Value');

listbox1_Callback(container.hobj, eventdata, handles);
%listbox1_Callback(hObject, eventdata, handles);
%listbox2_Callback(hObject, eventdata, handles);
    


%for plotting get the position in the struct 'pos'

%check_peril(hObject, eventdata, handles)

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
