function Trajectory_draw(trajectory)
    arguments
        trajectory Trajectory;
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
        arc.draw('-');
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
