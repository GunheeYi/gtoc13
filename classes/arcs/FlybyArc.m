classdef FlybyArc
    properties
        t {mustBeScalarOrEmpty mustBeNonnegative}
        body CelestialBody
        V_in (3,1) {mustBeReal}
        V_out (3,1) {mustBeReal}
    end
    properties (Dependent)
        % TODO: implement setters & getters for dependent properties
        R
        V_body
        Vinf_in
        Vinf_out
        t_start
        t_end
        R_start
        R_end
        V_start
        V_end
    end
    methods
        function flybyArc = FlybyArc(t, body, V_in, V_out)
            arguments
                t {mustBeScalarOrEmpty mustBeNonnegative}
                body CelestialBody
                V_in (3,1) {mustBeReal}
                V_out (3,1) {mustBeReal}
            end

            global t_max; %#ok<GVMIS>

            if t > t_max
                error('Flyby time exceeds maximum allowed time.');
            end

            % TODO: implement validity check
            % (R_flyby within allowed range, etc.)

            flybyArc.t = t;
            flybyArc.body = body;
            flybyArc.V_in = V_in;
            flybyArc.V_out = V_out;
        end

        function R = get.R(flybyArc)
            R = flybyArc.body.R_at(flybyArc.t);
        end

        function V_body = get.V_body(flybyArc)
            V_body = flybyArc.body.V_at(flybyArc.t);
        end

        function Vinf_in = get.Vinf_in(flybyArc)
            Vinf_in = flybyArc.V_in - flybyArc.V_body;
        end

        function Vinf_out = get.Vinf_out(flybyArc)
            Vinf_out = flybyArc.V_out - flybyArc.V_body;
        end

        function t_start = get.t_start(flybyArc)
            t_start = flybyArc.t;
        end
        function t_end = get.t_end(flybyArc)
            t_end = flybyArc.t;
        end

        function R_start = get.R_start(flybyArc)
            R_start = flybyArc.R;
        end
        function R_end = get.R_end(flybyArc)
            R_end = flybyArc.R;
        end

        function V_start = get.V_start(flybyArc)
            V_start = flybyArc.V_in;
        end
        function V_end = get.V_end(flybyArc)
            V_end = flybyArc.V_out;
        end
    end
end
