vid = vision.VideoFileReader('TownCentre.avi');
bg = im2double(imread('background.tif'));

hFig = figure();
while ishandle(hFig)
    if isDone(vid)
        reset(vid);
    end
    
    newframe = step(vid);
    newgray = rgb2gray(newframe);
    
    VM = videoMask(newgray);
    OM = objManager();
    
    nframe = 1;
    
    while ~isDone(vid)
        if ~ishandle(hFig)
            break;
        end
        
        nframe = nframe + 1;
        
        %oldframe = newframe;
        oldgray = newgray;
        newframe = step(vid);
        newgray = rgb2gray(newframe);
%         VM = VM.objectMaskExtraction(oldgray,newgray);
%         [box,hist] = VM.extractHistAndBox(newgray);        
%         
%         if nframe > 10
%             OM = OM.update(box,hist);
%         end
        
        BDM = VM.bgDiff(newgray,bg);
        showFrame(OM,BDM,newgray);
    end
end

release(vid);
close all;