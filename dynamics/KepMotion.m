% from Mercury
function KOE = KepMotion(KOE0,dt,mu)
    arguments
        KOE0
        dt (1,:) {mustBeReal, mustBeNumeric}
        mu
    end
    
    if ~isreal(KOE0)
        error('KepMotion:KOE0NotReal', 'KOE0 must be real-valued.') ;
    end

    KOE = repmat(KOE0,[1 length(dt)]) ;
    
    tol = 1e-12 ;
    a = KOE0(1:6:end) ;
    e = KOE0(2:6:end) ;
    ell = e < 1 - tol ;
    hyp = e > 1 + tol ;
    par = ~ (ell|hyp) ;

    n = zeros(size(e)) ;
    n(ell) = sqrt(mu./a(ell).^3) ;
    n(hyp) = sqrt(-mu./a(hyp).^3) ;
    n(par) = 2*sqrt(mu./a(par).^3) ;

    KOE(6:6:end,:) = KOE(6:6:end,:) + 180/pi*n.*dt ;
end
