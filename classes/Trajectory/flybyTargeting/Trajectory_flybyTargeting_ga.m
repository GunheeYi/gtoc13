% Method using `ga` and `lsqnonlin` without sailing, by Jaewoo.
% Refactored into the framework by Gunhee.
function [flybyArc, conicArc] = Trajectory_flybyTargeting_ga(trajectory, target, dt_min, dt_max)
    arguments
        trajectory Trajectory;
        target CelestialBody;
        dt_min {mustBeNonnegative};
        dt_max {mustBeNonnegative};
        % min/maximum time after flyby to rendezvous with target [s]
        % set to 0 for no limit (hard lmit: 0 ~ (t_max - t_flyby - 1))
    end

    global AU TU year_in_secs t_max; %#ok<GVMIS,NUSED>

    arc_last = trajectory.arc_last;
    t_flyby = arc_last.t_end;
    body_flyby = arc_last.target;
    V_sc_flyby_in = arc_last.V_end;

    dt_in_TU_lb = max(dt_min, 1) / TU;
    if dt_max == 0
        dt_in_TU_ub = (t_max - t_flyby - 1) / TU;
    else
        if t_flyby + dt_max >= t_max
            warning('dt_max is too large and will be adjusted to fit within t_max.');
            dt_max = t_max - t_flyby - 1;
        end
        dt_in_TU_ub = dt_max / TU;
    end
    lb = [1.1, -pi, dt_in_TU_lb];
    ub = [101,  pi, dt_in_TU_ub];

    function dR_res = calc_dR_res(x) % position residual
        conicArc = produceNextConicArcFromFlybyGeometry_usingX(arc_last, x, target);
        dR_res = conicArc.dR_res;
    end

    function J = calc_weighted_sum_of_dr_and_dt(x)
        dR = calc_dR_res(x);
        dr_in_AU = norm(dR) / AU;
        dt_in_TU = x(3);

        weight_r = 1;
        weight_t = 1e-3;

        J = (weight_r * dr_in_AU)^2 + (weight_t * dt_in_TU)^2;
        if ~isfinite(J)
            J = 1e30; 
        end
    end

    ga_opts = optimoptions('ga', ...
        'Display','iter', ...
        'UseParallel', false, ...      % 병렬 가능하면 true
        'MaxGenerations', 400, ...
        'PopulationSize', 400, ...
        'FunctionTolerance', 1e-4);

    opts_lsq = optimoptions('lsqnonlin', ...
        'Display','iter-detailed', ...
        'Algorithm','levenberg-marquardt', ...
        'FunctionTolerance',1e-12, ...
        'StepTolerance',1e-12, ...
        'MaxFunctionEvaluations',1e10, ...
        'ScaleProblem','jacobian');
    
    % uncomment below for reproducibility of GA
    % rng(1); 
    x0 = ga(@calc_weighted_sum_of_dr_and_dt, 3, [],[],[],[], lb, ub, [], ga_opts);
    [x, ~, ~, exitflag, ~] = lsqnonlin(@calc_dR_res, x0, lb, ub, opts_lsq);
    if exitflag <= 0
        % uncomment below to visualize last valid trajectory
        % trajectory.draw(10000);
        error('flybyTargeting_ga failed to converge.');
    end

    conicArc = produceNextConicArcFromFlybyGeometry_usingX(arc_last, x, target);
    V_sc_flyby_out = conicArc.V_start;
    flybyArc = FlybyArc(t_flyby, body_flyby, V_sc_flyby_in, V_sc_flyby_out);
end

function conicArc = produceNextConicArcFromFlybyGeometry_usingX(arc_last, x, target)
    global TU; %#ok<GVMIS>

    r_multiple_p_flyby = x(1);
    angle_flyby = x(2);
    dt = x(3) * TU;

    conicArc = produceNextConicArcFromFlybyGeometry(arc_last, r_multiple_p_flyby, angle_flyby, dt, target);
end
