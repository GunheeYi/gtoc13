function plot_system(varargin)
    plot_altaira();
    plot_planets();
    plot_asteroids();
    plot_comets();
end

function plot_altaira()
    plot3mat(zeros(3,1), 'r*', 'DisplayName', 'Altaira');
end

function plot_planets()
    global planets; %#ok<GVMIS>

    for i = 1:numel(planets)
        planet = planets(i);
        planet.draw(0, {'o', 'DisplayName', planet.name}, {}, {'-', 'HandleVisibility', 'off'});
    end
end

function plot_asteroids()
    global asteroids; %#ok<GVMIS>

    for i = 1:numel(asteroids)
        asteroid = asteroids(i);
        asteroid.draw(0, {'o', 'color', [.5 .5 .5] 'DisplayName', sprintf('a%s', asteroid.id), 'HandleVisibility', 'off'}, {}, {});
    end
end

function plot_comets()
    global comets; %#ok<GVMIS>

    for i = 1:numel(comets)
        comet = comets(i);
        comet.draw(0, {'co', 'DisplayName', sprintf('c%s', comet.id), 'HandleVisibility', 'off'}, {}, {});
    end
end


