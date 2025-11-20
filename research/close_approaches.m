clear;
prepare;

global asteroids comets year_in_secs day_in_secs AU;

trajectory = Trajectory();
trajectory = trajectory.load("20251112-bfs-130.mat");

arc = trajectory.arcs{15};

pool = [num2cell(asteroids); num2cell(comets)];

closeApproaches = [];

for i_conicArc = 1:numel(trajectory.conicArcs)
    conicArc = trajectory.conicArcs(i_conicArc);
    closeApproaches_current = conicArc.getCloseApproaches(pool);
    closeApproaches = [closeApproaches; closeApproaches_current]; %#ok<AGROW>
end

[~, sortIdx] = sort([closeApproaches.r]);
closeApproaches = closeApproaches(sortIdx);

for i = 1:numel(closeApproaches)
    approach = closeApproaches(i);
    fprintf("Body: %s, Distance: %.2fkm (%.6fAU), Time: %.2fy\n", ...
        approach.body.name, ...
        approach.r, ...
        approach.r / AU, ...
        approach.t / year_in_secs ...
    );
end
