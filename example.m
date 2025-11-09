clear;
prepare();

%% design trajectory

% First create a default `Trajectory` class instance.
% This does not contain any arcs yet.
trajectory = Trajectory();

% Add the first arc (`conicArc`) 
% that departs at time `t_start` with velocity `vx_start`.
% Here we set the destination to be PlanetX.
% Works with any `CelestialObject` class instances.
t_start = 0;
vx_start = 6;
trajectory = trajectory.startByTargeting(planetX, t_start, vx_start);

% Then perform a flyby around PlanetX to eventually reach Rogue1,
% with a time of flight between 1 day and 100 years, without using sails.
trajectory = trajectory.flybyTargeting(rogue1, 1*day_in_secs, 100*year_in_secs, false);

% You can also perform flybys without time of flight constraints,
% by setting either `dt_min` or `dt_max` to zero.
% Hard constraints (zero time of flight ~ until 200yrs) are still being applied.
trajectory = trajectory.flybyTargeting(wakonyingo, 0, 0, false);

% If you wish to use solar sails,
trajectory = trajectory.flybyTargeting(wakonyingo, 0, 0, true);

% In case when reaching the target is not possible (failed to converge),
% an error will be raised.
% Handle these conditions using `try-catch` blocks as needed.

% Proceed to perform flybys around Hoth and Bespin as well.
trajectory = trajectory.flybyTargeting(hoth, 0, 0, false);
trajectory = trajectory.flybyTargeting(bespin, 0, 0, false);

% *Flybys along massless bodies are still under development.

% Save and load the trajectory anytime.
% Without any filename argument, it uses the default path.
trajectory.save("my_trajectory.mat");
trajectory = trajectory.load("my_trajectory.mat");

%% plot results
% Draw the trajectory. 
trajectory.draw();

% Draw an interactive figure of the trajectory (by Mercury).
% The argument specifies the time step in seconds. 10 days by default.
trajectory.draw_interactive(10 * day_in_secs);

%% export as solution

% Export the trajectory as a solution text file.
trajectory.exportAsSolution('trajectory.txt');
