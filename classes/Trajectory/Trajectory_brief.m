function Trajectory_brief(trajectory)
    arguments
        trajectory Trajectory;
    end

    if isempty(trajectory.arcs)
        error("Trajectory has no arcs to brief.");
    end

    trajectory = trajectory.appendFinalFlybyIfPossible();

    global year_in_secs day_in_secs; %#ok<GVMIS>

    fprintf('[[Trajectory Briefing]]\n\n');
    fprintf('[Overview]\n');

    fprintf('score = %.2f\n', trajectory.score);

    sequenceString = char(trajectory.sequenceString);
    if isempty(sequenceString)
        sequenceString = '(none)';
    end
    fprintf('visiting order: %s\n', sequenceString);

    t_start_years = trajectory.t_start / year_in_secs;
    t_start_days = trajectory.t_start / day_in_secs;
    fprintf('t_start = %.2fyrs (%.0fdays)\n', t_start_years, t_start_days);

    fprintf('Vx = %.10fkm/s\n', trajectory.V_start(1));

    fprintf('\n');
    fprintf('[Sequence]\n');

    for i = 1:numel(trajectory.arcs)
        arc = trajectory.arcs{i};
        arcSummary = describeArc(arc, year_in_secs, day_in_secs);
        fprintf('(seq%02d) %s\n', i, arcSummary);
    end
end

function arcSummary = describeArc(arc, year_in_secs, day_in_secs)
    % emit concise description per arc type for the briefing output
    if isa(arc, 'FlybyArc')
        bodyName = char(arc.body.name);
        if strlength(bodyName) == 0
            bodyName = 'unknown';
        end
        arcSummary = sprintf('%s flyby @ t = %.2fyrs, F = %.2f (vinf = %.2fkm/s)', ...
            bodyName, arc.t / year_in_secs, calc_F(arc.vinf), arc.vinf);
        return;
    end

    if isa(arc, 'TransferArc')
        dt = arc.t_end - arc.t_start;
        dt_years = dt / year_in_secs;
        dt_days = dt / day_in_secs;

        if isa(arc, 'PropagatedArc')
            arcSummary = sprintf('controlled coast for %.2fyrs (%.0fdays)', dt_years, dt_days);
        else
            arcSummary = sprintf('free coast for %.2fyrs (%.0fdays)', dt_years, dt_days);
        end
        return;
    end

    arcSummary = sprintf('%s arc', class(arc));
end
