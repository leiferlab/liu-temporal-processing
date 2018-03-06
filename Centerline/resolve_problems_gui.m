function varargout = resolve_problems_gui(varargin)
% RESOLVE_PROBLEMS_GUI MATLAB code for resolve_problems_gui.fig
%      RESOLVE_PROBLEMS_GUI, by itself, creates a new RESOLVE_PROBLEMS_GUI or raises the existing
%      singleton*.
%
%      H = RESOLVE_PROBLEMS_GUI returns the handle to a new RESOLVE_PROBLEMS_GUI or the handle to
%      the existing singleton*.
%
%      RESOLVE_PROBLEMS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RESOLVE_PROBLEMS_GUI.M with the given input arguments.
%
%      RESOLVE_PROBLEMS_GUI('Property','Value',...) creates a new RESOLVE_PROBLEMS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before resolve_problems_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to resolve_problems_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help resolve_problems_gui

% Last Modified by GUIDE v2.5 18-Sep-2015 00:06:11

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @resolve_problems_gui_OpeningFcn, ...
                       'gui_OutputFcn',  @resolve_problems_gui_OutputFcn, ...
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

% --- Executes just before resolve_problems_gui is made visible.
function resolve_problems_gui_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to resolve_problems_gui (see VARARGIN)

    % Choose default command line output for resolve_problems_gui
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);

    hObject.UserData = varargin;  
    
    worm_images = hObject.UserData{1};
    Track = hObject.UserData{2};
    worm_frame_start_index = hObject.UserData{3};
    worm_frame_end_index = hObject.UserData{4};
    
    

    current_frame = worm_frame_start_index;
    hObject.UserData{6} = current_frame; %current frame
    
    display_frame(hObject, current_frame);
end

% --- Outputs from this function are returned to the command line.
function varargout = resolve_problems_gui_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;
end

% --- Executes on button press in GoButton.
function GoButton_Callback(hObject, eventdata, handles)
    % hObject    handle to GoButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    axes(handles.image_axes);
    cla;

    h = findobj('Tag','figure1');
    popup_sel_index = get(handles.ActionsPopupMenu, 'Value');
    h.UserData{7} = popup_sel_index;
    uiresume
end

% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to FileMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
end

% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
    % hObject    handle to OpenMenuItem (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    file = uigetfile('*.fig');
    if ~isequal(file, 0)
        open(file);
    end
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
    % hObject    handle to PrintMenuItem (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    printdlg(handles.figure1)
end
% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
    % hObject    handle to CloseMenuItem (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                         ['Close ' get(handles.figure1,'Name') '...'],...
                         'Yes','No','Yes');
    if strcmp(selection,'No')
        return;
    end
    h = findobj('Tag','figure1');
    popup_sel_index = get(handles.ActionsPopupMenu, 'Value');
    h.UserData{7} = popup_sel_index;
    uiresume
end

% --- Executes on selection change in ActionsPopupMenu.
function ActionsPopupMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to ActionsPopupMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = get(hObject,'String') returns ActionsPopupMenu contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from ActionsPopupMenu

end
% --- Executes during object creation, after setting all properties.
function ActionsPopupMenu_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to ActionsPopupMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
         set(hObject,'BackgroundColor','white');
    end

%     set(hObject, 'String', {'plot(rand(5))', 'plot(sin(1:0.01:25))', 'bar(1:.5:10)', 'plot(membrane)', 'surf(peaks)'});
end

% --- Executes on button press in BackButton.
function BackButton_Callback(hObject, eventdata, handles)
    % hObject    handle to BackButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    h = findobj('Tag','figure1');
    Track = h.UserData{2};
    worm_frame_start_index = h.UserData{3};
    worm_frame_end_index = h.UserData{4};
    current_frame = h.UserData{6};
    if current_frame > 1
        current_frame = current_frame - 1;
    end
    display_frame(h, current_frame);
    
    h.UserData{6} = current_frame;
end

% --- Executes on button press in NextButton.
function NextButton_Callback(hObject, eventdata, handles)
    % hObject    handle to NextButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    h = findobj('Tag','figure1');
    Track = h.UserData{2};
    worm_frame_start_index = h.UserData{3};
    worm_frame_end_index = h.UserData{4};
    current_frame = h.UserData{6};
    if current_frame < length(Track.Frames)
        current_frame = current_frame + 1;
    end
    display_frame(h, current_frame);
    
    h.UserData{6} = current_frame;
end

function display_frame(hObject, frame_index)
    worm_images = hObject.UserData{1};
    Track = hObject.UserData{2};
    track_index = hObject.UserData{5};
    I = squeeze(worm_images(:,:,frame_index));
    plot_worm_frame(I, squeeze(Track.Centerlines(:,:,frame_index)), ...
        Track.UncertainTips(frame_index), ...
        Track.Eccentricity(frame_index), Track.Direction(frame_index), ...
        Track.Speed(frame_index),  Track.TotalScore(frame_index), 1);
    
    text_handle = findobj('Tag', 'PropertiesText');
    text_handle.String = {['Track #: ', num2str(track_index)], ...
        ['Frame #: ', num2str(frame_index)], ...
        ['Error: ', problem_code_lookup(Track.PotentialProblems(frame_index))], ...
        ['Eccentricity: ', num2str(Track.Eccentricity(frame_index))], ...
        ['Total Score: ', num2str(Track.TotalScore(frame_index))], ...
        ['Image Score: ', num2str(Track.ImageScore(frame_index))], ...
        ['Displacement Score: ', num2str(Track.DisplacementScore(frame_index))], ...
        ['Area: ', num2str(Track.Size(frame_index))], ...
        ['Pixels Out of Body: ', num2str(Track.PixelsOutOfBody(frame_index))], ...
        ['Possible Head Switch: ', num2str(Track.PossibleHeadSwitch(frame_index))], ...
        ['Length: ', num2str(Track.Length(frame_index))], ...
        ['Omega Turn Annotation: ', num2str(Track.OmegaTurnAnnotation(frame_index))] ...
        ['Dilation Size: ', num2str(Track.DilationSize)], ...
        ['Aspect Ratio: ', num2str(Track.AspectRatio(frame_index))], ...
        ['Mean Aspect Ratio: ', num2str(Track.MeanAspectRatio)] ...
        ['Thinning Iteration: ', num2str(Track.ThinningIteration(frame_index))] ...
        };
    
    if Track.PotentialProblems(frame_index) > 0
        text_handle.BackgroundColor = [1, 0.5 ,0.5];
    else
        text_handle.BackgroundColor = [0.94, 0.94, 0.94];
    end

end
