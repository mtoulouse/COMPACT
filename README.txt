Welcome to COMPACT, or the Compact Model of Potential Flow and Convective Transport.  

This is a MATLAB tool, model + GUI, intended to expeditiously model the air temperature in a data center room. It's not intended as a replacement of conventional CFD by any stretch, but more as an initial design tool to quickly narrow down the parameter space, or as something to make the initial guesses for a CFD run, or maybe one day adapted for real-time controllers, who knows. As the name suggests, it uses potential flow theory and the convective energy transport equation to generate a temperature field. There's an added feature called vortex superposition to account for issues with buoyancy and recirculation, which should improve the temperature accuracy (validation in progress).

1) First thing to do is copy this folder to some place on your computer, obviously.

2) Then add it to your path. Go to File > Set Path > Add with Subfolders, and add the folder to your path.

3) To start the program, go to the command window in MATLAB and enter "Rm = makeroom" without quotation marks. "Rm" can be any variable name, it's just the name for the room object in your workspace.

5) Explore and enjoy! The code should be commented, and I'm working on a user's manual.