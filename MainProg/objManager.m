classdef objManager
    
    properties
        objs;
        objTmp;
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
    end
    
end

