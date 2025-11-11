% Method with sailing by Jinsung.
% Use this when solution `conicArc` produced by other methods without sailing
% does not target well enough.
% Refactored into the framework by Gunhee.
function [flybyArc, propagatedArc] = Trajectory_flybyTargeting_withSails(arc_last, ...
        flybyArc, conicArc, rendezvousDirection, allow_retrograde, allow_low_pass)
    global AU; %#ok<GVMIS>
    fprintf('Refining arc using solar sail...\n');
    fprintf('  Initial dr_res = %.2fkm (%.2fAU)\n', conicArc.dr_res, conicArc.dr_res / AU);
    fprintf('  Starting coarse optimization...\n');
    [flybyArc, propagatedArc] = refineArcUsingSail_coarse(arc_last, ...
        flybyArc, conicArc, rendezvousDirection, allow_retrograde, allow_low_pass);
    fprintf('  Coarse optimization produced dr_res = %.2fkm (%.2fAU)\n', ...
        propagatedArc.dr_res, propagatedArc.dr_res / AU);
    % fprintf('  Starting precise optimization...\n');
    % [flybyArc, propagatedArc] = refineArcUsingSail_precise(arc_last, ...
    %     flybyArc, propagatedArc, rendezvousDirection, allow_retrograde, allow_low_pass);
    % fprintf('  Precise optimization produced dr_res = %.2fkm (%.2fAU)\n', ...
    %     propagatedArc.dr_res, propagatedArc.dr_res / AU);
end

function [flybyArc, propagatedArc] = refineArcUsingSail_coarse(arc_last, ...
        flybyArc, conicArc, rendezvousDirection, allow_retrograde, allow_low_pass)
    propagatedArc = PropagatedArc(conicArc);
    
    [flybyArc, propagatedArc, ~] = refineLastControls(arc_last, ...
        flybyArc, propagatedArc, propagatedArc.n_controls, rendezvousDirection, allow_retrograde, allow_low_pass, 1e7);
end

function [flybyArc, propagatedArc] = refineArcUsingSail_precise(arc_last, ...
        flybyArc, propagatedArc_coarse, rendezvousDirection, allow_retrograde, allow_low_pass)
    n_controls_tail = 2;
    propagatedArc = propagatedArc_coarse.splitControls_tail(n_controls_tail);
    [flybyArc, propagatedArc, ~] = ...
        refineLastControls(arc_last, ...
            flybyArc, propagatedArc, propagatedArc.n_controls_tail, ...
            rendezvousDirection, allow_retrograde, allow_low_pass, 1e3);
        % note that `n_controls_tail` ~= `propagatedArc.n_controls_tail`
        % because of the splitting of tail in `splitControls_tail()`
end

function [flybyArc_new, propagatedArc_new, flag] = refineLastControls(arc_last, ...
        flybyArc, propagatedArc, n_controls_last, ...
        rendezvousDirection, allow_retrograde, allow_low_pass, FitnessLimit)
    % decision x = [r_multiple_p_flyby, angle_rotation,
    %               alpha1, beta1, alpha2, beta2, ..., alphaN, betaN,
    %               global_dt_scaling_factor                          ]

    % initial guesses
    if flybyArc.body.flybyable
        r_multiple_p_flyby_ig = flybyArc.r_multiple_p;
        angle_rotation_flyby_ig = flybyArc.angle_rotation;
    else
        r_multiple_p_flyby_ig = 0;
        angle_rotation_flyby_ig = 0;
    end
    flybyGeoemtry_ig = [r_multiple_p_flyby_ig; angle_rotation_flyby_ig]; % 2x1
    controlVector_ig = propagatedArc.exportLastControlsAsVector(n_controls_last); % (2*n_controls_last+1)x1
    x_ig = [flybyGeoemtry_ig; controlVector_ig]; % (2*n_controls_last+3)x1
    assert(isreal(x_ig));
    
    if ~flybyArc.body.flybyable || propagatedArc.n_controls ~= n_controls_last
        % gravity assist is not possible, or 
        % was requested to refine only the last part of the sequence;
        % maintain flyby geometry as-is
        lb_flybyGeometry = [r_multiple_p_flyby_ig; angle_rotation_flyby_ig];
        ub_flybyGeometry = [r_multiple_p_flyby_ig; angle_rotation_flyby_ig];
        
    else
        % gravity assist is possible and
        % was requested to refine the whole sequence;
        % therefore include flyby geometry in variables
        lb_r_multiple_p_flyby = min(max(0.7 * r_multiple_p_flyby_ig, 1.1+eps), 101-eps);
        ub_r_multiple_p_flyby = min(max(1.4 * r_multiple_p_flyby_ig, 1.1+eps), 101-eps);
        lb_flybyGeometry = [lb_r_multiple_p_flyby; angle_rotation_flyby_ig - deg2rad(60)];
        ub_flybyGeometry = [ub_r_multiple_p_flyby; angle_rotation_flyby_ig + deg2rad(60)];
    end
    lb = [lb_flybyGeometry; repmat([   0; -pi], n_controls_last, 1); 0.5];
    ub = [ub_flybyGeometry; repmat([pi/2;  pi], n_controls_last, 1); 2.0];
    % TODO: differ `global_dt_scaling_factor` based on whether its outward or inward

    function dr_res = fun(x)
        dr_res = nan;

        try
            [~, propagatedArc_new] = produceNextArcs(flybyArc, propagatedArc, controlVector_ig, x);
            % ^ transferArc passes too low, etc.
        catch
            return;
        end

        % TODO: handle low pass

        if ~allow_retrograde && ~propagatedArc_new.isProgradeAtEnd
            return;
        end

        try
            dr_res = propagatedArc_new.dr_res;
        catch
            return; % in case of propagation failure
        end
    end

    % options_ga = optimoptions('ga', ...
    %     'Display','iter', ...
    %     'UseParallel', false, ...
    %     'MaxGenerations', 1, ...
    %     'PopulationSize', 10, ...
    %     'FunctionTolerance', 1e-4, ...
    %     'FitnessLimit', FitnessLimit ...
    % );
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
    guarantee_ig_within_bounds(x_ig, lb, ub); % for debugging
    [x, dr_res, flag] = fmincon(@fun, x_ig, [],[],[],[], lb, ub, [], options_fmincon);
    fprintf('Refined sail control produced dr_res = %.6fkm.\n', dr_res);

    [flybyArc_new, propagatedArc_new] = produceNextArcs(flybyArc, propagatedArc, controlVector_ig, x);
end

function guarantee_ig_within_bounds(x_ig, lb, ub)
    % Assume x0, lb, ub are your vectors
    viol_lower = find(x_ig < lb);
    viol_upper = find(x_ig > ub);

    if ~isempty(viol_lower)
        fprintf('Elements below LB:\n');
        for i = 1:length(viol_lower)
            idx = viol_lower(i);
            error('  Index %d: x0 = %g, LB = %g\n', idx, x_ig(idx), lb(idx));
        end
    end

    if ~isempty(viol_upper)
        fprintf('Elements above UB:\n');
        for i = 1:length(viol_upper)
            idx = viol_upper(i);
            error('  Index %d: x0 = %g, UB = %g\n', idx, x_ig(idx), ub(idx));
        end
    end

    if isempty(viol_lower) && isempty(viol_upper)
        disp('All elements of x0 are within bounds.');
    end
end

function [flybyArc_new, propagatedArc_new] = produceNextArcs(flybyArc, propagatedArc, controlVector_ig, x)
    controlVector = x(3:end);
    if flybyArc.body.flybyable
        r_multiple_p_flyby = x(1);
        angle_rotation_flyby = x(2);
        dt = propagatedArc.t_end - propagatedArc.t_start;
        [flybyArc_new, conicArc] = produceNextArcsFromFlybyGeometry(arc_last, r_multiple_p_flyby, angle_rotation_flyby, dt, propagatedArc.target);
        propagatedArc_new = PropagatedArc(conicArc);
        propagatedArc_new = propagatedArc_new.updateLastControlsFromVector(controlVector_ig);
        propagatedArc_new = propagatedArc_new.updateLastControlsFromVector(controlVector);
    else
        flybyArc_new = flybyArc;
        propagatedArc_new = propagatedArc.updateLastControlsFromVector(controlVector_ig);
        propagatedArc_new = propagatedArc_new.updateLastControlsFromVector(controlVector);
    end
end

