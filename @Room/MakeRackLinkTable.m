function next2rack = MakeRackLinkTable(Rm)
%MAKERACKLINKTABLE creates a table for linking the front and back cells
%   on a server rack. 
%
%   Make an array "next2rack" to deal with tracing flows through racks
%
%   Format of next2rack: 
%   Four numbers are stored corresponding to a location in the room - 
%   [(direction) (location 2 subscripts x,y,z)]

% obviously given in RC coord, not true coord.
[room_config,partition_config,u0,v0,w0,Q] = extract_BC_data(Rm);
SR = Rm.ObjectList.ServerRacks;
[SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
next2rack = zeros([size(room_config) 4]);
for f = 1:SR_num
    ori = SR{f}.Orientation;
    ori_opp = opposite(SR{f});
    [A,B,A_in,B_in] = GetInFace(SR{f}); % Two points defining the inflow face
    [A,B,A_out,B_out] = GetOutFace(SR{f}); % Two points defining the outflow face
    IF_x = A_in(1):B_in(1);
    IF_y = A_in(2):B_in(2);
    IF_z = A_in(3):B_in(3);
    OF_x = A_out(1):B_out(1);
    OF_y = A_out(2):B_out(2);
    OF_z = A_out(3):B_out(3);
    for px = 1:length(IF_x)
        for py = 1:length(IF_y)
            for pz = 1:length(IF_z)
                next2rack(IF_x(px),IF_y(py),IF_z(pz),1:4) = [ori OF_x(px) OF_y(py) OF_z(pz)];
                next2rack(OF_x(px),OF_y(py),OF_z(pz),1:4) = [ori_opp IF_x(px) IF_y(py) IF_z(pz)];
            end
        end
    end
end