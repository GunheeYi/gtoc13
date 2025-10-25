function plot_system(t)
    arguments
        t (1,1) {mustBeNonnegative} = 0;
    end

    plot_altaira();
    plot_planets(t);
    plot_asteroids(t);
    plot_comets(t);
end

function plot_altaira()
    plot3mat(zeros(3,1), 'r*', 'DisplayName', 'Altaira');
end

function plot_planets(t)
    global planets; %#ok<GVMIS>

    for i = 1:numel(planets)
        planet = planets(i);
        planet.draw(t, {'o', 'DisplayName', planet.name}, {}, {'-', 'HandleVisibility', 'off'});
    end
end

function plot_asteroids(t)
    global asteroids; %#ok<GVMIS>

    for i = 1:numel(asteroids)
        asteroid = asteroids(i);
        asteroid.draw(t, {'o', 'color', [.5 .5 .5] 'DisplayName', sprintf('a%s', asteroid.id), 'HandleVisibility', 'off'}, {}, {});
    end
end

function plot_comets(t)
    global comets; %#ok<GVMIS>

    for i = 1:numel(comets)
        comet = comets(i);
        comet.draw(t, {'co', 'DisplayName', sprintf('c%s', comet.id), 'HandleVisibility', 'off'}, {}, {});
    end
end


