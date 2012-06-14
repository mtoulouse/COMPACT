function ExDestResults = ExergyDestruction(TempResults)
%EXERGYDESTRUCTION Exergy Destruction Code
%   EXERGYDESTRUCTION takes a Results object containing a temperature field
%   and uses it to compute an exergy destruction field. Iterated through
%   each cell and sums up exergy destruction terms based on entropy of in-
%   and out-flows.

disp('-----Exergy Solver START')
tic % start the timer
ExDestResults = TempResults; % copy the temperature result object, you'll be adding to it
Rm = ExDestResults.Room;
resolution = Rm.Resolution;
T_field = TempResults.Temp; % the temperature field

T0 = 25; %Rm.InletTemp; % Temperature of incoming flow into the room
g = Air.g; %ft/s^2
rho = Air.rho; %kg/ft^3
cp = Air.cp; %J/kg-K

[room_config,partition_config,u0,v0,w0,Q] = extract_BC_data(Rm); % extract some boundary condition + room configuration info
next2rack = MakeRackLinkTable(Rm); % info on whether a point in the room is next to a rack, and in what direction
[L M N] = size(room_config); % dimensions of matrix representing the room
flows = extract_vel_flows(TempResults.Phi,room_config,partition_config,resolution); % extract the flow information from the potential solver results
diradd = [-1 0 0;1 0 0;0 -1 0;0 1 0;0 0 -1;0 0 1]; % just a little something to make the iteration through air cells more concise

% Is the solution one with vortex superposition? Add the vortex flow field.
if Rm.ResultSettings.VortexSuper == 1 && ~isempty(TempResults.VortexSuper)
    flows_b = TempResults.VortexSuper;
    flows = flows + flows_b; %ft/s
end
m_dot = Air.rho*Rm.Resolution^2*flows; % mass flow field, kg/s

psi_d = zeros(size(T_field)); % initialize solution matrix
init_time = toc;
disp(['Exergy Solver: Initialization finished at ' num2str(init_time) ' seconds'])
%% Exergy destruction iteration

% diagnostic variables
include_V_term = 0; % include the kinetic energy term?
include_gZ_term = 0; % include the gravitational potential energy term?
H = 0;

for i = 2:L-1
    for j = 2:M-1
        for k = 2:N-1
            if room_config(i,j,k) % iterate through each cell in the air
                c = sub2ind(size(room_config),i,j,k);
                iT = i - 1; % Temperature field coords (no virtual node at beginning)
                jT = j - 1;
                kT = k - 1;
                % now iterate through each direction
                for m = 1:6
                    in_term = 0;
                    out_term = 0;
                    Q_term = 0;
                    V = flows(i,j,k,m)/Air.SI_length; % convert to m/s
                    Z = (kT - 0.5 + 0.5*diradd(m,3))*resolution/Air.SI_length; % convert to m
                    if m_dot(i,j,k,m) >= 0 % air flows out of the cell?
                        T_out = T_field(iT,jT,kT);
%                         H = cp*(T_out-T0);
                        TS = (T0+273.15)*(air_entropy(T_out)-air_entropy(T0)); % entropy is of air at the cell temp.
                        out_term = m_dot(i,j,k,m)*...
                            (H + include_V_term*V^2/2 + ...
                            include_gZ_term*g/Air.SI_length*Z - TS);
%                             (-TS);                        
                    elseif m_dot(i,j,k,m) < 0 % air flows into the cell?
                        ia = iT + diradd(m,1); % Coordinate of adjacent cell
                        ja = jT + diradd(m,2);
                        ka = kT + diradd(m,3);
                        % Defining the temperature of the inflowing air:
                        if room_config(ia+1,ja+1,ka+1) == 0 % is the adjacent point not in the room?
                            if next2rack(i,j,k,1) == m % the flow into the cell is from a rack
                                iR = next2rack(i,j,k,2)-1;
                                jR = next2rack(i,j,k,3)-1;
                                kR = next2rack(i,j,k,4)-1;
                                T_in = T_field(iR,jR,kR) + Q(i,j,k)/(cp*abs(m_dot(i,j,k,m))); %T of cell on front of rack                                
%                                 T_in = T_field(iT,jT,kT); %just assume it's about the same T as the cell itself
%                                 Q_term = Q(i,j,k)*(1-(T0+273.15)/(T_in+273.15));
%                                 disp(Q_term);
                            else % air flows in from not in room? it's a room inlet. T is inlet temp.
                                T_in = Rm.InletTemp;
                            end
                        else % adjacent point is in the room.
                            T_in = T_field(ia,ja,ka); % temperature of adjacent cell.
                        end
%                         H = cp*(T_in-T0);
                        TS = (T0+273.15)*(air_entropy(T_in)-air_entropy(T0)); % entropy is of incoming air.
                        in_term = -m_dot(i,j,k,m)*...
                            (H + include_V_term*V^2/2 + ...
                            include_gZ_term*g/Air.SI_length*Z - TS); % units of TS, H etc. are [J/kg] aka [m^2/s^2]
%                             (-TS);
                        % spot check!
%                         if isequal([i j k],[17 5 7])
%                             disp(['direc' num2str(m)])
% %                             disp(-m_dot(i,j,k,m))
% %                             disp(T_in)
%                             disp(in_term)
%                             disp(V^2/2)
%                             disp(g*Z)
%                             disp(-TS)
%                         end
                    end
                    psi_d(iT,jT,kT) = psi_d(iT,jT,kT) + in_term - out_term + Q_term; % sum up + and - exergy destroyed for the cell
                end
            end
        end
    end
end
exd_time = toc;
disp(['Exergy Solver: Exergy destruction field created at ' num2str(exd_time) ' seconds'])

%% Store the results
ExDestResults.ExergyDest = psi_d;
if Rm.ResultSettings.ExergyTime == 1
    final_time = toc;
    ExDestResults.ExergyTime = final_time;
end
final_time = toc;
disp(['Exergy Solver: Final results recorded at ' num2str(final_time) ' seconds'])
disp('-----Exergy Solver END')
end
function s = air_entropy(T) % J/kg/K, if given temp in C
% this is a perfect quadratic curve fit to air entropy data from 10:1:50 C
s = -0.0055*T^2 + 3.648*T + 6773;
end