function hFa = rgbHistogram( srcIm )
    [row,column,channel] = size(srcIm);
    nRoom = 100;
    step = 1.0/nRoom;
    hFa = zeros(channel,nRoom);

    for color = 1:channel;
        clIm = srcIm(1:row,1:column,color);
        tmp = zeros(nRoom);
        for iter = 1:row*column
            room = floor(clIm(iter)/step) + 1;
            tmp(room) = tmp(room) + 1;
        end
        tmp = tmp/sum(tmp);
        hFa(color,1:nRoom) = tmp;
    end
end

