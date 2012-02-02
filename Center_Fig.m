function PosVec = Center_Fig(W,H)
%CENTER_FIG Figure position generation function
%   CENTER_FIG takes the desired dimensions of a figure (in pixels), checks
%   the screen size and shrinks to fit, centers the figure, and outputs a 
%   position vector of format [left bottom width height], whichh is 
%   commonly used in defining graphics object position and size.
ScrnPos = get(0,'ScreenSize');
S_W = ScrnPos(3);
S_H = ScrnPos(4);
if W > S_W
    H = H/W*S_W;
    W = S_W;
end
if H > S_H
    W = W/H*S_H;
    H = S_H;
end
Center = [S_W S_H]/2;
PosVec = [Center-[W H]/2 W H]; 