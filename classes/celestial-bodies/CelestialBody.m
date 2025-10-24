classdef CelestialBody
    properties
        id
        K0 (6,1) {mustBeReal} % initial Keplerian orbital elements
        weight {mustBeScalarOrEmpty mustBePositive} % for exploration
        flybyable
    end
    methods
        function celestialBody = CelestialBody(id, K0, weight)
            arguments
                id {mustBeScalarOrEmpty mustBePositive mustBeInteger}
                K0 (6,1) {mustBeReal}
                weight {mustBeScalarOrEmpty mustBePositive}
            end
            celestialBody.id = id;
            celestialBody.K0 = K0;
            celestialBody.weight = weight;
            celestialBody.flybyable = false; % will be overwritten for planets
        end

        function K = K_at(celestialBody, t)
            arguments
                celestialBody CelestialBody
                t {mustBeScalarOrEmpty mustBeNonnegative}
            end

            global mu_altaira %#ok<GVMIS>

            K = KepMotion(celestialBody.K0, t, mu_altaira); % from Mercury
        end
    end
end
