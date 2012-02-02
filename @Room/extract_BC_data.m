function [room_config,partition_config,u0,v0,w0,Q] = extract_BC_data(Rm)
%EXTRACT_BC_DATA Extracts room characteristics and relevant boundary
%conditions from a ROOM object.
%   EXTRACT_BC_DATA takes a room object and pulls out the room
%   configuration array, which records what nodes in the solution array are
%   within air. It also sets the location of prescribed boundary conditions
%   by processing flow object data as well. All outputs are the same size
%   as the solution array will be.
%
%   room_config: ones (air nodes) and zeros(internal nodes)
%   partition_config: 4-d field (x,y,z,dir). Ones mean "there is a 
%   partition adjacent to the cell (x,y,z) in this direction".
%   u0,v0,w0: prescribed flow rate in +x/+y/+z directions at a given node
%   Q: heat generation at a given node (on the "Out"-face of a server rack)

res = Rm.Resolution; % Room resolution
rd_v = Rm.Dimensions/res + 2; % room dimensions, in number of nodes

room_config = zeros(rd_v);
u0 = zeros(rd_v);
v0 = zeros(rd_v);
w0 = zeros(rd_v);
Q = zeros(rd_v);

[SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
ObjList = Rm.ObjectList;
RckList = ObjList.ServerRacks;
InList = ObjList.Inlets;
OutList = ObjList.Outlets;

% partition_config: stores the locations of cells on the surface of a zero-thickness
% partition, as well as the direction towards the partition from that
% point.

partition_config = zeros([size(room_config) 6]);
[SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
for h = 1:P_num
    [P1,P2,d1,d2] = GetFaces(Rm.ObjectList.Partitions{h});
    partition_config(P1(1,1):P1(2,1),P1(1,2):P1(2,2),P1(1,3):P1(2,3),d2) = 1;
    partition_config(P2(1,1):P2(2,1),P2(1,2):P2(2,2),P2(1,3):P2(2,3),d1) = 1;
end

% Initializing the interior room configuration matrix with 1.
% Virtual points outside the room, are still 0.
room_config(2:end-1,2:end-1,2:end-1) = 1;

for i = 1:SR_num % For each server rack
    Rck = RckList{i};
    VRC = Rck.Vertices/res + [2 2 2; 1 1 1]; % room_config array subscripts for the rack interior.
    % Fill room_config that is inside the rack with zeroes.
    room_config(VRC(1,1):VRC(2,1),VRC(1,2):VRC(2,2),VRC(1,3):VRC(2,3)) = 0;

    % Characterize in- and out-faces
    [A,B,A_in,B_in] = GetInFace(Rck); % Two points defining the inflow face
    [A,B,A_out,B_out] = GetOutFace(Rck); % Two points defining the outflow face

    %Set flow boundary conditions
    flow_profile = Rck.FlowProfile.Value';
    switch Rck.Orientation
        case 1 % Rack facing west
            flow_profile = -flow_profile; %flow is in a negative direction (-X)
            u0(A_in(1):B_in(1),A_in(2):B_in(2),A_in(3):B_in(3)) = flow_profile; %sets BC on in-face
            u0(A_out(1):B_out(1),A_out(2):B_out(2),A_out(3):B_out(3)) = flow_profile; %sets BC on out-face
        case 2 % Rack facing east
            u0(A_in(1):B_in(1),A_in(2):B_in(2),A_in(3):B_in(3)) = flow_profile;
            u0(A_out(1):B_out(1),A_out(2):B_out(2),A_out(3):B_out(3)) = flow_profile;
        case 3 % Rack facing south
            flow_profile = -flow_profile; %flow is in a negative direction (-Y)
            v0(A_in(1):B_in(1),A_in(2):B_in(2),A_in(3):B_in(3)) = flow_profile;
            v0(A_out(1):B_out(1),A_out(2):B_out(2),A_out(3):B_out(3)) = flow_profile;
        case 4 % Rack facing north
            v0(A_in(1):B_in(1),A_in(2):B_in(2),A_in(3):B_in(3)) = flow_profile;
            v0(A_out(1):B_out(1),A_out(2):B_out(2),A_out(3):B_out(3)) = flow_profile;
    end

    % Set location of heat generation nodes
    Q(A_out(1):B_out(1),A_out(2):B_out(2),A_out(3):B_out(3)) = Rck.HeatGenProfile.Value'; %sets Q on out-face
end

for i = 1:Ob_num % For each obstacle
    Obst = ObjList.Obstacles{i};
    VRC = Obst.Vertices/res + [2 2 2; 1 1 1]; % room_config array subscripts for obstacle rack interior.
    % Fill room_config that is inside the obstacle with zeroes.
    room_config(VRC(1,1):VRC(2,1),VRC(1,2):VRC(2,2),VRC(1,3):VRC(2,3)) = 0;
end


for i = 1:I_num % For each inlet
    InL = InList{i};
    [A,B,ARC,BRC] = GetFace(InL); % Two points defining the outflow face
    flow_profile = InL.FlowProfile.Value';
    switch InL.Orientation
        case 1 % Inlet faces west, air flows west
            u0(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = -flow_profile;
        case 2 % Inlet faces east, air flows east
            u0(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = flow_profile;
        case 3 % Inlet faces south, air flows south
            v0(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = -flow_profile;
        case 4 % Inlet faces north, air flows north
            v0(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = flow_profile;
        case 5 % Inlet on ceiling, air flows down
            w0(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = -flow_profile;
        case 6 % Inlet on floor, air flows up
            w0(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = flow_profile;
    end  
%     w0(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = flow_profile; %sets BC on inlet face
end

for i = 1:O_num % For each outlet
    OutL = OutList{i};
    [A,B,ARC,BRC] = GetFace(OutL); % Two points defining the outflow face
    flow_profile = OutL.FlowProfile.Value';
    switch OutL.Orientation
        case 1 % Outlet faces west, air flows east
            u0(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = flow_profile;
        case 2 % Outlet faces east, air flows west
            u0(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = -flow_profile;
        case 3 % Outlet faces south, air flows north
            v0(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = flow_profile;
        case 4 % Outlet faces north, air flows south
            v0(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = -flow_profile;
        case 5 % Outlet on ceiling, air flows up
            w0(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = flow_profile;
        case 6 % Outlet on floor, air flows down
            w0(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = -flow_profile;
    end
end
end