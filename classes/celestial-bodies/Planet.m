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

        function turn_angle = calc_turn_angle(planet, vinf, r_p)
            arguments
                planet Planet;
                vinf {mustBeNonnegative};
                r_p {mustBePositive};
            end

            if ~planet.flybyable
                error('This planet is not flybyable.');
            end

            muOverRp = planet.mu / r_p;
            sinValue = muOverRp / (vinf^2 + muOverRp);
            turn_angle = 2 * asin(sinValue);
        end
        function [turn_angle_min, turn_angle_max] = calc_feasible_turn_angle_range(planet, vinf)
            arguments
                planet Planet;
                vinf {mustBeNonnegative};
            end

            turn_angle_min = planet.calc_turn_angle(vinf, planet.r * 101);
            turn_angle_max = planet.calc_turn_angle(vinf, planet.r * 1.01);
        end
    end
end
