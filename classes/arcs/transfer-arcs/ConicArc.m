classdef ConicArc < TransferArc
    % This is an arc 
    % whose start is defined by a time `t_start`
    % and cartesian state `R_start` and `V_start` at that time.
    % It follows a conic trajectory around Altaira until time `t_end`.
    % The arc does not necessarily rendezvous with the target body,
    % and the residual position at `t_end` is given by `dR_res`.
    methods
        function conicArc = ConicArc(t_start, R_start, V_start, t_end, target)
            conicArc@TransferArc(t_start, R_start, V_start, t_end, target);
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
    methods (Access = protected)
        function K_end = get_K_end(conicArc)
            global mu_altaira; %#ok<GVMIS>
            K_end = KepMotion(conicArc.K_start, conicArc.t_end - conicArc.t_start, mu_altaira);
        end
        function S_end = get_S_end(conicArc)
            global mu_altaira; %#ok<GVMIS>
            S_end = K2S(conicArc.K_end, mu_altaira);
        end
    end
end
