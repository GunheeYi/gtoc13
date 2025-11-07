function search(filepath)
    global year_in_secs mu_altaira ...
        vulcan yavin eden hoth yandi beyonce bespin ...
    ; %#ok<GVMIS>

    t_max_for_search = 130 * year_in_secs;

    trajectory = Trajectory();
    trajectory = trajectory.load(filepath);
    
    if trajectory.t_end > t_max_for_search
        return;
    end

    n_flybys_max = 10;
    if trajectory.n_flybys_possible >= n_flybys_max
        return;
    end

    dirpath = split(filepath, '/');
    dirpath = strjoin(dirpath(1:end-1), '/');

    for planet = [vulcan, yavin, eden, hoth, yandi, beyonce, bespin]
        dirpath_planet = sprintf('%s/%s', dirpath, planet.name);
        filepath_planet_infeasible = sprintf('%s/infeasible', dirpath_planet);
        filepath_planet_feasible = sprintf('%s/trajectory.mat', dirpath_planet);
        
        if isfile(filepath_planet_infeasible)
            continue;
        end
        if isfile(filepath_planet_feasible)
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
            new_trajectory.save(filepath_planet_feasible);
            search(filepath_planet_feasible);
        catch
            if ~exist(dirpath_planet, 'dir')
                mkdir(dirpath_planet);
            end
            fid = fopen(filepath_planet_infeasible, 'w');
            fclose(fid);
        end
    end
end
