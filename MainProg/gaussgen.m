function gx = gaussgen(size,sigma)
    % gen 1-d gaussian filter
    s = floor(size/2);
    x2 = (-s:s).^2;
    gx = exp(-x2/(2*sigma*sigma));
    gx = gx/sum(gx);
end

