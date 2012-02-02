function FlowResults = SolvePotMatrix(Rm)
%SOLVEPOTMATRIX Potential flow solver.
%   SOLVEPOTMATRIX takes the room object and runs the potential flow model
%   based off the initial room configuration, solver options, and
%   convergence criteria. Similar to SOLVEPOTFLOW, but uses the sparse
%   matrix solver.

%% Start Initialization
disp('-----Flow Solver START')
tic % Start a stopwatch timer for time to execute Initialization cell

% Create Initial Result Object
FlowResults = Results('ResultData');
FlowResults.RunDate = datestr(now);
FlowResults.Room = Rm;

% Extract relevant data from Room object
[room_config, partition_config, u0,v0,w0,Q] = extract_BC_data(Rm);
[n m l] = size(room_config);
resolution = Rm.Resolution;

% Initialize solution matrices
phi = zeros(n,m,l);                     % Potential matrix

% Scaling the boundary conditions
u0 = u0*resolution;
v0 = v0*resolution;
w0 = w0*resolution;

% Initialize residual values and diagnostic arrays
phi_resid = zeros(size(phi)); 
bc_errors = zeros([size(room_config) 3]);

% Sweep order for points of room
k_inds = l:-1:1;
j_inds = m:-1:1;
i_inds = n:-1:1;
diradd = [-1 0 0;1 0 0;0 -1 0;0 1 0;0 0 -1;0 0 1];

[prop,border,borderadd,cornerflag] = ...
    BorderChecks(room_config,partition_config,u0,v0,w0);

 % store those tricky corner phi values in here
phi_corner = zeros([size(room_config) 6]);

init_time = toc; % read stopwatch timer for time to execute Initialization cell
disp(['Flow Solver: Initialization finished at ' num2str(init_time) ' seconds'])

%% List the nodal interrelations
num = nnz(prop == 1) + nnz(border);

% Create index list. 
% entries are either air nodes [i j k] or virtual nodes [i j k mm]
disp('Flow Solver: Creating nodal interrelations')                        
indlist = zeros(num,5);
% adjlist = zeros(num,6);
nodelist_ind = 0;
for k = k_inds
    for j = j_inds
        for i = i_inds
            if prop(i,j,k)==1 % node is in the air
                nodelist_ind = nodelist_ind + 1;
                hash = hashpipe(n,m,l,i,j,k,7);
                % add air node index to list
                indlist(nodelist_ind,:) = [i j k 0 hash];
                for mm = 1:6
                    if border(i,j,k,mm) % adjacent air node was actually virtual!!
                        nodelist_ind = nodelist_ind + 1;
                        virtnode = [i j k mm];
                        hash = hashpipe(n,m,l,i,j,k,mm);
                        % add the virtual node to the main list
                        indlist(nodelist_ind,:) = [virtnode hash]; 
                    end
                end
            end
        end
    end
end
nodir_time = toc; % read stopwatch timer for time to execute nodal interrelation cell
disp(['Flow Solver: Nodal interrelations tabulated at ' num2str(nodir_time) ' seconds'])
%% Populate the potential matrix
sp_numel = 7*nnz(indlist(:,4) == 0)-6 + 2*nnz(indlist(:,4) > 0);

sp_f = zeros(num,1);
sp_i = zeros(sp_numel,1);
sp_j = zeros(sp_numel,1);
sp_s = zeros(sp_numel,1);
% IMPORTANT: This anchors the very first node potential to zero value.
% Otherwise there is an infinite number of possible solutions.
sp_i(1) = 1;
sp_j(1) = 1;
sp_s(1) = 1;

sp_node_ind = 1; % 
for ww = 2:num
    sp_node_ind=sp_node_ind+1;
    m_ind = indlist(ww,:);
    i = m_ind(1);
    j = m_ind(2);
    k = m_ind(3);
    mm = m_ind(4);
    if mm == 0 % currently an air node
        sp_i(sp_node_ind) = ww;
        sp_j(sp_node_ind) = ww;
        sp_s(sp_node_ind) = -6;
        for ii = 1:6
            adj_node = m_ind(1:3) + diradd(ii,:);
            sp_node_ind=sp_node_ind+1;
            bordair = ~border(i,j,k,ii);
            if bordair % borders air node
                hash_ad = hashpipe(n,m,l,adj_node(1),adj_node(2),adj_node(3),7);
                adjmatind = find(indlist(:,5) == hash_ad,1,'first');
                sp_i(sp_node_ind) = ww;
                sp_j(sp_node_ind) = adjmatind;
                sp_s(sp_node_ind) = 1;
            elseif ~bordair % borders virtual node
                hash_virt = hashpipe(n,m,l,i,j,k,ii);
                adjmatind = find(indlist(:,5) == hash_virt,1,'first');
                sp_i(sp_node_ind) = ww;
                sp_j(sp_node_ind) = adjmatind;
                sp_s(sp_node_ind) = 1;
            end
        end
    elseif mm ~= 0 % currently a virtual node
        hash_air = hashpipe(n,m,l,i,j,k,7);
        air_ind = find(indlist(:,5) == hash_air,1,'first');
        sp_i(sp_node_ind) = ww;
        sp_j(sp_node_ind) = ww;
        sp_s(sp_node_ind) = -1;

        sp_node_ind = sp_node_ind + 1;
        sp_i(sp_node_ind) = ww;
        sp_j(sp_node_ind) = air_ind;
        sp_s(sp_node_ind) = 1;        
        sp_f(ww) = -borderadd(i,j,k,mm);
    end
end
B = sp_f;
A = sparse(sp_i,sp_j,sp_s,num,num);

popu_time = toc; % read stopwatch timer for time to execute nodal interrelation cell
disp(['Flow Solver: Population of matrix finished at ' num2str(popu_time) ' seconds'])
%% Solve the Potential Matrix
try
    PF = A\B;
catch ME
    disp('Matrix is funky. Try an iterative method instead.')
    return
end
solut_time = toc;
disp(['Flow Solver: Matrix solved at ' num2str(solut_time) ' seconds'])
R = A*PF-B; % residual
%% Re-form into phi and phi_corner and phi_residual
for p1 = 1:num
    node_ind = indlist(p1,:);
    ip = node_ind(1);
    jp = node_ind(2);
    kp = node_ind(3);
    mp = node_ind(4);
    if mp == 0 % air node
        phi(ip,jp,kp) = PF(p1);
        phi_resid(ip,jp,kp) = R(p1);
    elseif mp > 0 % virtual node
        ipa = ip + diradd(mp,1);
        jpa = jp + diradd(mp,2);
        kpa = kp + diradd(mp,3);
        if Rm.ResultSettings.PhiBCError == 1
            switch mp
                case {1,2}
                    bc_errors(ip,jp,kp,1) = bc_errors(ip,jp,kp,1) + R(p1);
                case {3,4}
                    bc_errors(ip,jp,kp,2) = bc_errors(ip,jp,kp,2) + R(p1);
                case {5,6}
                    bc_errors(ip,jp,kp,3) = bc_errors(ip,jp,kp,3) + R(p1);
            end
        end
        if cornerflag(ip,jp,kp,mp) % virtual node is in a corner or partition
            phi_corner(ip,jp,kp,mp) = PF(p1);
        else % virtual node is not in a corner or partition, just in a normal wall
            phi(ipa,jpa,kpa) = PF(p1);
        end
    end
end
%% Record Final Results
FlowResults.Phi.Bulk = phi;
FlowResults.Phi.Corners = phi_corner;

if Rm.ResultSettings.PhiResidual == 1
    FlowResults.PhiResidual = phi_resid;
end

if Rm.ResultSettings.PhiBCError == 1
    FlowResults.PhiBCError = bc_errors;
end

if Rm.ResultSettings.FlowTime == 1
    final_time = toc;
    FlowResults.FlowTime = final_time;
end
% if Rm.ResultSettings.FlowTimeEvol == 1
%     FlowResults.FlowTimeEvol = [init_time popu_time solut_time];
% end
final_time = toc;
disp(['Flow Solver: Final results recorded at ' num2str(final_time) ' seconds'])
disp('-----Flow Solver END')
end

function ndx = hashpipe(n,m,l,x1,x2,x3,x4)
ndx = x1 + (x2-1)*n + (x3-1)*n*m + (x4-1)*n*m*l;
end