vid = vision.VideoFileReader('MVI_8863.avi');
%bg = im2double(imread('background.tif'));

hFig = figure();
while ishandle(hFig)
    if isDone(vid)
        reset(vid);
    end
    
    newframe = step(vid);
    newgray = rgb2gray(newframe);
    bg = newgray;
    
    VM = videoMask(newgray);
    OM = objManager();
    
    nframe = 1;
    
    while ~isDone(vid)
        if ~ishandle(hFig)
            break;
        end
        
%         res = input('next');
        
        nframe = nframe + 1;
        
        %oldframe = newframe;
        oldgray = newgray;
        newframe = step(vid);
        newgray = im2double(rgb2gray(newframe));
        
%         VM = VM.bgDiff(newgray,bg);
%         VM = VM.objectMaskExtraction(oldgray,newgray);
%         [box,hist] = VM.extractHistAndBox(newframe);
%         if nframe>10
%             [OM,boxStat] = OM.update2(box,hist);
%         end
        VM = VM.objectMaskExtraction(oldgray,newgray);
        [box,hist] = VM.extractHistAndBox(newframe);
        if nframe>15
            OM = OM.update2(box,hist);
        end
        showFrame(VM,OM,newframe);
    end
end

release(vid);
close all;