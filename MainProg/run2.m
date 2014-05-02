vid = vision.VideoFileReader('MVI_8863.avi');
hFig = figure();

% geta 1st frame to init data
newframe = step(vid);

BA = BlobAnalys('bgExtract',newframe);
OM = ObjectManager();

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
    [OM,Mobj] = OM.update(box,hist);
    
    showFrame(BA,OM,newframe);
end

release(vid);
close all;