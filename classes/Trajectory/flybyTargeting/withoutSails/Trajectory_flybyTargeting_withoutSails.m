function [flybyArc, conicArc] = Trajectory_flybyTargeting_withoutSails(trajectory, target, dt_min, dt_max)
    body_current = trajectory.arc_last.target;
    if ~body_current.flybyable
        fprintf('Current body (%s) is not flybyable. Making continuing arcs without targeting.\n', body_current.name);
        [flybyArc, conicArc] = makeContinuingArcs(trajectory, target, dt_min, dt_max);
        return;
    end

    [flybyArc, conicArc] = Trajectory_flybyTargeting_withoutSails_ga(trajectory, target, dt_min, dt_max); % by Jaewoo
    % [flybyArc, conicArc] = Trajectory_flybyTargeting_withoutSails_lambert(trajectory, target, dt_min, dt_max); % by Jinsung
end

function [flybyArc, conicArc] = makeContinuingArcs(trajectory, target, dt_min, dt_max)
    % Make continuing arcs that just passes through the last body,
    % without performing any flyby maneuver.
    % `conicArc` is set to minimize residual position error from target at the end.

    global AU TU; %#ok<GVMIS>

    arc_last = trajectory.arc_last;
    body_current = arc_last.target;
    t_start = arc_last.t_end;
    R_start = arc_last.R_end;
    V_start = arc_last.V_end;

    flybyArc = FlybyArc(t_start, body_current, V_start, V_start);

    lb = dt_min / TU;
    ub = dt_max / TU;

    function dr_res = calc_dr_res(dt)
        t_end = t_start + dt;
        conicArc = ConicArc(t_start, R_start, V_start, t_end, target);
        dr_res = conicArc.dr_res;
    end

    function J = calc_weighted_sum_of_dr_and_dt(dt)
        dr = calc_dr_res(dt);
        dr_in_AU = dr / AU;
        dt_in_TU = dt / TU;

        weight_r = 1;
        weight_t = 1e-3;

        J = (weight_r * dr_in_AU)^2 + (weight_t * dt_in_TU)^2;
        if ~isfinite(J)
            J = 1e30; 
        end
    end

    options_ga = optimoptions('ga', ...
        'Display','iter', ...
        'UseParallel', false, ...      % 병렬 가능하면 true
        'MaxGenerations', 400, ...
        'PopulationSize', 400, ...
        'FunctionTolerance', 1e-4);

    options_lsqnonlin = optimoptions('lsqnonlin', ...
        'Display','iter-detailed', ...
        'Algorithm','levenberg-marquardt', ...
        'FunctionTolerance',1e-12, ...
        'StepTolerance',1e-12, ...
        'MaxFunctionEvaluations',1e10, ...
        'ScaleProblem','jacobian');
    
    dt0_in_TU = ga(@(dt_in_TU) calc_weighted_sum_of_dr_and_dt(dt_in_TU * TU), ...
                        1, [],[],[],[], lb, ub, [], options_ga);
    dt_in_TU = lsqnonlin(@(dt_in_TU) calc_dr_res(dt_in_TU * TU), ...
                            dt0_in_TU, lb, ub, options_lsqnonlin);
    t_end = t_start + dt_in_TU * TU;
    conicArc = ConicArc(t_start, R_start, V_start, t_end, target);
end
