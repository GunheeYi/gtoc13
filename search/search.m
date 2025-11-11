function search(filepath)
    global year_in_secs ...
        vulcan yavin eden hoth beyonce bespin jotunn wakonyingo...
    ; %#ok<GVMIS>

    t_max_for_search = 130 * year_in_secs;

    filepath_splitted = split(filepath, '/');
    filepath_for_loading = strjoin(filepath_splitted(2:end), '/');

    trajectory = Trajectory();
    trajectory = trajectory.load(filepath_for_loading);

    fprintf( ...
        'Search for %dth flyby requested. Current t = %.2fyrs, score = %.2f.\n', ...
        trajectory.n_flybys_possible, trajectory.t_end / year_in_secs, trajectory.score ...
    );
    
    if trajectory.t_end > t_max_for_search
        fprintf('Maximum time (%dyrs) exceeded. Stopping search.\n', ...
            t_max_for_search / year_in_secs);
        return;
    end

    n_flybys_max = 50;
    if trajectory.n_flybys_possible >= n_flybys_max
        fprintf('Maximum number of flybys (%d) reached. Stopping search.\n', n_flybys_max);
        return;
    end

    dirpath = split(filepath, '/');
    dirpath = strjoin(dirpath(1:end-1), '/');

    targets_flyby = [wakonyingo, jotunn, bespin, beyonce, hoth, eden, yavin, vulcan];
    % targets_flyby = targets_flyby(randperm(length(targets_flyby))); % randomize order
    for target = targets_flyby
        if trajectory.arc_last.target.id == target.id
            continue;
        end

        fprintf( ...
            'Trying flyby to %s as %dth flyby (current t = %.2fyrs, score = %.2f)...\n', ...
            target.name, trajectory.n_flybys_possible, ...
            trajectory.t_end / year_in_secs, trajectory.score ...
        );

        dirpath_planet = sprintf('%s/%s', dirpath, target.name);
        filepath_planet_infeasible = sprintf('%s/infeasible', dirpath_planet);
        filepath_planet_feasible = sprintf('%s/trajectory.mat', dirpath_planet);
        
        if isfile(filepath_planet_infeasible)
            fprintf('Flyby to %s already deemed infeasible. Skipping...\n', target.name);
            continue;
        end
        if isfile(filepath_planet_feasible)
            fprintf('Flyby to %s already exists. Using the file...\n', target.name);
            search(filepath_planet_feasible);
            continue;
        end

        dt_max_for_search = t_max_for_search - trajectory.t_end;

        T_sc = trajectory.arc_last.T_end;
        dt_max = min(max(T_sc, target.T), dt_max_for_search);

        try
            new_trajectory = trajectory.flybyTargeting(target, 0, dt_max);
            flybyArc_last = new_trajectory.arcs{end-1};
            fprintf( ...
                'Flyby to %s successful (vinf = %.2f). Saving and continuing search...\n', ...
                target.name, flybyArc_last.vinf ...
            );
            filepath_planet_feasible_splitted = split(filepath_planet_feasible, '/');
            filepath_planet_feasible_for_saving ...
                = strjoin(filepath_planet_feasible_splitted(2:end), '/');
            new_trajectory.save(filepath_planet_feasible_for_saving);
            search(filepath_planet_feasible);
        catch ME
            switch ME.identifier
                case 'Trajectory:flybyTargeting:noConvergenceWithoutSails'
                    fprintf('Flyby to %s infeasible. Marking and continuing...\n', ...
                        target.name);
                    if ~exist(dirpath_planet, 'dir')
                        mkdir(dirpath_planet);
                    end
                    fid = fopen(filepath_planet_infeasible, 'w');
                    fclose(fid);
                otherwise
                    logError(trajectory, target, ME, dirpath);
            end
        end
    end
end

function logError(trajectory, planet, ME, dirpath)
    % get root directory path. dirpath always starts with trajectory/
    % if dirpath is trajectory/dir1/dir2/..., search root dir is defined to be dir1.
    dirpath_splitted = split(dirpath, '/');
    dirpath_search_root = strjoin(dirpath_splitted(1:2), '/');
    filepath_log = sprintf('%s/log.txt', dirpath_search_root);

    fid = fopen(filepath_log, 'a');
    if fid == -1
        warning('Could not open log file at %s to log error: %s', filepath_log, ME.message);
        return;
    end
    cleanup_fid = onCleanup(@() fclose(fid));
    fprintf(fid, '%s\n', trajectory.sequenceString);
    fprintf(fid, '    Unknown error occurred while attempting flyby targeting %s:\n', planet.name);
    fprintf(fid, '    %s\n', ME.message);
end
