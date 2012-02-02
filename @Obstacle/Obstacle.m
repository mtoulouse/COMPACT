classdef Obstacle < FlowObject
    %OBSTACLE Flow obstacles in the room
    %   Pretty much any 3D object sitting in the room. No orientation or
    %   anything, just two vertices as the properties.

    methods
        function OBS = Obstacle(V1,V2)
            % Constructor for this object.
            OBS = OBS@FlowObject(V1,V2,[],[]);
        end

        function display(OBS)
            % Display function, mostly for debugging. Gives the basic
            % information about the inlet.
            disp(['Obstacle: ' OBS.Name])
            A = OBS.Vertices(1,:);
            B = OBS.Vertices(2,:);
            disp(['Vertices: (' num2str(A(1)) ',' num2str(A(2)) ',' ...
                num2str(A(3)) ') and (' num2str(B(1)) ',' num2str(B(2))...
                ',' num2str(B(3)) ')'])
        end
    end
end
