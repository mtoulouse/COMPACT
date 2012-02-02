function UpdateListBox(room)
%UPDATELISTBOX Updates flow object list on main room GUI.
%   UPDATELISTBOX finds the 'listbox' graphics object where racks, inlet,
%   and outlets are listed, and repopulates it with whatever flow objects
%   are currently in the room, according to the Room-class object input.
%
%   Generally used to update the list when a flow object has just been
%   added/deleted, or when the display is refreshed. The order is Server
%   racks, inlets, outlets, partitions, obstacles.

LB = findobj(room.Figure,'Tag','ObjLB'); % Find the listbox
[SR_num I_num O_num P_num Ob_num] = CountObjs(room);
total_num = SR_num+I_num+O_num+P_num+Ob_num;
[AllObj,AO_ind,AO_type] = NumListObjs(room);

ListStr = {}; % array of strings corresponding to each entry in the list box.
LBVal = 1; % index of selected item on list. Initialized in case the list is empty.

for h = 1:total_num
    FO = AllObj{h};
    typ = class(FO);
    switch typ
        case 'ServerRack'
            NamePrefix = '(SR) ';
        case {'Inlet','Outlet'}
            NamePrefix = ['(' typ(1) ') '];
        case 'Partition'
            NamePrefix = '(P) ';
        case 'Obstacle'
            NamePrefix = '(Ob) ';
    end
%     disp(class(FO))
%     assignin('base','FOOF',FO)
    if isempty(FO.Name)
        ListStr{end+1} = [NamePrefix num2str(AO_ind(h))];
    else
        ListStr{end+1} = [NamePrefix FO.Name];
    end
    if isequal(room.SelectedObject,FO)
        % if the object was "selected" before, make note of it to set as
        % the new listbox's selection as well.
        LBVal = length(ListStr);
    end
end

if isempty(ListStr)
    ListStr = '<none>';
end

% actually set the listbox properties now
set(LB,'String',ListStr);
set(LB,'Value',LBVal);
end