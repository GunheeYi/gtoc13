function propagatedArc = PropagatedArc_updateLastControlsFromVector(propagatedArc, vector)
    arguments
        propagatedArc PropagatedArc;
        vector (1,:) {mustBeReal};
    end

    global t_max;

    n_vector = length(vector);
    if mod((n_vector-1), 2) ~= 0 % except `global_dt_scaling_factor` at the end
        error('Input vector length must be even (pairs of alpha, beta).');
    end

    n_controls_last = (n_vector-1) / 2;
    if n_controls_last > propagatedArc.n_controls
        error('Number of (alpha, beta) pairs exceeds the number of controls.');
    end

    % update last `n_controls_last` controls only
    i_control_start = propagatedArc.n_controls - (n_controls_last - 1);
    dt_scaling_factor = vector(end);
    for i = 1:n_controls_last
        i_control = i_control_start + (i - 1);
        control = propagatedArc.controls(i_control);
        control.dt_scaling_factor = dt_scaling_factor; % keep the same dt and only update its scaling factor
        control.alpha = vector(2*i-1); % first two values in vector are flyby geometries
        control.beta = vector(2*i);
        propagatedArc.controls(i_control) = control;
    end

    if propagatedArc.t_end > t_max
        error('End time exceeds maximum allowed time.');
    end
end
