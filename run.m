close all;
clear all;

ResourcePath = 'H:\Matlab\Resource';
Helper = 'H:\Matlab\LVTN\helper';
addpath(ResourcePath);
addpath(Helper);

vid = vision.VideoFileReader('street.avi');

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
        subplot(1,2,1),imshow(newframe);
        subplot(1,2,2),imshow(BW);
        %% Draw setting
        axis off;
        pause(0.01);        
    end
end

release(vid);
close all;