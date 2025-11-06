function plot_system(t)
    arguments
        t {mustBeNonnegative} = 0;
    end

    plot_altaira();
    plot_no_fly_zone();
    plot_planets(t);
    plot_asteroids(t);
    plot_comets(t);
end

function plot_altaira()
    plot3mat(zeros(3,1), 'r*', 'DisplayName', 'Altaira');
end

function plot_planets(t)
    global planets year_in_secs; %#ok<GVMIS>

    for i = 1:numel(planets)
        planet = planets(i);

        planet.draw(t, {'o', 'HandleVisibility', 'off'}, {}, {'-', 'DisplayName', sprintf('%s (%.2gyrs)', planet.name, planet.T / year_in_secs)});
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

function plot_no_fly_zone()
    draw_sphere(0.01, ...
        'FaceColor', [1 0 0], ...   % red
        'EdgeColor', 'none', ...    % no mesh lines
        'FaceAlpha', 0.5, ...       % 0 = fully transparent, 1 = opaque
        'DisplayName', 'no-fly zone' ...
    );

    draw_sphere(0.05, ...
        'FaceColor', [1 1 0], ...   % red
        'EdgeColor', 'none', ...    % no mesh lines
        'FaceAlpha', 0.3, ...       % 0 = fully transparent, 1 = opaque
        'DisplayName', 'one-time pass only' ...
    );
end

function s = draw_sphere(r, varargin)
    [X,Y,Z] = sphere(50);
    X = r*X; Y = r*Y; Z = r*Z;

    s = surf(X,Y,Z, varargin{:});
    
    camlight headlight
    lighting gouraud
end


