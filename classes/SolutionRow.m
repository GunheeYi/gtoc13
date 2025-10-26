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
                '%4d, %d, %21.8f, %14.1f, %14.1f, %14.1f, %21.8f, %21.8f, %21.8f, %21.8f, %21.8f, %21.8f\n', ...
                ... % TODO: restore position precision after resolving position discontinuity issue
                solutionRow.body_id, solutionRow.flag, solutionRow.epoch, ...
                solutionRow.position(1), solutionRow.position(2), solutionRow.position(3), ...
                solutionRow.velocity(1), solutionRow.velocity(2), solutionRow.velocity(3), ...
                solutionRow.control(1), solutionRow.control(2), solutionRow.control(3) ...
            );
        end
    end
end
