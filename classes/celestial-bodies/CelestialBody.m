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

            global mu_altaira; %#ok<GVMIS>

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

        function draw(celestialBody, t, drawingOptions_body, drawingOptions_tail, drawingOptions_orbit)
            arguments
                celestialBody CelestialBody
                t {mustBeScalarOrEmpty mustBeNonnegative}
                drawingOptions_body cell = {}
                drawingOptions_tail cell = {}
                drawingOptions_orbit cell = {}
            end

            global mu_altaira AU %#ok<GVMIS>

            if ~isempty(drawingOptions_body)
                S = celestialBody.S_at(t);
                plot3mat(S(1:3) / AU, drawingOptions_body{:});
            end

            if ~isempty(drawingOptions_tail)
                K_t = celestialBody.K_at(t);
                M_t = K_t(6);
                Ms = linspace(M_t - 30, M_t, 10);
                Ks = populate_K_with_Ms(celestialBody.K0, Ms);
                Ss = K2S(Ks, mu_altaira);
                plot3mat(Ss(1:3, :) / AU, drawingOptions_tail{:});
            end

            if ~isempty(drawingOptions_orbit)
                Ms = linspace(0, 360, 60); % mean anomalies
                Ks = populate_K_with_Ms(celestialBody.K0, Ms);
                Ss = K2S(Ks, mu_altaira);
                plot3mat(Ss(1:3, :) / AU, drawingOptions_orbit{:});
            end
        end
    end
end

function Ks = populate_K_with_Ms(K, Ms)
    arguments
        K (6, 1) {mustBeReal}
        Ms (1, :) {mustBeReal} % mean anomalies
    end

    Ks = repmat(K, 1, length(Ms));
    Ks(6, :) = Ms;
end
