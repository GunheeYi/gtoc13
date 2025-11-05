function load_celestial_bodies()
    load_planets();
    load_asteroids();
    load_comets();
    make_celestialBody_placeholder();

    % disp_loaded_celestial_bodies();
end

function load_planets()
    global planets; %#ok<GVMIS>

    data = readcell('data/gtoc13_planets.csv');
    data = data(2:end, :);
    n = size(data, 1);
    planets = Planet.empty(0, 1);

    for i = 1:n
        id     = data{i, 1};
        name   = string(data{i, 2});
        mu     = data{i, 3};
        r      = data{i, 4};
        K0     = cell2mat(data(i, 5:10)).';
        weight = data{i, 11};
        flybyable = (mu ~= 0);
        planets(i, 1) = Planet(id, K0, weight, name, mu, r, flybyable);
    end

    declare_planets_as_global_variables();
end

function load_asteroids()
    global asteroids; %#ok<GVMIS>

    data = readcell('data/gtoc13_asteroids.csv');
    data = data(2:end, :);
    n = size(data, 1);
    asteroids = Asteroid.empty(0, 1);

    for i = 1:n
        id     = data{i, 1};
        K0     = cell2mat(data(i, 2:7)).';
        weight = data{i, 8};
        asteroids(i, 1) = Asteroid(id, K0, weight);
    end
end

function load_comets()
    global comets; %#ok<GVMIS>

    data = readcell('data/gtoc13_comets.csv');
    data = data(2:end, :);
    n = size(data, 1);
    comets = Comet.empty(0, 1);

    for i = 1:n
        id     = data{i, 1};
        K0     = cell2mat(data(i, 2:7)).';
        weight = data{i, 8};
        comets(i, 1) = Comet(id, K0, weight);
    end
end

function make_celestialBody_placeholder()
    global celestialBody_placeholder; %#ok<GVMIS>
    id = 9999;
    K0 = zeros(6,1);
    weight = eps;
    name = "placeholder";
    mu = 0;
    r = 0;
    flybyable = false;
    celestialBody_placeholder = Planet(id, K0, weight, name, mu, r, flybyable);
end

function disp_loaded_celestial_bodies() %#ok<DEFNU>
    global planets asteroids comets; %#ok<GVMIS>
    fprintf('Loaded %d planets:\n', length(planets));
    for i = 1:length(planets)
        fprintf('  - %s\n', planets(i).name);
    end
    fprintf('Loaded %d asteroids.\n', length(asteroids));
    fprintf('Loaded %d comets.\n', length(comets));
end

function declare_planets_as_global_variables()
    global planets ...
        vulcan yavin eden hoth ...
        yandi ...
        beyonce bespin jotunn wakonyingo rogue1 ...
        planetX; %#ok<GVMIS>

    vulcan     = planets(1);
    yavin      = planets(2);
    eden       = planets(3);
    hoth       = planets(4);
    yandi      = planets(5);
    beyonce    = planets(6);
    bespin     = planets(7);
    jotunn     = planets(8);
    wakonyingo = planets(9);
    rogue1     = planets(10);
    planetX    = planets(11);
end