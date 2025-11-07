function r_min = ConicArc_get_r_min(conicArc)
    global mu_altaira; %#ok<GVMIS>

    R_start = conicArc.R_start;
    V_start = conicArc.V_start;

    r_start = norm(R_start);

    r_candidates = [r_start, norm(conicArc.R_end)];

    a = conicArc.K_start(1);
    e = conicArc.K_start(2);
    h = norm(cross(R_start, V_start));
    p = h^2 / mu_altaira;
    r_p = p / (1+e);

    M_start = deg2rad(conicArc.K_start(6));
    M_end = deg2rad(conicArc.K_end(6));

    if e < 1-1e-9        % ellipse
        n = sqrt(mu_altaira/a^3);
        k0 = ceil(M_start/(2*pi)); k1 = floor(M_end/(2*pi));
        for k = k0:k1
            if k >= 0
                t_peri = conicArc.t_start + (2*pi*k - M_start)/n;
                if t_peri >= conicArc.t_start && t_peri <= conicArc.t_end
                    r_candidates(end+1) = r_p;
                end
            end
        end
    elseif e > 1+1e-9    % hyperbola
        if M_start <= 0 && M_end >= 0
            r_candidates(end+1) = r_p;
        end
    else                 % parabola
        vr0 = dot(R_start,V_start)/norm(R_start);
        if vr0 < 0 && dot(conicArc.R_end,conicArc.V_end)/norm(conicArc.R_end) > 0
            r_candidates(end+1) = r_p;
        end
    end

    r_min = min(r_candidates);
end