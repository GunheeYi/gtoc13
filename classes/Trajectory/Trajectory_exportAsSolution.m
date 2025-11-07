function Trajectory_exportAsSolution(trajectory, filename)
    arguments
        trajectory Trajectory;
        filename {mustBeTextScalar};
    end

    if isempty(trajectory.arcs)
        error("Trajectory has no arcs to export.");
    end

    arc_last = trajectory.arc_last;
    if isa(arc_last, 'TransferArc') && arc_last.hitsTarget()
        t = arc_last.t_end;
        body = arc_last.target;
        R = arc_last.R_end;
        V = arc_last.V_end;
        flybyArc = FlybyArc(t, body, R, V, V);
        trajectory = trajectory.addArc(flybyArc);
    end

    s = "";

    for i = 1:numel(trajectory.arcs)
        arc = trajectory.arcs{i};
        solutionRows = arc.to_solutionRows();
        n = numel(solutionRows);
        for j = 1:n
            solutionRow = solutionRows(j);
            s = s + solutionRow.toString();
        end
    end

    fid = fopen("solutions/" + filename, 'w');
    fwrite(fid, s);
    fclose(fid);
end
