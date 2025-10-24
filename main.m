%% setup
close all; clear; clc;
format longg;
% format compact

addpath(genpath('../mercury'));
addpath(genpath('classes'));
addpath(genpath('main-blocks'));

set_constants();
load_celestial_bodies();
