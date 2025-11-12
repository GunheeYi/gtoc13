classdef Planet < CelestialBody
    properties
        name_ string; % underscore to avoid conflict with dependent property already defined in `CelestialBody`
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
            planet.name_ = name;
            planet.mu = mu;
            planet.r = r;
            planet.flybyable = flybyable;
        end

        function angle_turn = calc_angle_turn(planet, vinf, r_p)
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
            angle_turn = 2 * asin(sinValue);
        end
        function [angle_turn_min, angle_turn_max] = calc_range_angle_turn_feasible(planet, vinf)
            arguments
                planet Planet;
                vinf {mustBeNonnegative};
            end

            angle_turn_min = planet.calc_angle_turn(vinf, planet.r * 101);
            angle_turn_max = planet.calc_angle_turn(vinf, planet.r * 1.01);
        end
    end

    methods (Access = protected)
        function name = get_name(planet)
            name = planet.name_;
        end
    end
end
