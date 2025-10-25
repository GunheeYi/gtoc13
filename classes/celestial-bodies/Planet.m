classdef Planet < CelestialBody
    properties
        name string;
        mu {mustBeNonnegative};
        r {mustBeNonnegative};
    end
    methods
        function planet = Planet(id, K0, weight, name, mu, r, flybyable)
            arguments
                id {mustBePositive, mustBeInteger};
                K0 (6,1) {mustBeReal};
                weight {mustBePositive};
                name string;
                mu {mustBeNonnegative};
                r {mustBeNonnegative};
                flybyable logical;
            end
            planet@CelestialBody(id, K0, weight);
            planet.name = name;
            planet.mu = mu;
            planet.r = r;
            planet.flybyable = flybyable;
        end
    end
end
