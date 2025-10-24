classdef Asteroid < CelestialBody
    methods
        function asteroid = Asteroid(id, K0, weight)
            asteroid@CelestialBody(id, K0, weight);
        end
    end
end
