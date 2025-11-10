classdef PropagatedArc < TransferArc
    properties
        controls Control;
        n_controls_tail {mustBeNonnegative, mustBeInteger} = 0;
    end
    properties (Dependent)
        n_controls {mustBePositive};
        segments; % cells that each contain an array (6xN) of cartesian states (6x1)
    end
    methods
        function propagatedArc = PropagatedArc(t_start, R_start, V_start, t_end, target)
            arguments
                t_start {mustBeNonnegative};
                R_start (3,1) {mustBeReal};
                V_start (3,1) {mustBeReal};
                t_end {mustBeNonnegative};
                target CelestialBody = CelestialBody.empty;
            end

            propagatedArc@TransferArc(t_start, R_start, V_start, t_end, target);

            n_controls = (t_end - t_start) / 60;
            n_controls = max(2, min(10, round(n_controls)));
            
            dt = (t_end - t_start) / n_controls;
            control = Control(dt, 1, pi/2 - deg2rad(1e-1), 0);
            % 0.1deg: to make initial guess be between lb and ub
            propagatedArc.controls = repmat(control, 1, n_controls);
        end

        function n_controls = get.n_controls(propagatedArc)
            n_controls = length(propagatedArc.controls);
        end

        function vector = exportLastControlsAsVector(propagatedArc, n_last)
            vector = PropagatedArc_exportLastControlsAsVector(propagatedArc, n_last);
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
            % TODO: implement
            error('Not yet implemented.');
        end
    end
    methods (Access = protected)
        function t_end = get_t_end(propagatedArc)
            t_end = propagatedArc.t_start;
            for control = propagatedArc.controls
                t_end = t_end + control.dt;
            end
        end

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
