% Method with sailing by Jinsung.
% Use this when solution `conicArc` produced by other methods without sailing
% does not target well enough.
% Refactored into the framework by Gunhee.
function [flybyArc, propagatedArc] = Trajectory_flybyTargeting_withSails(arc_last, flybyArc, conicArc, allow_retrograde, allow_low_pass)
    global AU; %#ok<GVMIS>
    fprintf('Refining arc using solar sail...\n');
    fprintf('  Initial dr_res = %.2fkm (%.2fAU)\n', conicArc.dr_res, conicArc.dr_res / AU);
    fprintf('  Starting coarse optimization...\n');
    propagatedArc = refineArcUsingSail_coarse(arc_last, flybyArc, conicArc, allow_retrograde, allow_low_pass);
    fprintf('  Coarse optimization produced dr_res = %.2fkm (%.2fAU)\n', ...
        propagatedArc.dr_res, propagatedArc.dr_res / AU);
    fprintf('  Starting precise optimization...\n');
    [flybyArc, propagatedArc] = refineArcUsingSail_precise(arc_last, flybyArc, propagatedArc, allow_retrograde, allow_low_pass);
    fprintf('  Precise optimization produced dr_res = %.2fkm (%.2fAU)\n', ...
        propagatedArc.dr_res, propagatedArc.dr_res / AU);
end

function propagatedArc = refineArcUsingSail_coarse(arc_last, flybyArc, conicArc, allow_retrograde, allow_low_pass)
    propagatedArc = PropagatedArc(conicArc);
    
    [~, propagatedArc, ~] = refineLastControls(arc_last, flybyArc, propagatedArc, propagatedArc.n_controls, allow_retrograde, allow_low_pass, 1e7);
end

function [flybyArc, propagatedArc] = refineArcUsingSail_precise(arc_last, flybyArc, propagatedArc_coarse, allow_retrograde, allow_low_pass)
    n_controls_tail = 2;
    propagatedArc = propagatedArc_coarse.splitControls_tail(n_controls_tail);
    [flybyArc, propagatedArc, flag] = ...
        refineLastControls(arc_last, flybyArc, propagatedArc, propagatedArc.n_controls_tail, allow_retrograde, allow_low_pass, 1e3);
        % note that `n_controls_tail` ~= `propagatedArc.n_controls_tail`
        % because of the splitting of tail in `splitControls_tail()`
end

function [flybyArc, propagatedArc_new, flag] = refineLastControls(arc_last, flybyArc, propagatedArc, n_controls_last, allow_retrograde, allow_low_pass, FitnessLimit)
    % decision x = [r_multiple_p_flyby, angle_rotation,
    %               alpha1, beta1, alpha2, beta2, ..., alphaN, betaN,
    %               global_dt_scaling_factor                          ]

    % initial guess of flyby geometry
    r_multiple_p_flyby_ig = flybyArc.r_multiple_p;
    angle_rotation_flyby_ig = flybyArc.angle_rotation;
    
    if propagatedArc.n_controls == n_controls_last
        % was requested to refine the whole sequence;
        % therefore include flyby geometry in variables
        lb_r_multiple_p_flyby = min(max(0.7 * r_multiple_p_flyby_ig, 1.1), 101);
        ub_r_multiple_p_flyby = min(max(1.4 * r_multiple_p_flyby_ig, 1.1), 101);
        lb_flyby_geometry = [lb_r_multiple_p_flyby, angle_rotation_flyby_ig - deg2rad(60)];
        ub_flyby_geometry = [ub_r_multiple_p_flyby, angle_rotation_flyby_ig + deg2rad(60)];
        x0 = [r_multiple_p_flyby_ig, angle_rotation_flyby_ig, repmat([deg2rad(1e-2) 0], 1, n_controls_last), 1];
    else
        % maintain flyby geometry as-is
        lb_flyby_geometry = [r_multiple_p_flyby_ig, angle_rotation_flyby_ig];
        ub_flyby_geometry = [r_multiple_p_flyby_ig, angle_rotation_flyby_ig];
    end
    lb = [lb_flyby_geometry, repmat([   0 -pi], 1, n_controls_last), 0.5];
    ub = [ub_flyby_geometry, repmat([pi/2  pi], 1, n_controls_last), 2.0];
    % TODO: differ `global_dt_scaling_factor` based on whether its outward or inward

    function dr_res = fun(x)
        dr_res = nan;

        r_multiple_p_flyby = x(1);
        angle_rotation_flyby = x(2);
        dt = propagatedArc.t_end - propagatedArc.t_start;

        [~, conicArc] = produceNextArcsFromFlybyGeometry(arc_last, r_multiple_p_flyby, angle_rotation_flyby, dt, propagatedArc.target);
        propagatedArc_new = PropagatedArc(conicArc);
        propagatedArc_new = propagatedArc_new.updateLastControlsFromVector(x);
        % TODO: handle low pass

        if ~allow_retrograde && ~propagatedArc_new.isPrograde
            return;
        end

        try
            dr_res = propagatedArc_new.dr_res;
        catch
            return; % in case of propagation failure
        end
    end

    options_ga = optimoptions('ga', ...
        'Display','iter', ...
        'UseParallel', false, ...
        'MaxGenerations', 1, ...
        'PopulationSize', 10, ...
        'FunctionTolerance', 1e-4, ...
        'FitnessLimit', FitnessLimit ...
    );
    % 'MaxGenerations', 20, ...
    % 'PopulationSize', 3000, ...
    
    options_fmincon = optimoptions('fmincon', ...
        'Algorithm','interior-point', ...
        'Display','iter-detailed', ...
        'MaxFunctionEvaluations', 3000, ...
        'StepTolerance', 1e-21, ...
        'FunctionTolerance', 1e-3, ...
        'OptimalityTolerance', 1e-6, ...
        'ConstraintTolerance', 1e-3, ...
        'FiniteDifferenceType', 'central', ...
        'TypicalX', [2, deg2rad(10), 0.1*ones(1, 2*n_controls_last), 1], ...
        'ObjectiveLimit', 0.1 ...
    );
    % 'MaxFunctionEvaluations', 3000, ...

    % fprintf('Initiating GA to generate inital seed for sail control...\n');
    % [x0, dr_res] = ga(@fun, 2 * n_controls_last + 3, [],[],[],[], lb, ub, [], options_ga);
    % fprintf('Initial GA seed for sail control produced dr_res = %.6fkm.\n', dr_res);

    fprintf('Refining sail control using fmincon...\n');
    [x, dr_res, flag] = fmincon(@fun, x0, [],[],[],[], lb, ub, [], options_fmincon);
    fprintf('Refined sail control produced dr_res = %.6fkm.\n', dr_res);

    r_multiple_p_flyby = x(1);
    angle_rotation_flyby = x(2);
    dt = propagatedArc.t_end - propagatedArc.t_start;

    [flybyArc, conicArc] = produceNextArcsFromFlybyGeometry(arc_last, r_multiple_p_flyby, angle_rotation_flyby, dt, propagatedArc.target);
    propagatedArc_new = PropagatedArc(conicArc);
    propagatedArc_new = propagatedArc_new.updateLastControlsFromVector(x);
end
