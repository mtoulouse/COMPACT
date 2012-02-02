function Rm = makeroom()
%MAKEROOM Initial room-creating function
%   MAKEROOM queries the user for the dimensions of a new room and creates 
%   an initial Room object, then calls the main room-editing GUI
%   ROOM_SHAPE.
Rm = [];
answer = inputdlg({['Width(' Air.abbr '):'],['Length(' Air.abbr '):'],['Height(' Air.abbr '):'],['Resolution(' Air.abbr '):']},...
    'Create Room',1,{'26','21','10','1'},'on');
if ~isempty(answer)
    W = str2num(answer{1});
    L = str2num(answer{2});
    H = str2num(answer{3});
    R = str2num(answer{4});
    Rm = Room([W L H], R);
    room_shape(Rm);
end