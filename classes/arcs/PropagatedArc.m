classdef PropagatedArc
    properties
        ts (1,:) {mustBeNonnegative}
        Rs (3,:) {mustBeReal}
        Vs (3,:) {mustBeReal}
        Cs (3,:) {mustBeReal} % controls
    end
    properties (Dependent)
        t_start
        t_end
        R_start
        R_end
        V_start
        V_end
    end
    methods
        function propagatedArc = PropagatedArc(ts, Rs, Vs, Cs)
            arguments
                ts (1,:) {mustBeNonnegative}
                Rs (3,:) {mustBeReal}
                Vs (3,:) {mustBeReal}
                Cs (3,:) {mustBeReal}
            end

            n = length(ts);
            if n < 2
                error('At least two rows are required per arc.');
            end

            if size(Rs,2) ~= n || size(Vs,2) ~= n || size(Cs,2) ~= n
                error('Size of Rs, Vs, and Cs must match length of ts.');
            end

            for i = 2:n
                t1 = ts(i-1);
                t2 = ts(i);
                if t1 >= t2
                    error('Time must be increasing.');
                end
                if t2 - t1 < 60
                    error('Minimum time step is 60 seconds.');
                end
            end

            global t_max; %#ok<GVMIS>
            if ts(n) > t_max
                error('End time exceeds maximum allowed time.');
            end

            propagatedArc.ts = ts;
            propagatedArc.Rs = Rs;
            propagatedArc.Vs = Vs;
            propagatedArc.Cs = Cs;
        end

        function t_start = get.t_start(propagatedArc)
            t_start = propagatedArc.ts(1);
        end
        function t_end = get.t_end(propagatedArc)
            t_end = propagatedArc.ts(end);
        end

        function R_start = get.R_start(propagatedArc)
            R_start = propagatedArc.Rs(:,1);
        end
        function R_end = get.R_end(propagatedArc)
            R_end = propagatedArc.Rs(:,end);
        end

        function V_start = get.V_start(propagatedArc)
            V_start = propagatedArc.Vs(:,1);
        end
        function V_end = get.V_end(propagatedArc)
            V_end = propagatedArc.Vs(:,end);
        end
    end
end
