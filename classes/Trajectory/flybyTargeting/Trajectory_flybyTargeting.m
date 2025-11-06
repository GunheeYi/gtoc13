function trajectory = Trajectory_flybyTargeting(trajectory, target, dt_min, dt_max, use_sail)
    arguments
        trajectory Trajectory;
        target CelestialBody;
        dt_min {mustBeNonnegative};
        dt_max {mustBeNonnegative};
        % min/maximum time after flyby to rendezvous with target [s]
        % set to 0 for no limit (hard lmit: 0 ~ (t_max - t_flyby - 1))
        use_sail logical = true;
    end

    global t_max AU tol_r; %#ok<GVMIS>

    t_flyby = trajectory.arc_last.t_end;

    dt_min = max(dt_min, 1);
    if dt_max == 0
        dt_max = Inf;
    end
    dt_max = min(dt_max, t_max - t_flyby - 1);

    [flybyArc, conicArc] = Trajectory_flybyTargeting_ga(trajectory, target, dt_min, dt_max); % by Jaewoo
    % [flybyArc, conicArc] = Trajectory_flybyTargeting_lambert(trajectory, target, dt_min, dt_max); % by Jinsung
    fprintf('flybyTargeting(%s) produced dr_res = %.0fkm (%.2fAU) without sail.\n', ...
        target.name, conicArc.dr_res, conicArc.dr_res / AU);
    if conicArc.dr_res < tol_r
        trajectory = trajectory.addArc(flybyArc);
        trajectory = trajectory.addArc(conicArc);
        return;
    end

    if ~use_sail
        % uncomment below to visualize the solution before solar sail optimization
        trajectory_ = trajectory.addArc(flybyArc);
        trajectory_ = trajectory_.addArc(conicArc);
        trajectory_.draw();
        trajectory_.draw_interactive();
        error('flybyTargeting(%s) did not converge. Try setting use_sail = true.', target.name);
    end

    propagatedArc = Trajectory_flybyTargeting_withSails(conicArc);
    fprintf('flybyTargeting(%s) produced dr_res = %.0fkm (%.2fAU) with sail.\n', ...
        target.name, propagatedArc.dr_res, propagatedArc.dr_res / AU);
    if propagatedArc.dr_res > tol_r
        error('flybyTargeting(%s) did not converge even when using solar sail.', target.name);
    end

    trajectory = trajectory.addArc(flybyArc);
    trajectory = trajectory.addArc(propagatedArc);
end
