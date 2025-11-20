classdef ConicArc < TransferArc
    % This is an arc 
    % whose start is defined by a time `t_start`
    % and cartesian state `R_start` and `V_start` at that time.
    % It follows a conic trajectory around Altaira until time `t_end`.
    % The arc does not necessarily rendezvous with the target body,
    % and the residual position at `t_end` is given by `dR_res`.
    properties
        t_end;
    end
    properties (Dependent)
        T % orbital period
        r_min % closest approach distance to Altaira
    end

    methods
        function conicArc = ConicArc(t_start, R_start, V_start, t_end, target)
            arguments
                t_start {mustBeNonnegative};
                R_start (3,1) {mustBeReal};
                V_start (3,1) {mustBeReal};
                t_end;
                target {mustBeA(target, 'CelestialBody')};
            end

            global t_max AU; %#ok<GVMIS>

            if t_start >= t_end
                error('Time must be increasing.');
            end

            if t_end > t_max
                error('End time exceeds maximum allowed time.');
            end
            
            conicArc@TransferArc(t_start, R_start, V_start, target);
            conicArc.t_end = t_end;

            if conicArc.passes_too_low()
                error('ConicArc:passes_too_low', ...
                    'ConicArc passes too close to Altaira (r_min = %.4fAU).', ...
                    conicArc.r_min / AU);
            end
        end

        function K = K_at(conicArc, t)
            global mu_altaira; %#ok<GVMIS>
            K = KepMotion(conicArc.K_start, t - conicArc.t_start, mu_altaira);
        end
        function S = S_at(conicArc, t)
            global mu_altaira; %#ok<GVMIS>
            K = conicArc.K_at(t);
            S = K2S(K, mu_altaira);
        end
        function R = R_at(conicArc, t)
            S = conicArc.S_at(t);
            R = S(1:3);
        end
        function V = V_at(conicArc, t)
            S = conicArc.S_at(t);
            V = S(4:6);
        end
        function v = v_at(conicArc, t)
            V = conicArc.V_at(t);
            v = norm(V);
        end

        function T = get.T(conicArc)
            global mu_altaira; %#ok<GVMIS>
            a = conicArc.K_start(1);
            e = conicArc.K_start(2);
            if e < 1
                T = 2*pi*sqrt(a^3/mu_altaira);
            else
                T = Inf;
            end
        end

        function r_min = get.r_min(conicArc)
            r_min = ConicArc_get_r_min(conicArc);
        end

        function tf = passes_too_low(conicArc)
            global AU; %#ok<GVMIS>
            try
                tf = (conicArc.r_min < 0.01 * AU);
            catch ME
                if strcmp(ME.identifier, 'KepMotion:KOE0NotReal')
                    tf = true; % TODO:think: Better way? What is the root cause of this error?
                else
                    rethrow(ME);
                end
            end
        end

        function tf = passes_low(conicArc)
            global AU; %#ok<GVMIS>
            try
                tf = (conicArc.r_min < 0.05 * AU);
            catch ME
                if strcmp(ME.identifier, 'KepMotion:KOE0NotReal')
                    tf = true; % TODO:think: Better way? What is the root cause of this error?
                else
                    rethrow(ME);
                end
            end
        end

        function closeApproach = getCloseApproachTo(conicArc, body)
            arguments
                conicArc ConicArc;
                body;
            end
            closeApproach = ConicArc_getCloseApproachTo(conicArc, body);
        end

        function closeApproaches = getCloseApproaches(conicArc, pool)
            closeApproaches = ConicArc_getCloseApproaches(conicArc, pool);
        end

        % draw
        function draw(conicArc, varargin)
            arguments
                conicArc ConicArc;
            end
            arguments (Repeating)
                varargin;
            end

            global mu_altaira AU; %#ok<GVMIS>

            S0 = K2S(conicArc.K_start, mu_altaira);
            Sdot = @(~, S) two_body_dynamics(S, mu_altaira);
            tspan = [conicArc.t_start, conicArc.t_end];
            [~, Ss] = ode45(Sdot, tspan, S0);
            Ss = Ss';
            Rs = Ss(1:3, :);

            plot3mat( ...
                Rs / AU, varargin{1}, ...
                'DisplayName', sprintf('conic arc to %s', conicArc.target.name), ...
                varargin{2:end} ...
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
    methods (Access = protected)
        function K_end = get_K_end(conicArc)
            K_end = conicArc.K_at(conicArc.t_end);
        end
        function S_end = get_S_end(conicArc)
            S_end = conicArc.S_at(conicArc.t_end);
        end
    end
end
