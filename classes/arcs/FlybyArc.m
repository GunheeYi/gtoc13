classdef FlybyArc
    properties
        t {mustBeNonnegative};
        body CelestialBody;
        R_sc (3,1) {mustBeReal}; 
            % Position of spacecraft at flyby time.
            % Storing this separately because no matter how deliberately the propagation is done,
            % the final propagated position may not exactly match with the body's ephemeris position 
            % due to numerical errors. This property will be only used for output purposes.
        V_in (3,1) {mustBeReal};
        V_out (3,1) {mustBeReal};
    end
    properties (Dependent)
        R
        V_body
        Vinf_in
        Vinf_out
        vinf
        t_start
        t_end
        R_start
        R_end
        V_start
        V_end
    end
    methods
        function flybyArc = FlybyArc(t, body, R_sc, V_in, V_out)
            arguments
                t {mustBeNonnegative};
                body CelestialBody;
                R_sc (3,1) {mustBeReal};
                V_in (3,1) {mustBeReal};
                V_out (3,1) {mustBeReal};
            end

            global t_max; %#ok<GVMIS>

            if t > t_max
                error('Flyby time exceeds maximum allowed time.');
            end

            % TODO: implement validity check
            % (R_flyby within allowed range, etc.)

            flybyArc.t = t;
            flybyArc.body = body;
            flybyArc.R_sc = R_sc;
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

        function vinf = get.vinf(flybyArc)
            vinf = norm(flybyArc.Vinf_in);
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

        function solutionRows = to_solutionRows(flybyArc)
            solutionRow1 = SolutionRow( ...
                flybyArc.body.id, 1, flybyArc.t_start, ...
                flybyArc.R_sc, flybyArc.V_start, ...
                flybyArc.Vinf_in ...
            );
            solutionRow2 = SolutionRow( ...
                flybyArc.body.id, 1, flybyArc.t_end, ...
                flybyArc.R_sc, flybyArc.V_end, ...
                flybyArc.Vinf_out ...
            );
            solutionRows = [solutionRow1; solutionRow2];
        end
    end
end
