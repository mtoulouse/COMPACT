classdef Profile < handle
%PROFILE Class representing "profiles" of quantities present on object surfaces.
    % PROFILE is the class of objects used to define varying heat, air or
    % temperature quantities present on the faces of the server racks, and 
    % are stored within the server rack objects. In addition to an array of
    % values (which should be the same size as the  number of nodes on the 
    % out-flowing face of the server rack), also stored are the type of 
    % quantity stored (heat generation, flow rate, termperature rise) and
    % any unique qualities of the profile distribution.
    
    properties
        Type % 'HG' or 'TR' or 'FR'
        Value % Array of values
        DistributionType % 'uniform' or 'centered' or 'custom'
        DistributionSubtype % extra info, like custom distribution
        % or centering type (1/r, 1/r^2)
    end

    methods
        function PR = Profile(type)
            % Constructor for this object.
            PR.Type = type;
            PR.Value = [];
            PR.DistributionType = 'custom';
            PR.DistributionSubtype = [];
        end

        function YN = IsProfileEmpty(PR)
            % Checks if the profile's value property is empty.
            if isempty(PR.Value)
                YN = 1;
            else
                YN = 0;
            end
        end
        
        function YN = IsProfileValid(PR)
            % Checks if the profile's value property is valid, by checking
            % if it is empty and checking for any non-finite elements of
            % the value array.
            if ~IsProfileEmpty(PR) && all(all(isfinite(PR.Value)))
                YN = 1;
            else
                YN = 0;
            end
        end
        
        function PR = Redist(PR,r_mult)
            % Used to change the value array when the mesh is refined.
            newprval=[];
            if r_mult > 1 % expanding matrix
                for i = 1:size(PR.Value,1)
                    for j = 1:size(PR.Value,2)
                        xmat1 = (i-1)*r_mult+1;
                        xmat2 = i*r_mult;
                        ymat1 = (j-1)*r_mult+1;
                        ymat2 = j*r_mult;
                        oldmat = PR.Value(i,j);
                        switch PR.Type
                            case 'HG' % "spread" the heat around the new nodes
                                newmat = oldmat/r_mult^2*ones(r_mult);
                            case {'TR','FR'} % set the new nodes to the same value as the old
                                newmat = oldmat*ones(r_mult);
                        end
                        newprval(xmat1:xmat2,ymat1:ymat2) = newmat;
                    end
                end
            elseif r_mult < 1 % contracting matrix
                for i = 1:size(PR.Value,1)*r_mult
                    for j = 1:size(PR.Value,2)*r_mult
                        xmat1 = (i-1)/r_mult+1;
                        xmat2 = i/r_mult;
                        ymat1 = (j-1)/r_mult+1;
                        ymat2 = j/r_mult;
                        oldmat = PR.Value(xmat1:xmat2,ymat1:ymat2);
                        switch PR.Type
                            case 'HG' % sum the old nodes into the new one
                                newmat = sum(sum(oldmat));
                            case {'TR','FR'} % average the old nodes to define the new one
                                newmat = mean(mean(oldmat));
                        end
                        newprval(i,j) = newmat;
                    end
                end
            end
            if ~isempty(newprval)
                PR.Value = newprval;
            end
        end

        function ClearProfile(PR)
            % Clears the data from a profile object, but keeps the type and
            % resets
            PR.Value = [];
            PR.DistributionType = 'custom';
            PR.DistributionSubtype = [];
        end

        function str = Infostring(PR)
            % generates the information string that shows the profile
            % details in the property definition GUI
            if ~IsProfileEmpty(PR)
                DT = PR.DistributionType;
                DST = PR.DistributionSubtype;
                str = cellstr([DT ' distribution']);
                switch DT
                    case 'centered'
                        str = [str; ['varies with ' DST]];
                    case {'horiz. custom','vert. custom'}
                        if ~isempty(DST)
                            str = [str
                                'Coordinates:'
                                num2str(DST{1},'%-5g')
                                'Values:'
                                num2str(DST{2},'%-5g')];
                        end
                end
                switch PR.Type
                    case 'HG'
                        V = num2str(sum(sum(PR.Value)));
                        str = ['Heat Generation'; str
                            ['Total Heat: ' V  ' Watts']];
                    case 'TR'
                        V = num2str(mean(mean(PR.Value)));
                        str = ['Temperature Rise'; str
                            ['Avg. Rise:' V ' C']];
                    case 'FR'
                        V = num2str(mean(mean(PR.Value)));
                        str = ['Flow Rate'; str
                            ['Avg. Flow:' V ' ' Air.abbr '/s']];
                end
            else
                str = 'No info';
            end
        end
        
        function display(PR)
            % Display function, mostly for debugging. Gives the basic
            % information about the profile.
            str = Infostring(PR);
            disp(str);
        end
    end
end