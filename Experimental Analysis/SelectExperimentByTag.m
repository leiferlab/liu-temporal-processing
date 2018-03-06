function varargout = SelectExperimentByTag(varargin)
    % SELECTEXPERIMENTBYTAG MATLAB code for SelectExperimentByTag.fig
    %      SELECTEXPERIMENTBYTAG, by itself, creates a new SELECTEXPERIMENTBYTAG or raises the existing
    %      singleton*.
    %
    %      H = SELECTEXPERIMENTBYTAG returns the handle to a new SELECTEXPERIMENTBYTAG or the handle to
    %      the existing singleton*.
    %
    %      SELECTEXPERIMENTBYTAG('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in SELECTEXPERIMENTBYTAG.M with the given input arguments.
    %
    %      SELECTEXPERIMENTBYTAG('Property','Value',...) creates a new SELECTEXPERIMENTBYTAG or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before SelectExperimentByTag_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to SelectExperimentByTag_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help SelectExperimentByTag

    % Last Modified by GUIDE v2.5 30-Aug-2016 16:13:10

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @SelectExperimentByTag_OpeningFcn, ...
                       'gui_OutputFcn',  @SelectExperimentByTag_OutputFcn, ...
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


% --- Executes just before SelectExperimentByTag is made visible.
function SelectExperimentByTag_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to SelectExperimentByTag (see VARARGIN)

    % Choose default command line output for SelectExperimentByTag
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes SelectExperimentByTag wait for user response (see UIRESUME)
    % uiwait(handles.SelectExperimentByTag);

    taglistbox_handle = findobj('Tag', 'TagListbox');
    folderslistbox_handle = findobj('Tag', 'FoldersListbox');
    folderspanel_handle = findobj('Tag', 'FoldersPanel');
    
    hObject.UserData = varargin;  
    hObject.UserData{3} = 'All Tags';

    folders = hObject.UserData{1};
    folder_tags = hObject.UserData{2};
    
    unique_tags = unique(vertcat(folder_tags{:}));
    taglistbox_handle.String = [unique_tags; 'All Tags'];
    folderslistbox_handle.String = folders;
    
    folderspanel_handle.Title = [num2str(length(folders)) ' Folders Selected'];
end

% --- Outputs from this function are returned to the command line.
function varargout = SelectExperimentByTag_OutputFcn(hObject, eventdata, handles) 
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;

end

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
    % hObject    handle to pushbutton1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    taglistbox_handle = findobj('Tag', 'TagListbox');
    contents = cellstr(get(taglistbox_handle,'String'));
    selected_tag = contents{get(taglistbox_handle,'Value')};
    
    h = findobj('Tag','SelectExperimentByTag');
    h.UserData{3} = selected_tag;
    uiresume
end

% --- Executes on selection change in FoldersListbox.
function FoldersListbox_Callback(hObject, eventdata, handles)
    % hObject    handle to FoldersListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns FoldersListbox contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from FoldersListbox

end

% --- Executes during object creation, after setting all properties.
function FoldersListbox_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to FoldersListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

end

% --- Executes on selection change in TagListbox.
function TagListbox_Callback(hObject, eventdata, handles)
    % hObject    handle to TagListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns TagListbox contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from TagListbox
    h = findobj('Tag','SelectExperimentByTag');
    folders = h.UserData{1};
    folder_tags = h.UserData{2};
    
    contents = cellstr(get(hObject,'String'));
    selected_tag = contents{get(hObject,'Value')};

    folderslistbox_handle = findobj('Tag', 'FoldersListbox');
    folderspanel_handle = findobj('Tag', 'FoldersPanel');

    if strcmp(selected_tag, 'All Tags')
        % all tags are selected, remove filters
        folderslistbox_handle.String = folders;
        folderspanel_handle.Title = [num2str(length(folders)) ' Folders Selected'];
    else
        [filtered_folders, ~] = filter_folders(folders, folder_tags, selected_tag);
        folderslistbox_handle.String = filtered_folders;
        folderspanel_handle.Title = [num2str(length(filtered_folders)) ' Folders Selected'];
    end
    
end

% --- Executes during object creation, after setting all properties.
function TagListbox_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to TagListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
