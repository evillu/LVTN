function [bg,bwIm] = bgSubtraction(bg, newframe)
    alpha = 0.8;
    diff = abs(bg - newframe);
    bwIm = diff> (0.5e-1);
    bg = (1-alpha)*bg + alpha*newframe;
end

