classdef BlobAnalys
    
    properties
        Method;
        RMask; PMask;
        BG; BGTmp;
        OM;
        FDM; BDM;
        SI; BI;
        iBox;
    end
    
    methods
        function BA = BlobAnalys(method,initFrame)
            [BA.RMask,BA.PMask] = setRegion(initFrame);
            if nargin == 0;
                BA.Method = 'bgUpdate';
            elseif strcmp(method,'bgExtract')
                BA.Method = method;
                BA.BG = initFrame;
            elseif strcmp(method,'bgUpdate')
                BA.Method = method;
                BA.BG = initFrame;
                BA.BGTmp = initFrame;
                BA.FDM = false(size(initFrame,1),size(initFrame,2));
                BA.BDM = false(size(BA.FDM));
                BA.BI  = false(size(BA.FDM));
                BA.SI  = zeros(size(BA.FDM));
            end
        end
        
        function BA = ExtractMask(BA, oldframe, newframe)
            bgThresh = 0.1;
            FDThresh = 30;
            smallArea = 120;
            
            if strcmp(BA.Method,'bgExtract')
                BA.OM = BGExtract();
            elseif strcmp(BA.Method,'bgUpdate')
                BA.OM = BGUpdate();
            end
            
            function OM = BGExtract()
                Rdiff = abs(BA.BG(:,:,1)-newframe(:,:,1));
                Gdiff = abs(BA.BG(:,:,2)-newframe(:,:,2));
                Bdiff = abs(BA.BG(:,:,3)-newframe(:,:,3));
                OM = (Rdiff>bgThresh)|(Gdiff>bgThresh)|(Bdiff>bgThresh);
                OM = bwareaopen(OM,smallArea);
                OM = imfill(OM,'holes');
%                 OM = imdilate(OM,ones(3));
            end
            
            function OM = BGUpdate()
                
                Rdiff = abs(oldframe(:,:,1)-newframe(:,:,1));
                Gdiff = abs(oldframe(:,:,2)-newframe(:,:,2));
                Bdiff = abs(oldframe(:,:,3)-newframe(:,:,3));
                BA.FDM = (Rdiff>bgThresh)|(Gdiff>bgThresh)|(Bdiff>bgThresh);
                
                Rdiff = abs(BA.BG(:,:,1)-newframe(:,:,1));
                Gdiff = abs(BA.BG(:,:,2)-newframe(:,:,2));
                Bdiff = abs(BA.BG(:,:,3)-newframe(:,:,3));
                BA.BDM = (Rdiff>bgThresh)|(Gdiff>bgThresh)|(Bdiff>bgThresh);
                
                BA.SI = (~BA.FDM).*(BA.SI+1);
                BGChange = BA.BDM.*BA.SI;
                BA.BG(BGChange == FDThresh) = newframe(BGChange == FDThresh);
                BA.BI(BGChange == FDThresh) = 1;
                OM = BA.BI.*BA.BDM + (~BA.BI).*BA.FDM;
                OM = bwareaopen(OM,smallArea);
                OM = imfill(OM,'holes');
            end
        end 
        
        function [BA, iBox, hist] = extractHistAndBox(BA,Im)
            % magic
            Hjoin = 5;
            Vjoin = 0;
            
            % label binary image and detect boxxes
            [L,nLabel] = bwlabel(BA.OM,8);
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
                rgBW = BA.OM(b(2):b(2)+b(4),b(1):b(1)+b(3));
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