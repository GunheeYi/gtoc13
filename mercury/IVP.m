function K = IVP(K0,dt,mu)
    arguments
        K0 (:,1) {mustBeReal, mustBeNumeric}
        dt (1,:) {mustBeReal, mustBeNumeric}
        mu
    end

    K = repmat(K0,[1 length(dt)]) ;
    
    tol = 1e-12 ;
    a = K0(1:6:end) ;
    e = K0(2:6:end) ;
    ell = e < 1 - tol ;
    hyp = e > 1 + tol ;
    par = ~ (ell|hyp) ;

    n = zeros(size(e)) ;
    n(ell) = sqrt(mu./a(ell).^3) ;
    n(hyp) = sqrt(-mu./a(hyp).^3) ;
    n(par) = 2*sqrt(mu./a(par).^3) ;

    K(6:6:end,:) = K(6:6:end,:) + 180/pi*n.*dt ;
end