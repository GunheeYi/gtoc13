function Trajectory_draw(trajectory)
    arguments
        trajectory Trajectory;
    end

    global t_max celestialBody_placeholder; %#ok<GVMIS>

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

    arc_last = trajectory.arc_last;
    conicArc_projected = ConicArc( ...
        trajectory.t_end, arc_last.R_end, arc_last.V_end, t_max, ...
        celestialBody_placeholder ...
    );
    conicArc_projected.draw('--', 'DisplayName', 'conic arc, projected');

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
    view(0, 89)
end
