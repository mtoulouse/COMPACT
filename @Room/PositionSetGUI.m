function POS = PositionSetGUI(Rm,ObjType,InitVert)
%POSITIONSETGUI Creates the object placement GUI.
%   POSITIONSETGUI builds a GUI figure in which to place a flow object, 
%   based on the room input and the object type to place. The top projected
%   view is shown next to some relevant fields (vertex positions, rack 
%   height). Buttons are also present to snap the rectangle to the nearest
%   resolution and finalize the object placement. Initial vertices for the 
%   placement rectangle can be specified, in case the function was called 
%   in order to move an existing object and not create a new one.
%
%
%   Outputs have different lengths depending on the object type:
%       {} if cancelled
%       {Vertex1 Vertex2} for Obstacles/Racks
%       {Vertex1 Vertex2 Orientation of reference wall} for Inlets/Outlets

POS = {}; % Default output
rd = Rm.Dimensions;
res = Rm.Resolution;
rd_v = rd + 2*res;
ListString = {'Wall @ +X';'Wall @ -X';'Wall @ +Y';'Wall @ -Y';'Ceiling @ +Z'; 'Floor @ -Z'};
switch ObjType
    case {'Inlet','Outlet','Partition','Obstacle'}
        % Open a list dialog with options for wall to place object relative
        % to
        [side,v] = listdlg('PromptString',['Surface to Place ' ObjType ' Relative to:'],...
            'SelectionMode','single',...
            'ListString',ListString);
        if v == 0
            return % just stop here if no selection was made.
        else
            % choose the appropriate projected view and dimensions of the view
            switch side
                case {1,2} %+/-X
                    shownaxes = findobj(Rm.Figure,'Tag','Right View Axes');
                    L = rd_v(3);
                    W = rd_v(2);
                    D = rd(1);
                    dim3name = 'X';
                    VertCoStr = '(Y,Z)';
                case {3,4} %+/-Y
                    shownaxes = findobj(Rm.Figure,'Tag','Front View Axes');
                    L = rd_v(1);
                    W = rd_v(3);
                    D = rd(2);
                    dim3name = 'Y';
                    VertCoStr = '(X,Z)';
                case {5,6} %+/-Z
                    shownaxes = findobj(Rm.Figure,'Tag','Top View Axes');
                    L = rd_v(1);
                    W = rd_v(2);
                    D = rd(3);
                    dim3name = 'Z';
                    VertCoStr = '(X,Y)';
            end
        end
    otherwise
        % the default views/dimensions
        side = 6;
        dim3name = 'Z';
        shownaxes = findobj(Rm.Figure,'Tag','Top View Axes');
        L = rd_v(1);
        W = rd_v(2);
        D = rd(3);
        VertCoStr = '(X,Y)';
end
con_x = [0 L-2*res];
con_y = [0 W-2*res];
v_rat = .6; % fraction of figure for the view.

% set the dimensions for the figure depending on the view dimensions.
Fig_AR = (L/v_rat)/W;
if Fig_AR > 1.5
    FH = 450;
    FW = Fig_AR*FH;
else
    FW = 600;
    FH = FW/Fig_AR;
end

%% Create the GUI 
% Make the figure + panels/axes
PosSet = figure('Name',['Set Position of ' ObjType],...
    'Position',Center_Fig(FW,FH),...
    'NumberTitle','off','menubar','none');
set(PosSet,'DefaultUicontrolFontSize',12)

ButtonPanel = uipanel(PosSet,'Title','Placement Options',...
    'Units','normalized',...
    'Position',[v_rat 0 1-v_rat 1]);
ViewPanel = uipanel(PosSet,'Title','View of Room',...
    'Units','normalized',...
    'Position',[0 0 v_rat 1]);
ViewAxes = copyobj(shownaxes,ViewPanel);
axis(ViewAxes,'equal');

% if the view is from a wall, reverse the direction of the x/y coordinate 
% if necessary.
if side == 2 || side == 4
    set(ViewAxes,'XDir','reverse') % Projected View from main GUI, flipped x-coord
end
set(get(ViewAxes,'Children'),'HitTest','off')

% Make the buttons + fields + field labels
uicontrol(ButtonPanel,'Style','text',...
    'Units','normalized',...
    'Position',[0,.9,1,.1],...
    'String',['Place the ' ObjType]);

SnapButton = uicontrol(ButtonPanel,...
    'Units','normalized',...
    'Position',[.3 .85 .4 .1],...
    'String','Snap',...
    'Callback',@Snap_CBK);

VertexOne = uicontrol(ButtonPanel,'Style','edit',...
    'Units','normalized',...
    'BackGroundColor','w',...
    'Position',[.05,.65,.4,.1],...
    'String','0 , 0');
uicontrol(ButtonPanel,'Style','text',...
    'Units','normalized',...
    'Position',[.05,.75,.4,.05],...
    'String',['Vertex 1 ' VertCoStr]);

VertexTwo = uicontrol(ButtonPanel,'Style','edit',...
    'Units','normalized',...
    'BackGroundColor','w',...
    'Position',[.55,.65,.4,.1],...
    'String','0 , 0');
uicontrol(ButtonPanel,'Style','text',...
    'Units','normalized',...
    'Position',[.55,.75,.4,.05],...
    'String',['Vertex 2 ' VertCoStr]);

Dim3Panel = uipanel(ButtonPanel,...
    'Title',[dim3name ' Offset from ' ListString{side}],...
    'BorderType','line',...
    'FontSize',12,...
    'Units','normalized',...
    'Position',[.05 .5 .9 .1]);
FObjDim3 = uicontrol(Dim3Panel,'Style','edit',...
    'Units','normalized',...
    'BackGroundColor','w',...
    'Position',[0,0,1,1]);


HgtPanel = uipanel(ButtonPanel,...
    'Title','Height',...
    'BorderType','line',...
    'FontSize',12,...
    'Units','normalized',...
    'Position',[.05 .35 .9 .1],...
    'Visible','off');
FObjHgt = uicontrol(HgtPanel,'Style','edit',...
    'Units','normalized',...
    'BackGroundColor','w',...
    'Position',[0,0,1,1]);

PlaceButton = uicontrol(ButtonPanel,...
    'Units','normalized',...
    'Position',[.3 .2 .4 .1],...
    'String','Place',...
    'Callback',@Place_CBK);

CancelButton = uicontrol(ButtonPanel,...
    'Units','normalized',...
    'Position',[.3 .075 .4 .1],...
    'String','Cancel',...
    'Callback','close(gcf)');

% Placing the rectangle

% Default values for the rectangle x/y constraints, and initial rectangle

if isempty(InitVert)
    defaultV1 = .4*[L W];
    defaultV2 = .6*[L W];
    defaultdim3 = 0;
    defaulthgt = res;
else
    switch side
        case {1,2}
            defaultV1 = InitVert(1,[3 2]);
            defaultV2 = InitVert(2,[3 2]);
            defaultdim3 = InitVert(1,1);
            if side == 1
                defaultdim3 = D-defaultdim3;
            end
            defaulthgt = InitVert(2,1)-InitVert(1,1);
        case {3,4}
            defaultV1 = InitVert(1,[1 3]);
            defaultV2 = InitVert(2,[1 3]);
            defaultdim3 = InitVert(1,2);
            if side == 3
                defaultdim3 = D-defaultdim3;
            end
            defaulthgt = InitVert(2,2)-InitVert(1,2);
        case {5,6}
            defaultV1 = InitVert(1,[1 2]);
            defaultV2 = InitVert(2,[1 2]);
            defaultdim3 = InitVert(1,3);
            if side == 5
                defaultdim3 = D-defaultdim3;
            end
            defaulthgt = InitVert(2,3)-InitVert(1,3);
    end
end
% Set the rectangle color
switch ObjType
    case 'Inlet'
        col = 'b';
        if isempty(InitVert)
            defaulthgt = 0;
        end
    case 'Outlet'
        col = 'r';
        if isempty(InitVert)
            defaulthgt = 0;
        end
    case 'ServerRack'
        col = 'g';
        set(HgtPanel,'Title','Rack Height')
        set(HgtPanel,'Visible','on')
    case 'Partition'
        col = 'm';
        defaulthgt = 0;
    case 'Obstacle'
        col = 'k';
        set(HgtPanel,'Title','Obstacle Depth')
        set(HgtPanel,'Visible','on')
end
set(FObjDim3,'String',num2str(defaultdim3))
set(FObjHgt,'String',num2str(defaulthgt))


% Create the rectangle
hrect = imrect(ViewAxes, [defaultV1 defaultV2-defaultV1],...
    'PositionConstraintFcn',makeConstrainToRectFcn('imrect',con_x,con_y));
setColor(hrect,col);
Snap_CBK;

uiwait % The rest of the model waits for this GUI to finish its task.

    function Snap_CBK(src,eventdata)
        % "Snap" function to round the rectangle dimensions to the nearest
        % resolution. Change the fields showing the coordinates, too.
        pos = getPosition(hrect);
        RecV = [pos(1:2) pos(1:2)+pos(3:4)];
        RecV = round(RecV/res)*res;
        V1 = RecV(1:2);
        V2 = RecV(3:4);
        if any(V2-V1 == 0) % prevent zero-length dimension
            ind = find(V2-V1 == 0);
            max_constr = [L W] - 2*res;
            if V2(ind) == max_constr(ind) %
                V1(ind) = V1(ind)-res;
            else
                V2(ind) = V2(ind)+res;
            end
        end

        setPosition(hrect,[V1 V2-V1])
        set(VertexOne,'String',[num2str(V1(1)) ' , ' num2str(V1(2))])
        set(VertexTwo,'String',[num2str(V2(1)) ' , ' num2str(V2(2))])
        if side == 2 %|| side == 4
            % if a side view, swap the x/y coordinates to reflect the
            % greater room convention.
            set(VertexOne,'String',[num2str(V1(2)) ' , ' num2str(V1(1))])
            set(VertexTwo,'String',[num2str(V2(2)) ' , ' num2str(V2(1))])
        end
        d3 = str2double(get(FObjDim3,'String'));
        d3 = round(d3/res)*res; % round to nearest resolution
        d3 = min(d3,D); % lower if not in room
        d3 = max(d3,0); % raise if below zero
        hgt = str2double(get(FObjHgt,'String'));
        hgt = round(hgt/res)*res; % round to nearest resolution
        hgt = max(0,hgt);
        if strcmp(ObjType,'ServerRack') || strcmp(ObjType,'Obstacle')
            d3 = min(d3,D-res);
            hgt = max(res,hgt); % raise if below one unit height
            hgt = min(hgt,D-d3); % lower if raising above room
        end
        set(FObjDim3,'String',num2str(d3))
        set(FObjHgt,'String',num2str(hgt))
    end

    function Place_CBK(src,eventdata)
        Snap_CBK % round the vertices, just in case.
        pos = getPosition(hrect);
        % Get the rectangle coordinates and convert to the 3-D vertices of
        % the displayed object. For inlets/ outlets this can mean setting
        % the coordinate which is undefined by the rectangle to be one
        % resolution unit deep into the wall.
        d3 = str2double(get(FObjDim3,'String'));
        hgt = str2double(get(FObjHgt,'String'));
        offset = d3;
        switch side
            case 1 % relative to +X wall
                POS{1} = [D-offset pos(2) pos(1)];
                POS{2} = [D-offset-hgt pos(2)+pos(4) pos(1)+pos(3)];
            case 2 % relative to -X wall
                POS{1} = [offset pos(2) pos(1)];
                POS{2} = [offset+hgt pos(2)+pos(4) pos(1)+pos(3)];
            case 3 % relative to +Y wall
                POS{1} = [pos(1) D-offset pos(2)];
                POS{2} = [pos(1)+pos(3) D-offset-hgt pos(2)+pos(4)];
            case 4 % relative to -Y wall
                POS{1} = [pos(1) offset pos(2)];
                POS{2} = [pos(1)+pos(3) offset+hgt pos(2)+pos(4)];
            case 5 % relative to ceiling
                POS{1} = [pos(1:2) D-offset];
                POS{2} = [pos(1:2)+pos(3:4) D-offset-hgt];
            case 6 % relative to floor
                POS{1} = [pos(1:2) offset];
                POS{2} = [pos(1:2)+pos(3:4) offset+hgt];
        end
        if ~strcmp(ObjType,'ServerRack')
            POS{3} = side;
        else 
            POS{3} = [];
        end
        
        close(gcf); % close the GUI
    end
end