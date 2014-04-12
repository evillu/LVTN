function hists = regionHist(imSrc,bwIm,boxxes)
    hists = zeros(size(boxxes,1),256);
    for i = 1:size(boxxes,1)
        box = boxxes(i,:);
        partSrc = imSrc(box(2):box(4),box(1):box(3));
        partBW = bwIm(box(2):box(4),box(1):box(3));
        hists(i,:) = imhist(partBW.*partSrc);
        hists(i,1) = 0;
    end
end

