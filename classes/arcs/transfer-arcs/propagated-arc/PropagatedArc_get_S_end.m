function S_end = PropagatedArc_get_S_end(propagatedArc)
    n_controls = length(propagatedArc.controls);
    S = propagatedArc.S_start;
    Ss = nan(6, n_controls+1);
    Ss(:, 1) = S;
    for i = 1:n_controls
        control = propagatedArc.controls(i);
        S = propagate_with_constant_control(S, control);
        Ss(:, i+1) = S;
    end
    S_end = Ss(:, end);
end

function S_end = propagate_with_constant_control(S_start, control)
    function dSdt = odefun(S)
        global AU mu_altaira sc; %#ok<GVMIS>

        % exosun geometry
        R  = S(1:3);
        V = S(4:6);
        r = norm(R);
        [U_x, U_y, U_z] = produce_local_exosun_basis(R, V);
        U_n = - cos(control.alpha) * U_x ...
              + sin(control.alpha) * (cos(control.beta) * U_y + sin(control.beta) * U_z);

        a_local = sc.sail.a_at_1AU * (AU / r)^2;
        A_sail = - a_local * (cos(control.alpha)^2) * U_n; % points away from Sun overall
        A_gravitational  = - mu_altaira * R / (r^3);
        A = A_gravitational + A_sail;
        dSdt = [V; A];
    end

    tspan = [0 control.dt];
    options = odeset('RelTol',1e-11,'AbsTol',1e-14);

    [~, Ss] = ode113(@(~, S) odefun(S), tspan, S_start, options);
    S_end = Ss(end, :)';
end

function [U_x, U_y, U_z] = produce_local_exosun_basis(R, V)
    % build an orthonormal triad {U_x, U_y, U_z} with X = spacecraft -> Sun
    U_x = - normed(R); % spacecraft -> Sun
    H = cross(R, V);
    if norm(H) < 1e-12
        % near-radial: pick a robust Z perpendicular to X
        tmp = cross(U_x, [0 0 1]');
        if norm(tmp) < 1e-6
            tmp = cross(U_x, [0 1 0]');
        end
        U_z = normed(tmp);
    else
        U_z = normed(H);
    end
    U_y = cross(U_z, U_x);
    U_y = normed(U_y);
    % U_y = U_y / max(1e-15, norm(U_y)); <-- legacy guard necessary?
end