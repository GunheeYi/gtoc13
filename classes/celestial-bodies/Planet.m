classdef Planet < CelestialBody
    properties
        name
        mu
        r
    end
    methods
        function planet = Planet(id, K0, weight, name, mu, r, flybyable)
            planet@CelestialBody(id, K0, weight);
            planet.name = name;
            planet.mu = mu;
            planet.r = r;
            planet.flybyable = flybyable;
        end
    end
end
