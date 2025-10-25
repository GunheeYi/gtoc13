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

plot_system();
