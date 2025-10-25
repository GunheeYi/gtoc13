classdef ConicArc
    properties
        t_start {mustBeScalarOrEmpty mustBeNonnegative}
        R_start (3,1) {mustBeReal}
        V_start (3,1) {mustBeReal}
        t_end {mustBeScalarOrEmpty mustBeNonnegative}
        R_end (3,1) {mustBeReal}
        V_end (3,1) {mustBeReal}
    end
    methods
        function conicArc = ConicArc(t_start, R_start, V_start, t_end, R_end, V_end)
            arguments
                t_start {mustBeScalarOrEmpty mustBeNonnegative}
                R_start (3,1) {mustBeReal}
                V_start (3,1) {mustBeReal}
                t_end {mustBeScalarOrEmpty mustBeNonnegative}
                R_end (3,1) {mustBeReal}
                V_end (3,1) {mustBeReal}
            end

            global t_max; %#ok<GVMIS>

            if t_start >= t_end
                error('Time must be increasing.');
            end

            if t_end > t_max
                error('End time exceeds maximum allowed time.');
            end

            conicArc.t_start = t_start;
            conicArc.R_start = R_start;
            conicArc.V_start = V_start;
            conicArc.t_end = t_end;
            conicArc.R_end = R_end;
            conicArc.V_end = V_end;
        end
    end
end
