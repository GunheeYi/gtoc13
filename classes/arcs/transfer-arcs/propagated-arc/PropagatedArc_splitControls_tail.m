function propagatedArc = ...
    PropagatedArc_splitControls_tail(propagatedArc, n_controls_tail)
    arguments
        propagatedArc PropagatedArc;
        n_controls_tail {mustBeNonnegative, mustBeInteger};
    end

    if n_controls_tail > propagatedArc.n_controls
        error('n_controls_tail must be less than total number of controls.');
    end

    n_controls_head = propagatedArc.n_controls - n_controls_tail;
    controls_head = propagatedArc.controls(1:n_controls_head);
    controls_tail = propagatedArc.controls(n_controls_head+1:end);

    controls_tail_split = [];
    for control = controls_tail
        n_split = control.dt / 60;
        n_split = max(1, min(4, round(n_split)));
        dt_split = control.dt / n_split;
        for i = 1:n_split
            control_split = Control(dt_split, control.dt_scaling_factor, control.alpha, control.beta);
            controls_tail_split = [controls_tail_split, control_split]; %#ok<AGROW>
        end
    end

    propagatedArc.controls = [controls_head, controls_tail_split];
    propagatedArc.n_controls_tail = length(controls_tail_split);
end
