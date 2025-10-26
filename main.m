%% setup
close all; clear; clc;
format longg;
% format compact

addpath(genpath('../mercury'));
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
vx_start = 20;
trajectory = trajectory.startByTargeting(planetX, t_start, vx_start);
trajectory = trajectory.flybyTargeting(vulcan);
trajectory = trajectory.flybyTargeting(bespin);
trajectory = trajectory.flybyTargeting(beyonce);
% trajectory = trajectory.flybyTargeting(hoth);
% If hoth is included, position discontinuity error occurs.
% same for yavin, wakonyingo. Why??
% Lack in precision during solving Lambert's problem?

%% plot results

figure();
hold on;

% plot_system(0 * year_in_secs);
plot_system(trajectory.t_end);
trajectory.draw(10000);

axis equal;
grid on;
xlabel('x [AU]');
ylabel('y [AU]');
zlabel('z [AU]');
range_limit = [-10 10]; % in AUs
xlim(range_limit);
ylim(range_limit);
zlim(range_limit);
legend();
