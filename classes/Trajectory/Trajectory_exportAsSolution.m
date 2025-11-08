function Trajectory_exportAsSolution(trajectory, filename)
    arguments
        trajectory Trajectory;
        filename {mustBeTextScalar};
    end

    global celestialBody_placeholder; %#ok<GVMIS>

    if isempty(trajectory.arcs)
        error("Trajectory has no arcs to export.");
    end

    arc_last = trajectory.arc_last;
    if isa(arc_last, 'TransferArc') && arc_last.hitsTarget()
        [flybyArc, ~] = produceNextArcsFromFlybyGeometry(trajectory, ...
            2, 0, 1, celestialBody_placeholder);
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
