function BoundL = boundary_properties(BoundL)
%BOUNDARY_PROPERTIES Creates a GUI to edit flow properties of an inlet or
%outlet object.
%   BOUNDARY_PROPERTIES builds a GUI figure with fields/buttons to specify
%   flow rate and profile, populating it with stored values if present, and
%   changes the stored values depending on new input once 'OK' is clicked. 
%   You can also switch the rtype between inlet and outlet here.
%
%   Also links to the profile creation GUI that characterizes flow profiles
%   on surfaces. 
%% Find type of boundary object
BT = BoundL.Type;
if strcmp(BT,'Inlet')
    OtherBT = 'Outlet';
elseif strcmp(BT,'Outlet')
    OtherBT = 'Inlet';
end
%% Boundary GUI: First create the figure
BoundL.PropertyFigure = figure('Name',[BT ' Values'],'NumberTitle','off',...
    'menubar','none','Position',Center_Fig(400,300),'Resize','off');

% Create a field for the Boundary name

NamePanel = uipanel(BoundL.PropertyFigure,'Title',[BT ' Name'],...
    'Units','normalized',...
    'Position',[0,.6,.5,.4]);
NameBox = uicontrol(NamePanel,'Style','edit',...
    'BackGroundColor','w',...
    'Units','normalized',...
    'Position',[.1,.55,.8,.35]);

% Create a switcher button

SwitchTypeButton = uicontrol(NamePanel,'Style','togglebutton',...
    'String',['Switch type to ' OtherBT],...
    'Units','normalized',...
    'Position', [.1,.1,.8,.35]);

% Create the air temperature field

AirTempPanel = uibuttongroup('Parent',BoundL.PropertyFigure,...
    'Title','Air Temperature',...
    'Units','normalized',...
    'Position',[0,.15,.5,.45]);

RoomTempButton = uicontrol(AirTempPanel,'Style', 'radio', ...
    'String', 'Same as Room Temperature',...
    'Units','normalized',...
    'Position', [.1,.7,.8,.15]);

UniqueTempButton = uicontrol(AirTempPanel,'Style', 'radio', ...
    'String', 'Set Temperature',...
    'Units','normalized',...
    'Position', [.1,.4,.8,.15]);

SetTempField = uicontrol(AirTempPanel,'Style', 'edit', ...
    'Units','normalized',...
    'BackGroundColor','w',...
    'Position', [.1,.2,.8,.15]);

% Create the profile button and info field
FlowProfSelect = uibuttongroup(BoundL.PropertyFigure,'Title',[BT ' Flow Profile'],...
    'Units','normalized',...
    'Position',[.5,.15,.5,.85]);

FRProfButton = uicontrol(FlowProfSelect,'Style', 'pushbutton', 'String', 'Flow Rate Profile',...
    'Units','normalized',...
    'Position', [.1,.7,.8,.25],...
    'Callback', @FR_profile_callback);

FR_info = uicontrol(FlowProfSelect,'Style','text',...
    'Units','normalized',...
    'Position',[.1,.1,.8,.55],...
    'String','No info');

% Create an OK and Cancel Button
OKPanel = uipanel('Parent',BoundL.PropertyFigure,'Position',[0,0,1,.15]);
OKButt = uicontrol(OKPanel,'Style', 'pushbutton', 'String', 'OK',...
    'Units','normalized',...
    'Position', [.1 .15 .35 .7],...
    'Callback', {@OK_callback});
CancelButt = uicontrol(OKPanel,'Style', 'pushbutton', 'String', 'Cancel',...
    'Units','normalized',...
    'Position', [.55 .15 .35 .7],...
    'Callback', 'close(gcf)');

FRProfile = Profile('FR'); % initialize an empty flow profile

%% Fill in values if editing existing object
% Those were default values; now replace if the object was already in room 

if ~isempty(BoundL.Room)
    % set name
    set(NameBox,'String',num2str(BoundL.Name))

    % import profile if present, and show info
    FRProfile = BoundL.FlowProfile;
    set(FR_info,'String',Infostring(FRProfile))
    
    % set air temp
    if isempty(BoundL.AirTemp)
        set(AirTempPanel,'SelectedObject',RoomTempButton)
    else
        set(AirTempPanel,'SelectedObject',UniqueTempButton)
        set(SetTempField,'String',num2str(BoundL.AirTemp))
    end
    
end

%% Now that the UI is made, pause it until a button is pressed
uiwait(BoundL.PropertyFigure)

%% Make the OK callback store the information
    function OK_callback(src,eventdata)
        if IsProfileValid(FRProfile)
            BoundL.Name = get(NameBox,'String');
            BoundL.FlowProfile = FRProfile;
            switch 1
                case get(UniqueTempButton,'Value')
                    BoundL.AirTemp = str2num(get(SetTempField,'String'));
                case get(RoomTempButton,'Value')
                    BoundL.AirTemp = [];
            end
            if get(SwitchTypeButton,'Value')
                SwitchType(BoundL)
            end
            close(BoundL.PropertyFigure)
        else
            errordlg('Properly define the flow profile!',...
                'Inadequate Characterization')
        end
    end
%% profile button callback

    function FR_profile_callback(src,eventdata)
        % open the profile-setting GUI
        Prof = FlowObjProfileGUI(BoundL,FRProfile,BoundL.Orientation);
        if ~IsProfileEmpty(Prof)
            FRProfile = Prof;
            set(FR_info,'String',Infostring(FRProfile))
        end
    end
end