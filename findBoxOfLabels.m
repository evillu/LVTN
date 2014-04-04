function labels = findBoxOfLabels(bw,num)
        labels = zeros(num,4);
        for i = 1:size(bw,1)
            for j = 1:size(bw,2)
                pixel = bw(i,j);
                if( pixel ~= 0)
                    if  labels(pixel,1) == 0
                        labels(pixel,1) = i;
                        labels(pixel,2) = j;
                        labels(pixel,3) = i;
                        labels(pixel,4) = j;                      
                    else
                        if i < labels(pixel,1)
                            labels(pixel,1) = i;
                        elseif j < labels(pixel,2)
                            labels(pixel,2) = j;
                        elseif i > labels(pixel,3)
                            labels(pixel,3) = i;
                        elseif j > labels(pixel,4)
                            labels(pixel,4) = j;
                        end
                    
                    end
                end
            end
        end
end