function [V1plus, V2minus] = solve_lamberts_problem(R1, R2, dt, mu, String)
    
    r1 = norm(R1);
    %[km]Initial position vector magnitude.
    
    r2 = norm(R2);
    %[km]Final position vector magnitude.
    
    R3 = cross(R1, R2);
    %[km^2]Vector normal to initial and final position vectors.
    
    phi = acos(dot(R1, R2) / (r1 * r2));
    %[rad]Transfer angle.
    
    if strcmpi(String, 'Prograde')
        
        if R3(3) <= 0
            
            phi = 2 * pi - phi;
            %[rad]Transfer angle quadrant check.
            
        end
        
    elseif strcmpi(String, 'Retrograde')
        
        if R3(3) >= 0
            
            phi = 2 * pi - phi;
            %[rad]Transfer angle quadrant check.
            
        end
        
    else
        
        fprintf('Prograde trajectory assumed.\n');
        %[]Displays this string on the command window.
        
    end
    
    A = sin(phi) * sqrt(r1 * r2 / (1 - cos(phi)));
    %[km]Constant used to simplify calculations.
    
    z = -100;
    %[]Product of the semimajor axis reciprocal and universal anomaly.
    
    if z > 0
        
        S = (sqrt(z) - sin(sqrt(z))) / sqrt(z)^3;
        %[]Stumpff function for an ellipse.
        
    elseif z < 0
        
        S = (sinh(sqrt(-z)) - sqrt(-z)) / sqrt(-z)^3;
        %[]Stumpff function for a hyperbola.
        
    else
        
        S = 1 / 6;
        %[]Stumpff function for a parabola.
        
    end
    %[]Evaluates the Stumpff function S(z).
    
    if z > 0
        
        C = (1 - cos(sqrt(z))) / z;
        %[]Stumpff function for an ellipse.
        
    elseif z < 0
        
        C = (cosh(sqrt(-z)) - 1) / (-z);
        %[]Stumpff function for an hyperbola.
        
    else
        
        C = 1 / 2;
        %[]Stumpff function for an parabola.
        
    end
    %[]Evaluates the Stumpff function C(z).
    
    y = r1 + r2 + A * (z * S - 1) / sqrt(C);
    %[]Function of z used to simplify calculations.
    
    F = (y / C)^(3 / 2) * S + A * sqrt(y) - sqrt(mu) * dt;
    %[]Function of z and the transfer time of flight used to simplify calculations.
    
    while F < 0
        
        z = z + 0.1;
        %[]Increments z by 0.1.
        
        if z > 0
            
            S = (sqrt(z) - sin(sqrt(z))) / sqrt(z)^3;
            %[]Stumpff function for an ellipse.
            
        elseif z < 0
            
            S = (sinh(sqrt(-z)) - sqrt(-z)) / sqrt(-z)^3;
            %[]Stumpff function for a hyperbola.
            
        else
            
            S = 1 / 6;
            %[]Stumpff function for a parabola.
            
        end
        %[]Evaluates the Stumpff function S(z).
        
        if z > 0
            
            C = (1 - cos(sqrt(z))) / z;
            %[]Stumpff function for an ellipse.
            
        elseif z < 0
            
            C = (cosh(sqrt(-z)) - 1) / (-z);
            %[]Stumpff function for an hyperbola.
            
        else
            
            C = 1 / 2;
            %[]Stumpff function for an parabola.
            
        end
        %[]Evaluates the Stumpff function C(z).
        
        y = r1 + r2 + A * (z * S - 1) / sqrt(C);
        %[]New y function value.
        
        F = (y / C)^(3 / 2) * S + A * sqrt(y) - sqrt(mu) * dt;
        %[]New F(z, t) function value.
        
    end
    %[]Determines approximately where F(z, t) changes sign.
    
    tolerance = 1e-8;
    %[]Sets error tolerance.
    
    nmax = 1000;
    %[]Sets iteration limit.
    
    ratio = 1;
    %[]F(z, t) to differential F(z, t) ratio value.
    
    n = 0;
    %[]Initial number of iterations.
    
    while abs(ratio) > tolerance && n <= nmax
        
        n = n + 1;
        %[]Increments iteration number by one.
        
        if z > 0
            
            S = (sqrt(z) - sin(sqrt(z))) / sqrt(z)^3;
            %[]Stumpff function for an ellipse.
            
        elseif z < 0
            
            S = (sinh(sqrt(-z)) - sqrt(-z)) / sqrt(-z)^3;
            %[]Stumpff function for a hyperbola.
            
        else
            
            S = 1 / 6;
            %[]Stumpff function for a parabola.
            
        end
        %[]Evaluates the Stumpff function S(z).
        
        if z > 0
            
            C = (1 - cos(sqrt(z))) / z;
            %[]Stumpff function for an ellipse.
            
        elseif z < 0
            
            C = (cosh(sqrt(-z)) - 1) / (-z);
            %[]Stumpff function for an hyperbola.
            
        else
            
            C = 1 / 2;
            %[]Stumpff function for an parabola.
            
        end
        %[]Evaluates the Stumpff function C(z).
        
        y = r1 + r2 + A * (z * S - 1) / sqrt(C);
        %[]New y function value.
        
        F = (y / C)^(3 / 2) * S + A * sqrt(y) - sqrt(mu) * dt;
        %[]New F(z, t) function value.
        
        dF = (y / C)^(3 / 2) * (1 / (2 * z) * (C - 3 * S / (2 * C))...
            + 3 * S^2 / (4 * C)) + A / 8 * (3 * S * sqrt(y) / C + A * sqrt(C / y));
        %[]Differential F(z, t) function value.
        
        ratio = F / dF;
        %[]New F(z, t) to differential F(z, t) ratio value.
        
        z = z - ratio;
        %[]New z value.
    end
    %[]Iterates z until its value falls within tolerance value.
    
    if n >= nmax
        fprintf('Number of iterations exceeds %0.0f.\n', nmax);
        %[]Displays this message if the algorithm did not converge.
    end
    
    f = 1 - y / r1;
    %[]Lagrange coefficient.
    
    g = A * sqrt(y / mu);
    %[]Lagrange coefficient.
    
    gdot = 1 - y / r2;
    %[]Lagrange coefficient rate of change.
    
    V1plus = 1 / g * (R2 - f * R1);
    %[vu]Transfer orbit initial velocity vector.
    
    V2minus = 1 / g * (gdot * R2 - R1);
    %[vu]Transfer orbit final velocity vector.
    
end
%===================================================================================================