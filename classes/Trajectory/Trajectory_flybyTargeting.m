function trajectory = Trajectory_flybyTargeting(trajectory, target)
    arguments
        trajectory Trajectory;
        target CelestialBody;
    end

    global day_in_secs t_max tol_t tol_v; %#ok<GVMIS,NUSED>

    if isa(trajectory.arc_last, "FlybyArc")
        error('Consecutive flyby arcs are not allowed.');
    end

    % TODO: raise error if trajectory.arc_last.target is not set?

    % 1. find t_rendezvous that makes |Vinf_in| = |Vinf_out|

    options = optimset( ...
        'Display', 'iter', ...
        ... % 'TolFun', 1e-3*tol_v, 'TolX', 1e-3*tol_t, ...
        'MaxFunEvals', 500, 'MaxIter', 100 ...
    );

    dt_rendezvous_ig = 10 * day_in_secs;
    t_rendezvous_ig = trajectory.t_end + dt_rendezvous_ig; % initial guess
    while true
        if t_rendezvous_ig > t_max
            error('Failed to find a feasible t_rendezvous within t_max.');
        end

        try
            [t_rendezvous, ~, exitflag, ~] = fzero( ...
                @(t_rendezvous) calc_dvinf(trajectory.arc_last, t_rendezvous, target), ...
                t_rendezvous_ig, options ...
            );
        catch ME
            if strcmp(ME.identifier, 'Trajectory_flybyTargeting:TimeDecreasing')
                fprintf( ...
                    "Trajectory_flybyTargeting: fzero failed at dt_rendezvous_ig = %.8f years. " ...
                    + "Trying a larger dt...\n", ...
                    dt_rendezvous_ig / (365.25*86400) ...
                );
                dt_rendezvous_ig = dt_rendezvous_ig * 1.5;
                t_rendezvous_ig = trajectory.t_end + dt_rendezvous_ig;
                continue;
            else
                rethrow(ME);
            end
        end

        if exitflag <= 0
            error('Trajectory.startByTargeting optimization did not converge.');
        end

        dvinf_final = calc_dvinf(trajectory.arc_last, t_rendezvous, target);
        fprintf('Converged: t_rendezvous = %.8f years, dvinf = %.6f km/s\n', ...
            t_rendezvous / (365.25*86400), dvinf_final);

        break; % success
    end

    t_flyby = trajectory.arc_last.t_end;
    body_flyby = trajectory.arc_last.target;
    R_flyby = body_flyby.R_at(t_flyby);
    [V_flyby_body, V_flyby_in, V_flyby_out] = calc_Vs_flyby(trajectory.arc_last, t_rendezvous, target);

    % 2. check feasibility of flyby maneuver: TODO
    [Vinf_in, Vinf_out] = calc_Vinfs(V_flyby_body, V_flyby_in, V_flyby_out);
    turn_angle = calc_turn_angle(Vinf_in, Vinf_out);
    [turn_angle_min, turn_angle_max] = body_flyby.calc_feasible_turn_angle_range(norm(Vinf_in));
    if turn_angle < turn_angle_min || turn_angle > turn_angle_max
        error('Trajectory_flybyTargeting:InfeasibleFlyby', ...
            "The required flyby maneuver is infeasible. " ...
            + "Turn angle = %.6f deg, feasible range = [%.6f deg, %.6f deg]", ...
            rad2deg(turn_angle), rad2deg(turn_angle_min), rad2deg(turn_angle_max) ...
        );
    else
        fprintf('Feasible flyby maneuver found: turn angle = %.6f deg\n', rad2deg(turn_angle));
    end

    [V_flyby_out_refined, t_rendezvous_refined] = refineConicArc( ...
        t_flyby, R_flyby, V_flyby_body, V_flyby_out, target, t_rendezvous ...
    );

    % 3. add flyby arc and post-flyby conic arc to trajectory
    flybyArc = FlybyArc(t_flyby, body_flyby, V_flyby_in, V_flyby_out_refined);
    trajectory = trajectory.addArc(flybyArc);
    conicArc = ConicArc(t_flyby, R_flyby, V_flyby_out_refined, t_rendezvous_refined, target);
    trajectory = trajectory.addArc(conicArc);
end

function [V_flyby_body, V_flyby_in, V_flyby_out] = calc_Vs_flyby(arc_last, t_rendezvous, target)
    arguments
        arc_last {mustBeA(arc_last,["ConicArc","PropagatedArc"])};
        t_rendezvous {mustBeNonnegative};
        target CelestialBody;
    end

    global mu_altaira; %#ok<GVMIS>

    t_flyby = arc_last.t_end;
    dt = t_rendezvous - t_flyby;

    if dt <= 0
        error('Trajectory_flybyTargeting:TimeDecreasing', 't_rendezvous must be after t_flyby.');
    end

    body_flyby = arc_last.target;

    V_flyby_body = body_flyby.V_at(t_flyby);
    V_flyby_in = arc_last.V_end;

    R_flyby = body_flyby.R_at(t_flyby);
    R_rendezvous = target.R_at(t_rendezvous);
    [V_flyby_out, ~] = solve_lamberts_problem(R_flyby, R_rendezvous, dt, mu_altaira, 'Prograde');
end

function [Vinf_in, Vinf_out] = calc_Vinfs(V_flyby_body, V_flyby_in, V_flyby_out)
    arguments
        V_flyby_body (3,1) double;
        V_flyby_in (3,1) double;
        V_flyby_out (3,1) double;
    end

    Vinf_in = V_flyby_in - V_flyby_body;
    Vinf_out = V_flyby_out - V_flyby_body;
end

function turn_angle = calc_turn_angle(Vinf_in, Vinf_out)
    arguments
        Vinf_in (3,1) double;
        Vinf_out (3,1) double;
    end

    turn_angle = acos( dot(normed(Vinf_in), normed(Vinf_out)) );
end

function dvinf = calc_dvinf(arc_last, t_rendezvous, target)
    arguments
        arc_last {mustBeA(arc_last,["ConicArc","PropagatedArc"])};
        t_rendezvous {mustBeNonnegative};
        target CelestialBody;
    end

    [V_flyby_body, V_flyby_in, V_flyby_out] = calc_Vs_flyby(arc_last, t_rendezvous, target);
    [Vinf_in, Vinf_out] = calc_Vinfs(V_flyby_body, V_flyby_in, V_flyby_out);
    
    vinf_in = norm(Vinf_in);
    vinf_out = norm(Vinf_out);

    % fprintf('t_rendezvous = %.8f years: |Vinf_in| = %.6f km/s, |Vinf_out| = %.6f km/s\n', ...
    %     t_rendezvous / (365.25*86400), vinf_in, vinf_out);

    dvinf = vinf_out - vinf_in;
end

function [V_flyby_out_refined, t_rendezvous_refined] = refineConicArc( ...
        t_flyby, R_flyby, V_flyby_body, V_flyby_out, target, t_rendezvous ...
    )

    Vinf = V_flyby_out - V_flyby_body;
    vinf = norm(Vinf);

    v_normaliazation_factor = t_rendezvous / vinf; % to help optimization convergence

    dt_max = 1;
    dv_max = dt_max / v_normaliazation_factor;

    x_ig = [V_flyby_out * v_normaliazation_factor; t_rendezvous]; % initial guess
    lb = [(V_flyby_out - dv_max) * v_normaliazation_factor; t_rendezvous - dt_max];
    ub = [(V_flyby_out + dv_max) * v_normaliazation_factor; t_rendezvous + dt_max];
    
    function [c, ceq] = nonlcon(x_curr)
        V_flyby_out_curr = x_curr(1:3) / v_normaliazation_factor;
        t_rendezvous_curr = x_curr(4);

        conicArc = ConicArc(t_flyby, R_flyby, V_flyby_out_curr, t_rendezvous_curr);
        R_sc = conicArc.R_end;
        R_target = target.R_at(t_rendezvous_curr);

        ceq_vinf = (norm(V_flyby_out_curr - V_flyby_body) - vinf);
        ceq_pos = R_sc - R_target;

        fprintf('refineConicArc: t_rendezvous = %.8f years, dvinf = %.6f km/s, pos_err = [%.6f, %.6f, %.6f] km\n', ...
            t_rendezvous_curr / (365.25*86400), ceq_vinf, ceq_pos(1), ceq_pos(2), ceq_pos(3) ...
        );

        c = [];
        ceq = [ceq_vinf*1e6; ceq_pos];
    end

    options = optimoptions('fmincon', ...
        Algorithm="interior-point", ...
        EnableFeasibilityMode=true, ...
        SubproblemAlgorithm="cg", ...
        Display = 'iter-detailed', ...
        StepTolerance = 1e-20, ...
        ConstraintTolerance = 0.5e-1 ...
    );

    [x, ~, exitflag, ~] = fmincon(@(x) 0, x_ig, [], [], [], [], lb, ub, @nonlcon, options);
    if exitflag <= 0
        error('refineConicArc optimization did not converge.');
    end

    fprintf('refineConicArc converged.\n');

    V_flyby_out_refined = x(1:3) / v_normaliazation_factor;
    t_rendezvous_refined = x(4);
end