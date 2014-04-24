classdef objManager
    
    properties
        objs;
        objTmp;
        hidObj;
        maxId;
    end
    
    methods
        function OM = objManager()
            OM.maxId = 0;
            OM.objs = struct (...
                'id',{},...
                'type',{},...
                'hist',{},...
                'box',{},...
                'hit',{},...
                'age',{} );
            OM.objTmp = struct (...
                'hist',{},...
                'box',{},...
                'hit',{},...
                'age',{} );
            OM.hidObj = struct (...
                'id',{},...
                'hist',{} );
        end
        
        function OM = update(OM,bbox,hists)
            ageThresh = 10;
            histEsp = 0.005;
            
            hitBox = false(1,size(bbox,1));
            
            % update Main tracking objects
            i = 1;
            while i < size(OM.objs,2)
                % increase age
                OM.objs(i).age = OM.objs(i).age + 1;
                
                % predict new location
                box1 = OM.objs(i).box(end-1,:);
                box2 = OM.objs(i).box(end,:);
                OM.objs(i).box(end+1,:) = nextLocation(box1,box2);
                OM.objs(i).hit = 0;
                
                % measure location on current frame
                for h = 1:size(hists,1)
                    if ~hitBox(h) && histMatch(OM.objs(i).hist,hists(h,:),histEsp)
                        hitBox(h) = 1;
                        OM.objs(i).hist = hists(h,:);
                        OM.objs(i).age = 1;
                        OM.objs(i).box(end,:) = bbox(h,:);
                        OM.objs(i).hit = 1;
                        break;
                    end
                end
                
                % keep 10 last boxxes
                if size(OM.objs(i).box,1) > 10
                    OM.objs(i).box = OM.objs(i).box(2:end,:);
                end
                
                % remove lose tracks objects
                if OM.objs(i).age > ageThresh
                    OM.objs(i) = [];
                end
                
                i = i+1;
            end
            
            % update portential objects or delete it out of queue
            for i = 1:size(OM.objTmp,2)
                % measure location on current frame
                for h = 1:size(hists,1)
                    % if histogram matched, make it new Main object
                    if ~hitBox(h) && histMatch(OM.objTmp(i).hist,hists(h,:),histEsp)
                        hitBox(h) = 1;
                        indx = size(OM.objs,2) + 1;
                        OM.maxId = OM.maxId + 1;
                        OM.objs(indx).id = OM.maxId;
                        OM.objs(indx).type = 1;
                        OM.objs(indx).hist = hists(h,:);                        
                        OM.objs(indx).box = OM.objTmp(i).box;
                        OM.objs(indx).box(end+1,:) = bbox(h,:);                        
                        OM.objs(indx).age = 1;
                        OM.objs(indx).hit = 1;
                        break;
                    end
                end                
            end
            
            % add remaining boxxes to a portential queue
            OM.objTmp = [];
            for i = 1:size(bbox,1)
                if ~hitBox(i)
                    indx = size(OM.objTmp,2) + 1;
                    OM.objTmp(indx).hist = hists(i,:);
                    OM.objTmp(indx).box = bbox(i,:);                    
                end
            end
            
            %% helper functions
            function box = nextLocation(b1,b2)
                v = [b2(1)-b1(1)+floor((b2(3)-b1(3))/2), b2(2)-b1(2)+floor((b2(4)-b1(4))/2)];
                box = [b2(1)+v(1), b2(2)+v(2),b2(3), b2(4)];
            end
            
            function match = histMatch(h1,h2,esp)
                nh1 = h1./sum(h1);
                nh2 = h2./sum(h2);
                match = sum((nh1-nh2).^2) < esp;
                %disp(match);
            end
        end
        
        function [OM,boxStat] = update2(OM,bbox,hists)
            ageThresh = 5;
            histEsp = 0.01;
            Swidth = 640;
            Sheight = 360;
            
            boxStat = struct('iBox',{},'mBox',{},'hBox',{},'jBox',{},'stat',{});
            for b = 1:size(bbox,1)
                boxStat(b).stat = 0;
            end
            
            % update Main tracking objects 
            for i = 1:size(OM.objs,2)
                % increase age
                OM.objs(i).age = OM.objs(i).age + 1;
                
                % predict new location
                box1 = OM.objs(i).box(end-1,:);
                box2 = OM.objs(i).box(end,:);
                OM.objs(i).box(end+1,:) = nextLocation(box1,box2);
                OM.objs(i).hit = 0;
                
                % calculate new measurement boxxes
                for b = 1:size(bbox,1)
                    [r1,r2,d] = boxOverlap(OM.objs(i).box(end,:),bbox(b,:),0.7,20);
                    if d || (r1 && r2)
                        boxStat(b).mBox(end+1) = i;
                    elseif r1
                        boxStat(b).jBox(end+1) = i;
                    elseif r2
                        boxStat(b).iBox(end+1) = i;
                    end
                end
                
                % check histogram
                for h = 1:size(hists,1)
                    if histMatch(OM.objs(i).hist,hists(h,:),histEsp)
                        boxStat(h).hBox(end+1) = i;
                    end
                end
                                
                % keep 10 last boxxes
                if size(OM.objs(i).box,1) > 10
                    OM.objs(i).box = OM.objs(i).box(2:end,:);
                end
                          
            end
            
            % assignment each box to object
            for b = 1:size(boxStat,2)
                % boxStat(b).stat = 0;    %stat: 0-nothing, 1-matchObject, 2-merge, 3-split
                
                if ~isempty(boxStat(b).mBox)
                    hit = intersect(boxStat(b).mBox,boxStat(b).hBox);
                    indx = boxStat(b).mBox(1);
                    if hit, indx = hit(1); end
                    
                    boxStat(b).stat = 1;
                    OM.objs(indx).hist = hists(b,:);
                    OM.objs(indx).box(end,:) = bbox(b,:);
                    OM.objs(indx).age = 1;                    
                    OM.objs(indx).hit = 1;
                elseif size(boxStat(b).jBox,2) > 1
                    objId = [];
                    disp(boxStat(b).jBox);
                    for i = boxStat(b).jBox
                        objId = [objId,OM.objs(i).id];
                        if OM.objs(i).type == 1
                            indx = size(OM.hidObj,2)+1;
                            OM.hidObj(indx).id = OM.objs(i).id;
                            OM.hidObj(indx).hist = OM.objs(i).hist;
                            OM.objs(i).type = 0;
                        end
                    end                    
                    disp(['joinning: ',num2str(objId)]);
                    boxStat(b).stat = 2;
                    type = size(objId,2);
                    indx = size(OM.objs,2)+1;
                    OM.objs(indx).id = objId;
                    OM.objs(indx).type = type;
                    OM.objs(indx).hist = hists(b,:);
                    OM.objs(indx).box = [bbox(b,:); bbox(b,:)];
                    OM.objs(indx).age = 1;                    
                    OM.objs(indx).hit = 1;
                elseif ~isempty(boxStat(b).iBox)
                    i = boxStat(b).iBox(1);
                    objId = OM.objs(i).id;
                    disp(['splitting: ',num2str(objId)]);
                    for id = objId
                        
                        hidden = OM.hidObj([OM.hidObj.id] == id);
                        if ~isempty(hidden) && histMatch(hidden(1).hist,hists(b,:),histEsp)
                            boxStat(b).stat = 3;                            
                            indx = size(OM.objs,2)+1;
                            OM.objs(indx).id = id;
                            OM.objs(indx).type = 1;
                            OM.objs(indx).hist = hists(b,:);
                            OM.objs(indx).box = [bbox(b,:); bbox(b,:)];
                            OM.objs(indx).age = 1;                    
                            OM.objs(indx).hit = 1;
                            OM.hidObj([OM.hidObj.id] == id) = [];
                            OM.objs(i).type = OM.objs(i).type - 1;
                            rId = OM.objs(i).id;
                            rId = rId(rId~=id);
                            OM.objs(i).id = rId;
                            break;
                        end
                    end
                end
                
                if boxStat(b).stat == 0
                    % new object
                    
                    indx = size(OM.objs,2)+1;
                    OM.maxId = OM.maxId +1;
                    OM.objs(indx).id = OM.maxId;
                    OM.objs(indx).type = 1;
                    OM.objs(indx).hist = hists(b,:);
                    OM.objs(indx).box = [bbox(b,:); bbox(b,:)];
                    OM.objs(indx).age = 1;
                    OM.objs(indx).hit = 1;
%                     disp(['new: ',num2str(OM.objs(indx).id)]);
                end
            end
            
            % Remove garbage object
            i = 1;
            while i < size(OM.objs,2)
                % remove lose tracks objects
                if OM.objs(i).age > ageThresh || OM.objs(i).type == 0 || outOfScreen(OM.objs(i).box(end,:),Swidth,Sheight)
%                     disp(['remove: ',num2str([OM.objs(i).id,OM.objs(i).type,OM.objs(i).age])]);
                    OM.objs(i) = [];
                    i = i-1;
                end
                i = i+1;
            end
                        
            %% helper functions
            function box = nextLocation(b1,b2)
                v = [b2(1)-b1(1)+floor((b2(3)-b1(3))/2), b2(2)-b1(2)+floor((b2(4)-b1(4))/2)];
                box = [b2(1)+v(1), b2(2)+v(2),b2(3), b2(4)];
            end
            
            function match = histMatch(h1,h2,esp)
                nh1 = h1./sum(h1);
                nh2 = h2./sum(h2);
                match = sum((nh1-nh2).^2) < esp;
            end
            
            function [r1,r2,d] = boxOverlap(b1,b2,overlap,dist)
                if (b1(1) <= b2(1)+b2(3)) &&...
					(b2(1) <= b1(1)+b1(3)) &&...
					(b1(2) <= b2(2)+b2(4)) &&...
					(b2(2) <= b1(2)+b1(4)) % end condition
                
                    x = max(b1(1),b2(1));
                    y = max(b1(2),b2(2));
                    width = min(b1(1)+b1(3),b2(1)+b2(3)) - x;
                    height = min(b1(2)+b1(4),b2(2)+b2(4)) - y;
                    
                    dx = (b1(1) + b1(3)/2) - (b2(1) + b2(3)/2);
                    dy = (b1(2) + b1(4)/2) - (b2(2) + b2(4)/2);
                    
                    r1 = width*height > b1(3)*b1(4)*overlap;
                    r2 = width*height > b2(3)*b2(4)*overlap;
                    d = dx*dx+dy*dy < dist*dist;
                else
                    r1 = false;
                    r2 = false;
                    d = false;
                end
            end
            
            function r = outOfScreen(box,width,height)
                centerx = box(1) + box(3)/2;
                centery = box(2) + box(4)/2;
                r = centerx < 0 || centerx > width || centery < 0 || centery > height;
            end
        end
    end
    
end

