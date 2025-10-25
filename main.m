%% setup
close all; clear; clc;
format longg;
% format compact

addpath(genpath('../mercury'));
addpath(genpath('classes'));
addpath(genpath('dynamics'));
addpath(genpath('plots'));
addpath(genpath('main-blocks'));

set_constants();
load_celestial_bodies();

%% design trajectory

global planets; %#ok<GVMIS>

trajectory = Trajectory();
planetX = planets(11);
t_start = 0;
vx_start = 50;
trajectory = trajectory.startByTargeting(planetX, t_start, vx_start);

%% plot results

figure();
hold on;

plot_system(trajectory.t_end);
trajectory.draw();

axis equal;
grid on;
xlabel('x [AU]');
ylabel('y [AU]');
zlabel('z [AU]');
legend();
