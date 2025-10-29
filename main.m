%% setup
close all; clear; clc;
format longg;
% format compact

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
    vulcan yavin eden hoth yandi beyonce bespin jotunn wakonyingo rogue1 planetX ...
    ;%#ok<GVMIS,NUSED>

%% design trajectory

trajectory = Trajectory();
t_start = 0;
vx_start = 6;
trajectory = trajectory.startByTargeting(planetX, t_start, vx_start);
trajectory = trajectory.flybyTargeting(rogue1, 0, 100*year_in_secs);
trajectory = trajectory.flybyTargeting(wakonyingo, 0, 0);
trajectory = trajectory.flybyTargeting(bespin, 0, 0);
trajectory = trajectory.flybyTargeting(wakonyingo, 0, 0);
trajectory = trajectory.flybyTargeting(rogue1, 0, 0);

%% plot results
trajectory.draw(10000);

%% save solution

trajectory.exportAsSolution('trajectory.txt');
