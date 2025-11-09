classdef Comet < CelestialBody
    methods
        function comet = Comet(id, K0, weight)
            comet@CelestialBody(id, K0, weight);
        end
    end

    methods (Access = protected)
        function name = get_name(comet)
            name = sprintf('A%d', comet.id);
        end
    end
end
