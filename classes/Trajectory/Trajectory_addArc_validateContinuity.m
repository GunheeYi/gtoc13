% Helper function for method `Trajectory.addArc()`. Do not call directly.
function Trajectory_addArc_validateContinuity(arc1, arc2)
    % TODO: replace to comparison by reporting digits 
    % instead of absolute tolerances?

    global tol_t tol_r tol_v; %#ok<GVMIS>

    if abs(arc1.t_end - arc2.t_start) > tol_t
        error('Time discontinuity between arcs.');
    end

    if norm(arc1.R_end - arc2.R_start) > tol_r
        error('Position discontinuity between arcs.');
    end

    if norm(arc1.V_end - arc2.V_start) > tol_v
        error('Velocity discontinuity between arcs.');
    end
end
