function set_constants()
    global ...
        AU ...
        mu_altaira ...
        day_in_secs year_in_secs; %#ok<GVMIS>

    AU = 149597870.691;
    mu_altaira = 139348062043.343;
    day_in_secs = 86400; % in seconds
    year_in_secs = 365.25 * day_in_secs;
end
