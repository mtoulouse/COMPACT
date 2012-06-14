classdef Air 
    % AIR Class containing air properties
    %   Air contains the basic properties/units of air. Anywhere in the 
    %   code, you can ask for “Air.cp” or “Air.units” and it’ll give you the 
    %   values. Just comment in/out the blocks of code to switch from feet
    %   to meters. Note that this hasn’t been tested in-depth, so although
    %   there isn’t a fundamental inability coded in, you may need to debug
    %   the added functions.

    properties (Constant = true)
%         cp = 1003; %J/kg-K
%         g = 9.80665; %m/s^2
%         rho = 1.2; %kg/m^3
%         k = 0.02587; % W/m-K
%         abbr = 'm';
%         unit = 'meter';
%         units = 'meters';
%         SI_length = 1; % number of units per meter (used for some energy calculations)

        cp = 1003; %J/kg-K
        g = 32.1740; %ft/s^2
        rho = 0.0339802159; %kg/ft^3
        k = 0.0079; % W/ft-K
        abbr = 'ft';
        unit = 'foot';
        units = 'feet';
        SI_length = 3.281; % number of units per meter (used for some energy calculations)
    end
end