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
                Trajectory_addArc_validateContinuity(lastArc, arc);
            end

            trajectory.arcs{end+1,1} = arc;
        end

        function trajectory = startByTargeting(trajectory, target, t_start, vx_start)
            arguments
                trajectory Trajectory
                target CelestialBody
                t_start (1,1) {mustBeNonnegative}
                vx_start (1,1) {mustBePositive}
            end

            global year_in_secs AU; %#ok<GVMIS>

            if ~isempty(trajectory.arcs)
                error('startByTargeting can only be called on an empty trajectory.');
            end

            t_rendezvous = 6 * year_in_secs;
            ry_start = 1 * AU;
            rz_start = 2 * AU;

            x0 = [t_rendezvous ry_start rz_start];
            lb = [t_start -inf -inf];
            ub = [200*year_in_secs inf inf];

            lsqnonlin_options = optimoptions('lsqnonlin', ...
                'Display','iter-detailed', ...
                'Algorithm','levenberg-marquardt', ...
                'FunctionTolerance',1e-12, ...
                'StepTolerance',1e-12, ...
                'MaxFunctionEvaluations',1e10, ...
                'ScaleProblem','jacobian' ...
            );

            [x, ~, ~, exitflag, ~] = lsqnonlin( ...
                @(x) Trajectory_startByTargeting_calculatePositionError(target, t_start, vx_start, x), ...
                x0, lb, ub, lsqnonlin_options ...
            );
            
            if exitflag <= 0
                error('Trajectory.startByTargeting optimization did not converge.');
            end

            t_rendezvous = x(1);
            ry_start = x(2);
            rz_start = x(3);

            R_sc_start = [ -200*AU; ry_start; rz_start ];
            V_sc_start = [ vx_start; 0; 0 ];
            conicArc = ConicArc(t_start, R_sc_start, V_sc_start, t_rendezvous);

            trajectory = trajectory.addArc(conicArc);
        end
        
        function draw(trajectory, n_points_per_arc)
            arguments
                trajectory Trajectory
                n_points_per_arc (1,1) {mustBePositive} = 100
            end

            for i = 1:numel(trajectory.arcs)
                arc = trajectory.arcs{i};
                if isa(arc, "FlybyArc")
                    continue; % flyby arcs are not drawn
                end
                arc.draw(n_points_per_arc);
            end
        end
    end
end
