function [u,v] = LucasKanade2(im1,im2)
    [Dx,Dy,Dt] = Derivaties();
    
    m200=Dx.*Dx;
    m020=Dy.*Dy;
    m110=Dx.*Dy;
    m101=Dx.*Dt;
    m011=Dy.*Dt;
    
    %This method is added for completeness. You are not required to study
    %it. It is also a Lucas Kanade version, but regularized (Tikhinov regularization)
    %This way of doing LK, is an improvement in every way I can think of, except
    %that it is less pedagogical
    
    %add  value along the structure tensor diagonal, this ensures it
    %is well conditioned and invertible    
    TikConst  = 1;
    m200 = m200 + TikConst; %"L2"
    m020 = m020 + TikConst;
    
    %do the analytically derived inversion of the tensor and multiplication with "b"
    u =(-m101.*m020 + m011.*m110)./(m020.*m200 - m110.^2);%"L3"
    v =( m101.*m110 - m011.*m200)./(m020.*m200 - m110.^2);
    
    %% Compute Derivaties between 2 gray images
    function [Dx, Dy, Dt] = Derivaties()
        % Horn-Schunck method
        Dx = conv2(im1,0.25* [-1 1; -1 1],'same') + conv2(im2, 0.25*[-1 1; -1 1],'same');
        Dy = conv2(im1, 0.25*[-1 -1; 1 1], 'same') + conv2(im2, 0.25*[-1 -1; 1 1], 'same');
        Dt = conv2(im1, 0.25*ones(2),'same') + conv2(im2, -0.25*ones(2),'same');
    end
end

