function trajectory = Trajectory_flybyTargeting(trajectory, target, dt_min, dt_max, use_sails, allow_low_pass)
    global t_max AU; %#ok<GVMIS>

    arc_last = trajectory.arc_last;

    if ~arc_last.target.flybyable && ~use_sails
        error('Current body (%s) is not flybyable but using sails is disabled.', target.name);
    end

    t_flyby = arc_last.t_end;

    dt_min = max(dt_min, 1);
    if dt_max == 0
        dt_max = Inf;
    end
    dt_max = min(dt_max, t_max - t_flyby - 1);

    [flybyArc, conicArc] = Trajectory_flybyTargeting_withoutSails(trajectory, target, dt_min, dt_max, allow_low_pass);
    fprintf('flybyTargeting(%s) produced dr_res = %.0fkm (%.2fAU) without sail.\n', ...
        target.name, conicArc.dr_res, conicArc.dr_res / AU);
    if conicArc.hitsTarget()
        trajectory = trajectory.addArc(flybyArc);
        trajectory = trajectory.addArc(conicArc);
        return;
    end

    if ~use_sails
        % uncomment below to visualize the solution before solar sail optimization
        % trajectory_ = trajectory.addArc(flybyArc);
        % trajectory_ = trajectory_.addArc(conicArc);
        % trajectory_.draw();
        % trajectory_.draw_interactive();
        error('flybyTargeting(%s) did not converge. Try setting use_sail = true.', target.name);
    end

    fprintf('Trying with sails...\n');
    propagatedArc = Trajectory_flybyTargeting_withSails(conicArc, allow_low_pass);
    fprintf('flybyTargeting(%s) produced dr_res = %.0fkm (%.2fAU) with sail.\n', ...
        target.name, propagatedArc.dr_res, propagatedArc.dr_res / AU);
    if propagatedArc.hitsTarget()
        trajectory = trajectory.addArc(flybyArc);
        trajectory = trajectory.addArc(propagatedArc);
        return;
    end

    error('flybyTargeting(%s) did not converge even when using solar sail.', target.name);
end
