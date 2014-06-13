classdef BlobAnalys
    
    properties
        Method;
        RMask; PMask;
        epsilon;
        BG;
        IOM;
        FDM; BDM;
        SI; BI;
        iBox;
    end
    
    methods
        function BA = BlobAnalys(method,vid)
            
            % init background model
            if strcmp(method,'bgStatic')
                BA.Method = 'bgStatic';
                nFrame = 1;
                thresh = 0.05;
            elseif strcmp(method,'bgExtract')
                BA.Method = 'bgExtract';
                nFrame = 10;
                thresh = 0.05;
            elseif strcmp(method,'bgUpdate')
                BA.Method = 'bgUpdate';
                nFrame = 1;
                thresh = 0.05;
            end
            BA = BA.InitBackground(vid,nFrame,thresh);
            reset(vid);
            
            % init system analyser
            initFrame = step(vid);
            [BA.RMask,BA.PMask] = setRegion(initFrame);
            if strcmp(BA.Method,'bgStatic')
                % do nothing
            elseif strcmp(BA.Method,'bgUpdate')
                BA.epsilon = ones(size(initFrame));
                BA.epsilon = BA.epsilon*0.05;
            elseif strcmp(BA.Method,'bgExtract')
                BA.Method = method;
                BA.FDM = false(size(initFrame,1),size(initFrame,2));
                BA.BDM = false(size(BA.FDM));
                BA.SI  = zeros(size(BA.FDM));
            end
            reset(vid);
        end
        
        function BA = InitBackground(BA, vid, nFrame, thresh)
            initBG = step(vid);
            fgMask = false(size(initBG,1), size(initBG,2));
            for i = 2:nFrame
                nextframe = step(vid);
                Rdiff = abs(initBG(:,:,1)-nextframe(:,:,1));
                Gdiff = abs(initBG(:,:,2)-nextframe(:,:,2));
                Bdiff = abs(initBG(:,:,3)-nextframe(:,:,3));
                diff = (Rdiff>thresh)|(Gdiff>thresh)|(Bdiff>thresh);
                fgMask = fgMask | diff;
            end
            fgMask = expand(fgMask,1);
            fgMask = imfill(fgMask,'holes');
            fgMask = bwareaopen(fgMask,30);
            
            BA.BI = ~fgMask;
            BA.BG = zeros(size(initBG));
            BA.BG(:,:,1) = initBG(:,:,1).*BA.BI;
            BA.BG(:,:,2) = initBG(:,:,2).*BA.BI;
            BA.BG(:,:,3) = initBG(:,:,3).*BA.BI;
            
            function newBW = expand(bw,val)
                [row, col] = size(bw);
                newBW = false(row,col);
                for r = 1+val:row-val
                    for c = 1+val:col-val
                        if bw(r,c) == 1
                            newBW(r-val:r+val,c-val:c+val) = 1;
                        end
                    end
                end
            end
        end
        
        function BA = ExtractMask(BA, oldframe, newframe)
            alpha = 0.01;
            K = 2;
            bgThresh = 0.1;
            fgThresh = 0.05;
            FrameThresh = 100;
            smallArea = 120;            
            
            if strcmp(BA.Method,'bgStatic')
                BA.IOM = BGStatic();
            elseif strcmp(BA.Method,'bgExtract')
                BA.IOM = BGExtract();
            elseif strcmp(BA.Method,'bgUpdate')
                BA.IOM = BGUpdate();
            end
            
            function IOM = BGStatic()
                Rdiff = abs(BA.BG(:,:,1)-newframe(:,:,1));
                Gdiff = abs(BA.BG(:,:,2)-newframe(:,:,2));
                Bdiff = abs(BA.BG(:,:,3)-newframe(:,:,3));
                IOM = (Rdiff>bgThresh)|(Gdiff>bgThresh)|(Bdiff>bgThresh);
                IOM = bwareaopen(IOM,smallArea);
                IOM = imfill(IOM,'holes');
            end
            
            function IOM = BGUpdate()
                BA.BG = alpha*newframe + (1-alpha)*BA.BG;
                d = abs(newframe - BA.BG);
                BA.epsilon = sqrt(alpha*d.^2 + (1-alpha)*BA.epsilon.^2);
                
                mask = false(size(newframe));
                mask(d > K*BA.epsilon) = 1;
                
                IOM = mask(:,:,1)|mask(:,:,2)|mask(:,:,3);
                IOM = bwareaopen(IOM,smallArea);
                IOM = imfill(IOM,'holes');
            end
            
            function IOM = BGExtract()
                
                Rdiff = abs(oldframe(:,:,1)-newframe(:,:,1));
                Gdiff = abs(oldframe(:,:,2)-newframe(:,:,2));
                Bdiff = abs(oldframe(:,:,3)-newframe(:,:,3));
                BA.FDM = (Rdiff>fgThresh)|(Gdiff>fgThresh)|(Bdiff>fgThresh);
                
                Rdiff = abs(BA.BG(:,:,1)-newframe(:,:,1));
                Gdiff = abs(BA.BG(:,:,2)-newframe(:,:,2));
                Bdiff = abs(BA.BG(:,:,3)-newframe(:,:,3));
                BA.BDM = (Rdiff>bgThresh)|(Gdiff>bgThresh)|(Bdiff>bgThresh);
                
                BA.SI = (~BA.FDM).*(BA.SI+1);
                tmp = BA.BDM.*BA.SI; 
                BGChange = tmp;BGChange(:,:,2) = tmp;BGChange(:,:,3) = tmp;
                
                BA.BG(BGChange == FrameThresh) = newframe(BGChange == FrameThresh);                
                BA.BI(BA.SI == FrameThresh) = 1;
                
                IOM1 = BA.BDM.*BA.BI;
                IOM2 = BA.FDM.*(~BA.BI);
                IOM = IOM1|IOM2;
                
                IOM = bwareaopen(IOM,smallArea);
                IOM = imfill(IOM,'holes');
                
                % update background for light change
                alfa = 0.05;
                BA.BG(IOM == 0) = (1-alfa)*BA.BG(IOM == 0) + alfa*newframe(IOM == 0);                 
            end
        end 
        
        function [BA, iBox, hist] = extractHistAndBox(BA,Im)
            % magic
            Hjoin = 5;
            Vjoin = 0;
            
            % label binary image and detect boxxes
            [L,nLabel] = bwlabel(BA.IOM,8);
            iBox = zeros(nLabel,4);
            for i = 1:nLabel
                [r, c] = find(L==i);
                iBox(i,:) = [min(c) min(r) max(c)-min(c) max(r)-min(r)]; %box[x y w h]
            end
            
            % Join intersect boxxes
            still = true(nLabel,1);
            for i = 1:nLabel
                for j = 1:i-1
                    if still(j) && boxIntersect(iBox(i,:),iBox(j,:),Vjoin,Hjoin)
                        iBox(i,:) = boxUnion(iBox(i,:),iBox(j,:));
                        still(j) = 0;
                    end
                end
            end
            iBox = iBox(still==1,:);
            
            % remove out-of-boundaries boxxes
            still = true(size(iBox,1),1);
            for i = 1:size(iBox,1)
                still(i) = withinBoundary(iBox(i,:));
            end
            iBox = iBox(still==1,:);
            
            BA.iBox = iBox;
            
            % Get hue histogram in box
            Im = rgb2hsv(Im);
            Im = Im(:,:,1);
            hist = zeros(size(iBox,1),256);
            for i = 1:size(iBox,1)
                b = iBox(i,:);
                rgIm = Im(b(2):b(2)+b(4),b(1):b(1)+b(3));
                rgBW = BA.IOM(b(2):b(2)+b(4),b(1):b(1)+b(3));
                hist(i,:) = imhist(rgIm(rgBW==1));
            end
            
            function r = boxIntersect(b1,b2,vJoin,hJoin)
                r = (b1(1)-vJoin < b2(1)+b2(3)+vJoin) &&...
					(b2(1)-vJoin < b1(1)+b1(3)+vJoin) &&...
					(b1(2)-hJoin < b2(2)+b2(4)+hJoin) &&...
					(b2(2)-hJoin < b1(2)+b1(4)+hJoin);
            end
                        
            function box = boxUnion(b1,b2)
                x = min([b1(1) b2(1)]);
                y = min([b1(2) b2(2)]);
                w = max([b1(1)+b1(3), b2(1)+b2(3)]) - x;
                h = max([b1(2)+b1(4), b2(2)+b2(4)]) - y;
                box = [x y w h];
            end
            
            function r = withinBoundary(box)
                % get center point
                xc = round(box(1)+box(3)/2);
                yc = round(box(2)+box(4)/2);
                r = BA.RMask(yc,xc);
            end
        end
    end
    
end