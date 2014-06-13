vid = vision.VideoFileReader('MVI_8863.avi');
hFig = figure();


% init analyser
BA = BlobAnalys('bgStatic',vid);
OM = ObjectManager();

% get 1st frame
newframe = step(vid);
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