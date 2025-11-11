classdef Control
    properties
        dt {mustBePositive}
        dt_scaling_factor {mustBePositive} % to allow global scaling of dt during optimization
        alpha
        beta
    end
    properties (Dependent)
        dt_scaled
    end
    methods
        function control = Control(dt, dt_scaling_factor, alpha, beta)
            arguments
                dt {mustBeNonnegative}
                dt_scaling_factor {mustBePositive}
                alpha
                beta
            end

            mustBeBetween(alpha, 0, pi/2);
            mustBeBetween(beta, -pi, pi);

            control.dt = dt;
            control.dt_scaling_factor = dt_scaling_factor;
            control.alpha = alpha;
            control.beta = beta;
        end
        function dt_scaled = get.dt_scaled(control)
            dt_scaled = control.dt * control.dt_scaling_factor;
        end
    end
end
