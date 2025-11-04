classdef Control
    properties
        dt {mustBeNonnegative}
        alpha
        beta
    end
    methods
        function control = Control(dt, alpha, beta)
            arguments
                dt {mustBeNonnegative}
                alpha
                beta
            end

            mustBeBetween(alpha, 0, pi/2);
            mustBeBetween(beta, -pi, pi);

            control.dt = dt;
            control.alpha = alpha;
            control.beta = beta;
        end
    end
end
