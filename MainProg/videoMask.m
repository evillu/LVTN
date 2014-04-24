classdef videoMask
    
    properties
        FDM;
        OFM;
        BDM;
        SI;
        BI;
        BG;
        IOM;
    end
    
    methods
        function VM = videoMask(initframe)
            VM.FDM = false(size(initframe));
            VM.BDM = false(size(initframe));
            VM.SI = zeros(size(initframe));
            VM.BI = false(size(initframe));
            VM.BG = zeros(size(initframe));
            VM.IOM = false(size(initframe));
        end
        
        function VM = objectMaskExtraction(VM,oldgray,newgray)
            fdthresh = 0.05;
            bdthresh = 0.15;
            Fthresh = 10;
            FD = abs(newgray - oldgray);
            VM.FDM = FD>fdthresh;
            BD = abs(newgray - VM.BG);
            VM.BDM = BD>bdthresh;
            VM.SI = (~VM.FDM).*(VM.SI+1);
            BGChange = VM.BDM.*VM.SI;
            VM.BG(BGChange == Fthresh) = newgray(BGChange == Fthresh);
            VM.BI(BGChange == Fthresh) = 1;
            VM.IOM = VM.BI.*VM.BDM + (~VM.BI).*VM.FDM;
%             VM.BDM = bwareaopen(VM.BDM&(~VM.IOM),40);
%             VM.FDM = bwareaopen(VM.FDM,40);  
            VM.IOM = bwareaopen(VM.IOM,80);            
            VM.IOM = imdilate(VM.IOM,strel('line',9,90));
            VM.IOM = imfill(VM.IOM,'holes');
        end
        
        function VM = movingMask(VM,oldgray,newgray)
            ofthresh = 0.05;
            bdthresh = 0.15;
            Fthresh = 10;
            [u,v] = LucasKanade2(oldgray,newgray);
            OF = u.*u + v.*v;
            VM.OFM = OF>ofthresh;
            BD = abs(newgray - VM.BG);
            VM.BDM = BD>bdthresh;
            VM.SI = (~VM.OFM).*(VM.SI+1);
            BGChange = VM.BDM.*VM.SI;
            VM.BG(BGChange == Fthresh) = newgray(BGChange == Fthresh);
            VM.BI(BGChange == Fthresh) = 1;
            VM.IOM = VM.BI.*VM.BDM + (~VM.BI).*VM.OFM;
%             VM.BDM = bwareaopen(VM.BDM&(~VM.IOM),40);
%             VM.FDM = bwareaopen(VM.FDM,40);  
            VM.IOM = bwareaopen(VM.IOM,80);            
            VM.IOM = imdilate(VM.IOM,strel('line',9,90));
            VM.IOM = imfill(VM.IOM,'holes');
        end
        
        function [iBox, hist] = extractHistAndBox(VM,Im)
            
            % label binary image and detect boxxes
            [L,nLabel] = bwlabel(VM.IOM,8);
            iBox = zeros(nLabel,4);
            for i = 1:nLabel
                [r, c] = find(L==i);
                iBox(i,:) = [min(c) min(r) max(c)-min(c) max(r)-min(r)]; %box[x y w h]
            end
            
            % Join intersect boxxes
            still = true(nLabel,1);
            for i = 1:nLabel
                for j = 1:i-1
                    if still(j) && boxIntersect(iBox(i,:),iBox(j,:))
                        iBox(i,:) = boxUnion(iBox(i,:),iBox(j,:));
                        still(j) = 0;
                    end
                end
            end
            iBox = iBox(still==1,:);
            
            % Join vertical parts boxxes
%             dv = 10;
%             still = true(1,size(iBox,1));
%             for i = 1:size(iBox,1)
%                 for j = 1:i-1
%                     if still(j) && boxFragment(iBox(i,:),iBox(j,:),dv)
%                         iBox(i,:) = boxUnion(iBox(i,:),iBox(j,:));
%                         still(j) = 0;
%                     end
%                 end
%             end
%             iBox = iBox(still==1,:); 
            
            % Get hue histogram in box
            Im = rgb2hsv(Im);
            Im = Im(:,:,1);
            hist = zeros(size(iBox,1),256);
            for i = 1:size(iBox,1)
                b = iBox(i,:);
                rgIm = Im(b(2):b(2)+b(4),b(1):b(1)+b(3));
                rgBW = VM.IOM(b(2):b(2)+b(4),b(1):b(1)+b(3));
                hist(i,:) = imhist(rgIm(rgBW==1));
            end
            
            function r = boxIntersect(b1,b2)
                r = (b1(1) < b2(1)+b2(3)) &&...
					(b2(1) < b1(1)+b1(3)) &&...
					(b1(2) < b2(2)+b2(4)) &&...
					(b2(2) < b1(2)+b1(4));
            end
            
            % detect box for human body part fragmented;
            function r = boxFragment(b1,b2,d)
                r = b1(3)*b1(4) < b2(3)*b2(4)/3 &&...
                    (b1(1) > b2(1)-d/2) &&...
					(b1(1)+b1(3) < b2(1)+b2(3)+d/2) &&...
					(   (b1(2)-d < b2(2)+b2(4) && b1(2)+b1(4) > b2(2)+b2(4)) ||...
                        (b1(2)+b1(4)+d > b2(2) && b1(2) < b2(2)));
            end
            
            function box = boxUnion(b1,b2)
                x = min([b1(1) b2(1)]);
                y = min([b1(2) b2(2)]);
                w = max([b1(1)+b1(3), b2(1)+b2(3)]) - x;
                h = max([b1(2)+b1(4), b2(2)+b2(4)]) - y;
                box = [x y w h];
            end
        end
        
        function VM = bgDiff(VM,frame,bg)
            thresh = 0.1;
            diff = abs(frame - bg);
            bdm = diff > thresh;
            bdm = bwareaopen(bdm,20);
%             bdm = imdilate(bdm,ones(3));
            bdm = imclose(bdm,[0 1 1 0;1 1 1 1;1 1 1 1;0 1 1 0]);
            VM.IOM = imfill(bdm,'holes');
        end
    end
    
end

