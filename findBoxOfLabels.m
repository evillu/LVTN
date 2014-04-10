function labels = findBoxOfLabels(bw,num)
% return labelboxes that contains labels available on the image bw
% labels(pixel,1) x coord of min pixel
% labels(pixel,2) y coord of min pixel
% labels(pixel,3) x coord of min pixel
% labels(pixel,4) y coord of min pixel
% labels(pixel,5) pixel is available or not
        labels = zeros(num,5);
        finalLabels = zeros(num,5);
        for i = 1:size(bw,1)
            for j = 1:size(bw,2)
                pixel = bw(i,j);
                if( pixel ~= 0)
                    if  labels(pixel,1) == 0
                        labels(pixel,1) = j;
                        labels(pixel,2) = i;
                        labels(pixel,3) = j;
                        labels(pixel,4) = i;                      
                    else
                        if j < labels(pixel,1)
                            labels(pixel,1) = j;
                        elseif i < labels(pixel,2)
                            labels(pixel,2) = i;
                        elseif j > labels(pixel,3)
                            labels(pixel,3) = j;
                        elseif i > labels(pixel,4)
                            labels(pixel,4) = i;
                        end
                    
                    end
                    labels(pixel,5) = 1;
                    finalLabels(pixel,5) = 1;
                end
            end
        end
        %disp(labels);
        % detect any box inside other box or intersect with other box,
        % remove it
        for i = 1:size(labels,1)
            if labels(i,5) == 1
                for j = i + 1: size(labels,1)
                    if labels(j,5) == 1
                        box1 = labels(i,1:4);
                        box1(3) = box1(3) - box1(1);
                        box1(4) = box1(4) - box1(2);
                        box2 = labels(j,1:4);
                        box2(3) = box2(3) - box2(1);
                        box2(4) = box2(4) - box2(2);

                        if rectint(box1, box2) > 0
%                             disp(rectint(box1,box2));    
                            box = BBoxUnion(box1,box2);
     
                            if box(3) > 0 
                                labels(i,1) = box(1);
                                labels(i,2) = box(2);
                                labels(i,3) = box(1) + box(3);
                                labels(i,4) = box(2) + box(4);
                                labels(i,5) = 1;
                                labels(j,5) = 0;

                            end
                        end
                    end
                    
                end

            end
        end
end













