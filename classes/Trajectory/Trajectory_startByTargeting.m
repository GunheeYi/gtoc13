function trajectory = Trajectory_startByTargeting(trajectory, target, t_start, vx_start)
    arguments
        trajectory Trajectory;
        target CelestialBody;
        t_start {mustBeNonnegative};
        vx_start {mustBePositive};
    end

    global year_in_secs AU t_max; %#ok<GVMIS>

    if ~isempty(trajectory.arcs)
        error('startByTargeting can only be called on an empty trajectory.');
    end

    t_rendezvous = 6 * year_in_secs;
    ry_start = 10 * AU;
    rz_start = 5 * AU;
    % note: When rx/rz_start are too small(about 1~2AU), 
    % optimization may fail to converge.
    % Don't know exactly why. 
    % Maybe because it leads to extreme values in K?

    % TODO: initial guesses taylored for PlanetX;
    % change based on target?

    x0 = [t_rendezvous ry_start rz_start];
    lb = [t_start+1 -200*AU -200*AU];
    ub = [t_max 200*AU 200*AU];

    opts = optimoptions('lsqnonlin', ...
        'Display','iter-detailed', ...
        'Algorithm','levenberg-marquardt', ...
        'FunctionTolerance',1e-20, ...
        'StepTolerance',1e-20, ...
        'MaxFunctionEvaluations',1e10, ...
        'ScaleProblem','jacobian' ...
    );

    [x, ~, ~, exitflag, ~] = lsqnonlin( ...
        @(x) Trajectory_startByTargeting_calculatePositionError(target, t_start, vx_start, x), ...
        x0, lb, ub, opts ...
    );
    
    if exitflag <= 0
        error('Trajectory.startByTargeting optimization did not converge.');
    end

    t_rendezvous = x(1);
    ry_start = x(2);
    rz_start = x(3);

    R_sc_start = [ -200*AU; ry_start; rz_start ];
    V_sc_start = [ vx_start; 0; 0 ];
    conicArc = ConicArc(t_start, R_sc_start, V_sc_start, t_rendezvous, target);

    trajectory = trajectory.addArc(conicArc);
end
