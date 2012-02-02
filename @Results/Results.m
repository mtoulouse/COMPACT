classdef Results
%RESULTS Class for storage of solver results or solver options.
%   RESULTS has properties for every -independent- datum that the solvers 
%   can generate. RESULTS objects serve two purposes:
%
%   1) To store results generated from running a solver. Kept together,
%   this allows solvers to simply output a results object, and data post-
%   processing functions to simply take a results object as an input.
%
%   2)  To store which results should be generated in the first place. In
%   this case, each property only holds a logical value determining whether
%   that specific result should be generated or recorded. This is used as
%   an input to a solver, not an output like #1.

    properties
        % Properties unique to this Result object
        RunDate % Date of solver run
        Room % Stored room configuration from which results were generated
        Type % Type of result object ('Results' or 'Settings')
        
        % Flow results
        Phi % Velocity Potential Field
        PhiResidual % Residual of the potential field
        PhiBCError % Boundary condition errors of the potential field
        FlowTime % Time the flow solver took.
        
        % Temp results
        Temp % Temperature Field
        EnergyResidual % Convective energy residual of flow/temperature field
        TempTime % Time the temperature solver took.
        
        % Vortex Superposition results
        VortexSuper
        VortexTime
        
        % Exergy results
        ExergyDest
        ExergyTime
    end
    
    methods 
        function Resu = Results(type)
            % Constructor function. For settings-type objects, default 
            % values are defined here.
            if strcmp(type,'SettingData')
                %set default choice of data to generate. 1 means the data
                %will be generated, 0 means it won't.
                Resu.Type = 'Settings';
                % Flow results
                Resu.Phi = 1;
                Resu.PhiResidual = 1;
                Resu.PhiBCError = 1;
                Resu.FlowTime = 1;
                % Temp results
                Resu.Temp = 1;
                Resu.EnergyResidual = 1;
                Resu.TempTime = 1;
                % Vortex Superposition results
                Resu.VortexSuper = 1;
                Resu.VortexTime = 1;
                % Exergy results
                Resu.ExergyDest = 1;
                Resu.ExergyTime = 1;
            elseif strcmp(type,'ResultData')
                % in this case, other functions will set all other fields.
                Resu.Type = 'Results';
            end
        end
        function display(Resu)
            % Display function, for debugging or identifying contained data
            % of objects in the workspace. Gives basic information about 
            % the results object.
            if strcmp(Resu.Type,'Settings')
                runstr = [];
                if Resu.Phi
                    runstr = [runstr 'flow'];
                end
                if Resu.Phi && Resu.Temp
                    runstr = [runstr ' and '];
                end
                if Resu.Temp
                    runstr = [runstr 'temperature'];
                end
                if Resu.Temp && Resu.ExergyDest
                    runstr = [runstr ' and '];
                end
                if Resu.ExergyDest
                    runstr = [runstr 'exergy'];
                end
                disp(['Settings-type object, set to run ' runstr ' solver'])
            elseif strcmp(Resu.Type,'Results')
                runstr = [];
                if ~isempty(Resu.Phi)
                    runstr = [runstr 'flow'];
                end
                if ~isempty(Resu.Phi) && ~isempty(Resu.Temp)
                    runstr = [runstr ' and '];
                end
                if ~isempty(Resu.Temp)
                    runstr = [runstr 'temperature'];
                end
                if ~isempty(Resu.Temp) && ~isempty(Resu.ExergyDest)
                    runstr = [runstr ' and '];
                end
                if ~isempty(Resu.ExergyDest)
                    runstr = [runstr 'exergy'];
                end
                if isempty(Resu.Phi) && isempty(Resu.Temp)
                    runstr = 'no';
                end
                disp(['Results-type object, containing ' runstr ' data'])
                disp(['Created ' Resu.RunDate])
            end
        end
    end % methods end
end % classdef end