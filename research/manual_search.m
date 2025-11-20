clear;
prepare;

global ...
    AU ...
    day_in_secs year_in_secs ...
    vulcan yavin eden hoth yandi beyonce bespin jotunn wakonyingo rogue1 planetX ...
    ;%#ok<GVMIS,NUSED>

t_max_for_search = 200 * year_in_secs;

%%

trajectory = Trajectory();
% trajectory = trajectory.load("trajectory.mat");
trajectory = trajectory.load("2-outward/vulcan/eden/vulcan/beyonce/vulcan/bespin/vulcan/vulcan/trajectory.mat");

%%

trajectory.draw(false);
trajectory.draw_interactive();

%%

clc;

target = rogue1;

T_sc = trajectory.arc_last.T_end;
dt_max_for_search = t_max_for_search - trajectory.t_end;
dt_max = min(max(T_sc, target.T), dt_max_for_search);

trajectory_new = trajectory.flybyTargeting(target, 1, 10*year_in_secs, dt_max, true, true);

arc_last = trajectory_new.arc_last;
T_sc = arc_last.T_end;
fprintf('%.2frev\n', (arc_last.t_end - arc_last.t_start) / T_sc);

trajectory_new.brief();
trajectory_new.draw(false);
trajectory_new.draw_interactive();

%%

trajectory_new.save("trajectory.mat");

%%

trajectory = trajectory_new;