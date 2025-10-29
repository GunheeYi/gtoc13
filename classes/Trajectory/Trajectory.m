classdef Trajectory
    properties
        arcs (:,1) cell; % each cell contains either a ConicArc, PropagatedArc or FlybyArc
    end
    properties (Dependent)
        arc_last;
        t_end;
        R_end;
        n_flybys;
    end
    methods
        function trajectory = Trajectory()
        end

        function raiseErrorIfNoArc(trajectory)
            if isempty(trajectory.arcs)
                error('There isn''t any arc in this trajectory yet.');
            end
        end

        function arc_last = get.arc_last(trajectory)
            trajectory.raiseErrorIfNoArc();
            arc_last = trajectory.arcs{end};
        end

        function t_end = get.t_end(trajectory)
            t_end = trajectory.arc_last.t_end;
        end
        function R_end = get.R_end(trajectory)
            R_end = trajectory.arc_last.R_end;
        end

        function n_flybys = get.n_flybys(trajectory)
            n_flybys = 0;
            for i = 1:length(trajectory.arcs)
                if isa(trajectory.arcs{i}, 'FlybyArc')
                    n_flybys = n_flybys + 1;
                end
            end
        end

        function trajectory = addArc(trajectory, arc_new)
            trajectory = Trajectory_addArc(trajectory, arc_new);
        end

        function trajectory = startByTargeting(trajectory, target, t_start, vx_start)
            trajectory = Trajectory_startByTargeting(trajectory, target, t_start, vx_start);
        end
        
        function trajectory = flybyTargeting(trajectory, target, dt_max)
            % trajectory = Trajectory_flybyTargeting_shooting(trajectory, target);
            trajectory = Trajectory_flybyTargeting_ga(trajectory, target, dt_max);
        end

        function draw(trajectory, n_points_per_arc)
            Trajectory_draw(trajectory, n_points_per_arc);
        end

        function exportAsSolution(trajectory, filename)
            Trajectory_exportAsSolution(trajectory, filename);
        end

        % TODO: implement grading
    end
end
