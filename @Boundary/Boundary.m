classdef Boundary < FlowObject
    %BOUNDARY Object defining an inlet or outlet
    %   Boundary defines any "window" in or out of the room as a whole. There
    %   is also a method to classify it as an inlet or outlet.

    properties
        Type % "Inlet" or "Outlet"
        AirTemp % Only really applies for inlets
    end

    methods
        function BO = Boundary(TY,V1,V2,FP,ORI)
            % Constructor for this object.
            BO = BO@FlowObject(V1,V2,FP,ORI);
            BO.Type = TY;
        end
        
        function cl = class(BO)
            % This just needs to ba added in for Boundary-class objects.
            % This overloads the class method so that class(Object) returns
            % "Inlet" or "Outlet" instead of "Boundary".
            cl = BO.Type;
        end
        
        function SW = MatchType(BO)
            % Normally you define the Inlet/Outlet info separately, but
            % here you can automatically switch it if the flow rate is 
            % negative. An inlet with -1 m/s flow is really an outlet with
            % +1 m/s, after all.
            SW = false;
            meanflo = BO.FlowRate;
            if isfinite(meanflo) && meanflo < -1e-8
                SwitchType(BO)
                SW = true;
            end
        end
        
        function SwitchType(BO) 
            % This just switches the type between inlet/outlet and also
            % changes the sign of the flow. Sort of the opposite of the
            % above method.
            if strcmp(BO.Type,'Inlet')
                BO.Type = 'Outlet';
            elseif strcmp(BO.Type,'Outlet')
                BO.Type = 'Inlet';
            end
            BO.FlowProfile.Value = -BO.FlowProfile.Value;
        end

        function [A,B,ARC,BRC] = GetFace(BO)
            % Gets the flow face of this object. Overloads FLOWOBJECT's
            % getface function with this version, which already grabs the
            % orientation of the inlet.
            direc = BO.Orientation;
            [A,B,ARC,BRC] = GetFace@FlowObject(BO,direc);
        end

        function display(BO)
            % Display function, mostly for debugging. Gives the basic
            % information about the outlet.
            Dir = {'-X' '+X' '-Y' '+Y' 'down' 'up'};
            if iscell(BO.Name) && isempty(BO.Name)
                BO.Name = [];
            end
            switch class(BO)
                case 'Inlet'
                    str = 'entering';
                case 'Outlet'
                    str = 'leaving';
            end
            disp([BO.Type ': ' BO.Name])
            [A,B,ARC,BRC] = GetFace(BO);
            disp(['Vertices: (' num2str(A(1)) ',' num2str(A(2)) ',' ...
                num2str(A(3)) ') and (' num2str(B(1)) ',' num2str(B(2))...
                ',' num2str(B(3)) ')'])
            disp(['Orientation: pointing ' Dir{BO.Orientation} ' into the room'])
            disp(['Flow: ' BO.FlowProfile.DistributionType ' flow averaging ' ...
                num2str(BO.FlowRate) ' ' Air.abbr '/s, ' str ' the room'])
        end
    end
end
