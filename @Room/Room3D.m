function Room3D(Rm)
%ROOM3D Creates the 3-D view of the room
%   ROOM3D takes the current room object and creates the graphics objects
%   showing locations of each flow object in the room. Also stores the
%   "patch" objects corresponding to each flow object in its "Patch3D"
%   property for easy access in other functions.
%% First format the axes
ax = findobj(Rm.Figure,'Tag','3D Axes');
% cla(ax)
% title(ax,[])
set(Rm.Figure,'CurrentAxes',ax)
set(ax,'FontSize',14)
axis manual
rdx = Rm.Dimensions(1);
rdy = Rm.Dimensions(2);
rdz = Rm.Dimensions(3);
res = Rm.Resolution;
grid on; box on; view(3);
daspect([1 1 1]);
xlabel(['X (' Air.abbr ')']);
ylabel(['Y (' Air.abbr ')']);
zlabel(['Z (' Air.abbr ')']);

xlim([-res rdx+res]);
ylim([-res rdy+res]);
zlim([-res rdz+res]);

%% Now start creating the 3-D objects
% Gray room borders, mostly transparent, but with floor and ceiling
% slightly more opaque
roomvert = [0 0 0
    rdx 0 0
    rdx rdy 0
    0 rdy 0
    0 0 rdz
    rdx 0 rdz
    rdx rdy rdz
    0 rdy rdz];
roomwalls = [1 4 8 5; 2 3 7 6 ; 1 2 6 5 ; 4 3 7 8];
roomtopbot = [1 2 3 4; 5 6 7 8];

if isempty(findobj(ax,'Type','patch','Vertices',roomvert))
    h1 = patch('Vertices',roomvert,'Faces',roomwalls,'FaceColor',[0 0 0]);
    h2 = patch('Vertices',roomvert,'Faces',roomtopbot,'FaceColor',[0 0 0]);
    set(h1,'FaceAlpha',0.05,'HitTest','off');
    set(h2,'FaceAlpha',0.1,'HitTest','off');
end

% now make the actual in-room objects
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
    if isempty(CurrOb.Patch3D) || any(~ishandle(CurrOb.Patch3D))
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
        ThreeD = patch('Vertices',V,'Faces',F,'FaceAlpha',patchalpha,...
            'FaceColor',patchcolor,'UserData',CurrOb);
        CurrOb.Patch3D = ThreeD;
    end
end

%% Set the tick labeling and separation on the x/y/z axes
label_spacing = floor(max(Rm.Dimensions/res)/8);
label_res = max(1,ceil(res*label_spacing)); % label resolution (label the coordinate every
% multiple of __, or at 2x the resolution )
XT = 0:res:rdx;
for x = 1:length(XT)
    if mod(XT(x),label_res) == 0
        XTL{x} = XT(x);
    else
        XTL{x} = '';
    end
end
set(gca,'XTick',XT);
set(gca,'XTickLabel',XTL);

YT = 0:res:rdy;
for x = 1:length(YT)
    if mod(YT(x),label_res) == 0
        YTL{x} = YT(x);
    else
        YTL{x} = '';
    end
end
set(gca,'YTick',YT);
set(gca,'YTickLabel',YTL);

ZT = 0:res:rdz;
for x = 1:length(ZT)
    if mod(ZT(x),label_res) == 0
        ZTL{x} = ZT(x);
    else
        ZTL{x} = '';
    end
end
set(gca,'ZTick',ZT);
set(gca,'ZTickLabel',ZTL);

rotate3d on % allow user rotation of the 3-D view.
end