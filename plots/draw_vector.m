function arrow = draw_vector(v, origin, scale, varargin)
    if nargin < 2
        origin = zeros(3,1);
    end
    if nargin < 3
        scale = 1;
    end

    v = scale * v;

    arrow = quiver3(origin(1), origin(2), origin(3), ...
            v(1), v(2), v(3), ...
            0, varargin{:});
end
