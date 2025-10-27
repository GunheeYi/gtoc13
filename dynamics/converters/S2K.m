function K = S2K(S, mu)
    K = cartesian2keplerian(S, mu);
end

% from Mercury
function KOE = cartesian2keplerian(SV,mu)
    arguments
        SV {mustBeReal, mustBeNumeric}
        mu (1,1) {mustBeReal, mustBeNumeric}
    end

    assert(mod(size(SV,1),6)==0,'Input must be (6n,m)') ;

    rx = SV(1:6:end,:) ;
    ry = SV(2:6:end,:) ;
    rz = SV(3:6:end,:) ;
    vx = SV(4:6:end,:) ;
    vy = SV(5:6:end,:) ;
    vz = SV(6:6:end,:) ;

    r2 = rx.^2 + ry.^2 + rz.^2 ;
    v2 = vx.^2 + vy.^2 + vz.^2 ;
    r = sqrt(r2) ;

    hx = ry.*vz - rz.*vy ;
    hy = rz.*vx - rx.*vz ;
    hz = rx.*vy - ry.*vx ;
    h  = sqrt(hx.^2 + hy.^2 + hz.^2) ;

    % node vector nvec = z x h = [-hy, hx, 0]
    nx = -hy ;
    ny =  hx ;
    n  = sqrt(nx.^2 + ny.^2) ;

    fac1 = v2 - mu./r ;
    fac2 = rx.*vx + ry.*vy + rz.*vz ;
    
    ex = (fac1.*rx-fac2.*vx)/mu ;
    ey = (fac1.*ry-fac2.*vy)/mu ;
    ez = (fac1.*rz-fac2.*vz)/mu ;

    e = sqrt(ex.^2 + ey.^2 + ez.^2) ;
    a = 1./(2./r-v2/mu) ;

    i = acos(hz./h) ;
    O = acos(nx./n) ;
    w = acos((nx.*ex+ny.*ey)./n./e) ;
    f = acos((rx.*ex+ry.*ey+rz.*ez)./r./e) ;

    flag1 = ny < 0 ;
    flag2 = ez < 0 ;
    flag3 = fac2 < 0 ;

    O(flag1) = 2*pi - O(flag1) ;
    w(flag2) = 2*pi - w(flag2) ;
    f(flag3) = 2*pi - f(flag3) ;

    tol = 1e-12 ;
    circ = e < tol ;
    noncirc = ~circ ;
    eq = n < tol ;
    noneq = ~eq ;

    type = noncirc & eq ;
    if any(type,"all")
        O(type) = 0 ;
        
        w(type) = acos(ex(type)./e(type)) ;
        flag = ey < 0 ; w(type&flag) = 2*pi - w(type&flag) ;

        temp = ex.*rx + ey.*ry + ez.*rz ;
        f(type) = acos(temp(type)./e(type)./r(type)) ;
        flag = temp < 0 ; f(type&flag) = 2*pi - f(type&flag) ;
    end

    type = circ & noneq ;
    if any(type,"all")
        O(type) = acos(nx(type)./n(type)) ;
        flag = ny < 0 ; O(type&flag) = 2*pi - O(type&flag) ;

        w(type) = 0 ;

        f(type) = acos((nx(type).*rx(type)+ny(type).*ry(type))./n(type)./r(type)) ;
        flag = rz < 0 ; f(type&flag) = 2*pi - f(type&flag) ;
    end

    type = circ & eq ;
    if any(type,"all")
        w(type) = 0 ;
        
        O(type) = 0 ;

        f(type) = acos(rx(type)./r(type)) ;
        flag = ry < 0 ; f(type&flag) = 2*pi - f(type&flag) ;
    end

    ell = e < 1 - 1e-12 ;
    hyp = e > 1 + 1e-12 ;
    par = ~(ell | hyp) ;

    M = zeros(size(e)) ;

    if any(ell,"all")
        e_ell = e(ell) ;
        E = 2*atan(sqrt((1-e_ell)./(1+e_ell)).*tan(f(ell)/2)) ;
        M(ell) = E - e_ell.*sin(E) ;
        M(ell) = mod(M(ell),2*pi) ;
    end

    if any(hyp,"all")
        f_hyp = f(hyp) ; e_hyp = e(hyp) ;
        sinhH = sin(f_hyp).*sqrt(e_hyp.^2-1)./(1+e_hyp.*cos(f_hyp)) ;
        H = asinh(sinhH) ;
        M(hyp) = e_hyp.*sinhH - H ;
    end

    if any(par,"all")
        B = tan(f(par)/2) ;
        M(par) = B + B.^3/3 ;
    end

    i = rad2deg(i) ;
    O = rad2deg(mod(O,2*pi)) ;
    w = rad2deg(mod(w,2*pi)) ;
    M = rad2deg(M) ;

    KOE = zeros(size(SV)) ;
    KOE(1:6:end,:) = a ;
    KOE(2:6:end,:) = e ;
    KOE(3:6:end,:) = i ;
    KOE(4:6:end,:) = O ;
    KOE(5:6:end,:) = w ;
    KOE(6:6:end,:) = M ;
end
