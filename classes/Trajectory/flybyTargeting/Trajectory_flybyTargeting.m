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

    global t_max tol_r; %#ok<GVMIS>

    t_flyby = trajectory.arc_last.t_end;

    dt_min = max(dt_min, 1);
    if dt_max == 0
        dt_max = Inf;
    end
    dt_max = min(dt_max, t_max - t_flyby - 1);

    % [flybyArc, conicArc] = Trajectory_flybyTargeting_ga(trajectory, target, dt_min, dt_max); % by Jaewoo
    [flybyArc, conicArc] = Trajectory_flybyTargeting_lambert(trajectory, target, dt_min, dt_max); % by Jinsung
    fprintf('flybyTargeting() produced dr_res = %.6f km without sail.\n', conicArc.dr_res);
    if conicArc.dr_res < tol_r
        trajectory = trajectory.addArc(flybyArc);
        trajectory = trajectory.addArc(conicArc);
        return;
    end

    if ~use_sail
        error('flybyTargeting did not converge. Try setting use_sail = true.');
    end

    % uncomment below to visualize the solution before solar sail optimization
    % trajectory_ = trajectory.addArc(flybyArc);
    % trajectory_ = trajectory_.addArc(conicArc);
    % trajectory_.draw();
    % input('Press Enter to continue with solar sail optimization...');

    propagatedArc = Trajectory_flybyTargeting_sailing(conicArc);
    fprintf('flybyTargeting() produced dr_res = %.6f km with sail.\n', propagatedArc.dr_res);
    if propagatedArc.dr_res > tol_r
        error('flybyTargeting did not converge even when using solar sail.');
    end

    trajectory = trajectory.addArc(flybyArc);
    trajectory = trajectory.addArc(propagatedArc);
end
