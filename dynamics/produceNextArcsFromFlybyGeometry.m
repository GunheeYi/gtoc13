function [flybyArc, conicArc] = produceNextArcsFromFlybyGeometry(arc_last, r_multiple_p_flyby, angle_rotation_flyby, dt, target)
    t_flyby = arc_last.t_end;
    body_flyby = arc_last.target;
    R_flyby = arc_last.R_end;

    V_body_flyby = body_flyby.V_at(t_flyby);
    V_sc_flyby_in = arc_last.V_end;
    Vinf_in = V_sc_flyby_in - V_body_flyby;
    vinf = norm(Vinf_in);

    % two vectors below, orthogonal to each other,
    % are used to compute standard (ang_flyby = 0) Vinf_out
    Vinf_in_normed = normed(Vinf_in);
    Vinf_in_perp_normed = normed( cross( Vinf_in_normed, [0;0;1] ) );

    r_p_flyby = r_multiple_p_flyby * body_flyby.r;

    angle_turn = body_flyby.calc_angle_turn(vinf, r_p_flyby);
    Vinf_out_standard = vinf * ( ...
        cos(angle_turn)*Vinf_in_normed + sin(angle_turn)*Vinf_in_perp_normed ...
    );

    Vinf_out = make_dcm_rodrigues(Vinf_in, angle_rotation_flyby) * Vinf_out_standard;

    V_sc_flyby_out = V_body_flyby + Vinf_out;

    t_rdv = t_flyby + dt;

    flybyArc = FlybyArc(t_flyby, body_flyby, R_flyby, V_sc_flyby_in, V_sc_flyby_out);
    conicArc = ConicArc(t_flyby, R_flyby, V_sc_flyby_out, t_rdv, target);
end
