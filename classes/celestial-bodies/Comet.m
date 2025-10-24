classdef Comet < CelestialBody
    methods
        function comet = Comet(id, K0, weight)
            comet@CelestialBody(id, K0, weight);
        end
    end
end
