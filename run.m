close all;
clear all;

global gId;
gId = 0;
ResourcePath = '.\Resource';
Helper = '.\helper';
addpath(ResourcePath);
addpath(Helper);

vid = vision.VideoFileReader('people.mp4');

hFig = figure();
while ishandle(hFig)
    if isDone(vid)
        reset(vid);
    end
    objs = initObject();
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
        subplot(1,2,2),imshow(newframe);
        
        
        labelsBox = findBoxOfLabels(L,num);
        lb = labelsBox(labelsBox(:,5)==1,1:4);
        hists = regionHist(newframe,BW,lb);
%         disp(size(hists,1));
        objs = updateObject(objs,lb,hists);       
        % Draw boxxes
%         for i = 1:size(labelsBox,1)
%             %disp([ i, labelsBox(i,5)]);
%             if (labelsBox(i,1) ~= labelsBox(i,3))&& labelsBox(i,5) == 1
%                 x = labelsBox(i,1);
%                 y = labelsBox(i,2);
%                 w = abs(labelsBox(i,3) - labelsBox(i,1));
%                 h = abs(labelsBox(i,4) - labelsBox(i,2));
%                 if w ~= 0 && h ~= 0 && w*h > 150
%                     rectangle('Position',[x y w h], 'LineWidth',1, 'EdgeColor','g');                   
%                 end
%                 axis off;
%                 
%                 %plot::Rectangle(x, x + w, y, y + h);
%             end
%         end

        for i = 1:size(objs,2)
            %\\disp([ i, labelsBox(i,5)]);
%             disp(size(objs(i).box,1));
            box = objs(i).box(end,:);
%             disp(box);
%             disp(i);
%             if box(1) ~= box(3)
            x = box(1);
            y = box(2);
            w = abs(box(3) - box(1));
            h = abs(box(4) - box(2));
            if w ~= 0 && h ~= 0 && w*h > 150
                rectangle('Position',[x y w h], 'LineWidth',1, 'EdgeColor','r');                   
            end

                %plot::Rectangle(x, x + w, y, y + h);
%             end
        end        
        

        %% Draw setting
        axis off;
        pause(1/30);        
    end
end

release(vid);
close all;