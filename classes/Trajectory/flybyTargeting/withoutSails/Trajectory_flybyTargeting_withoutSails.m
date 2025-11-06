function [flybyArc, conicArc] = Trajectory_flybyTargeting_withoutSails(trajectory, target, dt_min, dt_max)
    [flybyArc, conicArc] = Trajectory_flybyTargeting_withoutSails_ga(trajectory, target, dt_min, dt_max); % by Jaewoo
    % [flybyArc, conicArc] = Trajectory_flybyTargeting_withoutSails_lambert(trajectory, target, dt_min, dt_max); % by Jinsung
end
