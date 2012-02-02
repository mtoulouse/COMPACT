function VortexPlacementGUI(Rm)
% VORTEXPLACEMENTGUI Manual Vortex Placement/Editing GUI
%   VORTEXPLACEMENTGUI creates a small GUI with a list of vortices and
%   aisles, plus their locations and which other vortices or aisles they
%   are linked to. AutomatedVortexPlacement.m generates these values, but
%   this GUI allows you to view their locations and manually edit their
%   attributes. You can also add or delete vortices/aisles entirely.

POS = {}; % Default output
rd = Rm.Dimensions;
res = Rm.Resolution;
rd_v = rd + 2*res;
VortInfo = Rm.VortexInfo;

%% Create the GUI 
VorSet = figure('Name','Aisles and Vortices',...
    'Position',Center_Fig(700,250),...
    'NumberTitle','off','menubar','none');

ButtonPanel = uipanel(VorSet,'Title','Placement Options',...
    'Units','normalized',...
    'Position',[.5 0 .5 1]);
ListPanel = uipanel(VorSet,'Title','List of Aisles/Vortices',...
    'Units','normalized',...
    'Position',[0 0 .5 1]);

AddButton = uicontrol(ButtonPanel,...
    'Units','normalized',...
    'Position',[.3 .8 .4 .1],...
    'String','Add',...
    'Callback',@Add_CBK);

EditButton = uicontrol(ButtonPanel,...
    'Units','normalized',...
    'Position',[.3 .6 .4 .1],...
    'String','Edit',...
    'Callback',@Edit_CBK);

DelButton = uicontrol(ButtonPanel,...
    'Units','normalized',...
    'Position',[.3 .4 .4 .1],...
    'String','Delete',...
    'Callback',@Delete_CBK);

ViewButton = uicontrol(ButtonPanel,...
    'Units','normalized',...
    'Position',[.3 .2 .4 .1],...
    'String','View',...
    'Callback',@View_CBK);

VAList= uicontrol(ListPanel,...
    'Style','listbox',...
    'Units','normalized',...
    'Position',[.1 .1 .8 .8],...
    'BackgroundColor','w');

UpdateVortexList;
%% Button callbacks
    function Add_CBK(src,eventdata)
        answer = vortinputdlg([]);
        if ~isempty(answer)
            VortInfo(end+1).Type = answer{1};
            VortInfo(end).Vertices = str2num(answer{2});
            VortInfo(end).Links = str2num(answer{3});
        end
        UpdateVortexList;
        Rm.VortexInfo = VortInfo;
    end

    function Edit_CBK(src,eventdata)
        if ~isempty(VortInfo)
            listind = get(VAList,'Value');
            VI = VortInfo(listind);
            defAns = {VI.Type, [num2str(VI.Vertices(1,:)) ' ; ' num2str(VI.Vertices(2,:))] , num2str(VI.Links)};
            answer = vortinputdlg(defAns);
            if ~isempty(answer)
                VortInfo(listind).Type = answer{1};
                VortInfo(listind).Vertices = str2num(answer{2});
                VortInfo(listind).Links = str2num(answer{3});
            end
        end
        UpdateVortexList;
        Rm.VortexInfo = VortInfo;
    end

    function Delete_CBK(src,eventdata)
        listind = get(VAList,'Value');
        if ~isempty(VortInfo)
            for i = 1:length(VortInfo)
                % if linked to a higher number than the index to be
                % deleted, subtract one
                % also remove reference to deleted entry
                VortInfo(i).Links(VortInfo(i).Links  ==  listind) = [];
                VortInfo(i).Links(VortInfo(i).Links > listind) = ...
                    VortInfo(i).Links(VortInfo(i).Links > listind) - 1;
            end
            VortInfo(listind) = [];
            set(VAList,'Value',1);
            UpdateVortexList;
            Rm.VortexInfo = VortInfo;
        end
    end

    function View_CBK(src,eventdata)
        listind = get(VAList,'Value');
        ViewVortex(Rm,VortInfo(listind));
    end
%% Fill in input dialog
    function answer = vortinputdlg(defAns)
        prompt = {'Type of object ("Aisle" or "Vortex")','Vertices "X Y Z ; X Y Z"','List numbers of linked vortices/aisles "A B"'};
        if isempty(defAns)
            answer = inputdlg(prompt,'Add Object',1);
        else
            answer = inputdlg(prompt,'Edit Object',1,defAns);
        end
    end

%% Update Vortex/Aisle List
    function UpdateVortexList
        ListStr = {}; % array of strings corresponding to each entry in the list box.
        for i = 1:length(VortInfo)
            VI = VortInfo(i);
            str = ['(' num2str(i) ') '...
                VI.Type ': [' num2str(VI.Vertices(1,:)) '; '...
                num2str(VI.Vertices(2,:)) '] linked to # ' num2str(VI.Links)];
            ListStr{end+1} = str;
        end
        if isempty(ListStr)
            ListStr = '<none>';
        end
        set(VAList,'String',ListStr);
    end

end