%% setup
close all; clear; clc;
format longg;
% format compact

addpath(genpath('basics'));
addpath(genpath('dynamics'));
addpath(genpath('classes'));
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
trajectory = trajectory.flybyTargeting(rogue1, 100*year_in_secs);
trajectory = trajectory.flybyTargeting(wakonyingo, 0);
trajectory = trajectory.flybyTargeting(beyonce, 0);
trajectory = trajectory.flybyTargeting(bespin, 0);
trajectory = trajectory.flybyTargeting(beyonce, 0);
trajectory = trajectory.flybyTargeting(hoth, 0);
trajectory = trajectory.flybyTargeting(beyonce, 0);
trajectory = trajectory.flybyTargeting(hoth, 0);
trajectory = trajectory.flybyTargeting(beyonce, 0);
% trajectory = trajectory.flybyTargeting(jotunn, 0);
% trajectory = trajectory.flybyTargeting(yandi, 0);
trajectory = trajectory.flybyTargeting(hoth, 0);
trajectory = trajectory.flybyTargeting(eden, 0);
trajectory = trajectory.flybyTargeting(yavin, 0);
trajectory = trajectory.flybyTargeting(vulcan, 0);



%% plot results
trajectory.draw(10000);

%% save solution

trajectory.exportAsSolution('planetx-vulcan-bespin-beyonce.txt');
