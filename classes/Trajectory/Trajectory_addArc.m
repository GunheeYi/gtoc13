function trajectory = Trajectory_addArc(trajectory, arc_new);
    arguments
        trajectory Trajectory;
        arc_new { mustBeA(arc_new, ["TransferArc", "FlybyArc"]) };
    end

    if isempty(trajectory.arcs)
        if ~isa(arc_new, "TransferArc")
            error('The first arc must be a transfer arc.');
        end
    else
        validateContinuity(trajectory.arc_last, arc_new);
    end

    trajectory.arcs{end+1,1} = arc_new;
end

function validateContinuity(arc1, arc2)
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
