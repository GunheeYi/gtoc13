function N = calc_sail_normal(S, control)
    R  = S(1:3);
    V = S(4:6);
    [U_x, U_y, U_z] = produce_local_exosun_basis(R, V);
    N = - cos(control.alpha) * U_x ...
            + sin(control.alpha) * (cos(control.beta) * U_y + sin(control.beta) * U_z);
    N = normed(N);
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
