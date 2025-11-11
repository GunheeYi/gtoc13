function Trajectory_exportAsSolution(trajectory, filename, wrapUp)
    if isempty(trajectory.arcs)
        error("Trajectory has no arcs to export.");
    end

    if wrapUp
        trajectory = trajectory.appendFinalFlybyIfPossible();
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
