function [prop,border,borderadd,cornerflag] = BorderChecks(room_config, partition_config,u0,v0,w0)
%BORDERCHECKS Border-checking potential flow initialization function
%   BORDERCHECKS is only used in the initialization of the potential flow 
%   solver. It creates a handful of arrays of similar size to the room 
%   configuration matrix (telling which cells are in the air), which 
%   describe whether their corresponding room cells are on a border, what 
%   amount of flow is going through that border, whether  a virtual node is
%   at a corner and thus needs special treatment since it occupies the same
%   space as another virtual node, etc.

[n m l] = size(room_config);
k_inds = l:-1:1;
j_inds = m:-1:1;
i_inds = n:-1:1;

prop = zeros(size(room_config));
% prop: stores both room configuration and locations/frequency of boundary
% conditions.
% 1 is an air node
% -X is a virtual node at which boundary conditions are applied, X = # of BCs applied there
% 0 is a virtual node which is not subject to BC (i.e. useless)

% 2-D example:
% 1  1  1  1  1  1
% 1  1__1__1__1__1
% 1  1|-2 -1 -1 -1
% 1  1|-1  0  0  0
% 1  1|-1  0  0  0
for k = k_inds
    for j = j_inds
        for i = i_inds
            if room_config(i,j,k)==1
                if room_config(i,j,k+1) == 0
                    prop(i,j,k+1) = prop(i,j,k+1) + 1;
                end
                if room_config(i,j,k-1) == 0
                    prop(i,j,k-1) = prop(i,j,k-1) + 1;
                end
                if room_config(i+1,j,k) == 0
                    prop(i+1,j,k) = prop(i+1,j,k) + 1;
                end
                if room_config(i-1,j,k) == 0
                    prop(i-1,j,k) = prop(i-1,j,k) + 1;
                end
                if room_config(i,j+1,k) == 0
                    prop(i,j+1,k) = prop(i,j+1,k) + 1;
                end
                if room_config(i,j-1,k) == 0
                    prop(i,j-1,k) = prop(i,j-1,k) + 1;
                end
            end
        end
    end
end
prop = room_config - prop;

% 'border' determines whether a border is present from a certain node
% pointing in a certain direction.
% 'borderadd' is the difference between the cell and that neighboring cell
% 'cornerflag' notes if the virtual node in question is in a corner or
% partition (no unique physical location in 3-D space, stored elsewhere)

border = zeros([size(room_config) 6]);
borderadd = zeros([size(room_config) 6]);
cornerflag = zeros([size(room_config) 6]);
diradd = [-1 0 0;1 0 0;0 -1 0;0 1 0;0 0 -1;0 0 1];
for k = k_inds
    for j = j_inds
        for i = i_inds
            for q = 1:6
                if prop(i,j,k)==1 % node is in the air
                    ia = i + diradd(q,1);
                    ja = j + diradd(q,2);
                    ka = k + diradd(q,3);
                    if partition_config(i,j,k,q)
                        border(i,j,k,q) = 1;
                        borderadd(i,j,k,q) = 0;
                        cornerflag(i,j,k,q) = 1;
                    elseif prop(ia,ja,ka) < 0
                        border(i,j,k,q) = 1;
                        switch q
                            case 1
                                borderadd(i,j,k,q) = u0(i,j,k);
                            case 2
                                borderadd(i,j,k,q) = -u0(i,j,k);
                            case 3
                                borderadd(i,j,k,q) = v0(i,j,k);
                            case 4
                                borderadd(i,j,k,q) = -v0(i,j,k);
                            case 5
                                borderadd(i,j,k,q) = w0(i,j,k);
                            case 6
                                borderadd(i,j,k,q) = -w0(i,j,k);
                        end
                        if prop(ia,ja,ka) <= -2
                            cornerflag(i,j,k,q) = 1;
                        end
                    end
                end
            end
        end
    end
end