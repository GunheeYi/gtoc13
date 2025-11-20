clear;
prepare(); % clear console & figures, set up paths & constants

global planetX rogue1 vulcan asteroids comets day_in_secs year_in_secs; %#ok<GVMIS>

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
% while heading inwards to the Sun (rdvDirection = -1),
% with a time of flight between 1 day (dt_min = 1*day_in_secs)
% and 100 years (dt_max = 100*year_in_secs),
% without using solar sails (use_sails = false),
% allowing only prograde trajectories (allow_retrograde = false),
% and not allowing low pass trajectories (allow_low_pass = false).
% Refer to the definition of `Trajectory:flybyTargeting` for more details.
trajectory = trajectory.flybyTargeting(rogue1, -1, 1*day_in_secs, 100*year_in_secs, false, false, false);

% In case when reaching the target is not possible (failed to converge),
% an error will be raised.
% Handle these conditions using `try-catch` blocks as needed.

% Proceed to perform flybys around other bodies as well, consecutively.
trajectory = trajectory.flybyTargeting(vulcan, 0, 0, false);

% *Attempting flybys around massless bodies without solar sails will raise errors.

% Save and load the trajectory anytime, to/from the `trajectories/` folder.
% Without any filename argument, it uses the default path.
trajectory.save("my_trajectory.mat");
trajectory = trajectory.load("my_trajectory.mat");

%% examine close apporaches to celestial bodies

% I have implemented methods to find close approaches
% to certain celestial bodies defined as a `pool`, during a conic arc.
% Even though they were not actively used as we lacked in time during the competition. T.T

pool = [num2cell(asteroids); num2cell(comets)];

closeApproaches = [];

for i_conicArc = 1:numel(trajectory.conicArcs)
    conicArc = trajectory.conicArcs(i_conicArc);
    closeApproaches_current = conicArc.getCloseApproaches(pool);
    closeApproaches = [closeApproaches; closeApproaches_current]; %#ok<AGROW>
end

%% plot results
% Draw the trajectory. 
trajectory.draw(true); % true: draw projected arc after last defined arc

% Draw an interactive figure of the trajectory (written by Mercury).
% The argument specifies the time step in seconds, which is set to 10 days by default.
trajectory.draw_interactive(10 * day_in_secs);

%% export as solution

% Export the trajectory as a solution text file, or load from it.
trajectory.exportAsSolution('trajectory.txt');
trajectory = trajectory.importSolution('trajectory.txt');
