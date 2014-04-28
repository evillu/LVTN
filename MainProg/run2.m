vid = vision.VideoFileReader('MVI_8863.avi');
%bg = im2double(imread('background.tif'));

hFig = figure();

newframe = step(vid);

BA = BlobAnalys('bgExtract',newframe);
OM = objManager();

nframe = 1;

while ~isDone(vid)
    if ~ishandle(hFig)
        break;
    end
    %         res = input('next');
    nframe = nframe + 1;
    
    oldframe = newframe;
    newframe = step(vid);
    
    BA = BA.ExtractMask(oldframe, newframe);
    [BA, box,hist] = BA.extractHistAndBox(newframe);
    %         [box,hist] = VM.extractHistAndBox(newframe);
    %         if nframe>15
    %             OM = OM.update2(box,hist);
    %         end
    showFrame(BA,OM,newframe);
end

release(vid);
close all;