classdef Partition < FlowObject
    %PARTITION Class representing flow barriers placed in the room
    %   PARTITION creates zero-thickness planes in the room to represent
    %   flow barriers. This is not often used, so be sure to double-check
    %   the 

    methods
        function PT = Partition(V1,V2,varargin)
            % Constructor for this object. Finds the orientation from the
            % given vertices.
            if isempty(varargin)
                flat_ind = find(~(V2-V1));
                if isempty(flat_ind)
                    disp(V1)
                    disp(V2)
                    disp('Invalid Vertices!')
                    ORI = [];
                else
                    switch flat_ind
                        case 1
                            ORI = 1;
                        case 2
                            ORI = 3;
                        case 3
                            ORI = 5;
                    end
                end
            else
                ORI = varargin{1};
            end
            PT = PT@FlowObject(V1,V2,[],ORI);
        end

        function [P1,P2,direc1,direc2] = GetFaces(PT)
            % Gets the faces of this object, to check the boundary
            % conditions. Also the orientation of the face.
            d = [2 1 4 3 6 5];
            direc1 = PT.Orientation;
            direc2 = d(direc1);
            [A,B,ARC1,BRC1] = GetFace(PT,PT.Orientation);
            P1 = [ARC1;BRC1];
            [A,B,ARC2,BRC2] = GetFace(PT,opposite(PT));
            P2 = [ARC2;BRC2];
        end

        function display(PT)
            % Display function, mostly for debugging. Gives the basic
            % information about the inlet.
            disp(['Partition: ' PT.Name])
%             [A,B,ARC,BRC] = GetFace(PT);
            A = PT.Vertices(1,:);
            B = PT.Vertices(2,:);
            disp(['Vertices: (' num2str(A(1)) ',' num2str(A(2)) ',' ...
                num2str(A(3)) ') and (' num2str(B(1)) ',' num2str(B(2))...
                ',' num2str(B(3)) ')'])
        end
    end % methods end
end % classdef end