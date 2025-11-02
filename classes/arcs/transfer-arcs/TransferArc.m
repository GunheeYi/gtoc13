classdef (Abstract) TransferArc
    properties
        t_start {mustBeNonnegative};
        R_start (3,1) {mustBeReal};
        V_start (3,1) {mustBeReal};
        t_end {mustBeNonnegative};
        target CelestialBody;
    end
    properties (Dependent)
        S_start (6,1) {mustBeReal};
        K_start (6,1) {mustBeReal};
        S_end (6,1) {mustBeReal};
        K_end (6,1) {mustBeReal};
        R_end (3,1) {mustBeReal};
        V_end (3,1) {mustBeReal};
    end
    methods
        function transferArc = TransferArc(t_start, R_start, V_start, t_end, target)
            arguments
                t_start {mustBeNonnegative};
                R_start (3,1) {mustBeReal};
                V_start (3,1) {mustBeReal};
                t_end {mustBeNonnegative};
                target CelestialBody = CelestialBody.empty;
            end

            global t_max; %#ok<GVMIS>

            if t_start >= t_end
                error('Time must be increasing.');
            end

            if t_end > t_max
                error('End time exceeds maximum allowed time.');
            end

            transferArc.t_start = t_start;
            transferArc.R_start = R_start;
            transferArc.V_start = V_start;
            transferArc.t_end = t_end;
            transferArc.target = target;
        end

        % state at start
        function S_start = get.S_start(transferArc)
            S_start = [transferArc.R_start' transferArc.V_start']';
        end
        function K_start = get.K_start(transferArc)
            global mu_altaira; %#ok<GVMIS>
            K_start = S2K(transferArc.S_start, mu_altaira);
        end

        % state at end
        function K_end = get.K_end(transferArc)
            K_end = transferArc.get_K_end();
        end
        function S_end = get.S_end(transferArc)
            global mu_altaira; %#ok<GVMIS>
            S_end = K2S(transferArc.K_end, mu_altaira);
        end
        function R_end = get.R_end(transferArc)
            R_end = transferArc.S_end(1:3);
        end
        function V_end = get.V_end(transferArc)
            V_end = transferArc.S_end(4:6);
        end
    end

    methods (Abstract, Access = protected)
        K_end = get_K_end(transferArc)
        draw(transferArc, n_points, varargin) % draw
        solutionRows = to_solutionRows(conicArc)
    end
end
