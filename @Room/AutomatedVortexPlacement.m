function VortInfo = AutomatedVortexPlacement(Rm)
%AUTOMATEDVORTEXPLACEMENT Automatic vortex and aisle placement function
%   AUTOMATEDVORTEXPLACEMENT does not make a GUI to manually place vortices
%   and aisles; that is elsewhere. This function is purely about specifying
%   vortex info for use in other functions. 
%   1) RowFinder.m reads the room object, sorts racks/obstacles into 
%   clusters/rows
%   2) Sets the tops of these clusters to be the vortex placement
%   coordinates
%   3) "Extrudes" aisles out from the flow faces of these rows of racks
%   until they hit a surface.

%% Define full row vertices
VortInfo = [];
[AllObj,AO_ind,AO_type] = NumListObjs(Rm);
res = Rm.Resolution;
[room_config,partition_config,u0,v0,w0,Q] = extract_BC_data(Rm);
RF = RowFinder(Rm);
listind = 0;
rownum = length(RF);

inairratio = 30/100; % if the next slice has less than this much in the air, stop
extrude_multiplier = 2; %multiples of rack depth to extrude out

for i = 1:rownum
    RowObs = RF{i};
    RV1 = [];
    RV2 = [];
    RDir = [];
    for j = 1:length(RowObs)
        RV1 = [RV1; AllObj{RowObs(j)}.Vertices(1,:)];
        RV2 = [RV2; AllObj{RowObs(j)}.Vertices(2,:)];
        RDir = [RDir AllObj{RowObs(j)}.Orientation];
    end
    
    RowVerts{i} = [min(RV1,[],1);max(RV2,[],1)];
    rowtop = RowVerts{i};
    rowtop(1,3) = max(RV2(:,3),[],1);
    
    listind = listind + 1;
    VortInfo(listind).Type = 'Vortex';
    VortInfo(listind).Vertices = rowtop;
    VortInfo(listind).Links = [listind+1 listind+2];
    
    switch mode(RDir)
        case {1,2}
            rowdir{i} = 'X';
            c = 1;
        case {3,4}
            rowdir{i} = 'Y';
            c = 2;
    end
    
    rowface1 = RowVerts{i};
    rowface1(:,c) = mode(RV1(:,c));
    rowface2 = RowVerts{i};
    rowface2(:,c) = mode(RV2(:,c));
    
    rackdep = rowtop(2,c)-rowtop(1,c);
    
    % define the aisle in the -1 direction
    inair = 1;
    if c == 1
        nextslice = rowface1 + res*[-1 0 0; 0 0 0];
    elseif c == 2
        nextslice = rowface1 + res*[0 -1 0; 0 0 0];
    end
    
    while inair > inairratio
        nextslice(:,c) = nextslice(:,c) - res;
        rc = nextslice/res + [2 2 2; 1 1 1];
        slice_rc = room_config(rc(1,1):rc(2,1),rc(1,2):rc(2,2),rc(1,3):rc(2,3));
        inair = nnz(slice_rc)/numel(slice_rc);
        if abs(nextslice(1,c)-rowface1(1,c)) > extrude_multiplier*rackdep
            break;
        end
    end
    nextslice(:,c) = nextslice(:,c) + res;
    aisle1 = [nextslice(1,:);  rowface1(2,:)];
    
    listind = listind + 1;
    VortInfo(listind).Type = 'Aisle';
    VortInfo(listind).Vertices = aisle1;
    VortInfo(listind).Links = listind-1;
    
    % define the aisle in the +1 direction
    inair = 1;
    if c == 1
        nextslice = rowface2 + res*[0 0 0; 1 0 0];
    elseif c == 2
        nextslice = rowface2 + res*[0 0 0; 0 1 0];
    end
    while inair > inairratio
        nextslice(:,c) = nextslice(:,c) + res;
        rc = nextslice/res + [2 2 2; 1 1 1];
        slice_rc = room_config(rc(1,1):rc(2,1),rc(1,2):rc(2,2),rc(1,3):rc(2,3));
        inair = nnz(slice_rc)/numel(slice_rc);
        if abs(nextslice(2,c)-rowface2(1,c)) > extrude_multiplier*rackdep
            break;
        end
    end
    nextslice(:,c) = nextslice(:,c) - res;
    aisle2 = [rowface2(1,:); nextslice(2,:)];
    
    listind = listind + 1;
    VortInfo(listind).Type = 'Aisle';
    VortInfo(listind).Vertices = aisle2;
    VortInfo(listind).Links = listind-2;
end
disp(['Automatically placed ' num2str(rownum) ' vortices, ' num2str(2*rownum) ' aisles'])