function trajectory = Trajectory_load(filename)
    arguments
        filename string = ""
    end
    global trajectory_path_default; %#ok<GVMIS>
    if filename == ""
        filepath = trajectory_path_default;
    else
        filepath = "trajectories/" + filename;
    end
    loaded_data = load(filepath, 'trajectory');
    trajectory = loaded_data.trajectory;
end
