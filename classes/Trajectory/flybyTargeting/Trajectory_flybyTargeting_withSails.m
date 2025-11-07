% Method with sailing by Jinsung.
% Use this when solution `conicArc` produced by other methods without sailing
% does not target well enough.
% Refactored into the framework by Gunhee.
function propagatedArc = Trajectory_flybyTargeting_withSails(conicArc, allow_low_pass)
    global AU; %#ok<GVMIS>
    fprintf('Refining arc using solar sail propulsion...\n');
    fprintf('  Initial dr_res = %.0fkm (%.2fAU)\n', conicArc.dr_res, conicArc.dr_res / AU);
    fprintf('  Starting coarse optimization...\n');
    propagatedArc_coarse = refineArcUsingSail_coarse(conicArc, allow_low_pass);
    fprintf('  Coarse optimization produced dr_res = %.0fkm (%.2fAU)\n', ...
        propagatedArc_coarse.dr_res, propagatedArc_coarse.dr_res / AU);
    fprintf('  Starting precise optimization...\n');
    propagatedArc = refineArcUsingSail_precise(propagatedArc_coarse, allow_low_pass);
    fprintf('  Precise optimization produced dr_res = %.0fkm (%.2fAU)\n', ...
        propagatedArc.dr_res, propagatedArc.dr_res / AU);
end

function propagatedArc = refineArcUsingSail_coarse(conicArc, allow_low_pass)
    propagatedArc = PropagatedArc(conicArc.t_start, ...
        conicArc.R_start, conicArc.V_start, conicArc.t_end, conicArc.target);
    
    [propagatedArc, ~] = refineLastControls(propagatedArc, propagatedArc.n_controls, allow_low_pass, 1e7);
end

function propagatedArc = refineArcUsingSail_precise(propagatedArc_coarse, allow_low_pass)
    n_controls_tail = 2;
    propagatedArc = propagatedArc_coarse.splitControls_tail(n_controls_tail);
    [propagatedArc, flag] = ...
        refineLastControls(propagatedArc, propagatedArc.n_controls_tail, allow_low_pass, 1e3);
        % note that `n_controls_tail` ~= `propagatedArc.n_controls_tail`
        % because of the splitting of tail in `splitControls_tail()`
    if flag <= 0
        error('Precise sailing optimization did not converge.');
    end
end

function [propagatedArc, flag] = refineLastControls(propagatedArc, n_controls_last, allow_low_pass, FitnessLimit)
    % decision x = [alpha1 beta1 alpha2 beta2 ... alphaN betaN global_dt_scaling_factor]
    lb = [repmat([   0 -pi], 1, n_controls_last), 0.5];
    ub = [repmat([pi/2  pi], 1, n_controls_last), 2.0];

    function dr_res = fun(x)
        propagatedArc = propagatedArc.updateLastControlsFromVector(x);
        % TODO: handle low pass
        try
            dr_res = propagatedArc.dr_res;
        catch
            dr_res = nan; % in case of propagation failure
        end
    end

    options_ga = optimoptions('ga', ...
        'Display','iter', ...
        'UseParallel', false, ...      % 병렬 가능하면 true
        'MaxGenerations', 100, ...
        'PopulationSize', 2000, ...
        'FunctionTolerance', 1e-4, ...
        'FitnessLimit', FitnessLimit ...
    );
    
    options_fmincon = optimoptions('fmincon', ...
        'Algorithm','interior-point', ...
        'Display','iter-detailed', ...
        'MaxFunctionEvaluations', 30000, ...
        'StepTolerance', 1e-21, ...
        'FunctionTolerance', 1e-3, ...
        'OptimalityTolerance', 1e-6, ...
        'ConstraintTolerance', 1e-3, ...
        'FiniteDifferenceType', 'central', ...
        'TypicalX', [0.1*ones(1, 2*n_controls_last), 1], ...
        'ObjectiveLimit', 0.1 ...
    );

    fprintf('Initiating GA to generate inital seed for sail control...\n');
    [x0, dr_res] = ga(@fun, 2 * n_controls_last + 1, [],[],[],[], lb, ub, [], options_ga);
    fprintf('Initial GA seed for sail control produced dr_res = %.6fkm.\n', dr_res);
    fprintf('Refining sail control using fmincon...\n');
    [x, dr_res, flag] = fmincon(@fun, x0, [],[],[],[], lb, ub, [], options_fmincon);
    fprintf('Refined sail control produced dr_res = %.6fkm.\n', dr_res);

    propagatedArc = propagatedArc.updateLastControlsFromVector(x);
end
