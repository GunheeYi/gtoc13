classdef SolutionRow
    properties
        body_id {mustBeInteger mustBeNonnegative};
        flag {mustBeMember(flag, [0, 1])};
        epoch (1,1) double {mustBeNonnegative};
        position (3,1) double {mustBeReal};
        velocity (3,1) double {mustBeReal};
        control (3,1) double {mustBeReal};
    end
    methods
        function solutionRow = SolutionRow(body_id, flag, epoch, position, velocity, control)
            arguments
                body_id {mustBeInteger mustBeNonnegative};
                flag {mustBeMember(flag, [0, 1])};
                epoch (1,1) double {mustBeNonnegative};
                position (3,1) double {mustBeReal};
                velocity (3,1) double {mustBeReal};
                control (3,1) double {mustBeReal};
            end
            solutionRow.body_id = body_id;
            solutionRow.flag = flag;
            solutionRow.epoch = epoch;
            solutionRow.position = position;
            solutionRow.velocity = velocity;
            solutionRow.control = control;
        end

        function solutionRowString = toString(solutionRow)
            solutionRowString = sprintf( ...
                '%4d, %d, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s\n', ...
                solutionRow.body_id, solutionRow.flag, ...
                smartFormat(solutionRow.epoch, 21), ...
                smartFormat(solutionRow.position(1), 21), ...
                smartFormat(solutionRow.position(2), 21), ...
                smartFormat(solutionRow.position(3), 21), ...
                smartFormat(solutionRow.velocity(1), 21), ...
                smartFormat(solutionRow.velocity(2), 21), ...
                smartFormat(solutionRow.velocity(3), 21), ...
                smartFormat(solutionRow.control(1), 21), ...
                smartFormat(solutionRow.control(2), 21), ...
                smartFormat(solutionRow.control(3), 21) ...
            );
        end
    end
end

function s = smartFormat(x, n)
%SMARTFORMAT Format number to fixed-point within total width N (sign included)
%
%   s = SMARTFORMAT(x, n)
%
%   - Always fixed-point (no exponent)
%   - Total length including sign <= n
%   - Integer values are zero-padded to use the full precision
%
%   Example:
%       smartFormat(0.000123456, 11)   % -> '   0.000123'
%       smartFormat(-0.000123456, 11)  % -> '  -0.000123'
%       smartFormat(12345.6789, 11)    % -> '   12345.68'
%       smartFormat(-12, 11)           % -> '     -12.000'

    if nargin < 2
        n = 10;
    end

    if ~isscalar(x) || ~isnumeric(x)
        error('Input x must be a numeric scalar.');
    end

    % Handle zero early
    if x == 0
        s = sprintf('%*s', n, '0');
        return;
    end

    sign_char = '';
    if x < 0
        sign_char = '-';
    end

    absx = abs(x);
    int_digits = floor(log10(absx)) + 1;   % count digits before decimal

    % compute how many decimals fit in total width n
    % reserve 1 for sign, 1 for decimal point (if fractional part allowed)
    frac_digits = max(n - int_digits - 1 - (x < 0), 0);

    % Construct format string
    fmt = sprintf('%%.%df', frac_digits);

    % Format number (absolute value, then reattach sign)
    s = sprintf(fmt, absx);
    s = [sign_char s];

    % If integer (no fractional part), pad with zeros to use all remaining width
    if mod(absx, 1) == 0
        % ensure decimal point exists
        if ~contains(s, '.')
            s = [s '.'];
        end
        % pad zeros to reach target length n
        pad_needed = n - length(s);
        s = [s repmat('0', 1, max(pad_needed, 0))];
    end

    % In case rounding made it too long, trim if needed
    if length(s) > n
        s = s(1:n);
    end

    % Left-pad to ensure fixed width (so right-aligned)
    if length(s) < n
        s = [repmat(' ', 1, n - length(s)) s];
    end
end
