function G = smooth(I,size,sigma)
% Gaussian filter for smoothing and remove noise
    gx = gaussgen(size,sigma);
    G = conv2(conv2(I,gx,'same'),gx','same');
end