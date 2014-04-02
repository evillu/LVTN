function [u,v] = HornSchunk(im1,im2)
    ite = 3;
    alpha = 1;
    % calculate the derivatives explicitly
    [Dx,Dy,Dt] = Derivaties();
    u = zeros(size(im1));
    v = zeros(size(im1));
    % Averaging kernel
    kernel_1=[1/12 1/6 1/12;1/6 0 1/6;1/12 1/6 1/12];
    for i=1:ite
        % Compute local averages of the flow vectors
        uAvg=conv2(u,kernel_1,'same');
        vAvg=conv2(v,kernel_1,'same');
        % Compute flow vectors constrained by its local average and the optical flow constraints
        u= uAvg - ( Dx.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
        v= vAvg - ( Dy.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
    end
    
    %% Compute Derivaties between 2 gray images
    function [Dx, Dy, Dt] = Derivaties()
        % Horn-Schunck method
        Dx = conv2(im1,0.25* [-1 1; -1 1],'same') + conv2(im2, 0.25*[-1 1; -1 1],'same');
        Dy = conv2(im1, 0.25*[-1 -1; 1 1], 'same') + conv2(im2, 0.25*[-1 -1; 1 1], 'same');
        Dt = conv2(im1, 0.25*ones(2),'same') + conv2(im2, -0.25*ones(2),'same');
    end
end