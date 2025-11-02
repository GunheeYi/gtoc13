classdef ConicArc < TransferArc
    methods
        function conicArc = ConicArc(t_start, R_start, V_start, t_end, target)
            conicArc@TransferArc(t_start, R_start, V_start, t_end, target);
        end

        % state at end
        function K_end = get_K_end(conicArc)
            global mu_altaira; %#ok<GVMIS>

            K_end = KepMotion(conicArc.K_start, conicArc.t_end - conicArc.t_start, mu_altaira);
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
