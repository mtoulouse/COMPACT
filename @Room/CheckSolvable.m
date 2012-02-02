function [YN] = CheckSolvable(Rm)
%CHECKSOLVABLE Solvability checker before running model.
%   CHECKSOLVABLE checks to make sure the room as it is set up is solvable.
%   Also generates an error dialogue with all the issues making
%   the room unsolvable.

% First checks that important quantities are defined/valid:
% every room at least needs resolution and dimensions (at
% positive values), and at least one inlet and outlet.
YN = false;
[SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
errstring = {};
if isempty(Rm.Resolution)
    errstring{end+1} = 'No resolution defined.';
elseif Rm.Resolution < 0
    errstring{end+1} = 'Resolution is negative.';
end
if isempty(Rm.Dimensions)
    errstring{end+1} = 'No dimensions defined.';
elseif any(Rm.Dimensions < 0)
    errstring{end+1} = 'Some dimensions are negative';
end
if isempty(Rm.ObjectList.Inlets)
    errstring{end+1} = 'Room has no inlets';
end
if isempty(Rm.ObjectList.Outlets)
    errstring{end+1} = 'Room has no outlets';
end

for II = 1:I_num
    if ~isfinite(Rm.ObjectList.Inlets{II}.FlowRate)
        errstring{end+1} = 'Nonfinite value present in inlet flow (or not defined)';
    end
end
for OO = 1:O_num
    if ~isfinite(Rm.ObjectList.Outlets{OO}.FlowRate)
        errstring{end+1} = 'Nonfinite value present in outlet flow (or not defined)';
    end
end
for SRSR = 1:SR_num
    if ~isfinite(Rm.ObjectList.ServerRacks{SRSR}.FlowRate)
        errstring{end+1} = 'Nonfinite value present in server rack flow (or not defined)';
    end
    if ~isfinite(Rm.ObjectList.ServerRacks{SRSR}.HeatGen)
        errstring{end+1} = 'Nonfinite value present in server rack heat generation (or not defined)';
    end
end

% If no major problems, moves on to other issues
if isempty(errstring)
    % Checking that at least one inlet has a nonzero flow rate
    FR = [];
    for k = 1:I_num
        FR(k) = Rm.ObjectList.Inlets{k}.FlowRate;
    end
    if sum(FR) > 0
        YN = true;
    else
        errstring{end+1} = 'Total inlet flow is zero';
    end

    % Now checks to make sure none of the rack flow faces are
    % obstructed by other racks. This check was not done
    % earlier b/c of unknown resolution and flow direction
    % until placement.
    res = Rm.Resolution;
    SRList = Rm.ObjectList.ServerRacks;
    for i = 1:SR_num
        % Potentially obstructING rack
        V = SRList{i}.Vertices;
        V_RC = V/res + [2 2 2; 1 1 1];
        % Arrays of node subscripts of points inside the rack.
        [VRCx,VRCy] = meshgrid(V_RC(1,1):V_RC(2,1),V_RC(1,2):V_RC(2,2));
        for h = 1:SR_num
            % Potentially obstructED rack.
            obstructflag = 0;
            if ~isequal(SRList{h},SRList{i}) % Make sure we
                % aren't comparing the same rack.
                [Ao,Bo,ARCout,BRCout] = GetOutFace(SRList{h});
                [Ai,Bi,ARCin,BRCin] = GetInFace(SRList{h});
                [In_RCx,In_RCy] = meshgrid(ARCin(1):BRCin(1),ARCin(2):BRCin(2));
                [Out_RCx,Out_RCy] = meshgrid(ARCout(1):BRCout(1),ARCout(2):BRCout(2));
                % Arrays of node subscripts of points on the
                % rack flow faces.
                WRCx = [In_RCx;Out_RCx];
                WRCy = [In_RCy;Out_RCy];
                % Compare the two lists, checking for
                % coinciding points, tripping a flag if so.
                for g = 1:numel(VRCx)
                    for f = 1:numel(WRCx)
                        if isequal([VRCx(g) VRCy(g)],[WRCx(f) WRCy(f)])
                            obstructflag = 1;
                        end
                    end
                end
                if obstructflag
                    YN = false;
                    errstring{end+1} = ['Server rack # ' num2str(h) 'flow face is obstructed'];
                end
            end
        end
    end
end
% Check if any error conditions were met, and list them if
% present.
if ~YN
    errordlg(errstring,'Not a solvable problem!')
end
end