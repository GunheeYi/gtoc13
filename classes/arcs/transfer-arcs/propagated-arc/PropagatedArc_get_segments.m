function segments = PropagatedArc_get_segments(propagatedArc)
    segments = cell(1, propagatedArc.n_controls);
    S = propagatedArc.S_start;
    for i = 1:propagatedArc.n_controls
        control = propagatedArc.controls(i);
        Ss = propagate_with_constant_control(S, control);
        segments{i} = Ss;
        S = Ss(:, end);
    end
end

function Ss = propagate_with_constant_control(S_start, control)
    N = calc_sail_normal(S_start, control);

    function dSdt = odefun(S)
        global AU mu_altaira sc; %#ok<GVMIS>

        % exosun geometry
        R = S(1:3);
        V = S(4:6);
        r = norm(R);

        a_local = sc.sail.a_at_1AU * (AU / r)^2;
        dot_sail_normal_and_sun_pointer = dot(normed(N), normed(-R));
        A_sail = - a_local * (dot_sail_normal_and_sun_pointer^2) * N;
        A_gravitational  = - mu_altaira * R / (r^3);
        A = A_gravitational + A_sail;
        dSdt = [V; A];
    end

    tspan = [0 control.dt_scaled];
    options = odeset('RelTol', 1e-5, 'AbsTol', 1e-2);
    warning('error', 'MATLAB:ode15s:IntegrationTolNotMet');
    [~, Ss] = ode45(@(~, S) odefun(S), tspan, S_start, options);
    warning('on', 'MATLAB:ode15s:IntegrationTolNotMet');

    Ss = Ss';
end
