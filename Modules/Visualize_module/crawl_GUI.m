%   ============   Opening function    ==========================

function varargout = crawl_GUI(varargin)
% CRAWL_GUI MATLAB code for crawl_GUI.fig
%      CRAWL_GUI, by itself, creates a new CRAWL_GUI or raises the existing
%      singleton*.
%
%      H = CRAWL_GUI returns the handle to a new CRAWL_GUI or the handle to
%      the existing singleton*.
%
%      CRAWL_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CRAWL_GUI.M with the given input arguments.
%
%      CRAWL_GUI('Property','Value',...) creates a new CRAWL_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before crawl_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to crawl_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help crawl_GUI

% Last Modified by GUIDE v2.5 06-Oct-2015 14:56:52

% Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @crawl_GUI_OpeningFcn, ...
                       'gui_OutputFcn',  @crawl_GUI_OutputFcn, ...
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
end

% --- Executes just before crawl_GUI is made visible.
function crawl_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to crawl_GUI (see VARARGIN)
    global state h_plots
    % Choose default command line output for show_results_export
    handles.output = hObject;
    state = struct('db_name', '','db_path', '', 'attr_name', '', 'attr_path', '', ...
                            'neuron_x', [], 'neuron_y', [], 'attr_x', [], 'attr_y', [], 'worm_z', [], ...
                            'worm_ratio', [], 'worm_raw', [], 'frame', 0, 'attrOn', false,...
                            'traceOn', false, 'delta', 0, 'head_on', true, 'trace_length', 50, ...
                            'pixToStage', 4);
    h_plots = struct('worm_cont', plot(1:3, 1:3));
    hold on;
    h_plots.worm_scat = scatter(1:3, 1:3);
    h_plots.worm_head = scatter(1, 1, 300, 'x', 'black');
    h_plots.attr = scatter(1:3, ones(1,3)*10);
    h_plots.slider =  handle.listener(handles.slider,'ActionEvent',{@slider_Callback,handles});
    % Update handles structure
    guidata(hObject, handles);

    % This sets up the initial plot - only do when we are invisible
    % so window can get raised using crawl_GUI.
    

% UIWAIT makes crawl_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = crawl_GUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

%========================   Callbacks   ===========================

% --- Executes on slider movement.
function slider_Callback(hObject, eventdata, handles)
    global state h_plots
% hObject    handle to slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    value = floor(get(handles.slider,'Value'));
    delete([h_plots.worm_scat h_plots.worm_cont h_plots.worm_head]);
    bottom_lim = 1;
    if(state.traceOn)
        bottom_lim = max(1,value - state.trace_length);
    end
    h_plots.worm_cont = plot(handles.axes1, state.neuron_x(bottom_lim:value), state.neuron_y(bottom_lim:value));
    h_plots.worm_scat = scatter(handles.axes1, state.neuron_x(bottom_lim:value), ...
                                state.neuron_y(bottom_lim:value), [], state.worm_ratio_fluo(bottom_lim:value)', 'filled');
    h_plots.worm_head = scatter(handles.axes1, state.head_x(value - state.delta), state.head_y(value - state.delta), 300, 'x', 'black');
    state.frame = value;
    set(handles.percents_text, 'String', [num2str(round(100*value/(length(state.neuron_y)))) '%   |   frame: ' num2str(8*(value-1) + 1) '   |   ' num2str(value)]);
end

% --- Executes on button press in loadMovie_button.
function loadMovie_button_Callback(hObject, eventdata, handles)
% hObject    handle to loadMovie_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)    [handles.state.db_name, handles.state.db_path] = uigetfile('*.mat','Select DB file');
    global state
    
    [db_name, db_path] = uigetfile('*.mat', 'Select DB file','MultiSelect','on');
    if(~(iscell(db_name)) && (length(db_name) == 1))
        return;
    end
    state.db_name=db_name; state.db_path=db_path; state.neuron_x=[]; state.neuron_y=[]; state.worm_raw_fluo=[]; state.head_x=[]; state.head_y=[];
    cd(db_path);
    if(iscell(db_name))
        for i = 1:length(db_name)
            [neuron_x, neuron_y, worm_raw_fluo, head_x, head_y] = get_data_from_movie(handles, db_path, db_name{i});
            state.neuron_x=[state.neuron_x neuron_x];
            state.neuron_y=[state.neuron_y neuron_y];
            state.worm_raw_fluo=[state.worm_raw_fluo worm_raw_fluo];
            state.head_x=[state.head_x head_x];
            state.head_y=[state.head_y head_y];
        end
    else
        [state.neuron_x, state.neuron_y, state.worm_raw_fluo, state.head_x, state.head_y] = get_data_from_movie(handles, db_path, db_name);
    end
    recalc_ratio();
    % plot results
    replot(handles);
end

function replot(handles)
    global state h_plots
    
    delete([h_plots.worm_cont h_plots.worm_scat h_plots.worm_head]);
    rescale();
    h_plots.worm_cont = plot(state.neuron_x, state.neuron_y);
    h_plots.worm_scat = scatter(state.neuron_x, state.neuron_y, [], state.worm_ratio_fluo, 'filled');
    h_plots.worm_head = scatter(handles.axes1, state.head_x(end - state.delta), state.head_y(end - state.delta), 300, 'x', 'black');
    set(gca,'CLim',[-50 100]);
    
    set(handles.movie_path, 'String', state.db_path);
    set(handles.movie_name, 'String', state.db_name);
    set(handles.slider, 'Max', length(state.neuron_x));
    set(handles.slider, 'Min', 1);
    set(handles.slider, 'Value', 1);
    set(handles.message_text, 'String', 'Movie Updated!!!');
end

function recalc_ratio()
    global state
    sorted = sort(state.worm_raw_fluo);
    
    base = mean(sorted(1:round(end/5)));
    state.worm_ratio_fluo = (state.worm_raw_fluo - base) / base * 100;
%     state.worm_ratio_fluo = (state.worm_ratio_fluo - min(state.worm_ratio_fluo))/(max(state.worm_ratio_fluo)-min(state.worm_ratio_fluo));
end

function [neuron_x, neuron_y, worm_raw_n, head_x, head_y] = get_data_from_movie(handles, db_path, db_name)
%     [db_name, db_path] = uigetfile('*.mat', 'Select DB file','MultiSelect','on');
%     if(db_name == 0)
%         db_name=0; db_path=0; neuron_x=0; neuron_y=0; worm_raw_n=0; head_x=0; head_y=0;
%         return;
%     end
    s = load([db_path db_name]);
    db_reduced = s.db_reduced;
    neuron_x = db_reduced.neuron_point_reduced(1,:);
    neuron_y = db_reduced.neuron_point_reduced(2,:);
    worm_raw_n = db_reduced.raw_fluo_reduced;
    head_x = db_reduced.head_point_reduced(1,:);
    head_y = db_reduced.head_point_reduced(2,:);   
    set(handles.movie_path, 'String', db_path);
    set(handles.movie_name, 'String', db_name);
end

% --- Executes on button press in load_attr_button.
function load_attr_button_Callback(hObject, eventdata, handles)
% hObject    handle to load_attr_button_Callback (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global state h_plots
    [file_name, path] = uigetfile(...
        {'*.mat',  'XY file of a attr. movie (*.m)'; ...
        '*.tif','Raw attr. movie (*.tif)'}...
        , 'Select attr movie');
    if(file_name == 0)
        return;
    end
    state.attr_path = path;
    state.attr_name = file_name;
    if(strcmp(file_name(end-2:end), 'mat'))
        load(file_name);
        X = Data.X;
        Y = Data.Y;
    else
        X = getDataFromTif( [path file_name] , 'X');
        Y = getDataFromTif( [path file_name] , 'Y');
    end
    
%         scatter3(X(X ~= 0), Y(X ~= 0), Y(X ~= 0)*0+6500,'black', 'filled');
    delete(h_plots.attr);
    state.attr_x = (X(X ~= 0)) + (512/2) * state.pixToStage;    % frame capturing attr keeps it at the center - so all attr XY sould be shifterd \\\
    state.attr_y = (Y(X ~= 0)) - (512/2) * state.pixToStage;
    h_plots.attr = scatter(state.attr_x, state.attr_y, 'black', 'filled');
%     caxis([-50 200]);

    state.attrOn = true;
    rescale()
    
    set(handles.attr_name, 'String', [path file_name]);
    set(handles.message_text, 'String', '===attr loaded!===');
    pause(1);
    set(handles.message_text, 'String', 'attr loaded!');
end

% --- Executes on button press in Custom_button.
function Custom_button_Callback(hObject, eventdata, handles)
    global state h_plots
% hObject    handle to Custom_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%      hLstn = handle.listener(h,'ActionEvent',@sliderCallback);
    disp(num2str(state.delta));
end

% --- Executes on button press in add_next_button.
function add_button_Callback(hObject, eventdata, handles)
% hObject    handle to add_next_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global state
    tag = get(hObject,'Tag');
    [db_name, db_path] = uigetfile('*.mat', 'Select DB file','MultiSelect','on');
    if(~(iscell(db_name)) && (length(db_name) == 0))
        return;
    end
    if(iscell(db_name))
        for i = 1:length(db_name)
            [neuron_x, neuron_y, worm_raw_fluo, head_x, head_y] = get_data_from_movie(handles, db_path, db_name{i});
            state.db_name = db_name{i};
            grow_arrays(neuron_x, neuron_y, head_x, head_y, worm_raw_fluo, tag);
        end
        
    else
        [neuron_x, neuron_y, worm_raw_fluo, head_x, head_y] = get_data_from_movie(handles, db_path, db_name);
        state.db_name = db_name;
        grow_arrays(neuron_x, neuron_y, head_x, head_y, worm_raw_fluo, tag);
    end
    
    recalc_ratio();
    replot(handles);
end

function grow_arrays(neuron_x, neuron_y, head_x, head_y, worm_raw_fluo, tag)
    global state
    
    if(strcmp(tag,'add_next_button'))   % add next movie
        state.neuron_x = [state.neuron_x neuron_x];
        state.neuron_y = [state.neuron_y neuron_y];
        state.head_x = [state.head_x head_x];
        state.head_y = [state.head_y head_y];
        state.worm_raw_fluo = [state.worm_raw_fluo worm_raw_fluo];
    else                                % add prev movie
        state.neuron_x = [neuron_x state.neuron_x];
        state.neuron_y = [neuron_y state.neuron_y];
        state.head_x = [head_x state.head_x];
        state.head_y = [head_y state.head_y];
        state.worm_raw_fluo = [worm_raw_fluo state.worm_raw_fluo];
    end
end

function rescale()
    global h_plots state
    h_plots.left = min(state.neuron_y)-2000;
    h_plots.right = max(state.neuron_y)+2000;
    h_plots.down = min(state.neuron_x)-2000;
    h_plots.up = max(state.neuron_x)+2000;
    
    if(state.attrOn)
        h_plots.left = min(min(state.neuron_y),min(state.attr_y))-2000;
        h_plots.right = max(max(state.neuron_y),max(state.attr_y))+2000;
        h_plots.down = min(min(state.neuron_x),min(state.attr_x))-2000;
        h_plots.up = max(max(state.neuron_x),max(state.attr_x))+2000;
    end
    height = h_plots.up - h_plots.down;
    width = h_plots.right-h_plots.left;
    if (height > width)
        h_plots.right = h_plots.left + height;
    else
        h_plots.up = h_plots.down + width;
    end
    axis([h_plots.down h_plots.up h_plots.left h_plots.right]);
    
end

% --- Executes on button press in trace_button.
function trace_Callback(hObject, eventdata, handles)
% hObject    handle to trace_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global state
    if(strcmp(get(hObject,'Tag'), 'trace_up'))
        state.trace_length = state.trace_length + 5;
        slider_Callback(hObject, eventdata, handles);
        return;
    elseif(strcmp(get(hObject,'Tag'), 'trace_down'))
        state.trace_length = max(0, state.trace_length - 5);
        slider_Callback(hObject, eventdata, handles);
        return;
    end
    
    if(strcmp(get(hObject,'String'),'Full'))
        set(handles.message_text, 'String', 'Showing trace');
        set(hObject,'String','Trace');
    else
        set(handles.message_text, 'String', 'Showing full');
        set(hObject,'String','Full');
    end
    state.traceOn = ~state.traceOn;
    slider_Callback(hObject, eventdata, handles);
end

% --- Executes on button press in remove_button.
function remove_button_Callback(hObject, eventdata, handles)
% hObject    handle to remove_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global state
    state.neuron_x = state.neuron_x(1:end-125);
    state.neuron_y = state.neuron_y(1:end-125);
    state.head_x = state.head_x(1:end-125);
    state.head_y = state.head_y(1:end-125);
    state.worm_ratio_fluo = state.worm_ratio_fluo(1:end-125);
    replot(handles);
end

function head_Callback(hObject, eventdata, handles)
    global state h_plots
    str = get(hObject,'Tag');
    if(strcmp(str, 'head_button'))
        if(state.head_on)
            set(handles.head_button,'String','Show head');
        else
            set(handles.head_button,'String','Hide head');
        end
        state.head_on = ~state.head_on;
    elseif(strcmp(str, 'head_less'))
        state.delta = state.delta - 1;
    else    %'head_more'
        state.delta = state.delta + 1;
    end
    set(handles.head_text, 'String', num2str(state.delta));
    slider_Callback(hObject, eventdata, handles);
end
%========================   CreateFunc (Junk)   ===========================

% --- Executes during object creation, after setting all properties.
function slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
    global state h_plots
    
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end
