function ViewVortex(Rm,vortstr)
%VIEWVORTEX View intended placement of a vortex or aisle
%   VIEWVORTEX takes the current room and a data structure containing the
%   vortex and/or aisle information to be displayed, and creates a figure 
%   showing their locations overlaid on the room view. The data structure 
%   can be multiple entries long, so you can easily view all the vortices
%   and aisles in the room, or just one.
h1 = figure('Name','View Current Object',...
    'Numbertitle','off',...
    'Position',Center_Fig(600,500));
ax = findobj(Rm.Figure,'Tag','3D Axes');
ViewAxes = copyobj(ax,h1);
rotate3d on;
axis(ViewAxes);
% Grab all the displayed objects and add them the the display.
allpatches = findobj(ViewAxes,'Type','patch');
%         set(allpatches,'LineWidth',0.5)
%         set(allpatches,'Visible','off')
%         set(allpatches,'HandleVisibility','off')
for i = 1:length(vortstr)
    VortInfo = vortstr(i);
    link = VortInfo.Links;
    vert = VortInfo.Vertices;
    switch VortInfo.Type
        case 'Aisle'
            [V,F] = patchaisle(VortInfo);
            abox(i) = patch('Vertices',V,'Faces',F);
            set(abox(i),'FaceAlpha',0.2,'FaceColor','k','LineWidth',2);
        case 'Vortex'
            [V,F] = patchaisle(VortInfo);
            vbox(i) = patch('Vertices',V,'Faces',F);
            set(vbox(i),'FaceColor','c','LineWidth',2);
    end
end
end
%% graphical functions
function [V,F] = patchaisle(ais)
Fmin = min(ais.Vertices,[],1);
Fmax = max(ais.Vertices,[],1);
ais.Vertices = [Fmin;Fmax];

X1 = ais.Vertices(1,1);
Y1 = ais.Vertices(1,2);
Z1 = ais.Vertices(1,3);
X2 = ais.Vertices(2,1);
Y2 = ais.Vertices(2,2);
Z2 = ais.Vertices(2,3);

V(1,:) = [X1 Y1 Z1];
V(2,:) = [X2 Y1 Z1];
V(3,:) = [X2 Y2 Z1];
V(4,:) = [X1 Y2 Z1];
V(5,:) = [X1 Y1 Z2];
V(6,:) = [X2 Y1 Z2];
V(7,:) = [X2 Y2 Z2];
V(8,:) = [X1 Y2 Z2];

F = [1 2 3 4; 5 6 7 8; 1 4 8 5; 2 3 7 6 ; 1 2 6 5 ; 4 3 7 8];
end
