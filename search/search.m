function search(filepath)
    global year_in_secs mu_altaira ...
        vulcan yavin eden hoth beyonce bespin jotunn wakonyingo...
    ; %#ok<GVMIS>

    t_max_for_search = 130 * year_in_secs;

    filepath_splitted = split(filepath, '/');
    filepath_for_loading = strjoin(filepath_splitted(2:end), '/');

    trajectory = Trajectory();
    trajectory = trajectory.load(filepath_for_loading);
    
    if trajectory.t_end > t_max_for_search
        return;
    end

    n_flybys_max = 50;
    if trajectory.n_flybys_possible >= n_flybys_max
        return;
    end

    dirpath = split(filepath, '/');
    dirpath = strjoin(dirpath(1:end-1), '/');

    targets_flyby = [wakonyingo, jotunn, bespin, beyonce, hoth, eden, yavin, vulcan];
    % targets_flyby = targets_flyby(randperm(length(targets_flyby))); % randomize order
    for planet = targets_flyby
        if trajectory.arc_last.target.id == planet.id
            continue;
        end

        fprintf('Trying flyby to %s as %dth flyby...\n', planet.name, trajectory.n_flybys_possible);

        dirpath_planet = sprintf('%s/%s', dirpath, planet.name);
        filepath_planet_infeasible = sprintf('%s/infeasible', dirpath_planet);
        filepath_planet_feasible = sprintf('%s/trajectory.mat', dirpath_planet);
        
        if isfile(filepath_planet_infeasible)
            fprintf('Flyby to %s already deemed infeasible. Skipping...\n', planet.name);
            continue;
        end
        if isfile(filepath_planet_feasible)
            fprintf('Flyby to %s already exists. Using the file...\n', planet.name);
            search(filepath_planet_feasible);
            continue;
        end

        a_sc = trajectory.arc_last.K_end(1);
        e_sc = trajectory.arc_last.K_end(1);
        if e_sc < 1
            T_sc = 2*pi*sqrt(a_sc^3/mu_altaira);
        else
            T_sc = Inf;
        end
        dt_max_for_search = t_max_for_search - trajectory.t_end;
        dt_max = min(max(T_sc, planet.T), dt_max_for_search);

        try
            new_trajectory = trajectory.flybyTargeting(planet, 0, dt_max);
            fprintf('Flyby to %s successful. Saving and continuing search...\n', planet.name);
            filepath_planet_feasible_splitted = split(filepath_planet_feasible, '/');
            filepath_planet_feasible_for_saving ...
                = strjoin(filepath_planet_feasible_splitted(2:end), '/');
            new_trajectory.save(filepath_planet_feasible_for_saving);
            search(filepath_planet_feasible);
        catch
            fprintf('Flyby to %s infeasible. Marking and continuing...\n', planet.name);
            if ~exist(dirpath_planet, 'dir')
                mkdir(dirpath_planet);
            end
            fid = fopen(filepath_planet_infeasible, 'w');
            fclose(fid);
        end
    end
end
