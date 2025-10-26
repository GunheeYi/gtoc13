classdef Trajectory
    properties
        arcs (:,1) cell; % each cell contains either a ConicArc, PropagatedArc or FlybyArc
    end
    properties (Dependent)
        arc_last;
        t_end;
        R_end;
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

        function trajectory = addArc(trajectory, arc_new)
            arguments
                trajectory Trajectory;
                arc_new {mustBeA(arc_new,["ConicArc","PropagatedArc","FlybyArc"])};
            end

            if isempty(trajectory.arcs)
                if ~isa(arc_new, "ConicArc") && ~isa(arc_new, "PropagatedArc")
                    error('The first arc must be heliocentric.');
                end
            else
                Trajectory_addArc_validateContinuity(trajectory.arc_last, arc_new);
            end

            trajectory.arcs{end+1,1} = arc_new;
        end

        function trajectory = startByTargeting(trajectory, target, t_start, vx_start)
            arguments
                trajectory Trajectory;
                target CelestialBody;
                t_start {mustBeNonnegative};
                vx_start {mustBePositive};
            end

            global year_in_secs AU t_max; %#ok<GVMIS>

            if ~isempty(trajectory.arcs)
                error('startByTargeting can only be called on an empty trajectory.');
            end

            t_rendezvous = 6 * year_in_secs;
            ry_start = 10 * AU;
            rz_start = 5 * AU;
            % note: When rx/rz_start are too small(about 1~2AU), 
            % optimization may fail to converge.
            % Don't know exactly why. 
            % Maybe because it leads to extreme values in K?

            % TODO: initial guesses taylored for PlanetX;
            % change based on target?

            x0 = [t_rendezvous ry_start rz_start];
            lb = [t_start+1 -200*AU -200*AU];
            ub = [t_max 200*AU 200*AU];

            opts = optimoptions('lsqnonlin', ...
                'Display','iter-detailed', ...
                'Algorithm','levenberg-marquardt', ...
                'FunctionTolerance',1e-12, ...
                'StepTolerance',1e-12, ...
                'MaxFunctionEvaluations',1e10, ...
                'ScaleProblem','jacobian' ...
            );

            [x, ~, ~, exitflag, ~] = lsqnonlin( ...
                @(x) Trajectory_startByTargeting_calculatePositionError(target, t_start, vx_start, x), ...
                x0, lb, ub, opts ...
            );
            
            if exitflag <= 0
                error('Trajectory.startByTargeting optimization did not converge.');
            end

            t_rendezvous = x(1);
            ry_start = x(2);
            rz_start = x(3);

            R_sc_start = [ -200*AU; ry_start; rz_start ];
            V_sc_start = [ vx_start; 0; 0 ];
            conicArc = ConicArc(t_start, R_sc_start, V_sc_start, t_rendezvous, target);

            trajectory = trajectory.addArc(conicArc);
        end
        
        function trajectory = flybyTargeting(trajectory, target)
            trajectory = Trajectory_flybyTargeting(trajectory, target);
        end

        function draw(trajectory, n_points_per_arc)
            arguments
                trajectory Trajectory;
                n_points_per_arc {mustBePositive} = 100;
            end

            for i = 1:numel(trajectory.arcs)
                arc = trajectory.arcs{i};
                if isa(arc, "FlybyArc")
                    continue; % flyby arcs are not drawn
                end
                arc.draw(n_points_per_arc, '-');
            end
        end

        function exportAsSolution(trajectory, filename)
            arguments
                trajectory Trajectory;
                filename {mustBeTextScalar};
            end

            Trajectory_exportAsSolution(trajectory, filename);
        end

        % TODO: implement grading
    end
end
