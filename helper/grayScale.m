function grayIm = grayScale( Im )
    % convert to grayscale image within range of [0,1]
    grayIm = double(rgb2gray(Im));
    if max(grayIm) > 1.0
        grayIm = grayIm/255;
    end
end

