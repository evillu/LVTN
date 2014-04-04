function grayIm = grayScale( Im )
    % convert to grayscale image within range of [0,1]
    gray1 = double(rgb2gray(Im));
    grayIm = mat2gray(gray1);
end

