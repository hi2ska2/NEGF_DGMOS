function [phi] = nLinPoisson2D(iterNum, jbase, nxz, ni, phi, boundary, Vgs, doping, ...
                    x_dlt, x_int, z_dlt, z_int, eps0, Vt, q)
                %     = nLinPoisson2D(iterNum, jbase, nxz, ni, phi, boundary, doping, ...
%                     x_dlt, x_int, z_dlt, z_int, eps0, Vt, q)
% set index x-direction
nx     = size(phi,1);
x_int1 = x_int{1};
x_int2 = x_int{2};

% set index z-direction
nz     = size(phi,2);
z_int1 = z_int{1};
z_int2 = z_int{2};

BC_index = find(boundary ~= 0);
boundary(BC_index) = boundary(BC_index) + Vgs;

oldphi = phi;

doping(:,z_int1) = 0;
doping(:,z_int2) = 0;

% for test
for i = 1:iterNum
    %% #1. residual vector 
    % calculating charge density 
    nn = nxz.*exp(+(phi-oldphi)/Vt); 
    pp = ni.*exp(-phi/Vt);
    g  = q*(pp - nn + doping);  
    
    % interface exception (:g)
    g(x_int1,:) = bsxfun( @times, g(x_int1,:), x_dlt(x_int1-1)./(x_dlt(x_int1-1)+x_dlt(x_int1)) ) ...
                + bsxfun( @times, g(x_int2,:), x_dlt(x_int1)  ./(x_dlt(x_int1-1)+x_dlt(x_int1)) );
    g(:,z_int1) = bsxfun( @times, g(:,z_int1), (z_dlt(z_int1-1)./(z_dlt(z_int1-1)+z_dlt(z_int1)))' ) ...
                + bsxfun( @times, g(:,z_int2), (z_dlt(z_int1)  ./(z_dlt(z_int1-1)+z_dlt(z_int1)))' );
    g(x_int2,:) = 0;    
    g(:,z_int2) = 0;
    
    % boundary exception 
    g(BC_index) = 0;
    
    r = ( jbase*matrixToVector(phi, nx, nz) - matrixToVector(boundary, nx, nz) )...
        *eps0*1e+9^2;
    R = r + matrixToVector(g, nx, nz);

    %% #2. jacobian matrix 
    h = -(q/Vt)*(pp + nn);
    % interface exception (:h)
    h(x_int1,:) = bsxfun( @times, h(x_int1,:), x_dlt(x_int1-1)./(x_dlt(x_int1-1)+x_dlt(x_int1)) ) ...
                + bsxfun( @times, h(x_int2,:), x_dlt(x_int1)  ./(x_dlt(x_int1-1)+x_dlt(x_int1)) );
    h(:,z_int1) = bsxfun( @times, h(:,z_int1), (z_dlt(z_int1-1)./(z_dlt(z_int1-1)+z_dlt(z_int1)))' ) ...
                + bsxfun( @times, h(:,z_int2), (z_dlt(z_int1)  ./(z_dlt(z_int1-1)+z_dlt(z_int1)))' );
    h(x_int2,:) = 0;
    h(:,z_int2) = 0;
    
    % boundary exception 
    h(BC_index) = 0;
    
    j = jbase*(eps0)*1e+9^2;
    J = j + diag( matrixToVector(h, nx, nz) );
    
    %% #3. finding negative delta vector 
    invJ = inv(J);
    dphi = -invJ*R;
    dphiMat = vectorToMatrix(dphi,nx,nz);
    
    phi = phi + dphiMat;
    dphiVec = matrixToVector(dphiMat, nx, nz);
    stop = full(max(abs(dphiVec)));
%     stop_log1(i,1) = stop;
    
%     disp(sprintf('nonLinear Poisson trial[%d]-error: %d \n', i, stop))
    if stop < 1e-12
%         save nLinPoisson
        break;
    end
end

end 
% 
