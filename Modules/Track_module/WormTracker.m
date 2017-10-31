%%% This file contains the call-back function that run as WormTraccker.fig
%	GUI is activated.
% 
%   !!!    THIS MODULE AUTOMATICALY OPERATES THE HARDWARE - PLEASE READ
%          "README :: HARDWARE" SECTION TO AVOID HARM TO YOUR SYSTEM        !!!
%
%	Gui initialization steps:
%       0.  Open Matlab in "Administrator mode" (right click on Matlab icon, 'Run as administrator')
%       1.  Run "WormTracker" in Command Window  -OR -  Right click on WormTracker.fig, select "Open in GUIDE"
%       2.  Turn on all your hardware (must be connected: camera, LED, Olympus IX83, prior stage)
%       3.  On the Gui, press Load HW (HardWare)
%           If hand-shake with HW was successful, all other buttons will be
%           activated.
%       4.  Press "Start real time picture"
%       5.  Find the worm, change to 10x, adjust focus, turn on LEDs
%       6.  Press "start record" or "start track", or both...
%       7.  Have fun!
%
%   Output of the module:
%       The acquired movie will be stored in the same folder, under the
%       name GUI_created.tif, or if the movie is above 2000 frames second chapter will be created: GUI_created_2.tif.
%       If after the first movie you pressed "stop record" and again "start rec", second session will be
%       crated with the following file names: GUI_created_s2.tif, GUI_created_s2_2.tif...
%       
%       Data regarding the movie parameters is stored in the tiff headers - can be extracted using the
%       "getDataFromTif.m". For each frame the next is stored {X,Y,Z,TimeStamp}.
%       First frame contains more data: {Em, Exp, WormStrain}


function varargout = WormTracker(varargin)
    % WORMTRACKER MATLAB code for WormTracker.fig
    %      WORMTRACKER, by itself, creates a new WORMTRACKER or raises the existing
    %      singleton*.
    %
    %      H = WORMTRACKER returns the handle to a new WORMTRACKER or the handle to
    %      the existing singleton*.
    %
    %      WORMTRACKER('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in WORMTRACKER.M with the given input arguments.
    %
    %      WORMTRACKER('Property','Value',...) creates a new WORMTRACKER or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before WormTracker_OpeningFcn gets called.  An
    %      unrecognised property name or invalid value makes property application
    %      stop.  All inputs are passed to WormTracker_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help WormTracker

    % Last Modified by GUIDE v2.5 04-Dec-2015 16:32:55

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @WormTracker_OpeningFcn, ...
                       'gui_OutputFcn',  @WormTracker_OutputFcn, ...
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

%=============      GUI main functions      =============

%	Executes just before WormTracker is made visible.
function WormTracker_OpeningFcn(hObject, eventdata, handles, varargin)
    global filming last_stamp
    filming = struct('PixToStage', 1.6,'isLive', 0, 'track_rad', 50,...
                     'DV_mode', 0 , 'isRecording', false, 'isTracking', false,...
                     'is_attr_Recording', false, 'num_frames', 0, 'maxCirc', false, ...
                     'mm_bar_text', '0.25 mm (10X Lens)', 'mm_bar_width', 7, 'mm_bar_length', 156,...
                     'mm_bar_dist', 10);
    reset_DB();
    last_stamp = struct('cycleID', 0, 'Head_point', [216,216],...
                        'Loaded', false, 'LED', [0,0,0,0], 'Mult', 1);
    import mmcorej.*;
    mmc = CMMCore;
    handles.mmc = mmc;
    filming.frame = imread('GUI_cover.tif',1);
    filming.thr = round(65535/max(max(filming.frame)));
    filming.Handles = struct('maxCircle',0);
    filming.loc_db = struct('up', [266113 156553], 'down', [266113 106125],...
                            'left', [241377 131744], 'right', [291423 133654], ...
                            'Attr_array', []);
    axis(handles.picture_area);
    handles.plot = imshow(filming.frame*filming.thr, 'Parent', handles.picture_area);
    maxPoints = max(max(filming.frame));
    [x,y] = find(maxPoints(1) == filming.frame);
    hold on
    filming.Handles.maxCircle = plot(handles.picture_area, y,x,'o','Color','black','MarkerSize',1, 'LineWidth',1);
    [h,w] = size(filming.frame);
    last_stamp.frame_X = h/2;
    last_stamp.frame_Y = w/2;
    filming.Handles.white_circ = rectangle('Position',[10 10 50 50],'Curvature',[1,1], 'FaceColor','w');
    filming.Handles.head = plot(35,35,'r*','MarkerSize', 2);
    filming.Handles.red_circle_handle = plot(handles.picture_area, h/2,w/2,'ro','MarkerSize',70, 'LineWidth',1);
    filming.Handles.attr_h = plot(handles.picture_area, 9,9,'o','Color','black','MarkerSize',1, 'LineWidth',1);
    filming.Handles.mm_bar_rect = rectangle('Position',[filming.mm_bar_dist (512-filming.mm_bar_width/2-filming.mm_bar_dist)...
                                                        filming.mm_bar_length filming.mm_bar_width], 'FaceColor','w');
    filming.Handles.mm_bar_text = text(filming.mm_bar_length/2-filming.mm_bar_dist-5, 512-filming.mm_bar_width-filming.mm_bar_dist, filming.mm_bar_text, 'Color', 'w');
    
    handles.timer_getFrame = timer('ExecutionMode','fixedRate',...
                        'Period', 0.09,...
                        'TimerFcn', {@getFrame,handles},...
                        'BusyMode','drop');
                    
    handles.output = hObject;
    handles.active_buttons = [handles.maxCirc handles.snap_button handles.attr_button...
        handles.snap_name_text handles.movie_name_text handles.attr_movie_button...
        handles.custom_button handles.start_button handles.refresh_button...
        handles.shut2_button handles.shut1_button handles.mult_go handles.exp_down handles.exp_up...
        handles.EM_up handles.EM_down handles.EM_go handles.DIC_button handles.mCherry_button...
        handles.GCaMP_button handles.DV_button handles.y_go handles.x_go handles.z_go...
        handles.vision_menu handles.red_on handles.red_go handles.green_on...
        handles.green_go handles.DIC_go handles.obj_menu handles.mult_up handles.mult_down];
    guidata(hObject, handles);
end

%	Outputs from this function are returned to the command line.
function varargout = WormTracker_OutputFcn(hObject, eventdata, handles) 
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;
end

% Reset the tiff acquisition DB.
function reset_DB()
    global filming tiff_creation
    filming.num_frames = 0;
    filming.stamp_cycle = 0;

    tiff_creation.file_name = 'WormT';
    tiff_creation.WormType = 'WormT.tif';
    tiff_creation.tiff_handle = 0;
    tiff_creation.Software = 'WormTracker.m';
    tiff_creation.SessionSerial = 1;
    tiff_creation.MovieSerial = 1;
    tiff_creation.file_name_stat = 'WormT';
    tiff_creation.tiff_size = 1000;
end

%=============      TIMER operation       =============

%   Call back function for the timer - each iteration a frame from the
%   camera is grabed - if "rec" mode is on it will be appended to the tiff,
%   if "track" mode is on the stage will move in order to minimize the
%   distance from the neuron to the frame center.
function getFrame(obj,event,handles)
%   TIMER-1     runs with first start on a big button.
    global filming last_stamp data
    
    img = typecast(handles.mmc.getLastImage(), 'uint16');
    img = reshape(img, [512, 512]);
    filming.frame = transpose(img);
%%%% Manual XY aquisition through RS-232 port - SLOWER!
%%%     handles.mmc.setSerialPortCommand('COM1', '', char(13));
%%%     position = handles.mmc.getSerialPortAnswer('COM1', char(13));
%%%     position = str2num(position)/25;    % conversion between stage units - 25!
%%%     last_stamp.stage_X = position(1);
%%%     last_stamp.stage_Y = position(2);
    position = handles.mmc.getXYStagePosition('XYStage');
    last_stamp.stage_X = position.getX;
    last_stamp.stage_Y = position.getY;
    if filming.isTracking && (filming.stamp_cycle ~= 0)
        move_stage(handles);
    end
    set(handles.plot,'CData',filming.frame*last_stamp.Mult);
    if filming.maxCirc
        delete(filming.Handles.maxCircle);
        maxPoints = max(max(filming.frame));
        [x,y] = find(maxPoints(1) == filming.frame);
        filming.Handles.maxCircle = plot(handles.picture_area,y,x,'bo','MarkerSize',40, 'LineWidth',1);
    end
    
    last_stamp.Z = handles.mmc.getPosition('FocusDrive');
    
    if filming.isRecording
        last_stamp.Time = toc;
        append_tiff();
    end
    update_GUI(handles);
    filming.stamp_cycle = filming.stamp_cycle + 1;
    if(filming.stamp_cycle > 7)
        filming.stamp_cycle = 0;
    end
    

    
    % create array of attractant
    if(filming.is_attr_Recording)
        attr_cuurent_x = 10 + 50*(last_stamp.stage_X - filming.loc_db.left(1))/abs(filming.loc_db.right(1) - filming.loc_db.left(1));
        attr_cuurent_y = 60 - 50*(last_stamp.stage_Y - filming.loc_db.down(2))/abs(filming.loc_db.down(2) - filming.loc_db.up(2));
        filming.loc_db.Attr_array = [filming.loc_db.Attr_array [attr_cuurent_x; attr_cuurent_y]];
        delete(filming.Handles.attr_h);
        filming.Handles.attr_h = plot(handles.picture_area, filming.loc_db.Attr_array(1,:), filming.loc_db.Attr_array(2,:) ,'g*','MarkerSize', 2);
    end
    
    % update red dot location (left upper corner white circle)
    if (last_stamp.stage_X ~= 0)
        delete(filming.Handles.head);
        draw_x = 10 + 50*(last_stamp.stage_X - filming.loc_db.left(1))/abs(filming.loc_db.right(1) - filming.loc_db.left(1));
        draw_y = 60 - 50*(last_stamp.stage_Y - filming.loc_db.down(2))/abs(filming.loc_db.down(2) - filming.loc_db.up(2));
        filming.Handles.head = plot(handles.picture_area, draw_x, draw_y ,'r*','MarkerSize', 2);
    end
end



%=============      Live picture and tracking operations       =============

%   Callback behind the "start real time" button. 
function start_live_Callback(hObject, eventdata, handles)
% first button press
    global last_stamp filming
    % setup for DIC
    
    get_hw_params(handles)
    update_full_gui(handles);
    
    set(handles.shut1_button, 'Value',0);
    set(handles.shut1_button, 'Value',1);
    set(handles.DIC_button, 'Value',0);
    set(handles.DIC_button, 'Value',1);
    
    handles.mmc.startContinuousSequenceAcquisition(last_stamp.Exp);
    set(hObject, 'Visible','off');
    set(handles.stop_live_button, 'Visible','on');
    set(handles.startTrack_button, 'Visible','on');
    set(handles.startRec_button, 'Visible','on');
    set(handles.DVmode_button, 'Visible','on');
    set(handles.update_text, 'String','--- real time ---');
    start(handles.timer_getFrame);
    filming.isLive = 1;
end

%   Callback behind the "start real time" button.   
function stop_live_button_Callback(hObject, eventdata, handles)
    global filming
    stop(handles.timer_getFrame);
    
    if filming.isTracking
        start_track_Callback(handles.startTrack_button, eventdata, handles);
        filming.isTracking = 0;
    end
    if filming.isRecording
        stopRec_Callback(handles.startRec_button, eventdata, handles);
        filming.isRecording = 0;
    end
    
    handles.mmc.stopSequenceAcquisition();
    set(handles.startRec_button, 'Visible','off');
    set(handles.startRec_button, 'Visible','off');
    set(handles.stop_live_button, 'Visible','off');
    set(handles.startTrack_button, 'Visible','off');
    set(handles.DVmode_button, 'Visible','off');
    set(handles.start_button, 'Visible','on');
    set(handles.update_text, 'String','--- RT Stopped ---');
    filming.isLive = 0;
end

%   Callback behind the "start track" button. 
function start_track_Callback(hObject, eventdata, handles)
    global filming last_stamp
    val = ~filming.isTracking;
    filming.isTracking = val;
    if val % start autotrack
        set(hObject, 'String','<html>Stop<br>track');
        set(handles.update_text, 'String','--- tracking!! ---');
        set(handles.startTrack_button, 'BackGroundColor', [0.902 0.553 0.208]);
        set(hObject, 'Value', 0);
        set(hObject, 'Value', 1);
    else
        set(hObject, 'String', '<html>Start<br>track');
        set(handles.update_text, 'String', '--- tracking stopped ---');
        %pause(0.2);
        handles.mmc.stop('XYStage');
        handles.mmc.stop('XYStage');
        set(handles.startTrack_button, 'BackGroundColor', [0.94, 0.94, 0.94]);
        set(hObject, 'Value', 1);
        set(hObject, 'Value', 0);
        last_stamp.frame_X = 512/(2*(1 + filming.DV_mode));
        last_stamp.frame_Y = 512/2;
        delete([filming.Handles.red_circle_handle filming.Handles.head]);
        filming.Handles.red_circle_handle = plot(last_stamp.frame_X, last_stamp.frame_Y, 'ro', 'MarkerSize', 70, 'LineWidth',1);
        filming.Handles.head = plot(handles.picture_area, 35,35,'r*','MarkerSize', 2);
    end
    
end

%	Function that calculates the {dX, dY} from the frame center, and moves
%	the stage accordingly. Called when "tracking" mode is on.
%	movement of the stage is based on vector math: {direction, speed}.

function move_stage(handles)
% computes a single shift of the [X , Y] for the stage
    global filming last_stamp
    rect_pic = getSubPicture(filming.frame, last_stamp.frame_X ,last_stamp.frame_Y , filming.track_rad, true, 16);
    [cols,rows] = find(rect_pic == max(max(medfilt2(rect_pic, [3 3]))));
    new_X = last_stamp.frame_X -filming.track_rad + rows(1) - 1;
    new_Y = last_stamp.frame_Y -filming.track_rad + cols(1) - 1;
    new_X = min(511 - filming.track_rad, max(filming.track_rad + 1, abs(new_X)));
    new_Y = min(511 - filming.track_rad, max(filming.track_rad + 1, abs(new_Y)));
    delete(filming.Handles.red_circle_handle);
    filming.Handles.red_circle_handle = plot(handles.picture_area, new_X, new_Y, 'ro', 'MarkerSize', 70, 'LineWidth',1); 
    %dx = -filming.track_rad+rows(1)-1;            %   set the Point to the brightest spot
    %dy = -filming.track_rad+cols(1)-1;
    %     handles.mmc.setRelativeXYPosition('XYStage',dx*filming.PixToStage, -dy*filming.PixToStage);
    
    x = (new_X-512/(2*(1 + filming.DV_mode)))*filming.PixToStage;
%     x = (new_X-512/2)*filming.PixToStage;
    y = (new_Y - 512/2)*filming.PixToStage;
    
%     const = 1 + filming.DV_mode;    % faster response of the stage if frame is narrowed to DV mode.
    const = 3;
    handles.mmc.setSerialPortCommand('COM1', ['VS ' num2str(-x*const) ' ' num2str(y*const)], '');
    
    last_stamp.frame_X = new_X;
    last_stamp.frame_Y = new_Y;
end



%=============      Record operations       =============

%   Callback behind the "start rec" button.
function startRec_Callback(hObject, eventdata, handles)

    global filming tiff_creation
    filming.num_frames =    0;
    tiff_creation.MovieSerial = 1;
    tic;
    
    set(handles.startRec_button, 'String', '<html>Stop<br>Recording');
    set(handles.startRec_button, 'BackGroundColor', [0.757 0.867 0.776]);
    set(handles.update_text, 'String', '--- RECORDING ---');
    set(handles.startRec_button, 'CallBack', @(hObject,eventdata)WormTracker('stopRec_Callback', hObject,eventdata,guidata(hObject)));
    
    % initialize the tiff
    tiff_creation.tiff_handle = Tiff([tiff_creation.file_name '_' num2str(tiff_creation.MovieSerial) '.tif'], 'w');
    filming.isRecording =   true;
    disp(['=========    Creating .tif file in dir:  ' cd() '    ==========']);
end

%   Callback behind the "start track" button.
function stopRec_Callback(hObject, eventdata, handles)
    global filming tiff_creation last_stamp
    filming.isRecording = false;   
    set(handles.startRec_button, 'String','<html>Start<br>Rec');
    set(handles.startRec_button, 'BackGroundColor',[0.94, 0.94, 0.94]);
    set(handles.update_text, 'String','--- Tracking ---');
    
    set(handles.startRec_button, 'CallBack',@(hObject,eventdata)WormTracker('startRec_Callback', hObject,eventdata,guidata(hObject)))
    tiff_creation.tiff_handle.close();
    tiff_creation.SessionSerial = tiff_creation.SessionSerial + 1;
    tiff_creation.file_name = [tiff_creation.file_name_stat '_s' num2str(tiff_creation.SessionSerial)];
    last_stamp.Time = 0;
end

%   function that deals with the tiff creation - O(n^2) complexity when n =
%   ||tiff||. Keep your tiff's small, up to 2000 frames by the
%   'tiff_creation.tiff_size' param init.
function append_tiff()
    global filming tiff_creation last_stamp
    
    % check if a new movie file should be created
    isNewFile = (mod(filming.num_frames , tiff_creation.tiff_size) == 0);
    if (isNewFile)
        tiff_creation.MovieSerial = (filming.num_frames / tiff_creation.tiff_size) + 1;
    end
    
    if(isNewFile || (filming.num_frames == 0))
        % Don't recreate file on first frame
        if (filming.num_frames ~= 0)
            tiff_creation.tiff_handle.close();
            tiff_creation.tiff_handle = Tiff([tiff_creation.file_name '_' num2str(tiff_creation.MovieSerial) '.tif'],'w');
        end
        tiff_creation.tiff_handle.setTag('XResolution', last_stamp.Exp);
        tiff_creation.tiff_handle.setTag('YResolution', last_stamp.EM);
        tiff_creation.tiff_handle.setTag('Software', tiff_creation.Software);
        tiff_creation.tiff_handle.setTag('Artist', tiff_creation.WormType);
        disp('--------- New File created! -----------')
    else
        writeDirectory(tiff_creation.tiff_handle);  % create new DIR inside the multi-tiff file
    end
    
    % write the header of a image
    tiff_creation.tiff_handle.setTag('ImageLength', 512.00);
    tiff_creation.tiff_handle.setTag('ImageWidth', 512.00);
    tiff_creation.tiff_handle.setTag('Photometric', Tiff.Photometric.MinIsBlack);
    tiff_creation.tiff_handle.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky)
    tiff_creation.tiff_handle.setTag('BitsPerSample', 16);
    tagStruct.DateTime = num2str(last_stamp.Time);  
    tagStruct.XPosition = last_stamp.stage_X;             
    tagStruct.YPosition = last_stamp.stage_Y;             
    tagStruct.HostComputer = num2str(last_stamp.Z);
    setTag(tiff_creation.tiff_handle, tagStruct)
       
    tiff_creation.tiff_handle.write(filming.frame);
    filming.num_frames = filming.num_frames + 1;
end


%=============      Gui + HW interactions       =============

%	Acquire data from the hardware
function get_hw_params(handles)    
%   creates array of the next data:     [X,Y,Z,time,Em,Ex,light]
    global last_stamp
    position = handles.mmc.getXYStagePosition('XYStage');
    last_stamp.stage_X = position.getX;
    last_stamp.stage_Y = position.getY;
    last_stamp.Z =          handles.mmc.getPosition('FocusDrive');
    last_stamp.Shutter =    [str2num(handles.mmc.getProperty('DiaShutter','State')),str2num(handles.mmc.getProperty('EpiShutter 1','State'))];
    last_stamp.Objective =  1 + str2num(handles.mmc.getProperty('Objective','State'));
    last_stamp.Brightness = str2num(handles.mmc.getProperty('TransmittedIllumination 1','Brightness'));
    last_stamp.Filter =     handles.mmc.getProperty('Dichroic 1','Label');
    last_stamp.EM =         str2num(handles.mmc.getProperty('Camera-1','MultiplierGain'));
    last_stamp.Exp =        str2num(handles.mmc.getProperty('Camera-1','Exposure'));
    last_stamp.Vision =     1 + str2num(handles.mmc.getProperty('Light Path','State'));
    last_stamp.LED(1) =     str2num(handles.mmc.getProperty('LED1 Device','L.09 On/Off State (1=On 0=Off)'));
    last_stamp.LED(2) =     str2num(handles.mmc.getProperty('LED1 Device','L.10 Intensity (0.0 or 5.0 - 100.0)%'));
    last_stamp.LED(3) =     str2num(handles.mmc.getProperty('LED4 Device','L.09 On/Off State (1=On 0=Off)'));
    last_stamp.LED(4) =     str2num(handles.mmc.getProperty('LED4 Device','L.10 Intensity (0.0 or 5.0 - 100.0)%'));
    last_stamp.Inv    =     str2num(handles.mmc.getProperty('Camera-1','TransposeMirrorX'));
end

function update_GUI(handles)
    global last_stamp filming
    x = last_stamp.stage_X;
    y = last_stamp.stage_Y;
    z = last_stamp.Z;
    %clc = datestr(last_stamp.Time,'MM:SS.FFF');
    set(handles.z_input, 'String',z);
    if(x ~= 0)
        set(handles.x_input, 'String',x);
        set(handles.y_input, 'String',y);
    end
    
    if filming.isRecording
        set(handles.time_text, 'String',[datestr(datenum(0,0,0,0,0,toc),'HH:MM:SS') '    |    ' num2str(filming.num_frames) ]);
    else
        set(handles.time_text, 'String', ['---    |    ' num2str(filming.num_frames) ]);
    end
    set(handles.EM_input, 'String',last_stamp.EM);
    set(handles.exp_input, 'String',last_stamp.Exp);
end

function update_full_gui(handles)
    global last_stamp filming
    update_GUI(handles);
    set(handles.mult_input, 'String', last_stamp.Mult);
    set(handles.red_input, 'String', last_stamp.LED(4));
    set(handles.green_input, 'String', last_stamp.LED(2));
    set(handles.DIC_input, 'String', last_stamp.Brightness);
    set(handles.vision_menu, 'value', last_stamp.Vision);
    obj_value = last_stamp.Objective;
    set(handles.obj_menu, 'value', obj_value);
    if(obj_value == 1)
        filming.mm_bar_text = '1 mm (4X Lens)';
        filming.mm_bar_length = 250;
        
        
        delete([filming.Handles.mm_bar_rect filming.Handles.mm_bar_text]);
        filming.Handles.mm_bar_rect = rectangle('Position',[filming.mm_bar_dist ...
                                                           (512-filming.mm_bar_width/2-filming.mm_bar_dist)...
                                                            filming.mm_bar_length filming.mm_bar_width], 'FaceColor','w');
        filming.Handles.mm_bar_text = text(filming.mm_bar_length/2-filming.mm_bar_dist, ...
                                           512-filming.mm_bar_width-filming.mm_bar_dist, ...
                                           filming.mm_bar_text, 'Color', 'w');
    end
    
    
end



%=============      Update graphics       =============


%	Executes on button press in load_button.
function load_button_Callback(hObject, eventdata, handles)

    global last_stamp
    if last_stamp.Loaded
        disp('un-mounting HW');
        handles.mmc.unloadAllDevices();
        last_stamp.Loaded = ~last_stamp.Loaded;
        set(handles.load_button, 'String','Load HW');
        set(handles.update_text, 'String','--- HW Released ---');
        set(handles.time_text, 'String','time    |    frames');
        set(handles.update_text, 'ForegroundColor','green');
        pause(0.5);
        set(handles.update_text, 'ForegroundColor','yellow');
        
        set(handles.green_on, 'Value',1);
        set(handles.red_on, 'Value',1);
        set(handles.red_on, 'Value',0);
        set(handles.green_on, 'Value',0);
        
        disable_buttons('off', handles);
    else
        handles.mmc.loadSystemConfiguration ('C:\Program Files\Micro-Manager-1.4\Tracker_config.cfg');
        disp('mounting HW');
        last_stamp.Loaded = ~last_stamp.Loaded;
        get_hw_params(handles);
        update_GUI(handles);
        set(handles.load_button, 'String','<html>Release<br>HW');
        set(handles.update_text, 'String','--- HW loaded ---');
        set(handles.update_text, 'ForegroundColor','green');
        pause(0.5);
        set(handles.update_text, 'ForegroundColor','yellow');
        last_stamp.Time = 0;
        
        disable_buttons('on', handles); % Activation of all buttons
        initHWParams(handles);
    end
end

%	Updates the GUI buttons and text areas.
function initHWParams(handles)

%     handles.mmc.setXYPosition('XYStage',39730,61400);
%     handles.mmc.setPosition('FocusDrive',6500);
    handles.mmc.setProperty('DiaShutter','State',1);
    handles.mmc.setProperty('EpiShutter 1','State',0);
    handles.mmc.setProperty('Camera-1','MultiplierGain',200);
    handles.mmc.setProperty('Camera-1','Exposure',30);
    handles.mmc.setProperty('Dichroic 1','Label','8-IX3-FDICT');
    handles.mmc.setProperty('TransmittedIllumination 1','Brightness',45);
    handles.mmc.setProperty('Objective','Label','2-UPLSAPO10X2');
    handles.mmc.setProperty('Objective','State',0);
    handles.mmc.setProperty('Light Path','State',0);
    
    get_hw_params(handles);
    update_full_gui(handles);
end

%	Function that disables buttons - called when hardware is not initialized or unmounted.
function disable_buttons(setOn, handles)
%   parameter setOn = {'on','off'}

    for i = 1:length(handles.active_buttons)
    	curr = handles.active_buttons(i);
    	set(curr, 'Enable', setOn);
    end    
end

%	Executes on button press in shut1_button.
function shut1_button_Callback(hObject, eventdata, handles)
    global last_stamp
    if ~assert(~last_stamp.Loaded,'HW not loaded!', handles)
        set(handles.shut1_button, 'Value',0);
        return;
    end;
    prev_state = str2num(handles.mmc.getProperty('DiaShutter','State'));
    handles.mmc.setProperty('DiaShutter','State',~prev_state);
    last_stamp.Shutter(1) = ~prev_state;
    set(handles.shut1_button, 'Value',~prev_state);
end

%   Executes on button press in shut2_button.
function shut2_button_Callback(hObject, eventdata, handles)
    global last_stamp
    prev_state = str2num(handles.mmc.getProperty('EpiShutter 1','State'));
    handles.mmc.setProperty('EpiShutter 1','State',~prev_state);
    last_stamp.Shutter(2) = ~prev_state;
    set(handles.shut2_button, 'Value',~prev_state);
end

%	Executes on button press in DV_button.
function DV_button_Callback(hObject, eventdata, handles)
    global last_stamp
    last_stamp.Filter = 'GFP + dsRED';
    handles.mmc.setProperty('Dichroic 1','Label','3-GFP/mCherry');
    set(handles.DV_button, 'Value',1);
    set(handles.GCaMP_button, 'Value',0);
    set(handles.mCherry_button, 'Value',0);
    set(handles.DIC_button, 'Value',0);
end

%	Executes on button press in GCaMP_button.
function GCaMP_button_Callback(hObject, eventdata, handles)
    global last_stamp
    if ~assert(~last_stamp.Loaded,'HW not loaded!', handles)
        set(handles.GCaMP_button, 'Value',0);
        return;
    end;
    last_stamp.Filter = 'GFP';
    handles.mmc.setProperty('Dichroic 1','Label','1-GFP');
    set(handles.DV_button, 'Value',0);
    set(handles.GCaMP_button, 'Value',1);
    set(handles.mCherry_button, 'Value',0);
    set(handles.DIC_button, 'Value',0);
end

%	Executes on button press in mCherry_button.
function mCherry_button_Callback(hObject, eventdata, handles)
    global last_stamp
    last_stamp.Filter = 'dsRED';
    handles.mmc.setProperty('Dichroic 1','Label','2-mCherry');
    set(handles.DV_button, 'Value',0);
    set(handles.GCaMP_button, 'Value',0);
    set(handles.mCherry_button, 'Value',1);
    set(handles.DIC_button, 'Value',0);
end

%	Executes on button press in DIC_button.
function DIC_button_Callback(hObject, eventdata, handles)
    global last_stamp
    last_stamp.Filter = 'DIC';
    handles.mmc.setProperty('Dichroic 1','Label','8-IX3-FDICT');
    set(handles.DV_button, 'Value',0);
    set(handles.GCaMP_button, 'Value',0);
    set(handles.mCherry_button, 'Value',0);
    set(handles.DIC_button, 'Value',1);
end

%	Callback functions behind the next GUI panels: {EM, Exposure, Viewer mult, Stage, Light} 
function Em_Exp_Callback(hObject, eventdata, handles)
    global last_stamp filming
    tag = get(hObject,'Tag');
    acqIsShut_temp = 0;
    % check if the live_acquisition is on: can't change EM/Exp.
    if(filming.isLive && (strcmp(tag,'exp_up') || strcmp(tag,'exp_down') || strcmp(tag,'EM_up')|| strcmp(tag,'EM_go')||strcmp(tag,'exp_go') || strcmp(tag,'EM_down')))
        acqIsShut_temp = 1;        % turn live Acq off!
        stop(handles.timer_getFrame);
        handles.mmc.stopSequenceAcquisition();
    end
    
    if(strcmp(tag,'exp_up'))
        val = last_stamp.Exp;
        if(assert(val > 100,'--- EM too high ---',handles))
        	handles.mmc.setProperty('Camera-1','Exposure',val+1);
            last_stamp.Exp = val+1;
            set(handles.exp_input, 'String',num2str(val+1));
        end
        
    elseif(strcmp(tag,'exp_down'))
        val = last_stamp.Exp;
        if(assert(val == 1,'--- Exp too low ---',handles))
        	handles.mmc.setProperty('Camera-1','Exposure',val-1);
            last_stamp.Exp = val-1;
            set(handles.exp_input, 'String',num2str(val-1));
        end

    elseif(strcmp(tag,'EM_up'))
        val = last_stamp.EM;
        if(assert(val >= 999,'--- EM too high ---',handles))
        	handles.mmc.setProperty('Camera-1','MultiplierGain',val+1);
            last_stamp.EM = val+1;
            set(handles.EM_input, 'String',num2str(val+1));
        end

    elseif(strcmp(tag,'EM_go'))
        val = round(str2double(get(handles.EM_input, 'String')));
        if (val < 0 || val > 1000)
            set(handles.update_text, 'String','--- Wtong value of EM ---');
            set(handles.EM_input, 'String',last_stamp.EM);
        else
        	last_stamp.EM = val;
            handles.mmc.setProperty('Camera-1','MultiplierGain',val);
        end

    elseif(strcmp(tag,'EM_down'))
        val = last_stamp.EM;
        if(assert(val < 5,'--- Too low EM ---',handles))
        	handles.mmc.setProperty('Camera-1','MultiplierGain',val-1);
            last_stamp.EM = val-1;
            set(handles.EM_input, 'String',num2str(val-1));
        end

    elseif(strcmp(tag,'mult_go'))
        val = round(str2double(get(handles.mult_input, 'String')));
        if (val < 0 || val > 100)
            set(handles.update_text, 'String','--- Mult value too low ---');
            set(handles.nult_input, 'String',last_stamp.mult);
        else
            last_stamp.Mult = val;
        end

    elseif(strcmp(tag,'x_go'))
        val = round(str2double(get(handles.x_input, 'String'))); % security - should not rise too hight
        if (val < 0 || val > 114000)
            set(handles.update_text, 'String','--- X collision avoided! ---');
            set(handles.x_input, 'String',last_stamp.stage_X);
        else
            handles.mmc.setXYPosition('XYStage',val, last_stamp.stage_Y);
            last_stamp.stage_X = val;
        end
        
    elseif(strcmp(tag,'y_go'))
        val = round(str2double(get(handles.y_input, 'String'))); % security - should not rise too hight
        if (val < 0 || val > 76400)
            set(handles.update_text, 'String','--- Y collision avoided! ---');
            set(handles.y_input, 'String',last_stamp.stage_Y);
        else
            handles.mmc.setXYPosition('XYStage',last_stamp.stage_X, val);
            last_stamp.stage_Y = val;
        end
    elseif(strcmp(tag,'z_go'))
        val = round(str2double(get(handles.z_input, 'String'))); % security - should not rise too hight
        if (val < 0 || val > 7800)
            set(handles.update_text, 'String','--- Z collision avoided! ---');
            set(handles.z_input, 'String',last_stamp.Z);
        else
            handles.mmc.setPosition('FocusDrive',val);
            last_stamp.Z = val;
        end
                  
    elseif(strcmp(tag,'DIC_go'))
        val = round(str2double(get(handles.DIC_input, 'String')));
        if(val < 0 || val > 255)
            set(handles.update_text, 'String','--- wrong value ---');
            set(handles.DIC_input, 'String',last_stamp.Brightness);
        else
            last_stamp.Brightness = val;
            handles.mmc.setProperty('TransmittedIllumination 1','Brightness',val);
        end
        
    elseif(strcmp(tag,'green_go'))
        val = round(str2double(get(handles.green_input, 'String')));
        if(val < 0 || val > 100)
            set(handles.update_text, 'String','--- wrong value ---');
            set(handles.green_input, 'String',last_stamp.LED(2));
        else
            last_stamp.LED(2) = val;
            handles.mmc.setProperty('LED1 Device','L.10 Intensity (0.0 or 5.0 - 100.0)%',val);
        end
        
    elseif(strcmp(tag,'green_on'))
        val = ~last_stamp.LED(1);
        if val
            handles.mmc.setProperty('LED1 Device','L.09 On/Off State (1=On 0=Off)', 1);
            set(handles.green_on, 'Value',1);
            set(handles.green_on, 'Value',0);
        else
            handles.mmc.setProperty('LED1 Device','L.09 On/Off State (1=On 0=Off)', 0);
            set(handles.green_on, 'Value',0);
            set(handles.green_on, 'Value',1);
        end
        last_stamp.LED(1) = val;
        
    elseif(strcmp(tag,'red_go'))
        val = round(str2double(get(handles.red_input, 'String')));
        if(val < 0 || val > 100)
            set(handles.update_text, 'String','--- wrong value ---');
            set(handles.red_input, 'String',last_stamp.LED(4));
        else
            last_stamp.LED(4) = val;
            handles.mmc.setProperty('LED4 Device','L.10 Intensity (0.0 or 5.0 - 100.0)%',val)
        end
        
    elseif(strcmp(tag,'mult_up') || strcmp(tag,'mult_down'))
        if(strcmp(tag,'mult_down'))
            last_stamp.Mult = max(1, last_stamp.Mult - 1);
        else
            last_stamp.Mult = last_stamp.Mult + 1;
        end
        
    elseif(strcmp(tag,'red_on'))
        val = ~last_stamp.LED(3);
        if val
            handles.mmc.setProperty('LED4 Device','L.09 On/Off State (1=On 0=Off)', 1);
            set(handles.red_on, 'Value',0);
            set(handles.red_on, 'Value',1);
        else
            handles.mmc.setProperty('LED4 Device','L.09 On/Off State (1=On 0=Off)', 0);
            set(handles.red_on, 'Value',1);
            set(handles.red_on, 'Value',0);
        end
        last_stamp.LED(3) = val;
        
    else        % exp_go
        val = round(str2double(get(handles.exp_input, 'String')));
        if val < 0 || val > 100
            set(handles.update_text, 'String','--- Wrong Exp. values ---');
            set(handles.exp_input, 'String',last_stamp.Exp);
        else
        	last_stamp.Exp = round(str2double(get(handles.exp_input, 'String')));
            handles.mmc.setProperty('Camera-1','Exposure',last_stamp.Exp);
        end

    end
    
    if acqIsShut_temp       % turn live Acq on!
    	start(handles.timer_getFrame);
    	handles.mmc.startContinuousSequenceAcquisition(last_stamp.Exp);
    end
    set(hObject, 'Value',0);
end

%	Sanity check + defends your hardware from dumb users (you, in most times...)
function [doExit] = assert(err_cond,message, handles)
%%% Asserting function - show error to user. Parameters: condition is 
%%% checked, if it is 'true' there is an error! message to be printed.
%%% Returns [false] err_cond is false.
    doExit = true;
	if (err_cond)
        set(handles.update_text, 'ForegroundColor','red');
        set(handles.update_text, 'FontWeight','Bold');
        set(handles.update_text, 'String',['--- ' message ' ---']);
        pause(0.5);
        set(handles.update_text, 'ForegroundColor','yellow');
        set(handles.update_text, 'FontWeight','normal');
        doExit = false;
	end
end

%	Changes the light path - options: {Cam, 50-50, Eyes}
function vision_callback(hObject, eventdata, handles)
    global last_stamp filming
    tag = get(hObject,'Value');
    if(tag == last_stamp.Vision)
        return;
    end
    last_stamp.Vision = tag;
    handles.mmc.setProperty('Light Path','State',tag-1);
    set(handles.update_text, 'String','--- vision state changed ---');
end

%	Changes the objective of the microscope - options: {x4, x10}
function obj_callback(hObject, eventdata, handles)
    global last_stamp filming
    tag = get(hObject,'Value');
    if(tag == last_stamp.Objective)
        return;
    end
    last_stamp.Objective = tag;
    handles.mmc.setProperty('Objective','State',tag-1);
    set(handles.update_text, 'String','--- objective changed ---');
    
    if(tag == 1)
        filming.mm_bar_text = '1 mm (4X Lens)';
        filming.mm_bar_length = 250;
    else
        filming.mm_bar_text = '0.25 mm (10X Lens)';
        filming.mm_bar_length = 156;
    end
	delete([filming.Handles.mm_bar_rect filming.Handles.mm_bar_text]);
	filming.Handles.mm_bar_rect = rectangle('Position',[filming.mm_bar_dist ...
                                                           (512-filming.mm_bar_width/2-filming.mm_bar_dist)...
                                                            filming.mm_bar_length filming.mm_bar_width], 'FaceColor','w');
	filming.Handles.mm_bar_text = text(filming.mm_bar_length/2-filming.mm_bar_dist, ...
                                           512-filming.mm_bar_width-filming.mm_bar_dist, ...
                                           filming.mm_bar_text, 'Color', 'w');
end

%	Reads data from all devices and updates the GUI. Advisable to call this function at init.
function refresh_button_Callback(hObject, eventdata, handles)
    get_hw_params(handles);
    update_full_gui(handles);
    set(handles.update_text, 'String','--- Updated! ---');
end

%	Shifts the red circle to the left (where mCHerry is shown), and adjusts
%   the auto-tracking function to track this area
function DVmode_button_Callback(hObject, eventdata, handles)
    global filming last_stamp
    val = ~filming.DV_mode;
    filming.DV_mode = val;
    delete(filming.Handles.red_circle_handle);
    if (val)    % set to dv mode
        last_stamp.frame_X = 512/4;
        last_stamp.frame_Y = 512/2;
        filming.Handles.red_circle_handle = plot(512/4,512/2,'ro','MarkerSize',70, 'LineWidth',1);
        last_stamp.Head_point = [512/4,216];
    else
        last_stamp.frame_X = 512/2;
        last_stamp.frame_Y = 512/2;
        filming.Handles.red_circle_handle = plot(512/2,512/2,'ro','MarkerSize',70, 'LineWidth',1);
        last_stamp.Head_point = [216,216];
    end
end

% --- Executes on button press in maxCirc.
function maxCirc_Callback(hObject, eventdata, handles)
% hObject    handle to maxCirc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global filming
    filming.maxCirc = ~filming.maxCirc;
    if ~filming.maxCirc
        delete(filming.Handles.maxCircle);
        filming.Handles.maxCircle = plot(1,1,'o','Color','black','MarkerSize',1, 'LineWidth',1);
    end
    
end

%	Custom function that provides access to every function while the GUI run.
%	As the Gui run, edit this code, and when "Custom Func" button pressed it will run.
%	Setting "num = 10" and running will evoke emergency clean exit - unmount all HW, clean timers and stop stage.
%
%	BEWARE: If gui run, never save this file with uncompilable code (by hitting ctrl+S in the middle of this function editing),
%   or code that may crush MMC lib!
%	Read "README :: HARDWARE" chapter in order of HW harm avoidance!
function custom_button_Callback(hObject, eventdata, handles)
    global last_stamp tiff_creation filming
    
    disp('==============    Custom Func:     =================')
    
    if(1)
        a = handles.mmc.getLoadedDevices().toArray;
    end
    if (0)
        stop(handles.timer_getFrame);
        delete(handles.timer_getFrame);
        handles.timer_getFrame = timer('ExecutionMode','fixedRate',...
                        'Period', 0.1,...
                        'TimerFcn', {@getFrame,handles},...
                        'BusyMode','drop');
         start(handles.timer_getFrame);
    end
    
    if (0)
%         stop(handles.timer_getFrame);
%         set(handles.timer_getFrame,'Period',0.09)
        disp(handles.timer_getFrame)
%         start(handles.timer_getFrame);
        
    end
    
    if(0)
%         handles.mmc.setProperty('XYStage','MaxSpeed',100);
        disp(handles.mmc.getProperty('XYStage','Acceleration'));
        disp(handles.mmc.getProperty('XYStage','SCurve'));
        disp(handles.mmc.getProperty('XYStage','MaxSpeed'));         
    end
    if(0)
        position = handles.mmc.getXYStagePosition('XYStage');
        disp(round(position.getX));
    end
    if (0)
%         filming.Handles.red_circle_handle = plot(handles.picture_area, new_X, new_Y, 'ro', 'MarkerSize', 70, 'LineWidth',1);
          filming.PixToStage = 8;
          disp(num2str(filming.PixToStage));          
    end
    
    
    if (0)
        handles.mmc.getXYStagePosition('XYStage');
        position = handles.mmc.getXYStagePosition('XYStage');
        disp(position.getX);
    end

    disp('==================================================')
end

% --- Executes on button press in snap_button.
function snap_button_Callback(hObject, eventdata, handles)
% hObject    handle to snap_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global filming last_stamp
    name = get(handles.snap_name_text, 'String');
        
    tif_h = Tiff([name '.tif'], 'w');
    tif_h.setTag('ImageLength', 512.00);
    tif_h.setTag('ImageWidth', 512.00);
    tif_h.setTag('Photometric', Tiff.Photometric.MinIsBlack);
    tif_h.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky)
    tif_h.setTag('BitsPerSample', 16);
    tagStruct.DateTime = num2str(last_stamp.Time);  
    tagStruct.XPosition = last_stamp.stage_X;             
    tagStruct.YPosition = last_stamp.stage_Y;             
    tagStruct.HostComputer = num2str(last_stamp.Z);
    setTag(tif_h, tagStruct);
    tif_h.write(filming.frame*last_stamp.Mult);
    tif_h.close();
    
    set(handles.update_text, 'String', '--- Snap taken! ---');
end

% --- Executes on button press in fast_exit_button.
function fast_exit_button_Callback(hObject, eventdata, handles)
% hObject    handle to fast_exit_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    delete(timerfindall);
	handles.mmc.unloadAllDevices();
end

function attr_loc_button_Callback(hObject, eventdata, handles)
    global filming last_stamp
    if(filming.isTracking || filming.isRecording)
        return;
    end
    
        filming.is_attr_Recording = ~filming.is_attr_Recording;
    
    if(filming.is_attr_Recording) % activate recording of atractant
        filming.loc_db.Attr_array = [];
        set(hObject, 'String','Stop Rec.');
        set(hObject, 'BackGroundColor', [0.902 0.553 0.208]);
        set(hObject, 'Value',0);
        set(hObject, 'Value',1);
    else        
        set(hObject, 'String','Rec. Attr. loc.');
        set(hObject, 'BackGroundColor', [0.94, 0.94, 0.94]);
        set(hObject, 'Value',1);
        set(hObject, 'Value',0);
    end
end

% --- Executes on button press in attr_movie_button.
function attr_movie_button_Callback(hObject, eventdata, handles)
% hObject    handle to attr_movie_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global filming last_stamp tiff_creation
    if(filming.isTracking)  %Unable to init the function if a movie is being filmed.
        return;
    end
    filming.is_attr_Recording = ~filming.is_attr_Recording;
    if(filming.is_attr_Recording) % activate recording of atractant
        filming.loc_db.Attr_array = [];
        input_name = get(handles.movie_name_text, 'String');
        tiff_creation.file_name = input_name;
        tiff_creation.tiff_handle = Tiff([tiff_creation.file_name '.tif'], 'w');
        tic;
        filming.isRecording = 1;
        
        set(hObject, 'String','Stop Rec');
        set(hObject, 'BackGroundColor', [0.902 0.553 0.208]);
        set(hObject, 'Value',0);
        set(hObject, 'Value',1);
        disp(['=========    Creating .tif file in dir:  ' cd() '    ==========']);
    else
        tiff_creation.file_name = [tiff_creation.file_name_stat '_s' num2str(tiff_creation.SessionSerial)];
        filming.isRecording = 0;
        tiff_creation.tiff_handle.close();
        
        set(hObject, 'String','Take Movie');
        set(hObject, 'BackGroundColor', [0.94, 0.94, 0.94]);
        set(hObject, 'Value',1);
        set(hObject, 'Value',0);
    end

end


%=============      CreateFnc (Junk)       =============

% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
    disp('|============== Tracker Module Terminated =================|');
    try
        stop(timerfindall);
        handles.mmc.unloadAllDevices();
        delete(timerfindall);
        delete(hObject);
    catch m
        
    end

end

% --- Executes during object creation, after setting all properties.
function exp_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to exp_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    global last_stamp
    last_stamp.Exp = 0;
    set(hObject,'String', last_stamp.Exp);
    
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function EM_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EM_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    global last_stamp
    set(hObject,'String', '4');
    last_stamp.EM = 4;
    
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function mult_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mult_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function z_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to z_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function red_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to red_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function green_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to green_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function DIC_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DIC_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function x_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to x_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function y_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to y_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function obj_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to obj_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function vision_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vision_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function movie_name_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to movie_name_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function snap_name_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to snap_name_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
