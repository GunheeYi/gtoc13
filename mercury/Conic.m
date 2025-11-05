function conic = Conic(K,resolution,bound)
    arguments
        K (:,1) {mustBeReal, mustBeNumeric}
        resolution = 1e+3
        bound = 200*1.5e+8
    end

    assert(mod(size(K,1),6)==0,'Input must be (6n, 1)') ;

    e = K(2:6:end) ;

    tol = 1e-12 ;
    ell = e < 1-tol ;
    hyp = e > 1+tol ;
    par = ~ (ell|hyp) ;

    Nobj = length(e) ;

    anomaly = nan(Nobj,resolution) ;
    
    if any(ell,"all")
        anomaly(ell,:) = repmat(linspace(-180,180,resolution),[sum(ell) 1]) ;
    end

    if any(hyp,"all")
        for idx = 1:sum(hyp)
            temp = hyp(idx) ;
            asymp = cosd(1./e(temp)) ;
            anomaly(temp,:) = linspace(-180+asymp+tol,180-asymp-tol,resolution) ;
        end
    end

    if any(par,"all")
        anomaly(par,:) = repmat(linspace(-180+tol,180-tol,resolution),[sum(par) 1]) ;
    end

    [~,~,const] = InitialSetup() ;

    K = repmat(K,[1 size(anomaly,2)]) ;
    K(6:6:end) = anomaly ;
    S = K2S(K,const.GM) ;

    conic = zeros(3*Nobj,resolution) ;
    conic(1:3:end,:) = S(1:6:end,:) ;
    conic(2:3:end,:) = S(2:6:end,:) ;
    conic(3:3:end,:) = S(3:6:end,:) ;

    conic(abs(conic)>bound) = nan ;
end