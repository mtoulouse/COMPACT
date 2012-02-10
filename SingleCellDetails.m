function SingleCellDetails(R,varargin)
%SINGLECELLDETAILS List multiple details about a single cell in the room.
%   SINGLECELLDETAILS takes a Results or Room object and a set of
%   coordinates, as well as the form of those coordinates, and outputs a
%   variety of details about the cell: temperature (if applicable), flow
%   into adjacent cells, whether the point is in the room, etc.
%
%   RC coords refers to location on room_config, which includes one layer
%   outside of walls. TF coords refers to Temp Field coords, which is
%   pretty much RC without the extra layer. PB coords, or Plot Box coords,
%   are the coordinates of the min and max vertices of the cell as plotted
%   in the GUI's 3-d and projected views. The input for PB can be of any
%   actual point (not cell subscripts, but physical (x = 1 ft, y = 3.5 ft
%   and so on) in the room; the function will simply look for the cell in
%   which the point resides.
% 
%   All of the following are valid inputs:
%   
%   >> SINGLECELLDETAILS(Rm)
%   >> SINGLECELLDETAILS(Rm,x,y,z)
%   >> SINGLECELLDETAILS(Rm,x,y,z,Ctype)
%   
%   The first two will simply open a small GUI to let you fill in the
%   blanks.
%
%   A future version might make this fancier with more stats? Maybe an 
%   attached room display highlighting the cell in question? Sliders to 
%   tick the coords up and down? I can copy some of the IsoSliceViewGUI 
%   code for that. Either way, this is a first crack and the function is 
%   uncomfortably long. I will break it up later.

if nargin == 5
    x = varargin{1};
    y = varargin{2};
    z = varargin{3};
    Ctype = varargin{4};
    cancelflag = 0;
else
    x = 1;
    y = 1;
    z = 1;
    Ctype = 'RC';
    cancelflag = 1;
    %    make GUI
    G = figure('Name','Choose a cell or point','NumberTitle','off',...
        'menubar','none','Position',Center_Fig(300,170));
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');

    G1 = uibuttongroup(G,'Position',[0 .2 .5 .8]);
    RCbutton = uicontrol(G1,'Style','radio','Units','normalized',...
        'Position',[.2 .7 .8 .2],'String','RC - room_config');
    TFbutton = uicontrol(G1,'Style','radio','Units','normalized',...
        'Position',[.2 .4 .8 .2],'String','TF - temp. field');
    PBbutton = uicontrol(G1,'Style','radio','Units','normalized',...
        'Position',[.2 .1 .8 .2],'String',['PB - plot box (' Air.abbr ')']);

    G2 = uipanel(G,'Position',[.5 .2 .5 .8]);
    xtex = uicontrol(G2,'Style','text','Units','normalized',...
        'Position',[.05 .65 .15 .2],'FontSize',14,'BackgroundColor',...
        defaultBackground,'String','X:');
    xbox = uicontrol(G2,'Style','edit','Units','normalized',...
        'Position',[.25 .7 .7 .2],'String',num2str(x));
    ztex = uicontrol(G2,'Style','text','Units','normalized',...
        'Position',[.05 .35 .15 .2],'FontSize',14,'BackgroundColor',...
        defaultBackground,'String','Y:');
    ybox = uicontrol(G2,'Style','edit','Units','normalized',...
        'Position',[.25 .4 .7 .2],'String',num2str(y));
    ztex = uicontrol(G2,'Style','text','Units','normalized',...
        'Position',[.05 .05 .15 .2],'FontSize',14,'BackgroundColor',...
        defaultBackground,'String','Z:');
    zbox = uicontrol(G2,'Style','edit','Units','normalized',...
        'Position',[.25 .1 .7 .2],'String',num2str(z));

    G3 = uipanel(G,'Position',[0 0 1 .2]);
    OKButt = uicontrol(G3,'Style', 'pushbutton', 'String', 'OK',...
        'Units','normalized',...
        'Position', [.1 .1 .35 .8],...
        'Callback', @OK_callback);
    CancelButt = uicontrol(G3,'Style', 'pushbutton', 'String', 'Cancel',...
        'Units','normalized',...
        'Position', [.55 .1 .35 .8],...
        'Callback', 'close(gcf)');

    if nargin == 4
        set(xbox,'String',num2str(varargin{1}))
        set(ybox,'String',num2str(varargin{2}))
        set(zbox,'String',num2str(varargin{3}))
    end
    uiwait(G)
end

%%
if cancelflag
    return
end
diradd = [-1 0 0;1 0 0;0 -1 0;0 1 0;0 0 -1;0 0 1];
Dirname = {'-X' '+X' '-Y' '+Y' '-Z' '+Z'};
InputIsRm = isa(R,'Room');
InputIsRes = isa(R,'Results');
if InputIsRm
    Rm = R;
elseif InputIsRes
    Rm = R.Room;
    Res = R;
    T = Res.Temp;
end
res = Rm.Resolution;

switch Ctype
    case 'RC'
        RCi=round(x); RCj=round(y); RCk=round(z);
    case 'TF'
        RCi=round(x+1); RCj=round(y+1); RCk=round(z+1);
    case 'PB'
        RCi=floor(x/res)+2; RCj=floor(y/res)+2; RCk=floor(z/res)+2;
end
TFi=RCi-1;TFj=RCj-1;TFk=RCk-1;
PBi1=res*(RCi-2);PBj1=res*(RCj-2);PBk1=res*(RCk-2);
PBi2=res*(RCi-1);PBj2=res*(RCj-1);PBk2=res*(RCk-1);

[room_config,partition_config,u0,v0,w0,Q] = extract_BC_data(Rm);
next2rack = MakeRackLinkTable(Rm);
%%

F = figure('Name',['Single Cell Details: ' Ctype '(' num2str(x) ',' num2str(y) ',' num2str(z) ')'],...
    'NumberTitle','off','menubar','none','Position',Center_Fig(400,450));
txtbox = uicontrol(F,'Style','listbox','Units','normalized',...
    'Position',[0 .1 1 .9]);
F2 = uipanel(F,'Position',[0 0 1 .1]);
print_butt = uicontrol(F2,'Style', 'pushbutton', ...
    'String', 'Print in Command Window',...
    'Units','normalized',...
    'Position', [.3 .1 .4 .8],...
    'Callback', @print_butt_callback);

cellinfo = {};

%%
cellinfo = [cellinfo; ['RC (room_config) coords: (' num2str(RCi) ',' num2str(RCj) ',' num2str(RCk) ')']];
cellinfo = [cellinfo; ['TF (temp. field) coords: (' num2str(TFi) ',' num2str(TFj) ',' num2str(TFk) ')']];
cellinfo = [cellinfo; ['PB (plot box) coords: (' num2str(PBi1) ',' num2str(PBj1) ',' num2str(PBk1) ...
    ') to (' num2str(PBi2) ',' num2str(PBj2) ',' num2str(PBk2) ')']];

i=RCi;j=RCj;k=RCk;
% cellinfo = [cellinfo; ];
cellinfo = [cellinfo; ['Inroom: ' inroom(i,j,k)]];
if strcmp(inroom(i,j,k),'Yes')
    cellinfo = [cellinfo; ['Q (W): ' num2str(Q(i,j,k))]];
end

if InputIsRes && ~isempty(T)
    T_center = T(TFi,TFj,TFk);
    cellinfo = [cellinfo; ['Temp (C): ' num2str(T_center)]];
    cellinfo = [cellinfo; ['E_resid (W): ' num2str(Res.EnergyResidual(i,j,k))]];
    cellinfo = [cellinfo; ['Entropy (J/kg/K): ' num2str(-0.0055*T_center^2 + 3.648*T_center + 6773)]];
    if ~isempty(Res.ExergyDest)
        cellinfo = [cellinfo; ['ExDest (W): ' num2str(Res.ExergyDest(TFi,TFj,TFk))]];
    end
end

cellinfo = [cellinfo; '------'];
cellinfo = [cellinfo; 'Surrounding Cell Statistics'];
for n = 1:6
    ia = i + diradd(n,1);
    ja = j + diradd(n,2);
    ka = k + diradd(n,3);
    TFia=ia-1;TFja=ja-1;TFka=ka-1;
    cellinfo = [cellinfo; '------'];
    cellinfo = [cellinfo; ['Direction: ' Dirname{n} '     RC(' num2str(ia) ',' num2str(ja) ',' num2str(ka) ')']];
    cellinfo = [cellinfo; ['Inroom: ' inroom(ia,ja,ka)]];
    if strcmp(inroom(ia,ja,ka),'Yes')
        cellinfo = [cellinfo; ['Q (W): ' num2str(Q(ia,ja,ka))]];
    end
    if InputIsRes
        flows = extract_vel_flows(Res.Phi,room_config,partition_config,Rm.Resolution);
        cellinfo = [cellinfo; ['Flow (' Air.abbr '/s): ' num2str(flows(i,j,k,n))]];
        if ~isempty(Res.Temp) && strcmp(inroom(ia,ja,ka),'Yes')
            T_adj = T(TFia,TFja,TFka);
            cellinfo = [cellinfo; ['Temp (C): ' num2str(T_adj)]];
            cellinfo = [cellinfo; ['Entropy (J/kg/K): ' num2str(-0.0055*T_adj^2 + 3.648*T_adj + 6773)]];
            if strcmp(inroom(ia,ja,ka),'No') && next2rack(i,j,k,1) == n
                TFi_n = next2rack(i,j,k,2);
                TFj_n = next2rack(i,j,k,3);
                TFk_n = next2rack(i,j,k,4);
                cellinfo = [cellinfo; ['Thru Rack - Temp: ' num2str(T(TFi_n,TFj_n,TFk_n))]];
            end
        end
    end

end

set(txtbox,'String',cellinfo)

    function ir = inroom(i,j,k)
        if all([i j k]>0) && room_config(i,j,k)
            ir = 'Yes';
        else
            ir = ['No' inobj(i,j,k)];
        end
    end

    function OK_callback(src,eventdata)
        x = str2num(get(xbox,'String'));
        y = str2num(get(ybox,'String'));
        z = str2num(get(zbox,'String'));
        switch 1
            case get(RCbutton,'Value')
                Ctype = 'RC';
            case get(TFbutton,'Value')
                Ctype = 'TF';
            case get(PBbutton,'Value')
                Ctype = 'PB';
        end
        close(G)
        cancelflag = 0;
    end

    function print_butt_callback(src,eventdata)
        disp(char(cellinfo))
    end

    function io = inobj(i,j,k)
        io = '';
    %empty right now, but will search to find exactly what object the cell is
    %inside of
    end
end