classdef Trajectory
    properties
        arcs (:,1) cell % each cell contains either a ConicArc, PropagatedArc or FlybyArc
    end
    methods
        function trajectory = Trajectory()
        end
        function trajectory = addArc(trajectory, arc)
            arguments
                trajectory Trajectory
                arc {mustBeA(arc,["ConicArc","PropagatedArc","FlybyArc"])}
            end

            if isempty(trajectory.arcs)
                if ~isa(arc, "ConicArc") && ~isa(arc, "PropagatedArc")
                    error('The first arc must be heliocentric.');
                end
            else
                lastArc = trajectory.arcs{end};
                validateContinuity(lastArc, arc);
            end

            trajectory.arcs{end+1,1} = arc;
        end
    end
end

function validateContinuity(arc1, arc2)
    % TODO: replace to comparison by reporting digits 
    % instead of absolute tolerances?

    global tol_t tol_r tol_v; %#ok<GVMIS>

    if abs(arc1.t_end - arc2.t_start) > tol_t
        error('Time discontinuity between arcs.');
    end

    if norm(arc1.R_end - arc2.R_start) > tol_r
        error('Position discontinuity between arcs.');
    end

    if norm(arc1.V_end - arc2.V_start) > tol_v
        error('Velocity discontinuity between arcs.');
    end
end
