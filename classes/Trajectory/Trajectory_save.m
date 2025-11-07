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
        folder_base = "trajectories";

        filepath = fullfile(folder_base, filename);

        dirpath = fileparts(filepath);

        if ~exist(dirpath, "dir")
            mkdir(dirpath);
        end
    end

    save(filepath, 'trajectory');
end
