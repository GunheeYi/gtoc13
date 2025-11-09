%% setup
close all; clc;
format longg;
% format compact

addpath(genpath('mercury'));
addpath(genpath('basics'));
addpath(genpath('dynamics'));
addpath(genpath('classes'));
addpath(genpath('score'));
addpath(genpath('search'));
addpath(genpath('plots'));
addpath(genpath('main-blocks'));

set_constants();
load_celestial_bodies();
