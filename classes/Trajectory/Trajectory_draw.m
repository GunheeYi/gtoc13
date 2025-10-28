function Trajectory_draw(trajectory, n_points_per_arc)
    arguments
        trajectory Trajectory;
        n_points_per_arc {mustBePositive} = 100;
    end

    figure();
    hold on;

    % plot_system(0 * year_in_secs);
    plot_system(trajectory.t_end);

    for i = 1:numel(trajectory.arcs)
        arc = trajectory.arcs{i};
        if isa(arc, "FlybyArc")
            continue; % flyby arcs are not drawn
        end
        arc.draw(n_points_per_arc, '-');
    end

    axis equal;
    grid on;
    xlabel('x [AU]');
    ylabel('y [AU]');
    zlabel('z [AU]');
    range_limit = [-200 200]; % in AUs
    xlim(range_limit);
    ylim(range_limit);
    zlim(range_limit);
    legend();
end
