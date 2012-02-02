classdef Room < handle
    %ROOM Class representing the whole server room.
    %   ROOM is the most important class, storing room specifications, flow
    %   objects, various solver settings, and some graphical settings as well.

    properties
        Dimensions % Room dimensions (X/Y/Z), in [Length]
        Resolution % Resolution of solution array, in [Length]
        ObjectList % Stores the flow objects taht are in the room
        SelectedObject % stores the handle of the currently selected object
        Figure % Graphical handle of the main room GUI associated with this room
        ResultSettings % The room's result generation settings for the flow solver
        InletTemp % Temperature of inlet air
        VorSupMult = 2.47; % Vortex Superposition Multiplier
        VortexInfo % location of aisles and vortices for use in vortex superposition
    end

    methods
        function Rm = Room(dim,res)
            % Constructor function. Makes in initially empty room with some
            % default values for solver options set. Also makes separate
            % fields in the object list for each type of flow object.
            Rm.Dimensions = dim;
            Rm.Resolution = res;
            Rm.ObjectList.ServerRacks = {};
            Rm.ObjectList.Obstacles = {};
            Rm.ObjectList.Inlets = {};
            Rm.ObjectList.Outlets = {};
            Rm.ObjectList.Partitions = {};
            Rm.ResultSettings = Results('SettingData');
            Rm.InletTemp = 15;
        end

        function display(Rm)
            % Display function, mostly for debugging. Gives the basic
            % information about the room.
            [SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
            disp([num2str(Rm.Dimensions(1)) 'x' num2str(Rm.Dimensions(2))...
                'x' num2str(Rm.Dimensions(3)) ' ' Air.unit ' room with:'])
            disp([num2str(SR_num) ' Racks'])
            disp([num2str(I_num) ' Inlets'])
            disp([num2str(O_num) ' Outlets'])
            disp([num2str(P_num) ' Partitions'])
            disp([num2str(Ob_num) ' Obstacles'])
            disp(['Resolution = ' num2str(Rm.Resolution) ' ' Air.units])
        end

        function [SR_num I_num O_num P_num Ob_num] = CountObjs(Rm)
            % Counts the number of each type of flow object contained in
            % the room. Useful when you have to proceed through each flow
            % object for some reason (e.g. 'for 1:I_num')
            OL = Rm.ObjectList;
            SR_num = length(OL.ServerRacks);
            I_num = length(OL.Inlets);
            O_num = length(OL.Outlets);
            P_num = length(OL.Partitions);
            Ob_num = length(OL.Obstacles);
        end

        function [AllObj,AO_ind,AO_type] = NumListObjs(Rm)
            SR = Rm.ObjectList.ServerRacks;
            I = Rm.ObjectList.Inlets;
            O = Rm.ObjectList.Outlets;
            P = Rm.ObjectList.Partitions;
            Ob = Rm.ObjectList.Obstacles;
            AllObj = [SR I O P Ob];
            [SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
            AO_ind = [1:SR_num 1:I_num 1:O_num 1:P_num 1:Ob_num];
            AO_type = [ones(1, SR_num) 2*ones(1, I_num) 3*ones(1, O_num) 4*ones(1, P_num) 5*ones(1, Ob_num)];
        end

        function Rm = AddFlowObject(Rm,FlowObj)
            % Adds a flow object to the room, adjusting all necessary
            % values as needed. Also checks that the placement is valid.
            res = Rm.Resolution;
            rmdim = Rm.Dimensions;
            % If the object is an inlet or outlet, part of the object is in
            % the walls. Set the outermost face to the edge of the current
            % extended room configuration.
            minpt = FlowObj.Vertices(1,:);
            maxpt = FlowObj.Vertices(2,:);
            FlowObj.Vertices(1,:) = ~(minpt < 0).*minpt - (minpt < 0)*res;
            FlowObj.Vertices(2,:) = ~(maxpt > rmdim).*maxpt + (maxpt > rmdim).*(rmdim+res);
            % Round the vertices to the nearest multiple of the resolution
            % (should have been done elsewhere too, but just as a safeguard)
            FlowObj.Vertices = round(FlowObj.Vertices/res)*res;
            if ValidPosition(Rm,FlowObj) % checks that the flow object is
                % at a valid position, then adds to the object list.
                switch class(FlowObj)
                    case 'Inlet'
                        Rm.ObjectList.Inlets{end+1} = FlowObj;
                    case 'Outlet'
                        Rm.ObjectList.Outlets{end+1} = FlowObj;
                    case 'ServerRack'
                        Rm.ObjectList.ServerRacks{end+1} = FlowObj;
                    case 'Obstacle'
                        Rm.ObjectList.Obstacles{end+1} = FlowObj;
                    case 'Partition'
                        Rm.ObjectList.Partitions{end+1} = FlowObj;
                end
                FlowObj.Room = Rm; % Also associates the room with the flow object.
            end
        end

        function UpdateDisplay(Rm)
            % Updates all aspects of the GUI display.
            if isempty(Rm.Figure)
                disp('No figure is bound to the room! Start up room_shape.m first')
            else
                set(findobj('Tag','ObjLB'),'Enable','off')
                Rm.UpdateListBox; % update the list of objects

                set(Rm.Figure,'Name',['Room Configuration - Views ' Rm.RoomInfoStr])
                Rm.RoomProjected; % update projected views
                Rm.Room3D; % update the 3-D view
                set(findobj('Tag','ObjLB'),'Enable','on')
                Rm.HighlightSelObj; % highlight the currently selected object
            end
        end

        function Rminfo = RoomInfoStr(Rm)
            x = Rm.Dimensions(1);
            y = Rm.Dimensions(2);
            z = Rm.Dimensions(3);
            res = Rm.Resolution;
            allcells = prod(Rm.Dimensions/Rm.Resolution + 2);
            [room_config,partition_config,u0,v0,w0,Q] = extract_BC_data(Rm);
            aircells = nnz(room_config);
            Rminfo = ['(' num2str(x) ' x ' num2str(y) ' x '...
                num2str(z) ' ' Air.abbr ', Res. = ' ...
                num2str(res) ' ' Air.abbr ', ' ...
                num2str(allcells) ' total cells, '...
                num2str(aircells) ' air cells)'];
        end

        function HighlightSelObj(Rm)
            % If a flow object is currently stored as the room's
            % 'selected object', highlight that object in the projected and
            % 3-D views, by thickening the edge lines.
            allpatches = findobj(Rm.Figure,'Type','patch');
            set(allpatches,'LineWidth',0.5)
            if ~isempty(Rm.SelectedObject)
                set(Rm.SelectedObject.PatchProj,'LineWidth',2.5)
                set(Rm.SelectedObject.Patch3D,'LineWidth',2.5)
            end
        end

        function correct_flows(Rm)
            % Corrects for imbalances in the summed inlet and outlet flows
            % of the room.
            [SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
            [AllObj,AO_ind,AO_type] = NumListObjs(Rm);
            ObjList = Rm.ObjectList;
            InList = ObjList.Inlets;
            OutList = ObjList.Outlets;
            total_num = SR_num+I_num+O_num+P_num+Ob_num;
            % Sum up the inflows
            TotalInFlow = 0;
            for h = 1:I_num
                IL = InList{h};
                [A,B,ARC,BRC] = GetFace(IL);
                FaceArea = prod(nonzeros(B-A));
                TotalInFlow = TotalInFlow + IL.FlowRate*FaceArea;
            end
            % Sum up the outflows, and change the last one to balance
            TotalOutFlow = 0;
            for h = 1:O_num
                OL = OutList{h};
                [A,B,ARC,BRC] = GetFace(OL);
                FaceArea = prod(nonzeros(B-A));
                TotalOutFlow = TotalOutFlow + OL.FlowRate*FaceArea;
            end

            OverFlow = TotalInFlow - TotalOutFlow; % too much flow entering by this much
            PctOverFlow = abs(OverFlow/TotalOutFlow)*100; % overflow as percent of outflow
            ListStr = {}; % array of strings corresponding to each entry in the list box.
            ListInd = []; % indices of corresponding objects
            SelectChangeFlag = false; % a specific change to flow was selected; else just pick the default

            if PctOverFlow > 0.5 % bigger than 0.5% change in outflow needed to correct
                button = questdlg(...
                    ['In order to balance the inflow and outflow, outflow will need to be increased by '...
                    num2str(OverFlow) ' ' Air.abbr '^3/s. Change inlet or outlet flow?'],...
                    'Correcting the Inlet and Outlet Balance','Inlet','Outlet','Cancel','Outlet');
                if ~strcmp(button,'Cancel')
                    for h = 1:total_num
                        FO = AllObj{h};
                        typ = class(FO);
                        if strcmp(typ,button)
                            NamePrefix = ['(' typ(1) ') '];
                            [A,B,ARC,BRC] = GetFace(FO);
                            FaceArea = prod(nonzeros(B-A));
                            if isempty(FO.Name)
                                ListStr{end+1} = [NamePrefix num2str(AO_ind(h)) ': ' ...
                                    num2str(FO.FlowRate*FaceArea) ' ' Air.abbr '^3/s'];
                            else
                                ListStr{end+1} = [NamePrefix FO.Name ': ' ...
                                    num2str(FO.FlowRate*FaceArea) ' ' Air.abbr '^3/s'];
                            end
                            ListInd(end+1,:) = [h FaceArea];
                        end
                    end
                    % open a listbox dialog to select the flow objects to
                    % assign
                    [s,v] = listdlg('PromptString',...
                        ['Select ' button 's to apply ' num2str(OverFlow) ' ' Air.abbr '^3/s flow correction to:'],...
                        'ListString',ListStr);
                    if v == 1 && ~isempty(s)
                        SelectChangeFlag = true;
                        corr_ind = ListInd(s,1);
                        corr_area = sum(ListInd(s,2));
                        if strcmp(button,'Inlet')
                            addflow = -OverFlow/corr_area;
                        elseif strcmp(button,'Outlet')
                            addflow = OverFlow/corr_area;
                        end
                        for k = 1:length(corr_ind)
                            AllObj{corr_ind(k)}.FlowProfile.Value = AllObj{corr_ind(k)}.FlowProfile.Value + addflow;
                        end
                    end
                end

                % starts immediately after. Allows graphical updates this
                % way.

                % Due to small machine errors, TotalOutFlow  and TotalInFlow
                % may be nearly identical if flows were correted before. In
                % that case, only give a warning to the user if the change in
                % the outlet value is more than 1 percent.
            end
            if ~SelectChangeFlag && OverFlow ~= 0
                LastO = OutList{O_num};
                [A,B,ARC,BRC] = GetFace(LastO);
                FaceArea = prod(nonzeros(B-A));
                LastO.FlowProfile.Value = LastO.FlowProfile.Value + OverFlow/FaceArea;
                p = warndlg(['Increasing Outlet "' LastO.Name '" velocity by ' num2str(OverFlow/FaceArea) ' ' Air.abbr '/s'],...
                    'Default Flow Correction');
                waitfor(p);
                pause(.05) % pause for a bit
            end
        end

        function DeleteCurrentFlowObject(Rm)
            % Deletes the selected flow object in the room from the room's
            % object list. Also removes the room from the object's "Room"
            % property.
            % EDIT: doesnt remove it if the class was misclassified or
            % changed. Adjusting to search all objects!
            FlowObj = Rm.SelectedObject;
            [SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
            total_num = SR_num+I_num+O_num+P_num+Ob_num;
            [AllObj,AO_ind,AO_type] = NumListObjs(Rm);
            for i = 1:total_num
                if isequal(AllObj{i},FlowObj)
                    FlowObj.Room = [];
                    switch AO_type(i)
                        case 1 % SR
                            Rm.ObjectList.ServerRacks(AO_ind(i)) = [];
                        case 2 % I
                            Rm.ObjectList.Inlets(AO_ind(i)) = [];
                        case 3 % O
                            Rm.ObjectList.Outlets(AO_ind(i)) = [];
                        case 4 % P
                            Rm.ObjectList.Partitions(AO_ind(i)) = [];
                        case 5 % Ob
                            Rm.ObjectList.Obstacles(AO_ind(i)) = [];
                    end
                    break
                end
            end
            Rm.SelectedObject = [];
        end

        function Rm = ReclassifyCurrentFO(Rm)
            SO = Rm.SelectedObject;
            DeleteCurrentFlowObject(Rm);
            AddFlowObject(Rm,SO);
        end

    end
end