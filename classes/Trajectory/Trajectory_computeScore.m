function score = Trajectory_computeScore(trajectory)
    arguments
        trajectory Trajectory;
    end

    score = 0;

    flybyArcsMap_byBodyIds = make_flybyArcsMap_byBodyIds(trajectory);
    bodyIds = keys(flybyArcsMap_byBodyIds);

    for i_body = 1:length(bodyIds)
        bodyId = bodyIds{i_body};
        flybyArcsForThisBody = flybyArcsMap_byBodyIds(bodyId);
        n_flybys = length(flybyArcsForThisBody);
        sum_SF = 0;
        for i_flyby_current = 1:n_flybys
            flybyArc_current = flybyArcsForThisBody(i_flyby_current);
            if i_flyby_current == 1
                S = 1;
            else
                denominator_S = 1;
                for i_flyby_previous = 1:(i_flyby_current-1)
                    flybyArc_previous = flybyArcsForThisBody(i_flyby_previous);
                    r_normed_current = normed(flybyArc_current.R_sc);
                    r_normed_previous = normed(flybyArc_previous.R_sc);
                    acd = acosd(dot(r_normed_current, r_normed_previous));
                    denominator_S = denominator_S + 10 * exp(-acd^2/50);
                end
                S = 0.1 + 0.9 / (1 + denominator_S); % seasonal penalty
            end
            F = calc_F(flybyArc_current.vinf); % flyby velocity penalty
            sum_SF = sum_SF + S * F;
        end
        w = flybyArcsForThisBody(1).body.weight;
        score = score + w * sum_SF;
    end

    b = calc_b(bodyIds); % grand tour bonus
    score = b * score;
end

function m = make_flybyArcsMap_byBodyIds(trajectory)
    flybyArcs = trajectory.flybyArcs;

    m = containers.Map('KeyType', 'double', 'ValueType', 'any');
    for i_body = 1:length(flybyArcs)
        flybyArc_current = flybyArcs(i_body);
        bodyId = flybyArc_current.body.id;
        if isKey(m, bodyId)
            flybyArcsForThisBody = m(bodyId);
            m(bodyId) = [ flybyArcsForThisBody; flybyArc_current ];
        else
            m(bodyId) = flybyArc_current;
        end
    end
end

function b = calc_b(bodyIds)
    global n_planets; %#ok<GVMIS>

    % bodyIds = unique(bodyIds(:)).'; % already unique

    n_planets_visited = 0;
    for i_body = 1:length(bodyIds)
        bodyId = bodyIds{i_body};
        if bodyId <= 1000
            n_planets_visited = n_planets_visited + 1;
        end
    end
    n_smallBodies_visited = length(bodyIds) - n_planets_visited;

    hasVisitedEveryPlanet = (n_planets_visited == n_planets);
    hasVisitedEnoughSmallBodies = n_smallBodies_visited >= 13;

    if hasVisitedEveryPlanet && hasVisitedEnoughSmallBodies
        b = 1.2;
    else
        b = 1;
    end
end
