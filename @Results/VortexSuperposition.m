function TempResults = VortexSuperposition(varargin)
%VORTEXSUPERPOSITION Vortex superposition code
%   VORTEXSUPERPOSITION Imports vortex and aisle positioning info stored in
%   the Room object, grabs the temperature field from inputted TempResults, 
%   calculates the vortex strength and outputs the flow field to 
%   superimpose, also storing it in the TempResults object under the
%   "VortexSuper" property.
tic
disp('-----Vortex Solver START')
TempResults = varargin{1};
Vmult = TempResults.Room.VorSupMult;
aislesize = 'rackend+racktop';
if nargin >= 2
    Vmult = varargin{2};
    if nargin == 3
        aislesize = varargin{3};
    end
end

Vort_Info = TempResults.Room.VortexInfo;

Rm = TempResults.Room;
T = TempResults.Temp;
resolution = Rm.Resolution;
g = Air.g;
inlettemp = Rm.InletTemp;
[room_config,partition_config,u0,v0,w0,Q] = extract_BC_data(Rm);
[L M N] = size(room_config);
vflows = extract_vel_flows(TempResults.Phi,room_config,partition_config,resolution);
w = (vflows(:,:,:,6)-vflows(:,:,:,5))./2;
diradd = 0.5*resolution*[-1 0 0;1 0 0;0 -1 0;0 1 0;0 0 -1;0 0 1];
flows_b = zeros(size(vflows));

init_time = toc;
disp(['Vortex Solver: Initialization finished at ' num2str(init_time) ' seconds'])
%% Translate the imported vortex info
for p = 1:length(Vort_Info)
    typ = Vort_Info(p).Type;
    vert = Vort_Info(p).Vertices;
    link = Vort_Info(p).Links;
    if strcmp(typ,'Aisle')
        % if it is an aisle, find:
        % 1) the avg temperature of the aisle
        % 2) the avg upward velocity of the aisle
        % 3) the average temperature of the entire
        VRC = vert/resolution + [2 2 2; 1 1 1];
        VT = VRC - 1;
        aisle_in_air = room_config(VRC(1,1):VRC(2,1),VRC(1,2):VRC(2,2),VRC(1,3):VRC(2,3));
        temp_in_aisle = T(VT(1,1):VT(2,1),VT(1,2):VT(2,2),VT(1,3):VT(2,3));
        up_vel_in_aisle = w(VRC(1,1):VRC(2,1),VRC(1,2):VRC(2,2),VRC(1,3):VRC(2,3));
        TH_av(p) = sum(sum(sum(aisle_in_air.*temp_in_aisle)))/nnz(aisle_in_air);
        wH_av(p) = sum(sum(sum(aisle_in_air.*up_vel_in_aisle)))/nnz(aisle_in_air);
        aisle_height = max(VT(:,3));
        Tav_dc(p) = sum(sum(sum(T(:,:,1:aisle_height).*room_config(2:end-1,2:end-1,1+(1:aisle_height)))))...
            /nnz(room_config(2:end-1,2:end-1,1+(1:aisle_height)));
%         disp(Tav_dc(p))
%         disp(VRC)
%         disp(size(T))
%         disp(aisle_height)
    elseif strcmp(typ,'Vortex')
        % grab location of the two aisles linked to this vortex
        A1 = Vort_Info(link(1)).Vertices;
        A2 = Vort_Info(link(2)).Vertices;
        % find direction of aisle-vortex-aisle: X or Y?
        Fmin = min(vert,[],1);
        Fmax = max(vert,[],1);
        Gmin = min(A1,[],1);
        Gmax = max(A1,[],1);
        Xoverlap = min(Fmax(1), Gmax(1)) - max(Fmin(1), Gmin(1));
        Yoverlap = min(Fmax(2), Gmax(2)) - max(Fmin(2), Gmin(2));
        if Xoverlap == 0
            direc{p} = 'X';
            c(p) = 1;
%             disp(['Vortex ' num2str(p) ' - ' direc{p}])
        elseif Yoverlap == 0
            direc{p} = 'Y';
            c(p) = 2;
%             disp(['Vortex ' num2str(p) ' - ' direc{p}])
        end
        % define the vortex centerline
        vorcent{p} = vert;
        vorcent{p}(:,c(p)) = mean(vert(:,c(p)));
        vorcent{p}(:,3) = max(vert(:,3));
        % place the linked aisles in sign order (lower coord first)
        if mean(A1(:,c(p))) > mean(vert(:,c(p)))
            L1(p) = link(2);
            L2(p) = link(1);
        else
            L1(p) = link(1);
            L2(p) = link(2);
        end
    end
end
tran_time = toc;
disp(['Vortex Solver: Input translation finished at ' num2str(tran_time) ' seconds'])
%% Vortex characterization
vinf = [];
for p = 1:length(Vort_Info)
    typ = Vort_Info(p).Type;
    vert = Vort_Info(p).Vertices;
    link = Vort_Info(p).Links;
    if strcmp(typ,'Vortex')
        Hs = vorcent{p}(2,3); % true dimensions, not # of cells
        Ws = abs(diff(vert(:,c(p)))); % true dimensions, not # of cells
        T1 = TH_av(L1(p)); % average temp of lower-coord linked aisle
        T2 = TH_av(L2(p)); % average temp of higher-coord linked aisle
        if T2 > T1
            TH_avg = T2;
            wH_avg = wH_av(L2(p));
            k_sign  = -1;
        else
            TH_avg = T1;
            wH_avg = wH_av(L1(p));
            k_sign  = 1;
        end
        wb = sqrt(wH_avg^2+g/(TH_avg+273.15)*(TH_avg-Tav_dc(link(1)))*Hs); % assuming beta is 1/TH_avg
        dwb = wb - wH_avg;
        r0 = .5*(Ws+resolution);
        k = -dwb/r0*Vmult;
        %         disp([wb dwb r0 k])
        vinf(p,:) = [wb dwb r0 k_sign*k];
    end
end
wb = vinf(:,1);
dwb = vinf(:,2);
r0 = vinf(:,3);
k = vinf(:,4);

% disp([wb dwb r0 k])

vorchar_time = toc;
disp(['Vortex Solver: Vortices characterized at ' num2str(vorchar_time) ' seconds'])

%% Flow field creation

for ii = 1:L
    for jj = 1:M
        for kk = 1:N
            %calculate and sum influence of each vortex, add to dv and dw
            if room_config(ii,jj,kk)
                for l = 1:length(Vort_Info)
                    if strcmp(Vort_Info(l).Type,'Vortex')
                        x = (ii - 1.5)*resolution;
                        y = (jj - 1.5)*resolution;
                        z = (kk - 1.5)*resolution;
                        xc = vorcent{l}(1,1);
                        yc = vorcent{l}(1,2);
                        zc = vorcent{l}(1,3);
                        for p = 1:6 % cycle through each face
                            df = 0;
                            x_w = x + diradd(p,1);
                            y_w = y + diradd(p,2);
                            z_w = z + diradd(p,3);
                            % x_w,y_w,z_w is the location of the wall
                            % center
                            Xbounded = x > vorcent{l}(1,1) && x < vorcent{l}(2,1);
                            Ybounded = y > vorcent{l}(1,2) && y < vorcent{l}(2,2);
                            if c(l) == 1 && Ybounded    
%                                 r_w =  sqrt((x_w-xc)^2 + (z_w-zc)^2);
                                r_w =  sqrt((x-xc)^2 + (z-zc)^2); % try with just center
                                if r_w < r0(l)
                                    switch p
                                        case 2 % face is in +x direction
                                            df = -k(l)*(z_w-zc);
                                        case 1 % face is in -x direction
                                            df = -(-k(l)*(z_w-zc));
                                        case 6 % face is in +z direction
                                            df = k(l)*(x_w-xc);
                                        case 5 % face is in -z direction
                                            df = -(k(l)*(x_w-xc));
                                        case {3,4} % face is in +/-y direction
                                            df = 0;
                                    end
                                else
                                    switch p
                                        case 2 % face is in +x direction
                                            df = -k(l)*(z_w-zc)*(r0(l)/r_w)^2;
                                        case 1 % face is in -x direction
                                            df = -(-k(l)*(z_w-zc)*(r0(l)/r_w)^2);
                                        case 6 % face is in +z direction
                                            df = k(l)*(x_w-xc)*(r0(l)/r_w)^2;
                                        case 5 % face is in -z direction
                                            df = -(k(l)*(x_w-xc)*(r0(l)/r_w)^2);
                                        case {3,4} % face is in +/-x direction
                                            df = 0;
                                    end
                                end
                            elseif c(l) == 2 && Xbounded
%                                 r_w =  sqrt((y_w-yc)^2 + (z_w-zc)^2);
                                r_w =  sqrt((y-yc)^2 + (z-zc)^2); % try with just center
                                if r_w < r0(l)
                                    switch p
                                        case 4 % face is in +y direction
                                            df = -k(l)*(z_w-zc);
                                        case 3 % face is in -y direction
                                            df = -(-k(l)*(z_w-zc));
                                        case 6 % face is in +z direction
                                            df = k(l)*(y_w-yc);
                                        case 5 % face is in -z direction
                                            df = -(k(l)*(y_w-yc));
                                        case {1,2} % face is in +/-x direction
                                            df = 0;
                                    end
                                else
                                    switch p
                                        case 4 % face is in +y direction
                                            df = -k(l)*(z_w-zc)*(r0(l)/r_w)^2;
                                        case 3 % face is in -y direction
                                            df = -(-k(l)*(z_w-zc)*(r0(l)/r_w)^2);
                                        case 6 % face is in +z direction
                                            df = k(l)*(y_w-yc)*(r0(l)/r_w)^2;
                                        case 5 % face is in -z direction
                                            df = -(k(l)*(y_w-yc)*(r0(l)/r_w)^2);
                                        case {1,2} % face is in +/-x direction
                                            df = 0;
                                    end
                                end
                            end
                            flows_b(ii,jj,kk,p) = flows_b(ii,jj,kk,p) + df;
                        end
                    end
                end
            end
        end
    end
end
flowb_time = toc;
disp(['Vortex Solver: Flow field created at ' num2str(flowb_time) ' seconds'])
TempResults.VortexSuper = flows_b;
if Rm.ResultSettings.VortexTime == 1
    final_time = toc;
    TempResults.VortexTime = final_time;
end
final_time = toc;
disp(['Vortex Solver: Final results recorded at ' num2str(final_time) ' seconds'])
disp('-----Vortex Solver END')
end