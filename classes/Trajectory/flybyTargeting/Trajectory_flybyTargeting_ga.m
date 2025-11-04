% method using `ga` and `lsqnonlin` by Jaewoo
% refactored into the framework by Gunhee
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
    R_flyby = arc_last.R_end;

    V_body_flyby = body_flyby.V_at(t_flyby);
    V_sc_flyby_in = arc_last.V_end;
    Vinf_in = V_sc_flyby_in - V_body_flyby;
    vinf = norm(Vinf_in);

    % two vectors below, orthogonal to each other,
    % will be later used to compute standard (ang_flyby = 0) Vinf_out
    Vinf_in_normed = normed(Vinf_in);
    Vinf_in_perp_normed = normed( cross( Vinf_in_normed, [0;0;1] ) );

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

    function conicArc = produce_conicArc(x)
        r_p_flyby = x(1) * body_flyby.r;
        ang_flyby = x(2);
        dt = x(3) * TU;

        turn_angle = body_flyby.calc_turn_angle(vinf, r_p_flyby);
        Vinf_out_standard = vinf * ( ...
            cos(turn_angle)*Vinf_in_normed + sin(turn_angle)*Vinf_in_perp_normed ...
        );

        Vinf_out = rotmat(Vinf_in, ang_flyby) * Vinf_out_standard;

        V_sc_flyby_out = V_body_flyby + Vinf_out;

        t_rendezvous = t_flyby + dt;

        conicArc = ConicArc(t_flyby, R_flyby, V_sc_flyby_out, t_rendezvous, target);
    end

    function dR_res = calc_dR_res(x) % position residual
        conicArc = produce_conicArc(x);
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
    x_ig = ga(@calc_weighted_sum_of_dr_and_dt, 3, [],[],[],[], lb, ub, [], ga_opts);
    [x, ~, ~, exitflag, ~] = lsqnonlin(@calc_dR_res, x_ig, lb, ub, opts_lsq);
    if exitflag <= 0
        % uncomment below to visualize last valid trajectory
        % trajectory.draw(10000);
        error('flybyTargeting_ga failed to converge.');
    end

    conicArc = produce_conicArc(x);
    V_sc_flyby_out = conicArc.V_start;
    flybyArc = FlybyArc(t_flyby, body_flyby, V_sc_flyby_in, V_sc_flyby_out);
end

% ================= helper =================
function R = rotmat(u, theta)
    % Rodrigues' rotation formula for unit axis u (3x1), angle theta (rad)
    u = u(:) / norm(u);
    ux = u(1); uy = u(2); uz = u(3);
    c = cos(theta); s = sin(theta); C = 1 - c;
    R = [c+ux*ux*C,   ux*uy*C - uz*s, ux*uz*C + uy*s; ...
        uy*ux*C + uz*s, c+uy*uy*C,   uy*uz*C - ux*s; ...
        uz*ux*C - uy*s, uz*uy*C + ux*s, c+uz*uz*C  ];
end
