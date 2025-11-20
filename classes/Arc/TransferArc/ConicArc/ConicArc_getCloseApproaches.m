function closeApproaches = ConicArc_getCloseApproaches(conicArc, pool)
    arguments
        conicArc ConicArc;
        pool cell;
    end

    if isempty(pool)
        closeApproaches = CloseApproach.empty(0, 1);
        return;
    end

    n_bodies = numel(pool);
    closeApproachCell = cell(n_bodies, 1);
    for i_body = 1:n_bodies
        body = pool{i_body};
        if ~isa(body, 'CelestialBody')
            error('ConicArc:InvalidPoolEntry', ...
                'Pool entries must be CelestialBody instances.');
        end
        closeApproachCell{i_body} = conicArc.getCloseApproachTo(body);
    end

    closeApproaches = vertcat(closeApproachCell{:});
    if isempty(closeApproaches)
        return;
    end

    [~, indices_sort] = sort([closeApproaches.r]);
    n_return = min(5, numel(indices_sort));
    closeApproaches = closeApproaches(indices_sort(1:n_return));
end
