function set_constants()
    global ...
        AU ...
        mu_altaira ...
        day_in_secs year_in_secs t_max...
        tol_t tol_r tol_v; %#ok<GVMIS>

    AU = 149597870.691;

    mu_altaira = 139348062043.343;

    day_in_secs = 86400; % in seconds
    year_in_secs = 365.25 * day_in_secs;
    t_max = 200 * year_in_secs;

    tol_t = 1e-6; % 1ms
    tol_r = 100e-3; % 100m
    tol_v = 0.1e-6; % 0.1mm/s
end
