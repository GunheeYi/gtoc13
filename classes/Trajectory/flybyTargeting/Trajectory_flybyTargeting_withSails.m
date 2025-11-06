% Method with sailing by Jinsung.
% Use this when solution `conicArc` produced by other methods without sailing
% does not target well enough.
% Refactored into the framework by Gunhee.
function propagatedArc = Trajectory_flybyTargeting_withSails(conicArc)
    propagatedArc_coarse = refineArcUsingSail_coarse(conicArc);
    propagatedArc = refineArcUsingSail_precise(propagatedArc_coarse);
end

function propagatedArc = refineArcUsingSail_coarse(conicArc)
    propagatedArc = PropagatedArc(conicArc.t_start, ...
        conicArc.R_start, conicArc.V_start, conicArc.t_end, conicArc.target);
    
    [propagatedArc, ~] = refineLastControls(propagatedArc, propagatedArc.n_controls);
end

function propagatedArc = refineArcUsingSail_precise(propagatedArc_coarse)
    n_controls_tail = 2;
    propagatedArc = propagatedArc_coarse.splitControls_tail(n_controls_tail);
    [propagatedArc, flag] = ...
        refineLastControls(propagatedArc, propagatedArc.n_controls_tail);
        % note that `n_controls_tail` ~= `propagatedArc.n_controls_tail`
        % because of the splitting of tail in `splitControls_tail()`
    if flag <= 0
        error('Precise sailing optimization did not converge.');
    end
end

function [propagatedArc, flag] = refineLastControls(propagatedArc, n_controls_last)
    global TU; %#ok<GVMIS>

    % decision x = [dt1 alpha1 beta1 dt2 alpha2 beta2 ... dtN alphaN betaN]
    lb = nan(3 * n_controls_last, 1);
    ub = nan(3 * n_controls_last, 1);
    for i = 1:n_controls_last
        % dt bounds: [0.5 * dt_initial, 1.5 * dt_initial]
        control = propagatedArc.controls(end - (n_controls_last - i));
        dt_in_TU = control.dt / TU;
        lb(3*i-2) = 0.5 * dt_in_TU;
        ub(3*i-2) = 1.5 * dt_in_TU;

        % alpha bounds: [0deg, 90deg]
        lb(3*i-1) = 0;
        ub(3*i-1) = pi/2;

        % beta bounds: [-180deg, 180deg]
        lb(3*i) = -pi;
        ub(3*i) = pi;
    end

    function dr_res = fun(x)
        propagatedArc = propagatedArc.updateLastControlsFromVector(x);
        dr_res = propagatedArc.dr_res;
    end

    options_ga = optimoptions('ga', ...
        'Display','iter', ...
        'UseParallel', false, ...      % 병렬 가능하면 true
        'MaxGenerations', 400, ...
        'PopulationSize', 400, ...
        'FunctionTolerance', 1e-4);
    
    options_fmincon = optimoptions('fmincon', ...
        'Algorithm','interior-point', ...
        'Display','iter-detailed', ...
        'MaxFunctionEvaluations', 30000, ...
        'StepTolerance', 1e-21, ...
        'FunctionTolerance', 1e-3, ...
        'OptimalityTolerance', 1e-6, ...
        'ConstraintTolerance', 1e-3, ...
        'FiniteDifferenceType', 'central', ...
        'TypicalX', 0.1*ones(2*n_controls_last,1), ...
        'ObjectiveLimit', 0.1 ...
    );

    fprintf('Initiating GA to generate inital seed for sail control...\n');
    [x0, dr_res] = ga(@fun, 3 * n_controls_last, [],[],[],[], lb, ub, [], options_ga);
    fprintf('Initial GA seed for sail control produced dr_res = %.6fkm.\n', dr_res);
    fprintf('Refining sail control using fmincon...\n');
    [x, dr_res, flag] = fmincon(@fun, x0, [],[],[],[], lb, ub, [], options_fmincon);
    fprintf('Refined sail control produced dr_res = %.6fkm.\n', dr_res);

    propagatedArc = propagatedArc.updateLastControlsFromVector(x);
end
