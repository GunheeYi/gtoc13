classdef PropagatedArc < TransferArc
    properties
        controls Control;
        n_controls_tail {mustBeNonnegative, mustBeInteger} = 0;
        t_end_; % `t_end` of `conicArc` that was used to construct this `propagatedArc`;
                % this differes from the actual `t_end` of this arc.
    end
    properties (Dependent)
        n_controls {mustBePositive};
        segments; % cells that each contain an array (6xN) of cartesian states (6x1)
        t_end;
    end
    methods
        function propagatedArc = PropagatedArc(conicArc)
            arguments
                conicArc ConicArc;
            end

            propagatedArc@TransferArc(conicArc.t_start, conicArc.R_start, conicArc.V_start, conicArc.target);
            
            dt_full = conicArc.t_end - conicArc.t_start;
            n_controls = dt_full / 60;
            n_controls = max(2, min(10, round(n_controls)));
            
            ts = linspace(conicArc.t_start, conicArc.t_end, n_controls+1);
            ts = ts(1:(end-1)) + dt_full / (n_controls * 2); % for curvature mimicry sampling
            vs = arrayfun(@conicArc.v_at, ts);
            % curvatures: not actual curvatures but a mimicry of them
            % TODO: adjust exponent based on heuristics
            curvatures = vs.^2;
            recips_curvature = 1 ./ curvatures;
            recips_curvature = recips_curvature ./ sum(recips_curvature); % normalize so that the sum becomes 1
            dts_control = recips_curvature * dt_full;

            propagatedArc.controls = createArray(1, n_controls, FillValue=Control(1,1,0,0));
            for i_control = 1:n_controls
                dt_control = dts_control(i_control);
                control = Control(dt_control, 1, pi/2 - deg2rad(1e-1), 0);
                propagatedArc.controls(i_control) = control;
            end

            propagatedArc.t_end_ = conicArc.t_end;
        end

        function n_controls = get.n_controls(propagatedArc)
            n_controls = length(propagatedArc.controls);
        end

        function t_end = get.t_end(propagatedArc)
            t_end = propagatedArc.t_start;
            for control = propagatedArc.controls
                t_end = t_end + control.dt_scaling_factor * control.dt;
            end
        end

        function propagatedArc = updateLastControlsFromVector(propagatedArc, vector)
            propagatedArc = PropagatedArc_updateLastControlsFromVector( ...
                propagatedArc, vector ...
            );
        end

        function propagatedArc = splitControls_tail(propagatedArc, n_controls_tail)
            propagatedArc = ...
                PropagatedArc_splitControls_tail(propagatedArc, n_controls_tail);
        end

        function Ss = get.segments(propagatedArc)
            Ss = PropagatedArc_get_segments(propagatedArc);
        end

        function draw(propagatedArc, varargin)
            arguments
                propagatedArc PropagatedArc;
            end
            arguments (Repeating)
                varargin;
            end

            global AU; %#ok<GVMIS>

            for i_segment = 1:numel(propagatedArc.segments)
                Ss = propagatedArc.segments{i_segment};
                Rs = Ss(1:3, :);
                plot3mat( ...
                    Rs / AU, varargin{1}, ...
                    'DisplayName', sprintf('prop arc to %s (%d)', propagatedArc.target.name, i_segment), ...
                    varargin{2:end} ...
                );
            end
        end

        function solutionRows = to_solutionRows(propagatedArc)
            t = propagatedArc.t_start;
            solutionRows = [];

            for i = 1:propagatedArc.n_controls
                Ss = propagatedArc.segments{i};
                S_start = Ss(:, 1);
                S_end = Ss(:, end);
                control = propagatedArc.controls(i);
                N = calc_sail_normal(S_start, control);

                solutionRow1 = SolutionRow(0, 1, t, S_start(1:3), S_start(4:6), N);
                t = t + control.dt_scaled;
                solutionRow2 = SolutionRow(0, 1, t, S_end(1:3), S_end(4:6), N);
                solutionRows = [solutionRows; solutionRow1; solutionRow2]; %#ok<AGROW>
            end
        end
    end
    methods (Access = protected)
        function S_end = get_S_end(propagatedArc)
            Ss = propagatedArc.segments{end};
            S_end = Ss(:, end);
        end

        function K_end = get_K_end(propagatedArc)
            global mu_altaira; %#ok<GVMIS>
            K_end = K2S(propagatedArc.S_end, mu_altaira);
        end
    end
end
