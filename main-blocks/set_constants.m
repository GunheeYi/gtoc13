function set_constants()
    global ...
        mu_altaira ...
        AU TU ...
        day_in_secs year_in_secs t_max...
        sc ...
        tol_t tol_r tol_v ...
        trajectory_path_default; %#ok<GVMIS>

    mu_altaira = 139348062043.343;

    AU = 149597870.691;
    TU = sqrt(AU^3 / mu_altaira);

    day_in_secs = 86400; % in seconds
    year_in_secs = 365.25 * day_in_secs;
    t_max = 200 * year_in_secs;

    sc = struct();
    sc.m = 500; % kg

    sail = struct();
    sail.C_at_1AU = 5.4026e-6; % N/m^2
    sail.A = 15000; % m^2
    sail.a_at_1AU = 2 * sail.C_at_1AU * sail.A / sc.m / 1000; % km/s^2
    sc.sail = sail;

    tol_t = 1e-6; % 1ms
    tol_r = 100e-3; % 100m
    tol_v = 0.1e-6; % 0.1mm/s

    trajectory_path_default = 'trajectories/default.mat';
end
