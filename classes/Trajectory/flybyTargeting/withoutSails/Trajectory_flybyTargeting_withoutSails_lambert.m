% Method using Lambert's problem solver without sailing, by Jinsung.
% Refactored into the framework by Gunhee.

% 진성이형꺼 그대로 옮겼는데도 수렴 안됨,, why????
% 현재 버전은 수렴하고자 좀 수정해본 것

function [flybyArc, conicArc] = Trajectory_flybyTargeting_withoutSails_lambert(trajectory, target, dt_min, dt_max, allow_retrograde, allow_low_pass)
    arguments
        trajectory Trajectory;
        target CelestialBody;
        dt_min {mustBeNonnegative};
        dt_max {mustBeNonnegative};
        % min/maximum time after flyby to rendezvous with target [s]
        % set to 0 for no limit (hard lmit: 0 ~ (t_max - t_flyby - 1))
        allow_retrograde logical = false;
        allow_low_pass logical = false; % under 0.05AU
        % TODO: consume above two arguments
    end

    [r_multiple_p_flyby, angle_flyby, dt] = search_whole_timespan(trajectory, target, dt_min, dt_max);
    [flybyArc, conicArc] = search_around_dt_seed(trajectory, r_multiple_p_flyby, angle_flyby, dt, target);
end

function [r_multiple_p_flyby, angle_flyby, dt] = search_whole_timespan(trajectory, target, dt_min, dt_max)
    global mu_altaira day_in_secs tol_dv; %#ok<GVMIS>

    R_sc = trajectory.R_end;

    function dv_out = fun(x, dt) % ||V_out_flyby - V_out_lambert||
        [flybyArc, ~] = produceNextArcsFromFlybyGeometry(trajectory, x(1), x(2), dt, target);
        V_out_flyby = flybyArc.V_end;
        dV_out = V_out_flyby - V_out_lambert;
        dv_out = norm(dV_out);
    end

    dt = dt_min;
    while dt <= dt_max
        t_end = trajectory.t_end + dt;
        R_target = target.R_at(t_end);
        [V_out_lambert, ~] = solve_lamberts_problem(R_sc, R_target, dt, mu_altaira, 'Prograde');
        if ~isreal(V_out_lambert)
            dt = dt + 1 * day_in_secs;
            continue;
        end

        % z = [r_p/target.r, ang]
        x0 = [ 50,   0];
        lb = [1.1, -pi];
        ub = [101,  pi];

        options = optimoptions('fmincon', ...
            'Algorithm', 'interior-point', ...
            'Display', 'none', ...
            'StepTolerance',1e-12, ...
            'OptimalityTolerance',1e-10, ...
            'ConstraintTolerance',1e-9 ...
        );

        [x, dv_res_out, flag] = fmincon(@(x) fun(x, dt), x0, [],[],[],[], lb, ub, [], options);
        fprintf('r_p = %3.2fradii, ang = %7.2f deg, dt = %7.2fd, ||V_out - V1+|| = %.4gkm/s\n', ...
            x(1), rad2deg(x(2)), dt/day_in_secs, dv_res_out);

        if flag > 0 && dv_res_out < tol_dv
            r_multiple_p_flyby = x(1);
            angle_flyby = x(2);
            return;
        end

        if dv_res_out > 1
            ddt_in_days = 100;
        else
            ddt_in_days = dv_res_out * 100;
        end
        dt = dt + ddt_in_days * day_in_secs;
    end

    error('No valid flyby geometry found in the given dt range.');
end

function [flybyArc, conicArc] = search_around_dt_seed(trajectory, r_multiple_p_flyby, angle_flyby, dt, target)
    global day_in_secs; %#ok<GVMIS>

    x0 = [r_multiple_p_flyby, angle_flyby, dt                    ];
    lb = [               1.1,         -pi, dt - 150 * day_in_secs];
    ub = [               101,          pi, dt + 150 * day_in_secs];

    options = optimoptions('lsqnonlin', ...
        'Display','iter-detailed', ...
        'Algorithm','levenberg-marquardt', ...
        'FunctionTolerance',1e-12, ...
        'StepTolerance',1e-40, ...
        'MaxFunctionEvaluations',1e10, ...
        'ScaleProblem','jacobian' ...
    );

    function dr_res = fun(x) % position residual
        dr_res = nan;
        try
            [~, conicArc] = produceNextArcsFromFlybyGeometry(trajectory, x(1), x(2), x(3), target);
        catch % in case of propagation failure or too low pass
            return;
        end
        if ~allow_low_pass && conicArc.passes_low()
            return;
        end
        dr_res = conicArc.dr_res;
    end

    [x, ~, dr_res, ~, ~] = lsqnonlin(@fun, x0, lb, ub, options);

    fprintf('r_p = %3.2fradii, ang = %7.2f deg, dt = %7.2fd, ||R_sc - R_target||_end = %.4gkm\n', ...
            x(1), rad2deg(x(2)), x(3)/day_in_secs, dr_res);

    % if exitflag <= 0
    %     error('flybyTargeting_lambert failed to converge.');
    % end

    [flybyArc, conicArc] = produceNextArcsFromFlybyGeometry(trajectory, x(1), x(2), x(3), target);
end
