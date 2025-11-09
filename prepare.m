%% setup
close all; clear; clc;
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

global ...
    AU ...
    day_in_secs year_in_secs ...
    vulcan yavin eden hoth yandi beyonce bespin jotunn wakonyingo rogue1 planetX ...
    ;%#ok<GVMIS,NUSED>
