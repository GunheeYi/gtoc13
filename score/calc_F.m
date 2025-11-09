function F = calc_F(vinf)
    F = 0.2 + exp(-vinf/13) / ( 1 + exp(-5 * (vinf-1.5)) );
end
