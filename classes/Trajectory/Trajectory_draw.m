function Trajectory_draw(trajectory, n_points_per_arc)
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
