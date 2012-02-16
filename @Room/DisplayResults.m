function DisplayResults(R,room)
%DISPLAYRESULTS Result display function.
%   DISPLAYRESULTS takes a structure with result information, including the
%   display method, and generates a figure or dialog box containing a
%   visual representation of the data. For some cases, an "iso/slice" GUI
%   function is called, where 3D scalar data can be viewed in a 3-D setting
%   with either isosurfaces or X/Y/Z slice plots, with or without overlaid
%   room objects shown.
%
%   Methods of display:
%   'scalar' - just a dialog w/ value
%   '2Devol' - semi-log y plot (x-axis is # of iterations)
%   '3Dscalar' - iso/slice plot
%   '3Dvector' - streamline
%   '4Dscalar' - iso/slice w/ a list box to change set of 3-D data showing

Rstr = R.String; % name of data set
Rdat = R.Data; % relevant data
Rwk = R.Workspace; % workspace name for variable containing data
Rdsp = R.Display; % way the data is shown

switch Rdsp
    case 'scalar'
        % if scalar, just make a dialog with the shown value.
        helpdlg([Rstr ' = ' num2str(Rdat)],'Result is a single scalar')
    case '2Devol'
        % Unless it turns out there is only one value in the evolution,
        % creates a semi-log y plot with "iterations" as the x-axis
        if isequal(size(Rdat),[1 1])
            helpdlg([Rstr ' = ' num2str(Rdat)],'Result is a single scalar')
        else
            figure('Name',Rwk);
            semilogy(Rdat);
            title(Rstr)
            xlabel('Iterations')
            % There may be three sets of values to display, in which case
            % they are the x, y and z sets. Adjuist the legend accordingly.
            if min(size(Rdat)) > 1
                j = legend([Rwk '_x'],[Rwk '_y'],[Rwk '_z']);
                set(j,'Interpreter','none');
            end
        end
    case '3Dscalar'
        % Displays a 3D scalar field. Calls the IsoSliceViewGUI function
        % to create the viewing GUI. If the potential field is the data
        % being called, the two arrays are combined for a visually
        % appealing data display.
        if strcmp(Rwk,'phi')
            [room_config,partition_config,u0,v0,w0,Q] = extract_BC_data(room);
            [l m n] = size(Rdat.Bulk);
            phi_disp = zeros(size(Rdat.Bulk));
            for k = 2:n-1
                for j = 2:m-1
                    for i = 2:l-1
                        if Rdat.Bulk(i,j,k) == 0
                            surrnum = room_config(i+1,j,k) + room_config(i-1,j,k) + ...
                                room_config(i,j+1,k) + room_config(i,j-1,k) +...
                                room_config(i,j,k+1) + room_config(i,j,k-1);
                            if surrnum == 2 || surrnum == 3
                                surrcorn = squeeze(Rdat.Corners(i,j,k,:));
                                phi_disp(i,j,k) = mean(nonzeros(surrcorn));
                            end
                        end
                    end
                end
            end
            phi_disp = phi_disp + Rdat.Bulk;
            Rdat = phi_disp;
        end
        IsoSliceViewGUI(Rstr,Rdat,Rwk,Rdsp,room)
    case '4Dscalar'
        % Displays a 4D scalar field. In this case, this means creating a
        % selectable list of 3D data groups to display. The names of the
        % extra data sets are added to the "String" field and passed to the
        % IsoSliceViewGUI function.
        switch Rwk
            case {'levels','delta_T','level1'}
                newRdat = [];
                for qi = 1:size(Rdat,4)
                    if nnz(Rdat(:,:,:,qi)) > 0
                        Rstr = [Rstr; {['Node # ' num2str(qi)]}];
                        newRdat = cat(4,newRdat,Rdat(:,:,:,qi));
                    end
                end
                IsoSliceViewGUI(Rstr,newRdat,Rwk,Rdsp,room)
            case 'bc_error'
                Rstr = {Rstr; 'X-direction'; 'Y-direction'; 'Z-direction'};
                IsoSliceViewGUI(Rstr,Rdat,Rwk,Rdsp,room)
            case {'flows','vortex_flow'}
                Rstr = {Rstr; '-X (West)'; '+X (East)'; '-Y (South)'; '+Y (North)';'-Z (Down)'; '+Z (Up)'};
                IsoSliceViewGUI(Rstr,Rdat,Rwk,Rdsp,room)
        end
    case '3Dvector'
        % One special case. Only one 3-D vector field can be generated
        % fromt the data, in which case a figure with streamline display is
        % made.
        UVWstreamline(Rdat,room)
end
end

function [] = UVWstreamline(Rdat,Rm)
% Streamline display function. Creates a new figure with streamlines which
% originate from the inlets and downstream faces of server racks. Also
% makes these originating points with red stars.
u = Rdat(2:end-1,2:end-1,2:end-1,1);
v = Rdat(2:end-1,2:end-1,2:end-1,2);
w = Rdat(2:end-1,2:end-1,2:end-1,3);
u_room = permute(u,[2 1 3]);
v_room = permute(v,[2 1 3]);
w_room = permute(w,[2 1 3]);

rdx = Rm.Dimensions(1);
rdy = Rm.Dimensions(2);
rdz = Rm.Dimensions(3);
res = Rm.Resolution;
x_room = (res/2:res:rdx-res/2);
y_room = (res/2:res:rdy-res/2);
z_room = (res/2:res:rdz-res/2);
[X,Y,Z] = meshgrid(x_room,y_room,z_room);

[SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
ObjList = Rm.ObjectList;
RackList = ObjList.ServerRacks;
InList = ObjList.Inlets;
OutList = ObjList.Outlets;

% Coordinates of streamline originating points stored here and populated
% below:
sx_tot = [];
sy_tot = [];
sz_tot = [];

if SR_num + I_num >= 3
    SL_res_SR = 2; %streamline resolution: number of originating points in
    % each dimension at server racks or inlets.
    SL_res_I = 2;
    SL_res_O = 2;
else
    SL_res_SR = 6;
    SL_res_I = 6;
    SL_res_O = 6;
end
for kk = 1:I_num
    IL = InList{kk};
    if IL.FlowRate ~= 0
        [A,B,ARC,BRC] = GetFace(IL);
        A(3) = A(3) + (A(3)==0)*res/2;
        B(3) = B(3) + (B(3)==0)*res/2;
        I_sx = linspace(A(1)+res/2,B(1)-res/2,SL_res_I);
        I_sy = linspace(A(2)+res/2,B(2)-res/2,SL_res_I);
        I_sz = linspace(A(3)+res/2,B(3)-res/2,SL_res_I);
        flat_ind = find(~(B-A));
        switch flat_ind
            case 1
                I_sx = A(1);
            case 2
                I_sy = A(2);
            case 3
                I_sz = A(3);
        end
        [sx, sy, sz] = meshgrid(I_sx,I_sy,I_sz);
        sx_tot = cat(2,sx_tot,sx);
        sy_tot = cat(2,sy_tot,sy);
        sz_tot = cat(2,sz_tot,sz);
    end
end

for kk = 1:SR_num
    Rck = RackList{kk};
    if Rck.FlowRate ~= 0
        [A,B,ARC,BRC] = GetOutFace(Rck);
        A(3) = A(3) + (A(3)==0)*res/2;
        B(3) = B(3) + (B(3)==0)*res/2;
        I_sx = linspace(A(1)+res/2,B(1)-res/2,SL_res_SR);
        I_sy = linspace(A(2)+res/2,B(2)-res/2,SL_res_SR);
        I_sz = linspace(A(3)+res/2,B(3)-res/2,SL_res_SR);
        flat_ind = find(~(B-A));
        switch flat_ind
            case 1
                I_sx = A(1);
            case 2
                I_sy = A(2);
            case 3
                I_sz = A(3);
        end
        [sx, sy, sz] = meshgrid(I_sx,I_sy,I_sz);
        sx_tot = cat(2,sx_tot,squeeze(sx));
        sy_tot = cat(2,sy_tot,squeeze(sy));
        sz_tot = cat(2,sz_tot,squeeze(sz));
    end
end

for kk = 1:O_num
    OL = OutList{kk};
    if OL.FlowRate < 0
        [A,B,ARC,BRC] = GetFace(OL);
        A(3) = A(3) + (A(3)==0)*res/2;
        B(3) = B(3) + (B(3)==0)*res/2;
        I_sx = linspace(A(1)+res/2,B(1)-res/2,SL_res_O);
        I_sy = linspace(A(2)+res/2,B(2)-res/2,SL_res_O);
        I_sz = linspace(A(3)+res/2,B(3)-res/2,SL_res_O);
        flat_ind = find(~(B-A));
        switch flat_ind
            case 1
                I_sx = A(1);
            case 2
                I_sy = A(2);
            case 3
                I_sz = A(3);
        end
        [sx, sy, sz] = meshgrid(I_sx,I_sy,I_sz);
        sx_tot = cat(2,sx_tot,squeeze(sx));
        sy_tot = cat(2,sy_tot,squeeze(sy));
        sz_tot = cat(2,sz_tot,squeeze(sz));
    end
end

ax = findobj(Rm.Figure,'Tag','3D Axes');
strfig = figure('Name','U/V/W Streamlines',...
    'Numbertitle','off',...
    'Position',Center_Fig(600,600));
ViewAxes = copyobj(ax,strfig); % copy over the flow object patch display.
rotate3d on;
axis(ViewAxes);
hold on;
plot3(sx_tot(:),sy_tot(:),sz_tot(:),'r*') % plot the red stars
streamline(ViewAxes,X,Y,Z,u_room,v_room,w_room,sx_tot,sy_tot,sz_tot) % plot the streamlines.
hold off;
end