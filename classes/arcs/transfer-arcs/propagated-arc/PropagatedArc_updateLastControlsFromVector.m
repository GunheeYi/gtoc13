function propagatedArc = PropagatedArc_updateLastControlsFromVector(propagatedArc, vector)
    arguments
        propagatedArc PropagatedArc;
        vector (1,:) {mustBeReal};
    end

    global TU; %#ok<GVMIS>

    n_vector = length(vector);
    if mod(n_vector, 3) ~= 0
        error('Input vector length must be even (pairs of alpha, beta).');
    end

    n_controls_last = n_vector / 3;
    if n_controls_last > propagatedArc.n_controls
        error('Number of (alpha, beta) pairs exceeds the number of controls.');
    end

    % update last `n_controls_last` controls only
    i_control_start = propagatedArc.n_controls - (n_controls_last - 1);
    for i = 1:n_controls_last
        i_control = i_control_start + (i - 1);
        dt = vector(3*i-2) * TU;
        alpha = vector(3*i-1);
        beta = vector(3*i);
        control = Control(dt, alpha, beta);
        propagatedArc.controls(i_control) = control;
    end
end
