close all;
clear all;

ResourcePath = '.\Resource';
Helper = '.\helper';
addpath(ResourcePath);
addpath(Helper);

vid = vision.VideoFileReader('street.mp4');

hFig = figure();
while ishandle(hFig)
    if isDone(vid)
        reset(vid);
    end
    
    newframe = smooth(grayScale(step(vid)),5,1);
    bg = newframe;
    while ~isDone(vid)
        if ~ishandle(hFig)
            break;
        end
        oldframe = newframe;
        frame = step(vid);
        newframe = smooth(grayScale(frame),5,1);
%         %% Optical Flow
%         [u,v] = LucasKanade2(oldframe, newframe);
%         bwIm = (u.*u + v.*v) > 1e-6;
%         subplot(1,2,1),imshow(oldframe);
%         subplot(1,2,2),imshow(bwIm);
        %% Background subtraction
        [bg,bwIm] = bgSubtraction(bg,newframe);
        BW = blobEnhance(bwIm,2);
        [L, num] = bwlabel(BW,8);
        
        subplot(1,2,1),imshow(bwIm);
        subplot(1,2,2),imshow(L);
        
        labelsMinMax = findBoxOfLabels(L,num);
        for i = 1:size(labelsMinMax,1)
            if labelsMinMax(i,1) ~= labelsMinMax(i,3)
                x = labelsMinMax(i,2);
                y = labelsMinMax(i,1);
                h = labelsMinMax(i,3) - labelsMinMax(i,1);
                w = labelsMinMax(i,4) - labelsMinMax(i,2);
                if w ~= 0 && h ~= 0 && w*h > 150
                    rectangle('Position',[x y w h], 'LineWidth',1, 'EdgeColor','b');                   
                end
                axis off;
                
                %plot::Rectangle(x, x + w, y, y + h);
            end
        end
        
        

        %% Draw setting
        axis off;
        pause(0.01);        
    end
end

release(vid);
close all;