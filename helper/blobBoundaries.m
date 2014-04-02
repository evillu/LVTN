function B = blobBoundaries(bw, blobsize)
    if nargin <2
       blobsize = 200; 
    end
    [maxR,maxC] = size(bw);
    B = [];
    access = false(maxR,maxC);
    [r,c] = find(bw==1);
    set(0,'RecursionLimit',1000);
    for i = 1:size(c,1)
        if access(r(i),c(i)) == 0
            % Box of the curent blob [maxR maxC minR minC]
            bbox = [r(i) c(i) r(i) c(i)];
            W = blobWeight(r(i),c(i));
            if W > blobsize
               B(end+1,1:4) = bbox;
            end
        end
    end
    
    function W = blobWeight(x,y)
        if (x>0 && x<maxR) && (y>0 && y<maxC) && bw(x,y) && ~access(x,y)
            access(x,y) = 1;
            bbox = [max(bbox(1),x) max(bbox(2),y) min(bbox(3),x) min(bbox(4),y)];
            W = 1 + blobWeight(x,y+1) + blobWeight(x+1,y) + blobWeight(x-1,y) + blobWeight(x,y-1);
        else
            W = 0;
        end
    end
end

