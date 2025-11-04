function Trajectory_save(trajectory, varargin)
    arguments
        trajectory Trajectory;
    end
    arguments (Repeating)
        varargin
    end
    global trajectory_path_default; %#ok<GVMIS>
    if nargin < 2
        filepath = trajectory_path_default;
    else
        filename = varargin{1};
        folder = "trajectories";
        if ~exist(folder, "dir")
            mkdir(folder);
        end
        filepath = fullfile(folder, filename);
    end
    save(filepath, 'trajectory');
end