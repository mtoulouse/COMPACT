function Rck = rack_properties(Rck)
%RACK_PROPERTIES Creates a GUI to edit flow/heat properties of a server rack object.
%   RACK_PROPERTIES builds a GUI figure with fields/buttons to specify
%   flow/heat rate and profile, populating it with stored values if present, and
%   changes the stored values depending on new input once 'OK' is clicked.
%   Also links to the profile creation GUI that characterizes flow and heat
%   profiles on server racks.

%% Rack Property GUI: First create the figure
Rck.PropertyFigure = figure('Name','Rack Values','NumberTitle','off',...
    'menubar','none','Position',Center_Fig(600,400),'Resize','off');
defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(Rck.PropertyFigure,'Color',defaultBackground)

% Create five panels/radio buttongroups: one for OK/Cancel buttons, one for
% heat generation, one each for flow and heat profiles, one for flow
% direction
OKPanel = uipanel('Parent',Rck.PropertyFigure,'Position',[0,0,1,.15]);
DirecSelect = uibuttongroup(Rck.PropertyFigure,'Title','Flow Direction',...
    'Units','normalized',...
    'Position',[0,.15,.3,.6],...
    'SelectionChangeFcn',@DirSel_callback);
HeatFlowPanel = uibuttongroup('Parent',Rck.PropertyFigure,...
    'Position',[.3,.15,.7,.85],'Title','Specify Rack Heat and Flow',...
    'SelectionChangeFcn',@SHG_callback);

% Create a field for inputting the server rack name
NameText = uicontrol(Rck.PropertyFigure,'Style','text',...
    'Units','normalized',...
    'Position',[.05,.85,.2,.1],...
    'String','Server Rack Name');
NameBox = uicontrol(Rck.PropertyFigure,'Style','edit',...
    'BackGroundColor','w',...
    'Units','normalized',...
    'Position',[.05,.825,.2,.075]);

% Create the radio buttons for flow direction
NS = uicontrol(DirecSelect,'Style','radio',...
    'String','North-South (-y)',...
    'Units','normalized',...
    'Position',[.2,.8,.8,.1]); % replace with the right number
SN = uicontrol(DirecSelect,'Style','radio',...
    'String','South-North (+y)',...
    'Units','normalized',...
    'Position',[.2,.6,.8,.1]);
WE = uicontrol(DirecSelect,'Style','radio',...
    'String','West-East (+x)',...
    'Units','normalized',...
    'Position',[.2,.4,.8,.1]);
EW = uicontrol(DirecSelect,'Style','radio',...
    'String','East-West (-x)',...
    'Units','normalized',...
    'Position',[.2,.2,.8,.1]);

% Create radio buttons for heat generation
HG_TR_button = uicontrol(HeatFlowPanel,'Style','radio',...
    'String','Heat Generation and Temperature Rise',...
    'Units','normalized',...
    'Position',[.2,.9,.6,.1]);
TR_FR_button = uicontrol(HeatFlowPanel,'Style','radio',...
    'String','Temperature Rise and Flow Rate',...
    'Units','normalized',...
    'Position',[.2,.8,.6,.1]);
FR_HG_button = uicontrol(HeatFlowPanel,'Style','radio',...
    'String','Flow Rate and Heat Generation',...
    'Units','normalized',...
    'Position',[.2,.7,.6,.1]);

% Create push buttons for various heat/flow/temp profiles
HGProfButton = uicontrol(HeatFlowPanel,'Style', 'pushbutton', 'String', 'Heat Gen Profile',...
    'Units','normalized',...
    'Position', [.025 .55 .3 .1],...
    'Callback', {@Edit_profile_callback,'HG'});
TRProfButton = uicontrol(HeatFlowPanel,'Style', 'pushbutton', 'String', 'Temp Rise Profile',...
    'Units','normalized',...
    'Position', [.35 .55 .3 .1],...
    'Callback', {@Edit_profile_callback,'TR'});
FRProfButton = uicontrol(HeatFlowPanel,'Style', 'pushbutton', 'String', 'Flow Rate Profile',...
    'Units','normalized',...
    'Position', [.675 .55 .3 .1],...
    'Callback', {@Edit_profile_callback,'FR'},...
    'Enable', 'off');

% Create fields for showing profile information
HG_info = uicontrol(HeatFlowPanel,'Style','text',...
    'Units','normalized',...
    'Position',[.025,.1,.3,.4],...
    'String','No info');
TR_info = uicontrol(HeatFlowPanel,'Style','text',...
    'Units','normalized',...
    'Position',[.35,.1,.3,.4],...
    'String','No info');
FR_info = uicontrol(HeatFlowPanel,'Style','text',...
    'Units','normalized',...
    'Position',[.675,.1,.3,.4],...
    'String','No info',...
    'Enable', 'off');

% Create an OK and Cancel Button
OKButt = uicontrol(OKPanel,'Style', 'pushbutton', 'String', 'OK',...
    'Units','normalized',...
    'Position', [.1 .25 .2 .5],...
    'Callback', @OK_callback);
CancelButt = uicontrol(OKPanel,'Style', 'pushbutton', 'String', 'Cancel',...
    'Units','normalized',...
    'Position', [.7 .25 .2 .5],...
    'Callback', 'close(gcf)');

HGProfile = Profile('HG');
TRProfile = Profile('TR');
FRProfile = Profile('FR');
switch 1
    case get(NS,'Value')
        direc = 3;
    case get(SN,'Value')
        direc = 4;
    case get(WE,'Value')
        direc = 2;
    case get(EW,'Value')
        direc = 1;
end
%% Those were default values; now replace if the rack is already in room

[SR_num I_num O_num P_num Ob_num] = CountObjs(Rck.Room);
Rck_in_room = 0;
for k = 1:SR_num
    if isequal(Rck.Room.ObjectList.ServerRacks{k},Rck)
        Rck_in_room = 1;
    end
end

if Rck_in_room
    % import profiles if present, and show info
    HGProfile = Rck.HeatGenProfile;
    set(HG_info,'String',Infostring(HGProfile))
    TRProfile = Rck.TempRiseProfile;
    set(TR_info,'String',Infostring(TRProfile))
    FRProfile = Rck.FlowProfile;
    set(FR_info,'String',Infostring(FRProfile))

    % set name
    set(NameBox,'String',Rck.Name)

    % set direction button
    direc = Rck.Orientation;
    switch Rck.Orientation
        case 3
            set(DirecSelect,'SelectedObject',NS)
        case 4
            set(DirecSelect,'SelectedObject',SN)
        case 2
            set(DirecSelect,'SelectedObject',WE)
        case 1
            set(DirecSelect,'SelectedObject',EW)
    end

    % set selected method of heat generation
    set([HG_info TR_info FR_info],'Enable','on')
    set([HGProfButton TRProfButton FRProfButton],'Enable','on')
    if ~any(strcmp(Rck.HeatGenCharac,'Heat Generation'))
        set(HeatFlowPanel,'SelectedObject',TR_FR_button)
        set(HG_info,'Enable','off')
        set(HGProfButton,'Enable','off')
    elseif ~any(strcmp(Rck.HeatGenCharac,'Temperature Rise'))
        set(HeatFlowPanel,'SelectedObject',FR_HG_button)
        set(TR_info,'Enable','off')
        set(TRProfButton,'Enable','off')
    elseif ~any(strcmp(Rck.HeatGenCharac,'Flow Rate'))
        set(HeatFlowPanel,'SelectedObject',HG_TR_button)
        set(FR_info,'Enable','off')
        set(FRProfButton,'Enable','off')
    end

end
%% Now that the UI is made, pause it until a button is pressed
uiwait(Rck.PropertyFigure)

%% Callbacks for heat generation radio buttons

    function SHG_callback(src,eventdata)
        switch eventdata.NewValue
            case HG_TR_button
                set([HG_info TR_info FR_info],'Enable','on')
                set(FR_info,'Enable','off')
                set([HGProfButton TRProfButton FRProfButton],'Enable','on')
                set(FRProfButton,'Enable','off')
            case TR_FR_button
                set([HG_info TR_info FR_info],'Enable','on')
                set(HG_info,'Enable','off')
                set([HGProfButton TRProfButton FRProfButton],'Enable','on')
                set(HGProfButton,'Enable','off')
            case FR_HG_button
                set([HG_info TR_info FR_info],'Enable','on')
                set(TR_info,'Enable','off')
                set([HGProfButton TRProfButton FRProfButton],'Enable','on')
                set(TRProfButton,'Enable','off')
        end
    end
 %% 
    function DirSel_callback(src,eventdata)
        switch eventdata.NewValue
            case NS
                direc = 3;
                if ~isequal(eventdata.OldValue,SN)
                    ClearProfs;
                end
            case SN
                direc = 4;
                if ~isequal(eventdata.OldValue,NS)
                    ClearProfs;
                end
            case WE
                direc = 2;
                if ~isequal(eventdata.OldValue,EW)
                    ClearProfs;
                end
            case EW
                direc = 1;
                if ~isequal(eventdata.OldValue,WE)
                    ClearProfs;
                end
        end
    end

    function ClearProfs
        ClearProfile(HGProfile)
        ClearProfile(TRProfile)
        ClearProfile(FRProfile)
        set(HG_info,'String',Infostring(HGProfile))
        set(TR_info,'String',Infostring(TRProfile))
        set(FR_info,'String',Infostring(FRProfile))
    end


%% Callbacks for Profile Creation buttons
    function Edit_profile_callback(src,eventdata,profsubj)
        switch profsubj
            case 'HG'
                Prof = FlowObjProfileGUI(Rck,HGProfile,direc);
                if ~isempty(Prof)
                    HGProfile = Prof;
                    set(HG_info,'String',Infostring(HGProfile))
                end
            case 'TR'
                Prof = FlowObjProfileGUI(Rck,TRProfile,direc);
                if ~isempty(Prof)
                    TRProfile = Prof;
                    set(TR_info,'String',Infostring(TRProfile))
                end
            case 'FR'
                Prof = FlowObjProfileGUI(Rck,FRProfile,direc);
                if ~isempty(Prof)
                    FRProfile = Prof;
                    set(FR_info,'String',Infostring(FRProfile))
                end
        end
    end

%% Make the OK callback to store the information
    function OK_callback(src,eventdata)

        numprofs = IsProfileValid(HGProfile) + ...
            IsProfileValid(TRProfile) + IsProfileValid(FRProfile);

        if numprofs < 2
            errordlg('Not enough profiles properly defined. If there is no flow, you still have to define it.',...
                'Inadequate Characterization')
        else

            %set name
            Rck.Name = get(NameBox,'String');

            % Set the server rack orientation, and find the flow face area of
            % the server rack
            switch 1
                case get(NS,'Value')
                    Rck.Orientation = 3;
                case get(SN,'Value')
                    Rck.Orientation = 4;
                case get(WE,'Value')
                    Rck.Orientation = 2;
                case get(EW,'Value')
                    Rck.Orientation = 1;
            end

            % Set the heat generation/flow rate/temperature rise
            switch 1
                case get(HG_TR_button,'Value')
                    Rck.HeatGenCharac = {'Heat Generation' 'Temperature Rise'};
                case get(TR_FR_button,'Value')
                    Rck.HeatGenCharac = {'Temperature Rise' 'Flow Rate'};
                case get(FR_HG_button,'Value')
                    Rck.HeatGenCharac = {'Flow Rate' 'Heat Generation'};
            end

            UpdateHeatGen(Rck,HGProfile,TRProfile,FRProfile)

            close(Rck.PropertyFigure)
        end
    end % OK callback end

end % rack properties end