function propagatedArc = Trajectory_flybyTargeting_sailing(conicArc)
    propagatedArc_coarse = sail_coarse(conicArc);
    propagatedArc = sail_precise(propagatedArc_coarse);
end

function propagatedArc = sail_coarse(conicArc)
    propagatedArc = PropagatedArc(conicArc.t_start, ...
        conicArc.R_start, conicArc.V_start, conicArc.t_end, conicArc.target);
    
    [propagatedArc, ~] = refineLastControls(propagatedArc, propagatedArc.n_controls);
end

function propagatedArc = sail_precise(propagatedArc_coarse)
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
    % decision x = [alpha1 beta1 alpha2 beta2 ... alphaN betaN]
    x0 = propagatedArc.exportLastControlsAsVector(n_controls_last);
    lb = repmat([0 -pi]', n_controls_last, 1);
    ub = repmat([pi/2 pi]', n_controls_last, 1);

    function dr_res = fun(x)
        propagatedArc = propagatedArc.updateLastControlsFromVector(x);
        dr_res = propagatedArc.dr_res;
    end

    function [c, ceq] = nonlcon(x)
        global tol_r; %#ok<GVMIS>
        propagatedArc = propagatedArc.updateLastControlsFromVector(x);
        c = propagatedArc.dr_res - tol_r; % residual distance must be < 0.1 km
        ceq = []; % no equality constraints
    end

    opts = optimoptions('fmincon', ...
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

    [x, ~, flag] = fmincon(@fun, x0, [],[],[],[], lb, ub, @nonlcon, opts);

    propagatedArc = propagatedArc.updateLastControlsFromVector(x);
end
