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

        function S = S_at(celestialBody, t)
            arguments
                celestialBody CelestialBody
                t {mustBeScalarOrEmpty mustBeNonnegative}
            end

            K = celestialBody.K_at(t);
            S = K2S(K, mu_altaira);
        end

        function R = R_at(celestialBody, t)
            arguments
                celestialBody CelestialBody
                t {mustBeScalarOrEmpty mustBeNonnegative}
            end

            S = celestialBody.S_at(t);
            R = S(1:3);
        end

        function V = V_at(celestialBody, t)
            arguments
                celestialBody CelestialBody
                t {mustBeScalarOrEmpty mustBeNonnegative}
            end

            S = celestialBody.S_at(t);
            V = S(4:6);
        end
    end
end
