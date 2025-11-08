function rankSearchResults(dirpath)
    % Rank all trajectory.mat files under the provided directory by score.
    arguments
        dirpath {mustBeTextScalar}
    end

    global year_in_secs;

    dirpath = string(dirpath);
    if ~isfolder(dirpath)
        error('rankResults:InvalidDirectory', 'Directory not found: %s', dirpath);
    end

    trajectoryFiles = collectTrajectoryFiles(dirpath);
    nTrajectories = numel(trajectoryFiles);

    outputLines = strings(0, 1);
    outputLines(end + 1) = sprintf('Directory: %s', dirpath);
    outputLines(end + 1) = sprintf('Total trajectories: %d', nTrajectories);

    if nTrajectories == 0
        writeOutput(outputLines, dirpath);
        return;
    end

    results = repmat(struct('filepath', "", 'score', NaN, 'tEnd', NaN), nTrajectories, 1);
    for iFile = 1:nTrajectories
        filepath = trajectoryFiles(iFile);
        results(iFile).filepath = filepath;
        try
            trajectory = loadTrajectoryFromFullPath(filepath);
            results(iFile).score = trajectory.score;
            results(iFile).t_end_in_years = trajectory.t_end / year_in_secs;
        catch ME
            warning('rankResults:EvaluationFailed', ...
                'Failed to evaluate %s: %s', filepath, ME.message);
        end
    end

    isValid = ~isnan([results.score]);
    if ~any(isValid)
        outputLines(end + 1) = 'No valid trajectories to rank.';
        writeOutput(outputLines, dirpath);
        return;
    end

    results = results(isValid);
    scores = [results.score];
    [scoresSorted, order] = sort(scores, 'descend');
    resultsSorted = results(order);

    topCount = min(100, numel(resultsSorted));
    outputLines(end + 1) = sprintf('Top %d trajectories:', topCount);
    for rankIdx = 1:topCount
        outputLines(end + 1) = sprintf('%3d. (t = %.2fyrs, score = %.2f) %s', ...
            rankIdx, resultsSorted(rankIdx).t_end_in_years, scoresSorted(rankIdx), ...
            resultsSorted(rankIdx).filepath); %#ok<AGROW>
    end

    writeOutput(outputLines, dirpath);
end

function trajectoryFiles = collectTrajectoryFiles(rootDir)
    items = dir(rootDir);
    trajectoryFiles = strings(0, 1);
    for item = items.'
        if item.isdir
            if strcmp(item.name, '.') || strcmp(item.name, '..')
                continue;
            end
            trajectoryFiles = [trajectoryFiles; ...
                collectTrajectoryFiles(fullfile(rootDir, item.name))]; %#ok<AGROW>
        elseif strcmp(item.name, 'trajectory.mat')
            trajectoryFiles(end + 1, 1) = string(fullfile(rootDir, item.name)); %#ok<AGROW>
        end
    end
end

function trajectory = loadTrajectoryFromFullPath(fullpath)
    segments = split(string(fullpath), filesep);
    idx = find(segments == "trajectories", 1);
    if isempty(idx)
        error('rankResults:InvalidFilepath', ...
            'Trajectory file must be inside the trajectories directory.');
    end
    relativePath = strjoin(segments(idx + 1:end), '/');
    trajectory = Trajectory();
    trajectory = trajectory.load(relativePath);
end

function writeOutput(lines, dirpath)
    for line = lines.'
        fprintf('%s\n', line);
    end
    rankFile = fullfile(dirpath, 'rank.txt');
    fid = fopen(rankFile, 'w');
    if fid == -1
        error('rankResults:CannotWriteRankFile', ...
            'Unable to open %s for writing.', rankFile);
    end
    cleaner = onCleanup(@() fclose(fid));
    for line = lines.'
        fprintf(fid, '%s\n', line);
    end
    clear cleaner; %#ok<CLSCR>
end
