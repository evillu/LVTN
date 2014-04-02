function imEdge = edgeDetect(imSrc)
if nargin > 0    
    threshold = 0.002;
    grayIm = rgb2gray(imSrc);
    %Create laplacian of gaussian 1d matrix
    mG = fspecial('gaussian',7,1);
    mLoG = fspecial('log',7,2);
    fIm = conv2(conv2(grayIm,mG,'same'),mLoG,'same');
    [row,col] = size(fIm);
    imEdge = zeros(size(fIm));
    zeroCrossing();
    thresholding();
end

    function zeroCrossing()
        for i = 1:row
            for j = 2:col-1
                if (fIm(i,j)*fIm(i,j-1) < 0)
                    imEdge(i,j) = abs(fIm(i,j)-fIm(i,j-1));
                elseif (fIm(i,j) == 0 && fIm(i,j-1)*fIm(i,j+1) < 0)
                    imEdge(i,j) = abs(fIm(i,j-1)-fIm(i,j+1));
                end
            end
        end
        
        for j = 1:col
            for i = 2:row-1                
                if (fIm(i,j)*fIm(i-1,j) < 0)
                    imEdge(i,j) = max(imEdge(i,j),abs(fIm(i,j)-fIm(i-1,j)));
                elseif (fIm(i,j) == 0 && fIm(i-1,j)*fIm(i+1,j) < 0)
                    imEdge(i,j) = max(imEdge(i,j),abs(fIm(i-1,j)-fIm(i+1,j)));
                end
            end
        end
    end

    function thresholding()
        imEdge(imEdge<threshold) = 0;
        imEdge(imEdge>=threshold) = 1;
    end
end

