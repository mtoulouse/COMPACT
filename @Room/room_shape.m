function room_shape(Rm)
%ROOM_SHAPE Creates the main GUI in which the room configuration is defined.
%   ROOM_SHAPE builds a GUI figure from which the configuration of the room
%   is specified, and the model is run. Both projected and 3-D views of the
%   room are shown here. All program functions can be accessed from the
%   ROOM_SHAPE GUI, including:
%   1) Creation/storage/loading of rooms
%   2) Placement/deletion of inlets/outlet/server racks
%   3) Moving of objects or editing of their properties
%   4) Setting of solver options and running of the solver
%   5) Refreshing the views or refining the mesh
%   6) Loading of result data from file or the workspace

%% Room shape GUI:

rd = Rm.Dimensions;
res = Rm.Resolution;
rd_v = rd + 2*res;
L = rd_v(1);
W = rd_v(2);
H = rd_v(3);

basepixelwidth = 600;
% Create the Figure
Rm.Figure = figure('Name',['Room Configuration ' Rm.RoomInfoStr],...
    'NumberTitle','off','menubar','none',...
    'Position',Center_Fig(basepixelwidth*2,basepixelwidth),...
    'Resize','off','NextPlot','new');
% set NextPlot property so that plotting something from the command
% line doesn't just overwrite one of the room views.

md_rat = 0.35; % The fraction of the left panel devoted to buttons as opposed to the projected views

%% Create some menu items

% Room option menu
RoomOpts = uimenu(Rm.Figure,'Label','Room Options');
NewRoom = uimenu(RoomOpts,'Label','New Room','Accelerator','N','Callback',@NewRoom_callback);
SaveRoom = uimenu(RoomOpts,'Label','Save Room','Accelerator','S','Callback',@SaveRoom_callback);
LoadRoom = uimenu(RoomOpts,'Label','Load Room','Accelerator','L','Callback',@LoadRoom_callback);
ExitRoom = uimenu(RoomOpts,'Label','Exit','Accelerator','X','Callback','close(gcf)');

% Display option menu
DispOpts = uimenu(Rm.Figure,'Label','Display Options');
RefMesh = uimenu(DispOpts,'Label','Refine Mesh','Callback',@RefMesh_callback);
UpDisp = uimenu(DispOpts,'Label','Refresh Display','Callback',@RefreshDisp_callback);
ReClas = uimenu(DispOpts,'Label','Reclassify Boundaries','Callback',@ReclassBound_callback);
ShowSingCell = uimenu(DispOpts,'Label','Show Single Cell Statistics','Callback',@SingleCell_callback);

% Run option menu
RunOpts = uimenu(Rm.Figure,'Label','Run Options');
SolverOpt = uimenu(RunOpts,'Label','Solver Options','Accelerator','O','Callback',@SolOpt_callback);
RunRoom = uimenu(RunOpts,'Label','Run Solver','Accelerator','R','Callback',@Run_callback);

% Result option menu
ResOpts = uimenu(Rm.Figure,'Label','Result Options');
LoadResultsFromFile = uimenu(ResOpts,'Label','Load Results from File','Callback',{@LoadResults_callback,'file'});
LoadResultsFromWksp = uimenu(ResOpts,'Label','Load Results from Workspace','Callback',{@LoadResults_callback,'wksp'});

% LCEA option menu
LCEAOpts = uimenu(Rm.Figure,'Label','LCEA Options');
OpenLCEARoom = uimenu(LCEAOpts,'Label','Open LCEA Room','Callback','disp(''LCEA'')');

% Vortex option menu
VortOpts = uimenu(Rm.Figure,'Label','Vortex Options');
AutoVorts = uimenu(VortOpts,'Label','Automatically Place Vortices/Aisles','Callback',@AutoVorPlace_callback);
PlaceVorts = uimenu(VortOpts,'Label','Manually Place/Edit Vortices/Aisles','Callback',@VorPlace_callback);
ViewVorts = uimenu(VortOpts,'Label','View Vortices/Aisles','Callback',@VorView_callback);

%% Create the Projected Views

% Create a panel in which the projected views will be placed
ProjViews = uipanel('Parent',Rm.Figure,...
    'Position',[0,md_rat,.5,1-md_rat],...
    'Title','Projected Views');

% ---------------------  ^
% |                   |  |
% |    FRONT VIEW     |  H
% |                   |  |
% ---------------------  v
% --------------------- --------  ^
% |                   | |      |  |
% |     TOP VIEW      | | SIDE |
% |                   | | VIEW |  W
% |                   | |      |  |
% --------------------- --------  v
% <---------L---------> <---H-->

% Use Room.Dimensions to find the right dimensions for the subpanels
AR = (W+H)/(L+H); % aspect ratio: ratio of height of projected views to the width
if AR > (1-md_rat) % rectangle of projected views "taller" than panel rectangle?
    W_mult = (1-md_rat)/AR;
    H_mult = 1/AR;
else % rectangle of projected views "wider" than panel rectangle?
    W_mult = 1;
    H_mult = 1/(1-md_rat);
end

topW = W_mult*L/(L+H); % L/(L+H)
topH = H_mult*W/(L+H); % W/(L+H)

frontW = W_mult*L/(L+H); % L/(L+H)
frontH = H_mult*H/(L+H); % H/(L+H)

sideW = W_mult*H/(L+H); % H/(L+H)
sideH = H_mult*W/(L+H); % W/(L+H)

% Create individual panels and axes within the main panel
toppanel = uipanel('Parent',ProjViews,'Position',[0,0,topW,topH],...
    'Title','Top View');
topaxes = axes('Parent',toppanel,'Tag','Top View Axes');

frontpanel = uipanel('Parent',ProjViews,'Position',[0,topH,frontW,frontH],...
    'Title','Front View');
frontaxes = axes('Parent',frontpanel,'Tag','Front View Axes');

rightpanel = uipanel('Parent',ProjViews,'Position',[topW,0,sideW,sideH],...
    'Title','Right View');
rightaxes = axes('Parent',rightpanel,'Tag','Right View Axes');

%% Create the 3D View

View3D = uipanel('Parent',Rm.Figure,'Position',[.5,0,.5,1],'Title','Three-Dimensional View');
Axes3D = axes('Parent',View3D,'Tag','3D Axes');

%% Create the Object Addition Panel + Buttons
% Buttons which when pressed open the position-setting GUI, and if an
% answer is returned, creates an object, opens the corresponding property
% editing GUI and adds the object to the room.

ObjAddSelect = uipanel('Parent',Rm.Figure,...
    'Title','Add Object to Room',...
    'Position',[0,0,.25,md_rat]);

AddRack = uicontrol(ObjAddSelect,'Style', 'pushbutton', 'String', 'Server Rack',...
    'Units','normalized',...
    'Position', [.05 .25 .45 .35],...
    'ForegroundColor','g',...
    'FontSize',14,'FontWeight','bold',...
    'Callback', @AddRack_callback);

AddInlet = uicontrol(ObjAddSelect,'Style', 'pushbutton', 'String', 'Inlet',...
    'Units','normalized',...
    'Position', [.05 .6 .45 .35],...
    'ForegroundColor','b',...
    'FontSize',14,'FontWeight','bold',...
    'Callback', @AddInlet_callback);

AddOutlet = uicontrol(ObjAddSelect,'Style', 'pushbutton', 'String', 'Outlet',...
    'Units','normalized',...
    'Position', [.5 .6 .45 .35],...
    'FontSize',12,'FontWeight','bold',...
    'ForegroundColor','r',...
    'Callback', @AddOutlet_callback);

AddObstacle = uicontrol(ObjAddSelect,'Style', 'pushbutton', 'String', 'Obstacle',...
    'Units','normalized',...
    'Position', [.5 .25 .45 .35],...
    'FontSize',12,'FontWeight','bold',...
    'ForegroundColor','k',...
    'Callback', @AddObstacle_callback);

AddPartition = uicontrol(ObjAddSelect,'Style', 'pushbutton', 'String', 'Partition',...
    'Units','normalized',...
    'Position', [.05 .05 .9 .2],...
    'FontSize',12,'FontWeight','bold',...
    'ForegroundColor','m',...
    'Callback', @AddPartition_callback);

%% Create the Object Option Buttons + Listbox

ObjOptions = uipanel('Parent',Rm.Figure,...
    'Title','Object Options',...
    'Position',[.25,0,.25,md_rat]);

ChgProp = uicontrol(ObjOptions,'Style', 'pushbutton', 'String', 'Change Properties',...
    'Units','normalized',...
    'Position', [.05 .7 .4 .25],...
    'Callback', @ChgProperty_callback);

MoveObj = uicontrol(ObjOptions,'Style', 'pushbutton', 'String', 'Move Object',...
    'Units','normalized',...
    'Position', [.05 .4 .3 .25],...
    'Callback', @MoveObj_callback);

DelObj = uicontrol(ObjOptions,'Style', 'pushbutton', 'String', 'Delete Object',...
    'Units','normalized',...
    'Position', [.05 .1 .3 .25],...
    'Callback', @DeleteCurrent_callback);

Promote = uicontrol(ObjOptions,'Style', 'pushbutton', 'String', '^',...
    'Units','normalized',...
    'Position', [.375 .4 .1 .25],...
    'Callback', {@ListMove_callback,'up'});

Demote = uicontrol(ObjOptions,'Style', 'pushbutton', 'String', 'v',...
    'Units','normalized',...
    'Position', [.375 .1 .1 .25],...
    'Callback', {@ListMove_callback,'down'});

ObjectListBox = uicontrol(ObjOptions,'Style', 'listbox',...
    'Units','normalized',...
    'Position', [.50 .05 .475 .9],...
    'BackgroundColor','w',...
    'Tag','ObjLB',...
    'Callback', @ObjListBox_callback);

%% Now update the figure with current data
Rm.UpdateDisplay
%% Object Addition Callbacks

% For the "Server Rack" button. Creates a server rack object, opens the
% position setting GUI, then the property setting GUI, then places the
% object in the room if valid inputs were given.
    function AddRack_callback(src,eventdata)
        answer = PositionSetGUI(Rm,'ServerRack',[]);
        if ~isempty(answer) % Was a position returned?
            % Vertex vectors
            p1 = answer{1};
            p2 = answer{2};
            Rck = ServerRack(p1,p2,Profile('FR'),Profile('HG'),Profile('TR'),[]);
            Rck.Room = Rm;
            Rck = rack_properties(Rck);
            if ~IsProfileEmpty(Rck.FlowProfile) && ...
                    ~IsProfileEmpty(Rck.HeatGenProfile) && ...
                    ~IsProfileEmpty(Rck.TempRiseProfile)
                Rm.AddFlowObject(Rck);
                Rm.UpdateDisplay
            end
        end
    end

% For the "Inlet" button. Similar process to the "Server Rack" button.
    function AddInlet_callback(src,eventdata)
        answer = PositionSetGUI(Rm,'Inlet',[]);
        if ~isempty(answer) % Was a position returned?
            % Vertex vectors
            p1 = answer{1};
            p2 = answer{2};
            % Orientation number
            p3 = answer{3};
            InL = Boundary('Inlet',p1,p2,Profile('FR'),p3);
            InL.Room = Rm;
            InL = boundary_properties(InL);
            if ~IsProfileEmpty(InL.FlowProfile)
                Rm.AddFlowObject(InL);
                Rm.UpdateDisplay
            end
        end
    end

% For the "Outlet" buttons. Similar process to the "Server Rack" button.
    function AddOutlet_callback(src,eventdata)
        answer = PositionSetGUI(Rm,'Outlet',[]);
        if ~isempty(answer) % Was a position returned?
            % Vertex vectors
            p1 = answer{1};
            p2 = answer{2};
            % Orientation number
            p3 = answer{3};
            OutL = Boundary('Outlet',p1,p2,Profile('FR'),p3);
            OutL.Room = Rm;
            OutL = boundary_properties(OutL);
            if ~IsProfileEmpty(OutL.FlowProfile)
                Rm.AddFlowObject(OutL);
                Rm.UpdateDisplay
            end
        end
    end

    function AddPartition_callback(src,eventdata)
        answer = PositionSetGUI(Rm,'Partition',[]);
        if ~isempty(answer) % Was a position returned?
            % Vertex vectors
            p1 = answer{1};
            p2 = answer{2};
            PT = Partition(p1,p2);
            PT.Room = Rm;
            PT = namebox(PT);
            if ~isempty(PT.Orientation)
                Rm.AddFlowObject(PT);
                Rm.UpdateDisplay
            end
        end
    end

    function AddObstacle_callback(src,eventdata)
        answer = PositionSetGUI(Rm,'Obstacle',[]);
        if ~isempty(answer) % Was a position returned?
            % Vertex vectors
            p1 = answer{1};
            p2 = answer{2};
            % Orientation number: not that the obstacle has an orientation
            % to it, but it does hold information as to the axes from which
            % it was created.
            p3 = answer{3};
            OB = Obstacle(p1,p2);
            OB.Orientation = p3;
            OB.Room = Rm;
            OB = namebox(OB);
            Rm.AddFlowObject(OB);
            Rm.UpdateDisplay
        end
    end

%% Object Option Callbacks

% For the "Move Object" button. Reopens the position-setting GUI to allow
% the selected object to be moved and resized. If the flow face has changed
% shape, the flow profile is cleared as well.
    function MoveObj_callback(src,eventdata)
        if ~isempty(Rm.SelectedObject)
            SelO = Rm.SelectedObject;
            V = SelO.Vertices;
            Ori = SelO.Orientation;
            ObjType = class(SelO);
            switch ObjType
                case 'ServerRack'
                    [A,B,ARC,BRC] = GetOutFace(SelO);
                case {'Inlet','Outlet'}
                    [A,B,ARC,BRC] = GetFace(SelO);
                case 'Partition'
                    [A,B,ARC,BRC] = GetFace(SelO,SelO.Orientation);
                case 'Obstacle'
                    [A,B,ARC,BRC] = GetFace(SelO,SelO.Orientation);
            end
            DIM_1 = nonzeros(B-A)';
            Rm.DeleteCurrentFlowObject;
            UpDispFlag = 0;
            POS = PositionSetGUI(Rm,ObjType,V);
            if ~isempty(POS)
                SelO.Vertices = [POS{1};POS{2}];
                if length(POS) == 3
                    SelO.Orientation = POS{3};
                end
                % revert changes if the new location is invalid
                if ~ValidPosition(Rm,SelO)
                    SelO.Vertices = V;
                    SelO.Orientation = Ori;
                    Rm.SelectedObject = SelO;
                    Rm = AddFlowObject(Rm,SelO);
                else
                    delete(SelO.PatchProj)
                    delete(SelO.Patch3D)
%                     disp(Ori)
%                     disp(class(SelO))
                    if isa(SelO,'ServerRack')
                        SelO.Orientation = Ori;
                    end
                    Rm.SelectedObject = SelO;
                    Rm = AddFlowObject(Rm,SelO);
                    UpDispFlag = 1;
%                     Rm.UpdateDisplay
                end
                switch class(SelO)
                    case 'ServerRack'
                        [A,B,ARC,BRC] = GetOutFace(SelO);
                        DIM_2 = nonzeros(B-A)';
                        if ~isequal(DIM_1,DIM_2)
                            ClearProfile(SelO.FlowProfile)
                            ClearProfile(SelO.TempRiseProfile)
                            ClearProfile(SelO.HeatGenProfile)
                            disp('Object flow face size was changed. Profile was cleared.')
                            ChgProperty_callback;
                        end
                    case {'Outlet','Inlet'}
                        [A,B,ARC,BRC] = GetFace(SelO);
                        DIM_2 = nonzeros(B-A)';
                        if ~isequal(DIM_1,DIM_2)
                            ClearProfile(SelO.FlowProfile)
                            disp('Object flow face size was changed. Profile was cleared.')
                            ChgProperty_callback;
                        end
                end
                if UpDispFlag
                    Rm.UpdateDisplay
                end
            else
                SelO.Vertices = V;
                SelO.Orientation = Ori;
                Rm.SelectedObject = SelO;
                Rm = AddFlowObject(Rm,SelO);
            end
        end
    end

    function ChgProperty_callback(src,eventdata)
        SOclass = class(Rm.SelectedObject);
        switch SOclass
            case {'Inlet','Outlet'}
                Rm.SelectedObject = boundary_properties(Rm.SelectedObject);
                if ~strcmp(class(Rm.SelectedObject),SOclass) % was the class of the object changed?
                    delete(Rm.SelectedObject.PatchProj)
                    delete(Rm.SelectedObject.Patch3D)
                    Rm = ReclassifyCurrentFO(Rm);
                    Rm.UpdateDisplay
                end
            case 'ServerRack'
                Rm.SelectedObject = rack_properties(Rm.SelectedObject);
            case {'Partition','Obstacle'}
                Rm.SelectedObject = namebox(Rm.SelectedObject);
        end
        Rm.UpdateDisplay
    end

    function DeleteCurrent_callback(src,eventdata)
        if ~isempty(Rm.SelectedObject)
            delete(Rm.SelectedObject.PatchProj)
            delete(Rm.SelectedObject.Patch3D)
            Rm.DeleteCurrentFlowObject;
            Rm.UpdateDisplay;
        end
    end

    function ListMove_callback(src,eventdata,LMdirec)
        TT = Rm.SelectedObject;
        switch LMdirec
            case 'up'
                shiftpos = -1;
            case 'down'
                shiftpos = 1;
        end
        if ~isempty(TT)
            K1 = get(ObjectListBox, 'Value');
            [AllObj,AO_ind,AO_type] = NumListObjs(Rm);
            NoUp = AO_ind(K1) == 1;
            NoDown = K1 == length(AO_ind) || AO_ind(K1+1) == 1;
            if (strcmp(LMdirec,'up') && ~NoUp) || (strcmp(LMdirec,'down') && ~NoDown)
                switch AO_type(K1)
                    case 1
                        F = Rm.ObjectList.ServerRacks{AO_ind(K1)};
                        Rm.ObjectList.ServerRacks{AO_ind(K1)} = Rm.ObjectList.ServerRacks{AO_ind(K1+shiftpos)};
                        Rm.ObjectList.ServerRacks{AO_ind(K1+shiftpos)} = F;
                    case 2
                        F = Rm.ObjectList.Inlets{AO_ind(K1)};
                        Rm.ObjectList.Inlets{AO_ind(K1)} = Rm.ObjectList.Inlets{AO_ind(K1+shiftpos)};
                        Rm.ObjectList.Inlets{AO_ind(K1+shiftpos)} = F;
                    case 3
                        F = Rm.ObjectList.Outlets{AO_ind(K1)};
                        Rm.ObjectList.Outlets{AO_ind(K1)} = Rm.ObjectList.Outlets{AO_ind(K1+shiftpos)};
                        Rm.ObjectList.Outlets{AO_ind(K1+shiftpos)} = F;
                    case 4
                        F = Rm.ObjectList.Partitions{AO_ind(K1)};
                        Rm.ObjectList.Partitions{AO_ind(K1)} = Rm.ObjectList.Partitions{AO_ind(K1+shiftpos)};
                        Rm.ObjectList.Partitions{AO_ind(K1+shiftpos)} = F;
                    case 5
                        F = Rm.ObjectList.Obstacles{AO_ind(K1)};
                        Rm.ObjectList.Obstacles{AO_ind(K1)} = Rm.ObjectList.Obstacles{AO_ind(K1+shiftpos)};
                        Rm.ObjectList.Obstacles{AO_ind(K1+shiftpos)} = F;
                end
            end
            Rm.UpdateListBox
        end
    end

    function ObjListBox_callback(src,eventdata)
        K = get(gcbo, 'Value'); % Get current list box object
        [AllObj,AO_ind,AO_type] = NumListObjs(Rm);
        if ~isempty(AO_ind) % if there are objects, find the
            % object that corresponds to the selected listbox entry
            switch AO_type(K)
                case 1
                    FObj = Rm.ObjectList.ServerRacks{AO_ind(K)};
                case 2
                    FObj = Rm.ObjectList.Inlets{AO_ind(K)};
                case 3
                    FObj = Rm.ObjectList.Outlets{AO_ind(K)};
                case 4
                    FObj = Rm.ObjectList.Partitions{AO_ind(K)};
                case 5
                    FObj = Rm.ObjectList.Obstacles{AO_ind(K)};
            end
            % Store that value in the Room object (so that it doesnt
            % get removed if the list is repopulated
            Rm.SelectedObject = FObj;
            % Make the selected object visually different
            Rm.HighlightSelObj;
        end
    end


%% Room Menu Callbacks

% Room Options

    function NewRoom_callback(src,eventdata)
        % Create a new room. Close the current figure and make a new one.
        close(gcf)
        Rm = makeroom;
    end

    function SaveRoom_callback(src,eventdata)
        % Save the current room configuration. Opens a save dialog to
        % store the Room object.
        addpath(pwd);
        cd('Room Configurations');
        [FileName,PathName,FilterIndex] = uiputfile('*.mat','Save Room Object','UntitledTestCase.mat');
        if FileName ~=0
            save([PathName FileName],'Rm')
            set(Rm.Figure,'Name',[FileName ' - Room Configuration ' Rm.RoomInfoStr])
        end
        cd('..');
        rmpath(pwd);
    end

    function LoadRoom_callback(src,eventdata)
        % Loads a room configuration. Opens a load dialog and assigns a Rm
        % object to the workspace if a valid file was selected, then opens
        % the new Room object with the room_shape GUI.
        [fname,pname] = uigetfile([pwd '\Room Configurations\*.mat'],...
            'Choose a Room Configuration');
        if fname ~= 0
            S = load([pname fname],'Rm');
            close(gcf)
            if ~isfield(S.Rm.ObjectList,'Partitions')
                S.Rm.ObjectList.Partitions = [];
            end
            assignin('base', 'Rm', S.Rm);
            room_shape(S.Rm);
            set(gcf,'Name',[fname ' - Room Configuration ' S.Rm.RoomInfoStr])
        end
    end

% Display Options

    function RefreshDisp_callback(src,eventdata)
        B = findobj(Rm.Figure,'Type','axes');
        for i = 1:length(B)
            cla(B(i)); % clear axes
        end
        Rm.UpdateDisplay;
    end

    function ReclassBound_callback(src,eventdata)
        [SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
        total_num = sum([SR_num I_num O_num P_num Ob_num]);
        [AllObj,AO_ind,AO_type] = NumListObjs(Rm);
        for i = 1:total_num
            if AO_type(i) == 2 || AO_type(i) == 3
                BO = AllObj{i};
                SW = MatchType(BO);
                if SW
                    Rm.SelectedObject = BO;
                    delete(Rm.SelectedObject.PatchProj)
                    delete(Rm.SelectedObject.Patch3D)
                    Rm = ReclassifyCurrentFO(Rm);
                end
            end
        end
        Rm.UpdateDisplay
    end

    function RefMesh_callback(src,eventdata)
        % Changes the mesh resolution of the current room configuration.
        % Does so by creating a blank room with the new resolution and
        % adding all flow objects to it.
        answer = inputdlg('Mesh Refinement Factor:',...
            'Shrink mesh by what factor?',1,{'2'},'on');
        if ~isempty(answer) && ~strcmp(answer{1},'0')
            mref = eval(answer{1});
            bton = 'Yes';
            if mref < 1
                bton = questdlg('Warning: Coarsening the mesh may result in averaging or summing of flow/heat/temperature profiles. Proceed?',...
                    'Mech Coarsening Warning');
            end
            if strcmp(bton,'Yes')
                Rm2 = Room(Rm.Dimensions, Rm.Resolution/mref);
                room_shape(Rm2);
                [SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
                SR = Rm.ObjectList.ServerRacks;
                IL = Rm.ObjectList.Inlets;
                OL = Rm.ObjectList.Outlets;
                PT = Rm.ObjectList.Partitions;
                OB = Rm.ObjectList.Obstacles;
                Rm2.ResultSettings = Rm.ResultSettings;
                Rm2.InletTemp = Rm.InletTemp;
                Rm2.VortexInfo = Rm.VortexInfo;
                for w = 1:SR_num
                    Rm2 = AddFlowObject(Rm2,SR{w});
                    Redist(SR{w}.FlowProfile,mref);
                    Redist(SR{w}.HeatGenProfile,mref);
                    Redist(SR{w}.TempRiseProfile,mref);
                end
                for x = 1:I_num
                    Rm2 = AddFlowObject(Rm2,IL{x});
                    Redist(IL{x}.FlowProfile,mref);
                end
                for y = 1:O_num
                    Rm2 = AddFlowObject(Rm2,OL{y});
                    Redist(OL{y}.FlowProfile,mref);
                end
                for z = 1:P_num
                    Rm2 = AddFlowObject(Rm2,PT{z});
                end
                for a = 1:Ob_num
                    Rm2 = AddFlowObject(Rm2,OB{a});
                end
                close(Rm.Figure);
                Rm2.UpdateDisplay;
                assignin('base', 'Rm', Rm2);
            end
        end
    end

    function SingleCell_callback(src,eventdata)
        % Opens a GUI which asks you to specify a cell in the room, then 
        % gives some basic statistics about that cell and its neighbors.
        SingleCellDetails(Rm);
    end

% Run Options

    function SolOpt_callback(src,eventdata)
        SolverOptionsGUI(Rm);
    end

    function Run_callback(src,eventdata)
        % Begins the steps necessary to run the model. First checks that
        % the solver options have the flow solver enabled and that the room
        % is solvable.
        if Rm.ResultSettings.Phi == 1 && Rm.CheckSolvable
            % Check for outlet-inlet flow match
            Rm.correct_flows;
            % Now solve for flow.
            FlowResults = SolvePotMatrix(Rm);
            % Do the solver options have the temperature solver enabled? In
            % either case, assign the final generated results to the
            % workspace.
            assignin('base', 'FlowResults', FlowResults);
            if Rm.ResultSettings.Temp == 0
                figure(Rm.Figure)
                ListResultsGUI(FlowResults)
            elseif Rm.ResultSettings.Temp == 1
                [room_config,partition_config,u0,v0,w0,Q] = extract_BC_data(Rm);
                if nnz(Q)>0
                    TempResults = SolveHeatMatrix(FlowResults);
                    assignin('base', 'TempResults', TempResults);
                    if Rm.ResultSettings.VortexSuper == 1
%                         disp('CHK1')
                        if isempty(Rm.VortexInfo)
                            AutoVorPlace_callback;
                        end
                        TempResults = VortexSuperposition(TempResults);
                        TempResults = SolveHeatMatrix(TempResults);
                        assignin('base', 'TempResults_VS', TempResults);
                    end
                    if Rm.ResultSettings.ExergyDest == 1
%                         disp('CHK2')
                        ExDestResults = ExergyDestruction(TempResults);
                        assignin('base', 'ExDestResults', ExDestResults);
                        figure(Rm.Figure)
                        ListResultsGUI(ExDestResults)
                    else
%                         disp('CHK3')
                        figure(Rm.Figure)
                        ListResultsGUI(TempResults)
                    end
                else
                    uiwait(errordlg('No heat generation in the room!','Temperature solver stopped'))
                    figure(Rm.Figure)
                    ListResultsGUI(FlowResults)
                end
            end
            beep;
        end
    end

% Result Options

    function LoadResults_callback(src,eventdata,loadtype)
        % Loads results into the ListResults GUI. Also opens the room_shape
        % GUI for the room associated with the results object.
        switch loadtype
            case 'file' % Either grab a stored results file
                [fname,pname] = uigetfile([pwd '\Generated Results\*.mat'],...
                    'Choose a Stored Result File');
                if fname ~= 0
                    qstr = ['This will load the room associated with these ',...
                        'results, replacing the currently loaded room. Continue?'];
                    button = questdlg(qstr,'Warning','Yes','No','Yes');
                    if strcmp(button,'Yes')
                        S = load([pname fname],'ResultData');
                        if ~isfield(S.ResultData.Room.ObjectList,'Partitions')
                            S.ResultData.Room.ObjectList.Partitions = [];
                        end
                        assignin('base', 'ResultData', S.ResultData);
                        assignin('base', 'Rm', S.ResultData.Room);
                        close(gcf)
                        room_shape(S.ResultData.Room);
                        LoadedFromFile = S.ResultData;
                        ListResultsGUI(LoadedFromFile)
                    end
                end
            case 'wksp' % Or grab the results object from the workspace.
                S = evalin('base','whos');
                str = {};
                for rr = 1:length(S)
                    if strcmp(S(rr).class,'Results')
                        str{end+1} = S(rr).name;
                    end
                end
                if ~isempty(str)
                    [s,v] = listdlg('PromptString','Select a Result Dataset:',...
                        'SelectionMode','single',...
                        'ListString',str);
                    if v == 1
                        qstr = ['This will load the room associated with these ',...
                            'results, replacing the currently loaded room. Continue?'];
                        button = questdlg(qstr,'Warning','Yes','No','Yes');
                        if strcmp(button,'Yes')
                            locRD = evalin('base',str{s});
                            close(gcf)
                            room_shape(locRD.Room);
                            LoadedFromWksp = locRD;
                            evalin('base',['ListResultsGUI(' str{s} ')'])
                        end
                    end
                elseif isempty(str)
                    warndlg('No Result-class objects in the base workspace','Nothing to load')
                end
        end
    end

% Vortex Options

    function AutoVorPlace_callback(src,eventdata)
        if ~isempty(Rm.VortexInfo)
            qstr = 'You have existing vortices/aisles placed. Overwrite?';
            button = questdlg(qstr,'Warning','Yes','No','Yes');
            if strcmp(button,'Yes')
                Rm.VortexInfo = AutomatedVortexPlacement(Rm);
                ViewVortex(Rm,Rm.VortexInfo)
            end
        else 
            RVI = AutomatedVortexPlacement(Rm);
            Rm.VortexInfo = RVI;
            ViewVortex(Rm,Rm.VortexInfo)
        end
    end
    
    function VorPlace_callback(src,eventdata)
        Rm.VortexPlacementGUI;
    end

    function VorView_callback(src,eventdata)
        ViewVortex(Rm,Rm.VortexInfo)
    end
end