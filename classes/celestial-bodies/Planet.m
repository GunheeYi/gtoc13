classdef Planet < CelestialBody
    properties
        name
        mu
    end
    methods
        function planet = Planet(id, K0, weight, name, mu, flybyable)
            planet@CelestialBody(id, K0, weight);
            planet.name = name;
            planet.mu = mu;
            planet.flybyable = flybyable;
        end
    end
end
