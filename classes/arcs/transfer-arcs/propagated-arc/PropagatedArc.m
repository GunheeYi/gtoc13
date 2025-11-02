classdef PropagatedArc < TransferArc
    methods
        function propagatedArc = PropagatedArc(t_start, R_start, V_start, t_end, target)
            propagatedArc@TransferArc(t_start, R_start, V_start, t_end, target);
        end

        function draw(propagatedArc, n_points, varargin)
            arguments
                propagatedArc PropagatedArc; %#ok<INUSA>
                n_points {mustBePositive} = 100; %#ok<INUSA>
            end
            arguments (Repeating)
                varargin;
            end
            % TODO: implement
            error('Not yet implemented.');
        end

        function solutionRows = to_solutionRows(propagatedArc)
            % TODO: implement
            error('Not yet implemented.');
        end
    end
    methods (Access = protected)
        function K_end = get_K_end(conicArc)
            global mu_altaira; %#ok<GVMIS>
            % TODO: implement
            error('Not yet implemented.');
        end
    end
end
