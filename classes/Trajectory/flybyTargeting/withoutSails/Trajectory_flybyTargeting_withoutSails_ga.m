% Method using `ga` and `lsqnonlin` without sailing, by Jaewoo.
% Refactored into the framework by Gunhee.
function [flybyArc, conicArc] = Trajectory_flybyTargeting_withoutSails_ga(trajectory, target, dt_min, dt_max)
    arguments
        trajectory Trajectory;
        target CelestialBody;
        dt_min {mustBeNonnegative};
        dt_max {mustBeNonnegative};
        % min/maximum time after flyby to rendezvous with target [s]
        % set to 0 for no limit (hard lmit: 0 ~ (t_max - t_flyby - 1))
    end

    global AU TU year_in_secs t_max; %#ok<GVMIS,NUSED>

    lb = [1.1, -pi, dt_min / TU];
    ub = [101,  pi, dt_max / TU];

    function dR_res = calc_dR_res(x) % position residual
        [~, conicArc] = produceNextArcsFromFlybyGeometry_usingX(trajectory, x, target);
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
        'MaxGenerations', 100, ...
        'PopulationSize', 1000, ...
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
        % trajectory.draw();
        error('flybyTargeting_ga failed to converge.');
    end

    [flybyArc, conicArc] = produceNextArcsFromFlybyGeometry_usingX(trajectory, x, target);
end

function [flybyArc, conicArc] = produceNextArcsFromFlybyGeometry_usingX(trajectory, x, target)
    global TU; %#ok<GVMIS>

    r_multiple_p_flyby = x(1);
    angle_flyby = x(2);
    dt = x(3) * TU;

    [flybyArc, conicArc] = produceNextArcsFromFlybyGeometry(trajectory, r_multiple_p_flyby, angle_flyby, dt, target);
end
