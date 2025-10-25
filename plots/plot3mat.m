function p = plot3mat(M, varargin)
    % M: 3 x n matrix
    % varargin: additional options (line color, type, etc.)
    p = plot3(M(1, :), M(2, :), M(3, :), varargin{:});
end
