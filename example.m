%% setup
close all; clear; clc;
format longg;
% format compact

addpath(genpath('mercury'));
addpath(genpath('basics'));
addpath(genpath('dynamics'));
addpath(genpath('classes'));
addpath(genpath('search'));
addpath(genpath('plots'));
addpath(genpath('main-blocks'));

set_constants();
load_celestial_bodies();

global ...
    AU ...
    day_in_secs year_in_secs ...
    planets asteroids comets ...
    vulcan yavin eden hoth yandi beyonce bespin jotunn wakonyingo rogue1 planetX ...
    ;%#ok<GVMIS,NUSED>

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
% with a time of flight between 1 day and 100 years.
trajectory = trajectory.flybyTargeting(rogue1, 1*day_in_secs, 100*year_in_secs);

% You can also perform flybys without time of flight constraints,
% by setting either `dt_min` or `dt_max` to zero.
% Hard constraints (zero time of flight ~ until 200yrs) are still being applied.
trajectory = trajectory.flybyTargeting(wakonyingo, 0, 0);

% Proceed to perform flybys around Hoth and Bespin as well.
% In case when reaching the target is not possible,
% an error will be raised.
% Handle these conditions using `try-catch` blocks as needed.
trajectory = trajectory.flybyTargeting(hoth, 0, 0);
trajectory = trajectory.flybyTargeting(bespin, 0, 0);

% *Flybys along massless bodies are still under development.

% Save and load the trajectory anytime.
% Without any filename argument, it uses the default path.
trajectory.save("my_trajectory.mat");
trajectory = trajectory.load("my_trajectory.mat");

%% plot results
% Draw the trajectory. 
% The argument specifies the number of points per arc. 100 by default.
trajectory.draw(10000);

% Draw an interactive figure of the trajectory (by Mercury).
% The argument specifies the time step in seconds. 10 days by default.
trajectory.draw_interactive(10 * day_in_secs);

%% export as solution

% Export the trajectory as a solution text file.
trajectory.exportAsSolution('trajectory.txt');
