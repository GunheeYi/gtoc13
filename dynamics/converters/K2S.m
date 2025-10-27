function S = K2S(K, mu)
    S = keplerian2cartesian(K, mu);
end

% from Mercury
function SV = keplerian2cartesian(KOE,mu)
    arguments
        KOE {mustBeReal, mustBeNumeric}
        mu (1,1) {mustBeReal, mustBeNumeric}
    end

    assert(mod(size(KOE,1),6)==0,'Input must be (6n, m)') ;

    a = KOE(1:6:end,:) ;
    e = KOE(2:6:end,:) ;
    i = deg2rad(KOE(3:6:end,:)) ;
    O = deg2rad(KOE(4:6:end,:)) ;
    w = deg2rad(KOE(5:6:end,:)) ;
    M = deg2rad(KOE(6:6:end,:)) ;

    f = M2f(e,M) ;

    isParabola = e == 1 ;
    p = a.*(1-e.^2) ;
    p(isParabola) = a(isParabola) ;

    cf = cos(f) ;
    sf = sin(f) ;

    r = p./(1+e.*cf) ;
    xP = r.*cf ;
    yP = r.*sf ;
    
    fac = sqrt(mu./p) ;
    vxP = -fac.*sf ;
    vyP =  fac.*(e+cf) ;

    cO = cos(O) ; sO = sin(O) ;
    cw = cos(w) ; sw = sin(w) ;
    ci = cos(i) ; si = sin(i) ;

    C11 =  cO.*cw - sO.*sw.*ci;
    C12 = -cO.*sw - sO.*cw.*ci;
    C21 =  sO.*cw + cO.*sw.*ci;
    C22 = -sO.*sw + cO.*cw.*ci;
    C31 =  sw.*si;
    C32 =  cw.*si;

    rx = C11.*xP + C12.*yP;
    ry = C21.*xP + C22.*yP;
    rz = C31.*xP + C32.*yP;

    vx = C11.*vxP + C12.*vyP;
    vy = C21.*vxP + C22.*vyP;
    vz = C31.*vxP + C32.*vyP;

    SV = zeros(size(KOE)) ;
    SV(1:6:end,:) = rx ;
    SV(2:6:end,:) = ry ;
    SV(3:6:end,:) = rz ;
    SV(4:6:end,:) = vx ;
    SV(5:6:end,:) = vy ;
    SV(6:6:end,:) = vz ;
end

function f = M2f(e,M)
    f = nan(size(e)) ;
    tol = 1e-12 ;
    iter_max = 50 ;

    for k = 1:numel(e)
        ek = e(k) ;
        Mk = M(k) ;

        if ek < 1 - tol
            Mk = wrapToPi(Mk) ;
            % initial guess
            if (-pi<Mk && Mk<0) || (pi<Mk && Mk<2*pi)
                Ek = Mk - ek ;
            else
                Ek = Mk + ek ;
            end

            for iter = 1:iter_max
                sEk = sin(Ek) ;
                d   = Ek - ek*sEk - Mk ;
                dp  = 1 - ek*cos(Ek) ;
                dpp = ek*sEk ;

                dE  = -2*d*dp/(2*dp^2-d*dpp) ;
                Ek  = Ek + dE ;

                if abs(dE) < tol, break, end
            end

            f(k) = 2*atan(sqrt((1+ek)/(1-ek))*tan(Ek/2)) ;

        elseif ek > 1 + tol
            % initial guess
            if ek < 1.6
                if (-pi<Mk && Mk<0) || (pi<Mk && Mk<2*pi)
                    Hk = Mk - ek ;
                else
                    Hk = Mk + ek ;
                end
            else
                if ek<3.6 && abs(Mk)>pi
                    Hk = Mk - sign(Mk)*ek ;
                else
                    Hk = Mk/(ek-1) ;
                end
            end

            for iter = 1:iter_max
                sHk = sinh(Hk) ;
                d   = ek*sHk - Hk - Mk ;
                dp  = ek*cosh(Hk) - 1 ;
                dpp = ek*sHk ;

                dH  = -2*d*dp/(2*dp^2-d*dpp) ;
                Hk  = Hk + dH ;

                if abs(dH) < tol, break, end
            end

            f(k) = 2*atan(sqrt((ek+1)/(ek-1))*tanh(Hk/2)) ;

        else
            Bk = Mk ; % initial guess
            for iter = 1:iter_max
                d   = Bk^3/3 + Bk - Mk ;
                dp  = Bk^2 + 1 ;
                dpp = 2*Bk ;

                dB  = -2*d*dp/(2*dp^2-d*dpp) ;
                Bk  = Bk + dB ;

                if abs(dB) < tol, break, end
            end

            f(k) = 2*atan(Bk) ;

        end
    end
end