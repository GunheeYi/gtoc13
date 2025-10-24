classdef Planet < CelestialBody
    properties
        mu
        flybyable
    end
    methods
        function planet = Planet(celestialBody_args, mu, flybyable)
            planet@CelestialBody(celestialBody_args)
            planet.mu = mu;
            planet.flybyable = flybyable;
        end
    end
end
