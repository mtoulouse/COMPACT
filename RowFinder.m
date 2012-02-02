function CL = RowFinder(Rm)
%ROWFINDER Server rack row and cluster sorter
%   ROWFINDER takes a room and sorts the server racks and obstacles into
%   clusters of adjacent objects, which it approximates as rows. It passes
%   the indices of these racks in separate cells back out to
%   AutomatedVortexPlacement, which uses it to generate vortex and aisle
%   placement.
%% First, link server racks to each other

[AllObj,AO_ind,AO_type] = NumListObjs(Rm);
SROb = (AO_type == 1 | AO_type == 5); % rack or obstacle?

linked_box = cell(size(AllObj));
for i = 1:length(AllObj)
    if SROb(i) % rack or obstacle?
        for j = 1:length(AllObj)
            if i~=j && SROb(j) % rack or obstacle?
                V1 = AllObj{i}.Vertices;
                V2 = AllObj{j}.Vertices;
                [VO, FO, EO] = FlowObject.BoxOverlap(V1,V2);
                if FO > 0 %they are connected
                    linked_box{i} = [linked_box{i} j];
                end
            end
        end
    end
end
% This only works for groups of 2 or more. Search the existing lists,
% assume any racks not covered are their own racks

rax_inds = find(AO_type == 1);
for k = 1:length(linked_box)
    rax_inds = setdiff(rax_inds, linked_box{k});
end
% disp(rax_inds)
% disp(linked_box)
% disp(linked_box)
%% Now, group them into individual clusters
cluster_list = [];
for i = 1:length(linked_box)
    if~isempty(linked_box{i})
        F = any(cluster_list == i); % current obj already in a cluster?
        if ~any(F) % not in the list
            conn_inds = connected_inds(linked_box,i);
            addflag = 1;
            % check connections to objs in list
            for j = 1:length(conn_inds)
                G = any(cluster_list == conn_inds(j));
                if any(G) % is the # connected to current obj already in a cluster?
                    col = find(G);
                    k = nnz(cluster_list(:,col));
                    cluster_list(k+1,col) = i;
                    addflag = 0;
                end
            end
            if addflag
                cluster_list(1,end+1) = i;
            end
        end
    end
end
%% Combine any common clusters
% disp(cluster_list)
for i = 1:size(cluster_list,2)
    CLi = nonzeros(cluster_list(:,i));
    for j = 1:size(cluster_list,2)
        CLj = nonzeros(cluster_list(:,j));
        if i ~= j
            c = intersect(CLi,CLj);
            if ~isempty(c)
                new_clus = setxor(CLi,CLj);
                cluster_list(1:length(new_clus),i) = new_clus;
                cluster_list(:,j) = 0;
            end
        end
    end
end
CL = [];
for i = 1:size(cluster_list,2)
    if any(cluster_list(:,i))
        CL = [CL {nonzeros(cluster_list(:,i))}];
    end
end

%% Add on any single racks left over
if ~isempty(rax_inds)
    CL = [CL num2cell(rax_inds)];
end

end
%% find mentions of the number in the linked_box group
function conn_inds = connected_inds(linked_box,ind)
conn_inds = [];
for j = 1:length(linked_box)
    if any(linked_box{j} == ind)
        conn_inds = [conn_inds j];
    end
end
end