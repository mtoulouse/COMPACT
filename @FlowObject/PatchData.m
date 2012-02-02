function [V, F] = PatchData(FObj)
%PATCHDATA Patch generation data extracted from object vertices
%   [V, F] = PATCHDATA(FOBJ) takes a flow object, extracts its minimum and
%   maximum vertices, and generates an array of 8 vertices and 6
%   combinations of these vertices that form faces of the object.
%
%   The data used here can be input directly into a "patch" function to
%   graphically generate the flow object as a box, or input into other
%   function to extract the coordinates of certain faces for the purpose of
%   defining boundary conditions.
%
%   Vertex and face ordering:
%   Z
%               8%%%%%%%%%%%%%%%%%%%/7
%   ^          / |     2(Top)      / |
%   |         /  |      6(Back)   /  |
%   |        5%%%%%%%%%%%%%%%%%%%6   |
%   |        |   |               | 4 |
%   |        | 3 |               |   |
%   |        |   4%%%%%%%%%%%%%%%|%%%3
%   |        |  /      5(Front)  |  /
%   |        | /        1(Bottom)| /
%   |   Y    |/                  |/
%   |  ^     1%%%%%%%%%%%%%%%%%%%2
%   | /
%   |/
%   %%%%%%%%%%%%%%%%%%%%%>  X


Fmin = min(FObj.Vertices,[],1);
Fmax = max(FObj.Vertices,[],1);
FObj.Vertices = [Fmin;Fmax];

X1 = FObj.Vertices(1,1);
Y1 = FObj.Vertices(1,2);
Z1 = FObj.Vertices(1,3);
X2 = FObj.Vertices(2,1);
Y2 = FObj.Vertices(2,2);
Z2 = FObj.Vertices(2,3);

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