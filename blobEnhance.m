function BW = blobEnhance(bwIm,level)
    BW = false(size(bwIm));
    for i = level+1:size(bwIm,1)-level
        for j = level+1:size(bwIm,2)-level
            if ~BW(i,j) && bwIm(i,j)
                BW(i-level:i+level,j-level:j+level) = 1;
            end
        end        
    end
end

