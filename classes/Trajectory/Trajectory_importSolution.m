function trajectory = Trajectory_importSolution(filename)
    arguments
        filename string;
    end
    filepath = "solutions/" + filename;
    M = readmatrix(filepath, 'Delimiter', ',', 'OutputType', 'double');

    trajectory = Trajectory();

    n_rows = size(M, 1);
    i_row = 1;
    while i_row <= n_rows
        row1 = M(i_row, :);
        id = row1(1);
        flag = row1(2); % TODO: manage scientific flyby flag
        t1 = row1(3);
        R1 = row1(4:6);
        V1 = row1(7:9);
        row2 = M(i_row+1, :);
        t2 = row2(3);
        R2 = row2(4:6);
        V2 = row2(7:9);

        i_row = i_row + 2;

        if id > 0 % is a flyby arc
            body = findBodyById(id);
            flybyArc = FlybyArc(t1, body, R1, V1, V2);
            trajectory = trajectory.addArc(flybyArc);
            continue;
        end

        if flag == 0 % is a conic arc
            target = findNearestBody(t2, R2); % TODO: improve by figuring out body from next flyby if possible
            conicArc = ConicArc(t1, R1, V1, t2, target);
            trajectory = trajectory.addArc(conicArc);
            continue;
        end

        error("Importing propagated is not yet implemented.");
        % TODO: implement propagated arc import

        % C1 = row1(10:12);
        % C2 = row2(10:12);
    end
end

function body = findBodyById(id)
    arguments
        id {mustBeNonnegative mustBeInteger}
    end

    global celestialBodies; %#ok<GVMIS>

    for i_candidate = 1:numel(celestialBodies)
        candidate = celestialBodies{i_candidate};
        if candidate.id == id
            body = candidate;
            return;
        end
    end

    error("No celestial body with id " + id + " found.");
end

function body = findNearestBody(t, R)
    arguments
        t {mustBeNonnegative};
        R (3,1) {mustBeReal};
    end

    global celestialBodies; %#ok<GVMIS>

    min_dist = inf;

    for i_candidate = 1:numel(celestialBodies)
        candidate = celestialBodies{i_candidate};
        R_candidate = candidate.R_at(t);
        dist = norm(R - R_candidate);
        if dist < min_dist
            min_dist = dist;
            body = candidate;
        end
    end
end
