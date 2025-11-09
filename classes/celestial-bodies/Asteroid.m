classdef Asteroid < CelestialBody
    methods
        function asteroid = Asteroid(id, K0, weight)
            asteroid@CelestialBody(id, K0, weight);
        end
    end

    methods (Access = protected)
        function name = get_name(asteroid)
            name = sprintf('A%d', asteroid.id);
        end
    end
end
