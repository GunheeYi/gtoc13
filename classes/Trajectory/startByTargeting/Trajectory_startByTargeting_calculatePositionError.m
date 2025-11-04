% Helper function for method `Trajectory.startByTargeting()`. Do not call directly.
function R_err = Trajectory_startByTargeting_calculatePositionError(target, t_start, vx_start, x)
    global AU; %#ok<GVMIS>

    t_end = x(1);
    ry_start = x(2);
    rz_start = x(3);

    R_sc_start = [ -200*AU; ry_start; rz_start ];
    V_sc_start = [ vx_start; 0; 0 ];
    conicArc = ConicArc(t_start, R_sc_start, V_sc_start, t_end, target);

    R_sc = conicArc.R_end;
    R_target = target.R_at(t_end);

    R_err = R_sc - R_target;
end
