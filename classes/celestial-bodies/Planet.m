classdef Planet < CelestialBody
    properties
        name
        mu
        flybyable
    end
    methods
        function planet = Planet(celestialBody_args, name, mu, flybyable)
            planet@CelestialBody(celestialBody_args)
            planet.name = name;
            planet.mu = mu;
            planet.flybyable = flybyable;
        end
    end
end
