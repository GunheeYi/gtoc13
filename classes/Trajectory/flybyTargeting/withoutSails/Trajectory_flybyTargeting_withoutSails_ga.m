% Method using `ga` and `lsqnonlin` without sailing, by Jaewoo.
% Refactored into the framework by Gunhee.
function [flybyArc, conicArc] = Trajectory_flybyTargeting_withoutSails_ga(trajectory, ...
        target, rdvDirection, dt_min, dt_max, allow_retrograde, allow_low_pass)

    global TU; %#ok<GVMIS>

    lb = [1.1, -pi, dt_min / TU];
    ub = [101,  pi, dt_max / TU];

    function [dR_res, T] = calc_dR_res_and_T(x) % position residual
        dR_res = [nan; nan; nan];
        T = nan; % orbital period of spacecraft after flyby
        try
            [~, conicArc] = produceNextArcsFromFlybyGeometry_usingX(trajectory.arc_last, x, target);
        catch % in case of propagation failure or too low pass
            return;
        end
        if ~conicArc.satisfiesConditions(rdvDirection, allow_retrograde, allow_low_pass)
            return;
        end
        dR_res = conicArc.dR_res;
        T = conicArc.T_end;
    end

    function dR_res = calc_dR_res(x)
        dR_res = calc_dR_res_and_T(x);
    end

    function J = calc_weighted_sum_of_dr_and_dt(x)
        [dR, T] = calc_dR_res_and_T(x);
        dr = norm(dR); % dr_res
        dt_in_T = x(3) * TU / T; % TODO:think: does it benefit hyperbolic trajectories (T=inf) too much?

        % effect of 1 rev difference should equal as about 1e5? 1e6? (TODO:think) km difference
        weight_dr = 1;
        weight_dt = 1e5;

        J = (weight_dr * dr)^2 + (weight_dt * dt_in_T)^2;
    end

    ga_opts = optimoptions('ga', ...
        'Display','iter', ...
        'UseParallel', false, ...      % 병렬 가능하면 true
        'MaxGenerations', 10, ...
        'PopulationSize', 2000, ...
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
    % if exitflag <= 0
    %     % uncomment below to visualize last valid trajectory
    %     % trajectory.draw();
    %     error('flybyTargeting_ga failed to converge.');
    % end

    [flybyArc, conicArc] = produceNextArcsFromFlybyGeometry_usingX(trajectory.arc_last, x, target);
end

function [flybyArc, conicArc] = produceNextArcsFromFlybyGeometry_usingX(arc_last, x, target)
    global TU; %#ok<GVMIS>

    r_multiple_p_flyby = x(1);
    angle_flyby = x(2);
    dt = x(3) * TU;

    [flybyArc, conicArc] = produceNextArcsFromFlybyGeometry(arc_last, r_multiple_p_flyby, angle_flyby, dt, target);
end
