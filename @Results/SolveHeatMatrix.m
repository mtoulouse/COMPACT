function TempResults = SolveHeatMatrix(FlowResults)
%SOLVEHEATMATRIX Heat transport code used to compute temperature
%   SOLVEHEATMATRIX takes flow results containing the potential field for
%   the room and generates the temperature field. This actually takes a
%   little reading to understand, because I switched to a shaved-down
%   version of the sub2ind function and shortened some of the other code
%   too to shave off extra seconds.
%
%   NOTE: if you want to change to Lopez/Hamann style convec (minus
%   conduction), u1*T1 + u2*T2 + ... = 2Q/(rho*cp*A). Not implemented.

disp('-----Temp Solver START')
tic
Rm = FlowResults.Room;
resolution = Rm.Resolution;
inlettemp = Rm.InletTemp;
[room_config,partition_config,u0,v0,w0,Q] = extract_BC_data(Rm);
[L M N] = size(room_config);
[SR_num I_num O_num P_num Ob_num] = CountObjs(Rm);
flows = extract_vel_flows(FlowResults.Phi,room_config,partition_config,resolution);
VortexFlag = Rm.ResultSettings.VortexSuper == 1 && ...
    ~isempty(FlowResults.VortexSuper); % Vortex Superposition Flag
if VortexFlag
    flows_b = FlowResults.VortexSuper;
    flows = flows + flows_b;
end
% disp('Temporary Checkpoint 1')
% pause(0.5)
next2rack = MakeRackLinkTable(Rm);
C = Air.rho*Air.cp*resolution^2;
diradd = [-1 0 0;1 0 0;0 -1 0;0 1 0;0 0 -1;0 0 1];

T_ma = inlettemp*ones(size(room_config)); % initialize temperature matrix, including walls
num_inlet_cells = 0;

% Go through each inlet and outlet, and if they have a different temp. than
% the default inlet temp., change the T in the wall. Also, count the number
% of cells in the inlets to use in initializing a properly-sized sparse
% matrix.
for p = 1:I_num
    FO = Rm.ObjectList.Inlets{p};
    [ARC,BRC] = RC_in_wall(FO);
    if ~isempty(FO.AirTemp)
        T_ma(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = FO.AirTemp;
    end
    if FO.FlowRate > 0
        num_inlet_cells = num_inlet_cells + prod(nonzeros(BRC-ARC)+1);
    end
end
for p = 1:O_num
    FO = Rm.ObjectList.Outlets{p};
    [ARC,BRC] = RC_in_wall(FO);
    if ~isempty(FO.AirTemp) && FO.FlowRate < 0
        T_ma(ARC(1):BRC(1),ARC(2):BRC(2),ARC(3):BRC(3)) = FO.AirTemp;
    end
    if FO.FlowRate < 0
        num_inlet_cells = num_inlet_cells + prod(nonzeros(BRC-ARC)+1);
    end
end
num_T_changed = nnz(T_ma-inlettemp);

init_time = toc;
disp(['Temp Solver: Initialization finished at ' num2str(init_time) ' seconds'])
% disp('Temporary Checkpoint 2')
%% Determine the node locations and the indices of their neighbors

num_aircells = nnz(room_config);
node_list = zeros(num_aircells,10);
node_index = 0;
for i = 2:L-1
    for j = 2:M-1
        for k = 2:N-1
            if room_config(i,j,k)
                node_index = node_index + 1;
                fd = permute(flows(i,j,k,:),[1 4 2 3]);
                hash = hashpipe(L,M,N,i,j,k);
                node_list(node_index,:) = [i j k hash fd]; % list of nodes + hash index + flows in 6 directions
            end
        end
    end
end
nodir_time = toc; % read stopwatch timer for time to execute nodal interrelation cell
disp(['Temp Solver: Nodal interrelations tabulated at ' num2str(nodir_time) ' seconds'])
%% Populate the heat equation matrix
sp_numel = num_aircells + nnz(node_list(:,5:10) < 0) - num_inlet_cells;

% # of elements  = # of nodes + # of inflows into each node from within the
% room.

sp_q = zeros(num_aircells,1);
sp_i = zeros(sp_numel,1);
sp_j = zeros(sp_numel,1);
sp_s = zeros(sp_numel,1);
sp_node_ind = 0;

for m = 1:num_aircells
    i = node_list(m,1);
    j = node_list(m,2);
    k = node_list(m,3);
    adjflows = node_list(m,5:10);
    sp_q(m) = Q(i,j,k)/C;
    % add up the outflows, these only contribute to the coefficient along
    % the main diagonal
    sp_node_ind = sp_node_ind + 1;
    sp_i(sp_node_ind) = m;
    sp_j(sp_node_ind) = m;
    sp_s(sp_node_ind) = sum((adjflows > 0).*adjflows); % sum of outflows
    n2r = next2rack(i,j,k,:);
    for n = 1:6
        ia = i + diradd(n,1);
        ja = j + diradd(n,2);
        ka = k + diradd(n,3);
        inflow = adjflows(n);
        if inflow < 0
            if ~room_config(ia,ja,ka) % the adjacent node is not in the room
                % it is either in a rack or outside the room
                if n2r(1) == n % in rack? change ia,ja,ka and treat it like a air node
                    ia = n2r(2);
                    ja = n2r(3);
                    ka = n2r(4);
                    sp_node_ind = sp_node_ind + 1;
                    sp_i(sp_node_ind) = m;
                    sp_j(sp_node_ind) = find(node_list(:,4) == hashpipe(L,M,N,ia,ja,ka),1,'first');
                    sp_s(sp_node_ind) = inflow;
                else % inflow from not in room and not a rack? it's an inlet.
                    sp_q(m) = sp_q(m) - inflow*T_ma(ia,ja,ka);
                end
            else
                sp_node_ind = sp_node_ind + 1;
                sp_i(sp_node_ind) = m;
                sp_j(sp_node_ind) = find(node_list(:,4) == hashpipe(L,M,N,ia,ja,ka),1,'first');
                sp_s(sp_node_ind) = inflow;
            end
        end
    end
end

% disp(sp_numel)
% disp(aircount)
% disp(inflcount)
% disp('---')
% disp(sp_node_ind)

sp_i(sp_node_ind+1:end) = [];
sp_j(sp_node_ind+1:end) = [];
sp_s(sp_node_ind+1:end) = [];

% disp(sp_numel)
% disp(num_aircells)
% disp(nnz(node_list(:,5:10) < 0))
% disp(num_inlet_cells)

B = sp_q;
A = sparse(sp_i,sp_j,sp_s,num_aircells,num_aircells);
popu_time = toc; % read stopwatch timer for time to execute nodal interrelation cell
disp(['Temp Solver: Population of matrix finished at ' num2str(popu_time) ' seconds'])

%% Solve the heat matrix
TT = A\B;
for p = 1:length(TT)
    T_ma(node_list(p,4)) = TT(p);
end
T_mat = T_ma(2:end-1,2:end-1,2:end-1);
solut_time = toc;
disp(['Temp Solver: Matrix solved at ' num2str(solut_time) ' seconds'])

if VortexFlag
    BiggestUnderTemp = min(min(min(T_mat-inlettemp)));
    if abs(BiggestUnderTemp) > 1e-9
    NumPointsUnderInletTemp = nnz(T_mat<inlettemp);
    AvgAmtUnderInletTemp = abs(mean(T_mat(T_mat<inlettemp)) - inlettemp);
        disp([num2str(NumPointsUnderInletTemp) ' points, averaging ' num2str(AvgAmtUnderInletTemp) ' under inlet temperature']);
        disp(['lowest was ' num2str(BiggestUnderTemp) 'C under inlet temperature']);
    end
    T_ma(T_ma<inlettemp) = inlettemp;
    T_mat(T_mat<inlettemp) = inlettemp;
end
%% Store data in the result object
TempResults = FlowResults;
TempResults.Temp = T_mat;

% generate the energy residual field if requested
if Rm.ResultSettings.EnergyResidual == 1
    E_resid = zeros(size(room_config));
    for i = 2:L-1
        for j = 2:M-1
            for k = 2:N-1
                if room_config(i,j,k)
                    Ein = 0;
                    mcout = 0;
                    qgen = Q(i,j,k);
                    for mm = 1:6
                        ia = i + diradd(mm,1);
                        ja = j + diradd(mm,2);
                        ka = k + diradd(mm,3);
                        fl = flows(i,j,k,mm);
                        if next2rack(i,j,k,1) == mm
                            Tadj = T_ma(next2rack(i,j,k,2),next2rack(i,j,k,3),next2rack(i,j,k,4));
                        else
                            Tadj = T_ma(ia,ja,ka);
                        end
                        if fl < 0 % inflow
                            Ein = Ein + C*-fl*Tadj;
                        elseif fl >= 0
                            mcout = mcout + C*fl;
                        end
                    end
                    E_resid(i,j,k) = (Ein+qgen)-mcout*T_ma(i,j,k);
                end
            end
        end
    end
    TempResults.EnergyResidual = E_resid;
end
if Rm.ResultSettings.TempTime == 1
    final_time = toc;
    if VortexFlag
        TempResults.TempTime(2) = final_time;
    else 
        TempResults.TempTime = final_time;
    end
end


final_time = toc;
disp(['Temp Solver: Final results recorded at ' num2str(final_time) ' seconds'])
disp('-----Temp Solver END')
end

function [ARC,BRC] = RC_in_wall(FO)
% takes a flow object as input, gives RC coords of nodes inside the wall
[A,B,ARC,BRC] = GetFace(FO);
diradd = [1 0 0;-1 0 0;0 1 0;0 -1 0;0 0 1;0 0 -1];
G = FO.Orientation;
ARC = ARC + diradd(G,:);
BRC = BRC + diradd(G,:);
end

function ndx = hashpipe(L,M,N,x,y,z) % shaved-down version of sub2ind
ndx = x + (y-1)*L + (z-1)*L*M;
end