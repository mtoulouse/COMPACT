classdef FlowObject < handle
    %FLOWOBJECT Abstract superclass representing objects placed within the room
    %   FLOWOBJECT stores basic physical properties and flow characteristics
    %   common to every object placed within the room, such as vertices,
    %   flow rate/profile/orientation, as well as storing its room and
    %   associated graphical objects.
    %
    %   Note that as an abstract class, a FLOWOBJECT object cannot be directly
    %   created. Other subclasses such as Inlet, Outlet, and ServerRack instead
    %   build upon it.

    properties
        Name = {}; % The name given to the Flow Object
        Room % Room object which flow object is stored in
        Vertices % Min and max vertices of the object in 3-D coordinates
        FlowProfile % Profile object describing flow through object
        Orientation % Direction of object flow (1-6, representing the six cardinal directions in 3-D)
        PropertyFigure % Stored handle of associated property-editing figure
        PatchProj % Stored handles of patches representing this object in a 2-D projected view
        Patch3D % Stored handles of patches representing this object in a 3-D view
    end
    properties (Dependent = true)
        FlowRate % Average flow rate through the object in [Length]/[Time]
    end
    methods
        function FObj = FlowObject(V1,V2,FP,ORI)
            % Constructor for this object. If input vertices are not
            % min/max, the constructor automatically makes it so.
            FObj.Vertices = [min(V1(1),V2(1)) min(V1(2),V2(2)) min(V1(3),V2(3))
                max(V1(1),V2(1)) max(V1(2),V2(2)) max(V1(3),V2(3))];
            FObj.FlowProfile = FP;
            FObj.Orientation = ORI;
        end

        % "get" method governing the dependent property "FlowRate". Returns
        % NaN if there is no (finite) flow profile defined yet.
        function fr = get.FlowRate(FO)
            if ~IsProfileEmpty(FO.FlowProfile)
                fr = mean(mean(FO.FlowProfile.Value));
            else
                fr = NaN;
            end
        end % FlowRate get method

        function [A,B,ARC,BRC] = GetFace(FObj,direc) % outputs two 3-D
            % points bounding the object face in the given direction.
            %
            % direction numbering
            % (direction #,cardinal direction,coordinate direction)
            % 1, "West", -X
            % 2, "East", +X
            % 3, "South", -Y
            % 4, "North", +Y
            % 5, "Down", -Z
            % 6, "Up", +Z
            %
            % A is the min point, B is the max point.  Coordinates are
            % given in both actual vertex values and converted to "RC" form.
            % RC form, or room configuration form, gives the coordinates of
            % the object face as array subscripts which can be used to
            % locate it on the actual node array used in the solver. Note
            % that if in RC form, the coords are actually off the surface
            % by resolution/2.
            res = FObj.Room.Resolution;
            [V, F] = PatchData(FObj);
            switch direc
                case 1
                    VS = V(F(3,:),:);
                    shiftA = [-1 0 0];
                    shiftB = [0 0 0];
                case 2
                    VS = V(F(4,:),:);
                    shiftA = [0 0 0];
                    shiftB = [+1 0 0];
                case 3
                    VS = V(F(5,:),:);
                    shiftA = [0 -1 0];
                    shiftB = [0 0 0];
                case 4
                    VS = V(F(6,:),:);
                    shiftA = [0 0 0];
                    shiftB = [0 +1 0];
                case 5
                    VS = V(F(1,:),:);
                    shiftA = [0 0 -1];
                    shiftB = [0 0 0];
                case 6
                    VS = V(F(2,:),:);
                    shiftA = [0 0 0];
                    shiftB = [0 0 +1];
            end
            A = min(VS);
            B = max(VS);
            ARC = min(VS)/res + 2 + shiftA;
            BRC = max(VS)/res + 1 + shiftB;
        end

        function direc = opposite(FObj)
            oppdirs = [2 1 4 3 6 5];
            direc = oppdirs(FObj.Orientation);
        end

        function FObj = namebox(FObj)
            if ~isempty(FObj.Name)
                defAns = cellstr(FObj.Name);
            else
                defAns = {''};
            end
            answer = inputdlg(['Enter Name of ' class(FObj)],'Name',1,defAns);
            if ~isempty(answer)
                FObj.Name = answer{1};
            end
        end
    end
    methods (Static)
        function [VO, FO, EO] = BoxOverlap(V1,V2)
            % A small function used by ValidPosition to determine whether
            % two 3-D flow objects overlap, or just their faces/edges.
            % Gives the actual volume/area/length overlapping as well.
            %
            % VO = Volume overlapping
            % FO = Face area overlapping
            % EO = Edge length overlapping
            VO = 0;
            FO = 0;
            EO = 0;
            Fmin = min(V1,[],1);
            Fmax = max(V1,[],1);
            Gmin = min(V2,[],1);
            Gmax = max(V2,[],1);
            Xoverlap = min(Fmax(1), Gmax(1)) - max(Fmin(1), Gmin(1));
            Yoverlap = min(Fmax(2), Gmax(2)) - max(Fmin(2), Gmin(2));
            Zoverlap = min(Fmax(3), Gmax(3)) - max(Fmin(3), Gmin(3));
            XYZ = [Xoverlap Yoverlap Zoverlap];
            if all(XYZ >= 0) % Something is touching!
                switch nnz(XYZ > 0)
                    case 1 % only an edge is touching
                        EO = nonzeros(XYZ);
                    case 2 % only a face is touching
                        FO = prod(nonzeros(XYZ));
                    case 3 % volumes are overlapping
                        VO = prod(XYZ);
                end
            end
        end
    end % methods end
end % classdef end