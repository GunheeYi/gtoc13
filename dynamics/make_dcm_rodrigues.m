% Rodrigues' rotation formula for unit axis u (3x1), angle theta (rad)
function R = make_dcm_rodrigues(u, theta)
    u = u(:) / norm(u);
    ux = u(1); uy = u(2); uz = u(3);
    c = cos(theta); s = sin(theta); C = 1 - c;
    R = [c+ux*ux*C,   ux*uy*C - uz*s, ux*uz*C + uy*s; ...
        uy*ux*C + uz*s, c+uy*uy*C,   uy*uz*C - ux*s; ...
        uz*ux*C - uy*s, uz*uy*C + ux*s, c+uz*uz*C  ];
end
