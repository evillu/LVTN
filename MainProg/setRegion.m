function [ RMask,PMask] = setRegion( initFrame )
%INITDATA return a hand draw region for objects to be recognized
    imshow(initFrame);
    RMask = false(size(initFrame,1),size(initFrame,2));
    h = impoly;     % H contain hand draw polygon
    p = wait(h);    % P contain coords for each vetex    
    p(end+1,:) = p(1,:);
    PMask = p;      % PMask contain closed poly-line vertex
    
    % draw boundary
    for i = 1:size(p,1)-1
        drawLine(p(i,1),p(i,2),p(i+1,1),p(i+1,2));
    end
    
    % fill the region
    RMask = imfill(RMask,'holes');    
    
    function drawLine(x1,y1,x2,y2)
        % distances according to both axes
        xn = abs(x2-x1);
        yn = abs(y2-y1);
        
        % interpolate against axis with greater distance between points;
        % this guarantees statement in the under the first point!
        if (xn > yn)
            xc = x1 : sign(x2-x1) : x2;
            yc = round( interp1([x1 x2], [y1 y2], xc, 'linear') );
        else
            yc = y1 : sign(y2-y1) : y2;
            xc = round( interp1([y1 y2], [x1 x2], yc, 'linear') );
        end
        
        % 2-D indexes of line are saved in (xc, yc), and
        % 1-D indexes are calculated here:
        ind = round(sub2ind( size(RMask), yc, xc ));
        
        % draw line on the image (change value to 1)
        RMask(ind) = 1;
    end

end

