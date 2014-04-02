function [u,v] = LucasKanade(im1, im2, windowSize)
    %% Lucas Kanade without pyramid
    [Dx, Dy, Dt] = Derivaties();
    u = zeros(size(im1));
    v = zeros(size(im1));
    
    halfWindow = floor(windowSize/2);
    for i = (halfWindow+1):(size(im1,1)-halfWindow)
        for j = (halfWindow+1):(size(im1,2)-halfWindow)
            curFx = Dx(i-halfWindow:i+halfWindow, j-halfWindow:j+halfWindow);
            curFy = Dy(i-halfWindow:i+halfWindow, j-halfWindow:j+halfWindow);
            curFt = Dt(i-halfWindow:i+halfWindow, j-halfWindow:j+halfWindow);
            
            curFx = curFx(:);
            curFy = curFy(:);
            curFt = -curFt(:);
            
            A = [curFx curFy];            
            
            U = pinv(A'*A)*A'*curFt;
            u(i,j)=U(1);
            v(i,j)=U(2);
        end
    end

    %% Compute Derivaties between 2 gray images
    function [Dx, Dy, Dt] = Derivaties()
        % Horn-Schunck method
        Dx = conv2(im1,0.25* [-1 1; -1 1],'same') + conv2(im2, 0.25*[-1 1; -1 1],'same');
        Dy = conv2(im1, 0.25*[-1 -1; 1 1], 'same') + conv2(im2, 0.25*[-1 -1; 1 1], 'same');
        Dt = conv2(im1, 0.25*ones(2),'same') + conv2(im2, -0.25*ones(2),'same');
    end
end

