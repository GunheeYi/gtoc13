function Sdot = two_body_dynamics(S, mu)
    R = S(1:3);
    V = S(4:6);

    r = norm(R);

    A = - mu / r^3 * R;

    Sdot = [V; A];
end
