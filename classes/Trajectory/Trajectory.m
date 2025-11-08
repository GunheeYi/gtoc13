classdef Trajectory
    properties
        arcs (:,1) cell; % each cell contains either a ConicArc, PropagatedArc or FlybyArc
    end
    properties (Dependent)
        arc_last;
        t_end;
        R_end;
        n_arcs;
        flybyArcs;
        n_flybys;
        n_flybys_possible; % `n_flyby` + (last conic arc converges to target) ? 1 : 0 
        sequenceString; % e.g., "PlanetX-Rogue 1-Jotunn"
        score;
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

        function n_arcs = get.n_arcs(trajectory)
            n_arcs = numel(trajectory.arcs);
        end

        function flybyArcs = get.flybyArcs(trajectory)
            flybyArcs = FlybyArc.empty(0, 1);
            for i = 1:length(trajectory.arcs)
                arc = trajectory.arcs{i};
                if isa(arc, 'FlybyArc')
                    flybyArcs(end+1, 1) = arc; %#ok<AGROW>
                end
            end
        end

        function n_flybys = get.n_flybys(trajectory)
            n_flybys = length(trajectory.flybyArcs);
        end

        function n_flybys_possible = get.n_flybys_possible(trajectory)
            if isempty(trajectory.arcs)
                n_flybys_possible = 0;
                return;
            end
            n_flybys_possible = trajectory.n_flybys;
            if isa(trajectory.arc_last, 'TransferArc') && trajectory.arc_last.hitsTarget()
                n_flybys_possible = n_flybys_possible + 1;
            end
        end

        function sequenceString = get.sequenceString(trajectory)
            sequenceString = '';
            for i_flybyArc = 1:trajectory.n_flybys
                flybyArc = trajectory.flybyArcs(i_flybyArc);
                name = flybyArc.body.name;
                if isempty(sequenceString)
                    sequenceString = sprintf('%s', name);
                else
                    sequenceString = sprintf('%s-%s', sequenceString, name);
                end
            end
        end

        function score = get.score(trajectory)
            score = Trajectory_computeScore(trajectory);
        end

        function trajectory = addArc(trajectory, arc_new)
            trajectory = Trajectory_addArc(trajectory, arc_new);
        end

        function trajectory = startByTargeting(trajectory, target, t_start, vx_start)
            trajectory = Trajectory_startByTargeting(trajectory, target, t_start, vx_start);
        end
        
        function trajectory = flybyTargeting(trajectory, target, dt_min, dt_max, use_sails, allow_low_pass)
            arguments
                trajectory Trajectory;
                target CelestialBody;
                dt_min {mustBeNonnegative};
                dt_max {mustBeNonnegative};
                % min/maximum time after flyby to rendezvous with target [s]
                % set to 0 for no limit (hard lmit: 0 ~ (t_max - t_flyby - 1))
                use_sails logical = false;
                allow_low_pass logical = false; % under 0.05AU
            end
            trajectory = Trajectory_flybyTargeting(trajectory, target, dt_min, dt_max, use_sails, allow_low_pass);
        end

        % draw a static plot of the trajectory
        function draw(trajectory)
            Trajectory_draw(trajectory);
        end

        % draw an interactive figure of the trajectory (by Mercury)
        function fig = draw_interactive(trajectory, dt)
            arguments
                trajectory Trajectory;
                dt (1,1) {mustBeReal, mustBePositive} = 10 * 86400
            end
            fig = Trajectory_draw_interactive(trajectory, dt);
        end

        function save(trajectory, varargin)
            Trajectory_save(trajectory, varargin{:});
        end

        function trajectory = load(~, varargin)
            trajectory = Trajectory_load(varargin{:});
        end

        function trajectory = importSolution(~, filename)
            trajectory = Trajectory_importSolution(filename);
        end

        function exportAsSolution(trajectory, filename)
            Trajectory_exportAsSolution(trajectory, filename);
        end

        % TODO: implement grading
    end
end
