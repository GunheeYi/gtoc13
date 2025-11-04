function propagatedArc = PropagatedArc_updateLastControlsFromVector(propagatedArc, vector)
    arguments
        propagatedArc PropagatedArc;
        vector (1,:) {mustBeReal};
    end

    n_vector = length(vector);
    if mod(n_vector, 2) ~= 0
        error('Input vector length must be even (pairs of alpha, beta).');
    end

    n_controls_last = n_vector / 2;
    if n_controls_last > propagatedArc.n_controls
        error('Number of (alpha, beta) pairs exceeds the number of controls.');
    end

    % update last `n_controls_last` controls only
    i_control_start = propagatedArc.n_controls - (n_controls_last - 1);
    for i = 1:n_controls_last
        i_control = i_control_start + (i - 1);
        control = propagatedArc.controls(i_control);
        control.alpha = vector(2*i-1);
        control.beta = vector(2*i);
        propagatedArc.controls(i_control) = control;
    end
end
