% Method to draw interactive plot of the trajectory.
% This just exports the trajectory as `solutions/temp-for-interactive-map.txt`
% and calls the interactive plotter implemented by Mercury.
function fig = Trajectory_draw_interactive(trajectory, dt)
    arguments
        trajectory Trajectory;
        dt (1,1) {mustBeReal, mustBePositive} = 10 * 86400
    end

    filename = 'temp-for-interactive-map.txt';
    filepath = "solutions/" + filename;
    Trajectory_exportAsSolution(trajectory, filename);
    fig = plotSystem(filepath, dt);
end
