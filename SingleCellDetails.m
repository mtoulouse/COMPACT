function SingleCellDetails(R,x,y,z,Ctype)
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
%   A future version will include a way to add this function to the main
%   GUI; for now, it's a standalone function.
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
        RCi=x; RCj=y; RCk=z;
    case 'TF'
        RCi=x+1; RCj=y+1; RCk=z+1;
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
    'Position',[0 0 1 1]);
cellinfo = {};

%%
cellinfo = [cellinfo; ['RC coords: (' num2str(RCi) ',' num2str(RCj) ',' num2str(RCk) ')']];
cellinfo = [cellinfo; ['TF coords: (' num2str(TFi) ',' num2str(TFj) ',' num2str(TFk) ')']];
cellinfo = [cellinfo; ['PB coords: (' num2str(PBi1) ',' num2str(PBj1) ',' num2str(PBk1) ...
    ') to (' num2str(PBi2) ',' num2str(PBj2) ',' num2str(PBk2) ')']];

i=RCi;j=RCj;k=RCk;
% cellinfo = [cellinfo; ];
cellinfo = [cellinfo; ['Q (W): ' num2str(Q(i,j,k))]];
cellinfo = [cellinfo; ['Inroom: ' inroom(i,j,k)]];

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
    cellinfo = [cellinfo; ['Direction: ' Dirname{n}]];
    cellinfo = [cellinfo; ['Inroom: ' inroom(ia,ja,ka)]];
    if InputIsRes
        flows = extract_vel_flows(Res.Phi,room_config,partition_config,Rm.Resolution);       
        cellinfo = [cellinfo; ['Flow (' Air.abbr '/s): ' num2str(flows(i,j,k,n))]];
        if ~isempty(Res.Temp)
            T_adj = T(TFia-1,TFja-1,TFka-1);
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
% assignin('base','cellinfo',cellinfo)
% disp(char(cellinfo))

    function ir = inroom(i,j,k)
        if room_config(i,j,k)
            ir = 'Yes';
        else
            ir = 'No';
        end
    end
end
% function inobj
%
% end