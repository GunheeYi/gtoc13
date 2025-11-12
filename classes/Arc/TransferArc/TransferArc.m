classdef (Abstract) TransferArc < Arc
    properties
        t_start {mustBeNonnegative};
        R_start (3,1) {mustBeReal};
        V_start (3,1) {mustBeReal};
        target;
    end
    properties (Abstract)
        t_end {mustBeNonnegative}
    end
    properties (Dependent)
        S_start (6,1) {mustBeReal};
        K_start (6,1) {mustBeReal};
        S_end (6,1) {mustBeReal};
        K_end (6,1) {mustBeReal};
        R_end (3,1) {mustBeReal};
        V_end (3,1) {mustBeReal};
        T_end {mustBeNonnegative};
        isProgradeAtEnd {mustBeNumericOrLogical};
        isMovingOutwardAtEnd {mustBeNumericOrLogical}
        dR_res (3,1) {mustBeReal}; % residual distance between 
                                   % propagated and target position at end
        dr_res (3,1) {mustBeReal};
    end
    methods
        function transferArc = TransferArc(t_start, R_start, V_start, target)
            arguments
                t_start {mustBeNonnegative};
                R_start (3,1) {mustBeReal};
                V_start (3,1) {mustBeReal};
                target {mustBeA(target, 'CelestialBody')};
            end

            transferArc.t_start = t_start;
            transferArc.R_start = R_start;
            transferArc.V_start = V_start;
            transferArc.target = target;
        end

        % state at start
        function S_start = get.S_start(transferArc)
            S_start = [transferArc.R_start' transferArc.V_start']';
        end
        function K_start = get.K_start(transferArc)
            global mu_altaira; %#ok<GVMIS>
            K_start = S2K(transferArc.S_start, mu_altaira);
        end

        % state at end
        function S_end = get.S_end(transferArc)
            S_end = transferArc.get_S_end();
        end
        function K_end = get.K_end(transferArc)
            K_end = transferArc.get_K_end();
        end
        function R_end = get.R_end(transferArc)
            R_end = transferArc.S_end(1:3);
        end
        function V_end = get.V_end(transferArc)
            V_end = transferArc.S_end(4:6);
        end
        function T_end = get.T_end(transferArc)
            global mu_altaira; %#ok<GVMIS>
            a = transferArc.K_end(1);
            e = transferArc.K_end(2);
            if e < 1
                T_end = 2*pi*sqrt(a^3/mu_altaira);
            else
                T_end = Inf;
            end
        end

        function tf = get.isProgradeAtEnd(transferArc)
            h_vec = cross(transferArc.R_end, transferArc.V_end);
            tf = (h_vec(3) >= 0);
        end
        function tf = get.isMovingOutwardAtEnd(transferArc)
            d = dot(transferArc.R_end, transferArc.V_end);
            tf = (d > 0);
        end
        function tf = satisfiesConditions(transferArc, rdvDirection, allow_retrograde, allow_low_pass)
            tf = false;
            if ~allow_low_pass && transferArc.passes_low()
                return;
            end
            if ~allow_retrograde && ~transferArc.isProgradeAtEnd
                return;
            end
            if rdvDirection > 0 % outward
                if ~transferArc.isMovingOutwardAtEnd
                    return;
                end
            elseif rdvDirection < 0 % inward
                if transferArc.isMovingOutwardAtEnd
                    return;
                end
            end
            tf = true;
        end

        function dR_res = get.dR_res(transferArc)
            R_target_end = transferArc.target.R_at(transferArc.t_end);
            dR_res = transferArc.R_end - R_target_end;
        end
        function dr_res = get.dr_res(transferArc)
            dr_res = norm(transferArc.dR_res);
        end
        function tf = hitsTarget(transferArc)
            arguments
                transferArc TransferArc;
            end
            global tol_dr; %#ok<GVMIS>
            tf = transferArc.dr_res <= tol_dr;
        end
    end

    methods (Abstract)
        draw(transferArc, varargin) % draw
        solutionRows = to_solutionRows(conicArc)
    end

    methods (Abstract, Access = protected)
        S_end = get_S_end(transferArc)
        K_end = get_K_end(transferArc)
    end
end
