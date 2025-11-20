clear;
prepare;

global ...
    AU ...
    day_in_secs year_in_secs ...
    vulcan yavin eden hoth yandi beyonce bespin jotunn wakonyingo rogue1 planetX ...
    ;%#ok<GVMIS,NUSED>

trajectory = Trajectory();
t_start = 0;
vx_start = 14;
trajectory = trajectory.startByTargeting(planetX, t_start, vx_start);
trajectory.draw_interactive();

%%

clc; close all;

target = vulcan;

T_sc = trajectory.arc_last.T_end;
t_max_for_search = 200 * year_in_secs;
dt_max_for_search = t_max_for_search - trajectory.t_end;
dt_max = min(max(T_sc, target.T), dt_max_for_search);

trajectory_new = trajectory.flybyTargeting(target, 0, 0, dt_max, false, false);

arc_last = trajectory_new.arc_last;
T_sc = arc_last.T_end;
fprintf('%.2frev\n', (arc_last.t_end - arc_last.t_start) / T_sc);

trajectory_new_appended = trajectory_new.appendFinalFlybyIfPossible();
trajectory_new_appended.brief();
trajectory_new_appended.draw();
trajectory_new_appended.draw_interactive();
ss = trajectory_new_appended.generateSequenceString();
trajectory_new.save(sprintf("jw-%s.mat", ss));
trajectory = trajectory_new;

