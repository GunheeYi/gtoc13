classdef CloseApproach
    properties
        body;
        t {mustBeNonnegative};
        r {mustBeNonnegative};
    end
    methods
        function closeApproach = CloseApproach(body, t, r)
            arguments
                body;
                t {mustBeNonnegative};
                r {mustBeNonnegative};
            end

            closeApproach.body = body;
            closeApproach.t = t;
            closeApproach.r = r;
        end
    end
end
