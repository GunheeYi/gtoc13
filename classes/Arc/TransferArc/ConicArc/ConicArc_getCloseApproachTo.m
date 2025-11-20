function closeApproach = ConicArc_getCloseApproachTo(conicArc, body)
    T_sc = conicArc.T;
    T_body = body.T;
    if xor(conicArc.isProgradeAtEnd, body.isPrograde)
        T_body = - T_body;
    end
    recip_T_synodic = abs(1/T_sc - 1/T_body);
    T_synodic = 1/recip_T_synodic;

    ts_sample = conicArc.t_start : T_synodic : conicArc.t_end;

    t_min = NaN;
    r_min = Inf;

    function [t, r] = getCloseApproachWithin(t_lb, t_ub)
        get_dr_at = @(t) norm( conicArc.R_at(t) - body.R_at(t) );
        [t, r] = fminbnd(get_dr_at, t_lb, t_ub);
    end

    function inquireWithinAndUpdateIfNeeded(t_lb, t_ub)
        [t, r] = getCloseApproachWithin(t_lb, t_ub);
        if r < r_min
            t_min = t;
            r_min = r;
        end
    end
    
    for i_t = 1:(length(ts_sample) - 1)
        t_lb = ts_sample(i_t);
        t_ub = ts_sample(i_t+1);
        inquireWithinAndUpdateIfNeeded(t_lb, t_ub);
    end

    if ts_sample(end) < conicArc.t_end % last segment
        t_lb = ts_sample(end);
        t_ub = conicArc.t_end;
        inquireWithinAndUpdateIfNeeded(t_lb, t_ub);
    end

    closeApproach = CloseApproach(body, t_min, r_min);
end
