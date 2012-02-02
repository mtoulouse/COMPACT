function YN = ValidPosition(Rm,FlowObj)
% Checks to see if FlowObj's position is valid. Called before
% adding to the current room configuration.

[SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
SR = Rm.ObjectList.ServerRacks;
I = Rm.ObjectList.Inlets;
O = Rm.ObjectList.Outlets;
P = Rm.ObjectList.Partitions;
Ob = Rm.ObjectList.Obstacles;
total_num = SR_num+I_num+O_num+P_num+Ob_num;
AllObj = [SR I O P Ob];

diradd = cat(3,[-1 0 0;0 0 0], ...
    [0 0 0;1 0 0],[0 -1 0;0 0 0],...
    [0 0 0;0 1 0],[0 0 -1;0 0 0],[0 0 0;0 0 1]);

% Checks to make:

% Quick note #1: we are treating server racks as obstacles, essentially.
% Checking in/outflowing faces of racks is for the CheckSolvable function.

% Quick note #2: for inlets+outlets, create a volume by translating
% the face out into the room one unit. If its volume overlaps w/
% something, flow is blocked!

% Physical volume overlap with any other object?
FO_class = class(FlowObj);
FO_vert = FlowObj.Vertices;
FaceArea = prod(nonzeros(FlowObj.Vertices(2,:)-FlowObj.Vertices(1,:)));

YN = true;
errstring = {};
BlockedFlow = false; % does an existing object block the object to be placed?
BlockingFlow = false; % does the object to be placed block an existing object?
ShareFace = false; % does the (flat) object being placed share a face with another flat object?
for h = 1:total_num
    curr_obj = AllObj{h};
    curr_class = class(curr_obj);
    curr_vert = curr_obj.Vertices;
    [VO, FO, EO] = FlowObject.BoxOverlap(FO_vert,curr_vert);
    if VO > 0 % volume overlap = error!
        YN = false;
        errstring{end+1} = [FO_class ' overlaps a ' curr_class '.'];
    end
    if strcmp(FO_class,'Inlet') || strcmp(FO_class,'Outlet')
        FO_extend =  FO_vert + diradd(:,:,FlowObj.Orientation);
        [VO, FO, EO] = FlowObject.BoxOverlap(FO_extend,curr_vert);
        if VO > 0
            BlockedFlow = true;
        end
        if FO > 0 && strcmp(curr_class,'Partition')
            ShareFace = true;
        end
    end
    if strcmp(curr_class,'Inlet') || strcmp(curr_class,'Outlet')
        curr_extend =  curr_vert + diradd(:,:,curr_obj.Orientation);
        [VO, FO, EO] = FlowObject.BoxOverlap(FO_vert,curr_extend);
        if VO > 0
            BlockingFlow = true;
        end
        if FO > 0 
            ShareFace = true;
        end
    end

end

OnWallObst = false;
[VO, FO, EO] = FlowObject.BoxOverlap(FO_vert,[0 0 0; Rm.Dimensions]);
if FO == 0 % face not on a wall
    for j = 1:Ob_num
        [VO, FO, EO] = FlowObject.BoxOverlap(FO_vert,Ob{j}.Vertices);
        if FO == FaceArea % Face is -fully- on an obstacle
            OnWallObst = true;
        end
    end
else %face is on a wall
    OnWallObst = true;
end

ShareFace = false;
switch FO_class
    case {'Inlet','Outlet'}
        if ~OnWallObst
            YN = false;
            errstring{end+1} = [FO_class ' not fully placed on a wall or obstacle.'];
        end
        if BlockedFlow
            YN = false;
            errstring{end+1} = [FO_class '''s flow is blocked by some object.'];
        end
        if ShareFace
            YN = false;
            errstring{end+1} = [FO_class ' shares a face with some other inlet or outlet or partition.'];
        end
    case {'ServerRack','Obstacle'}
        if BlockingFlow
            YN = false;
            errstring{end+1} = [FO_class ' is blocking the flow of some inlet or outlet.'];
        end
    case 'Partition'
        if ShareFace
            YN = false;
            errstring{end+1} = [FO_class ' shares a face with some inlet or outlet.'];
        end
end
% Check if any error conditions were met, and list them if
% present.
if ~YN
    errordlg(errstring,'Not a Valid Position!')
end
end