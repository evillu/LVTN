classdef videoMask
    
    properties
        FDM;
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
            Fthresh = 80;
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
            %VM.IOM = bwareaopen(VM.IOM,20);
            %VM.IOM = bwmorph(VM.IOM,'bridge');
%             VM.IOM = imclose(VM.IOM,[0 1 1 0;1 1 1 1;1 1 1 1;0 1 1 0]);
%            VM.IOM = imdilate(VM.IOM,ones(3));
            %VM.IOM = imfill(VM.IOM,'holes');
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
            
            % Get histogram in box
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
            
            function box = boxUnion(b1,b2)
                x = min([b1(1) b2(1)]);
                y = min([b1(2) b2(2)]);
                w = max([b1(1)+b1(3), b2(1)+b2(3)]) - x;
                h = max([b1(2)+b1(4), b2(2)+b2(4)]) - y;
                box = [x y w h];
            end
        end
        
        function bdm = bgDiff(VM,frame,bg)
            thresh = 0.1;
            diff = abs(frame - bg);
            bdm = diff > thresh;
            bdm = bwareaopen(bdm,30);
%             bdm = imdilate(bdm,ones(3));
            bdm = imfill(bdm,'holes');
        end
    end
    
end

