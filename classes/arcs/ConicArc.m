classdef ConicArc
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
        function conicArc = ConicArc(t_start, R_start, V_start, t_end, target)
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

            conicArc.t_start = t_start;
            conicArc.R_start = R_start;
            conicArc.V_start = V_start;
            conicArc.t_end = t_end;
            conicArc.target = target;
        end

        % state at start
        function S_start = get.S_start(conicArc)
            S_start = [conicArc.R_start' conicArc.V_start']';
        end
        function K_start = get.K_start(conicArc)
            global mu_altaira; %#ok<GVMIS>

            K_start = S2K(conicArc.S_start, mu_altaira);
        end

        % state at end
        function K_end = get.K_end(conicArc)
            global mu_altaira; %#ok<GVMIS>

            K_end = KepMotion(conicArc.K_start, conicArc.t_end - conicArc.t_start, mu_altaira);
        end
        function S_end = get.S_end(conicArc)
            global mu_altaira; %#ok<GVMIS>
            S_end = K2S(conicArc.K_end, mu_altaira);
        end
        function R_end = get.R_end(conicArc)
            R_end = conicArc.S_end(1:3);
        end
        function V_end = get.V_end(conicArc)
            V_end = conicArc.S_end(4:6);
        end

        % draw
        function draw(conicArc, n_points, varargin)
            arguments
                conicArc ConicArc;
                n_points {mustBePositive} = 100;
            end
            arguments (Repeating)
                varargin;
            end

            global mu_altaira AU; %#ok<GVMIS>

            M_start = conicArc.K_start(6);
            M_end = conicArc.K_end(6);
            if M_end < M_start
                M_end = M_end + 2*pi;
            end

            % TODO: draw more frequently for steep arcs (near altaira)
            Ms = linspace(M_start, M_end, n_points);

            Ks = repmat(conicArc.K_start, 1, n_points);
            Ks(6, :) = Ms;
            Ss = K2S(Ks, mu_altaira);
            Rs = Ss(1:3, :);
            plot3mat( ...
                Rs / AU, varargin{:}, ...
                'DisplayName', sprintf('conic arc to %s', conicArc.target.name) ...
            );
        end
        
        function solutionRows = to_solutionRows(conicArc)
            solutionRow1 = SolutionRow( ...
                0, 0, conicArc.t_start, ...
                conicArc.R_start, conicArc.V_start, ...
                [0;0;0] ...
            );
            solutionRow2 = SolutionRow( ...
                0, 0, conicArc.t_end, ...
                conicArc.R_end, conicArc.V_end, ...
                [0;0;0] ...
            );
            solutionRows = [solutionRow1; solutionRow2];
        end
    end
end
