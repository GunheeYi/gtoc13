function vector = PropagatedArc_exportLastControlsAsVector(propagatedArc, n_controls_last)
    arguments
        propagatedArc PropagatedArc;
        n_controls_last {mustBePositive, mustBeInteger};
    end

    if n_controls_last > propagatedArc.n_controls
        error('n_controls_last exceeds the number of controls.');
    end

    vector = controls_to_vector( ...
        propagatedArc.controls(end - (n_controls_last - 1) : end) ...
    );
end

function vector = controls_to_vector(controls)
    n_controls = length(controls);
    vector = nan(n_controls*2, 1);
    for i = 1:n_controls
        control = controls(i);
        vector(2*i-1) = control.alpha;
        vector(2*i) = control.beta;
    end
end
