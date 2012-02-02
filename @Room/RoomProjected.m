function RoomProjected(Rm)
%ROOMPROJECTED Creates the projected views of the room
%   ROOMPROJECTED takes the current room object, finds the appropriate axes
%   in which the projected views are displayed, clears them, and creates
%   the graphics objects showing locations of each flow object in the room.
%   Also stores the "patch" objects corresponding to each flow object in
%   its "PatchProj" property for easy access in other functions.

rd = Rm.Dimensions;
res = Rm.Resolution;
topaxes = findobj(Rm.Figure,'Tag','Top View Axes');
frontaxes = findobj(Rm.Figure,'Tag','Front View Axes');
rightaxes = findobj(Rm.Figure,'Tag','Right View Axes');
%% First correctly format each axis
% Treat the top axes
% cla(topaxes)
set(topaxes,'Position',[0 0 1 1],...
    'GridLineStyle','-',...
    'Xtick',0:res:rd(1),...
    'Ytick',0:res:rd(2),...
    'XtickLabel',[],...
    'YtickLabel',[],...
    'XLim',[-res rd(1)+res],...
    'YLim',[-res rd(2)+res])
axis manual
grid(topaxes,'on');
rectangle('Position',[0 0 rd(1) rd(2)],'Parent',topaxes,'LineWidth',2)
setAllowAxesRotate(rotate3d(topaxes),topaxes,false)

% Treat the front axes
% cla(frontaxes)
set(frontaxes,'Position',[0 0 1 1],...
    'GridLineStyle','-',...
    'Xtick',0:res:rd(1),...
    'Ytick',0:res:rd(3),...
    'XtickLabel',[],...
    'YtickLabel',[],...
    'XLim',[-res rd(1)+res],...
    'YLim',[-res rd(3)+res])
axis manual
grid(frontaxes,'on');
rectangle('Position',[0 0 rd(1) rd(3)],'Parent',frontaxes,'LineWidth',2)
setAllowAxesRotate(rotate3d(frontaxes),frontaxes,false)

% Treat the right axes
% cla(rightaxes)
set(rightaxes,'Position',[0 0 1 1],...
    'GridLineStyle','-',...
    'Xtick',0:res:rd(3),...
    'Ytick',0:res:rd(2),...
    'XtickLabel',[],...
    'YtickLabel',[],...
    'XLim',[-res rd(3)+res],...
    'YLim',[-res rd(2)+res])
axis manual
grid(rightaxes,'on');
rectangle('Position',[0 0 rd(3) rd(2)],'Parent',rightaxes,'LineWidth',2)
setAllowAxesRotate(rotate3d(rightaxes),rightaxes,false)

%% Now fill in the object locations
[SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
SR = Rm.ObjectList.ServerRacks;
I = Rm.ObjectList.Inlets;
O = Rm.ObjectList.Outlets;
P = Rm.ObjectList.Partitions;
Ob = Rm.ObjectList.Obstacles;
total_num = SR_num+I_num+O_num+P_num+Ob_num;
AllObj = [SR I O P Ob];
for i = 1:total_num
    CurrOb = AllObj{i};
    if isempty(CurrOb.PatchProj) || any(~ishandle(CurrOb.PatchProj))
        [V, F] = PatchData(CurrOb);
        switch class(CurrOb)
            case 'Inlet'
                patchcolor = 'b';
                patchalpha = 0.4;
            case 'Outlet'
                patchcolor = 'r';
                patchalpha = 0.4;
            case 'ServerRack'
                patchcolor = 'g';
                patchalpha = 0.4;
            case 'Partition'
                patchcolor = 'm';
                patchalpha = 0.25;
            case 'Obstacle'
                patchcolor = 'k';
                patchalpha = 0.25;
        end
        axes(topaxes)
        T = patch('Vertices',V([5 6 7 8],[1 2]),'Faces',[1 2 3 4],...
            'FaceAlpha',patchalpha,'FaceColor',patchcolor,'UserData',CurrOb);
        axes(frontaxes)
        F = patch('Vertices',V([1 2 6 5],[1 3]),'Faces',[1 2 3 4],...
            'FaceAlpha',patchalpha,'FaceColor',patchcolor,'UserData',CurrOb);
        axes(rightaxes)
        R = patch('Vertices',V([2 3 7 6],[3 2]),'Faces',[1 2 3 4],...
            'FaceAlpha',patchalpha,'FaceColor',patchcolor,'UserData',CurrOb);
        CurrOb.PatchProj = [T;F;R];
    end
end
end