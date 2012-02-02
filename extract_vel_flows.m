function flows = extract_vel_flows(Phi,room_config,partition_config,resolution)
%EXTRACT_VEL_FLOWS Extracts flow velocities from raw flow data
%   EXTRACT_VEL_FLOWS takes the phi field, field resolution, and room
%   configuration data to generate the estimated flow in [Length]/[Time]
%   between each air node and its six neighbors.
phi = Phi.Bulk;
phi_corner = Phi.Corners;
[n m l] = size(phi);
flows = zeros(n,m,l,6);

% Proceed through each point in the room that is not in the outer wall
for i=2:n-1
    for j=2:m-1
        for k=2:l-1
            if room_config(i,j,k) == 1 % Is the node in the air?
                % Set adjacent potentials to be values of phi at adjacent 
                % nodes.
                adjacent_potentials(1) = phi(i-1,j,k);
                adjacent_potentials(2) = phi(i+1,j,k);
                adjacent_potentials(3) = phi(i,j-1,k);
                adjacent_potentials(4) = phi(i,j+1,k);
                adjacent_potentials(5) = phi(i,j,k-1);
                adjacent_potentials(6) = phi(i,j,k+1);
                % Now replace the adjacent potentials in cases where it is 
                % 1) in a wall, and 
                % 2) the virtual potential at that point was not defined
                % with the bulk of the phi values, and must be one of the
                % corner "exceptions".
                if room_config(i-1,j,k) == 0 && phi(i-1,j,k) == 0 % node in -x direction is a wall node
                    % and has zero potential (skipped and stored in phi_corner)
                    adjacent_potentials(1) = phi_corner(i,j,k,1);
                end
                if room_config(i+1,j,k) == 0 && phi(i+1,j,k) == 0 % node in +x direction is a wall node
                    adjacent_potentials(2) = phi_corner(i,j,k,2);
                end
                if room_config(i,j-1,k) == 0 && phi(i,j-1,k) == 0 % node in -y direction is a wall node
                    adjacent_potentials(3) = phi_corner(i,j,k,3);
                end
                if room_config(i,j+1,k) == 0 && phi(i,j+1,k) == 0 % node in +y direction is a wall node
                    adjacent_potentials(4) = phi_corner(i,j,k,4);
                end
                if room_config(i,j,k-1) == 0 && phi(i,j,k-1) == 0 % node below is a wall node
                    adjacent_potentials(5) = phi_corner(i,j,k,5);
                end
                if room_config(i,j,k+1) == 0 && phi(i,j,k+1) == 0 % node above is a wall node
                    adjacent_potentials(6) = phi_corner(i,j,k,6);
                end
                for p = 1:6
                    if partition_config(i,j,k,p)
                        adjacent_potentials(p) = phi_corner(i,j,k,p);
                    end
                end
                
                % The flow velocities are the difference in potential 
                % between the current node and its neighbors.
                flows(i,j,k,:) = -adjacent_potentials + phi(i,j,k);
            end
        end
    end
end
% Smaller resolutions bring potentials closer, increasing the gradient.
% Correct for this:
flows = flows/resolution;
end