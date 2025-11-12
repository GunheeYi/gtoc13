function nextTargets = Trajectory_getNextTargets(trajectory, pool)
    % this function returns an array of planets 
    % (if pool is empty, it is set to all planets except yandi)
    % that are in the pool, by an order of their exploration priority.
    % Vulcan and current body of flyby is always of least priority.
    % Ones that hasn't been exlored (flyby-ed) lead in priority than those that are already explored.
    % Among same explored / not yet explored planets, those that are closer 
    % (in their natural ring-order) to the current planet of flyby
    % (`target` of last transfer arc. raise error if last arc isn't a transfer arc.)
    % has a higher priority. Planets' ring order is the same as their id.

    global planets yandi vulcan; %#ok<GVMIS>

    if isempty(trajectory.arcs)
        error('Trajectory:getNextTargets:noArc', ...
            'Cannot rank next targets because the trajectory has no arc.');
    end

    arc_last = trajectory.arc_last;
    if ~isa(arc_last, 'TransferArc')
        error('Trajectory:getNextTargets:lastArcNotTransfer', ...
            'The latest arc must be a transfer arc to determine the current flyby target.');
    end

    if isempty(pool)
        if isempty(planets)
            error('Trajectory:getNextTargets:noPlanetsLoaded', ...
                'Planets are not loaded. Call load_celestial_bodies first.');
        end
        pool = planets;
        if ~isempty(yandi)
            pool = pool(arrayfun(@(p) p.id ~= yandi.id, pool));
        end
    end

    pool = pool(:);
    if isempty(pool)
        nextTargets = pool;
        return;
    end

    if ~all(arrayfun(@(body) isa(body, 'Planet'), pool))
        error('Trajectory:getNextTargets:poolMustContainPlanets', ...
            'Next target pool must contain only planets.');
    end

    poolIds = arrayfun(@(body) body.id, pool);
    [~, uniqueIdx] = unique(poolIds, 'stable');
    pool = pool(uniqueIdx);
    poolIds = poolIds(uniqueIdx);

    if isempty(vulcan)
        vulcanMask = false(size(pool));
    else
        vulcanMask = (poolIds == vulcan.id);
    end
    vulcanSelection = pool(vulcanMask);
    pool = pool(~vulcanMask);
    poolIds = poolIds(~vulcanMask);

    flybyArcs = trajectory.flybyArcs;
    if isempty(flybyArcs)
        flybyIds = [];
    else
        flybyIds = arrayfun(@(arc) arc.body.id, flybyArcs);
    end

    currentPlanet = arc_last.target;
    currentId = currentPlanet.id;

    currentMask = (poolIds == currentId);
    currentSelection = pool(currentMask);
    pool = pool(~currentMask);
    poolIds = poolIds(~currentMask);

    exploredFlags = ismember(poolIds, flybyIds);
    ringDistances = abs(poolIds - currentId);

    priorityMatrix = [double(exploredFlags(:)) ringDistances(:) poolIds(:)];
    [~, order] = sortrows(priorityMatrix, [1 2 3]);
    pool = pool(order);

    nextTargets = [pool; vulcanSelection; currentSelection];
end
