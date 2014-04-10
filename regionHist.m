function hists = regionHist(imSrc,bwIm,boxxes)
    hists = zeros(size(boxxes,1),256);
    for i = 1:size(boxxes,1)
        box = boxxes(i,1:4);
        partSrc = imSrc(box(2):box(4),box(1):box(3));
        partBW = bwIm(box(2):box(4),box(1):box(3));
        hists(i,:) = imhist(partBW.*partSrc);
    end
end

