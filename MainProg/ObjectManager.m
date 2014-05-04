classdef ObjectManager
    %OBJECTMANAGER store tracked object and operate it
    
    properties
        maxId;
        obj; 
        hidObj;
    end
    
    methods
        function OM = ObjectManager()
            OM.maxId = 0;
            OM.obj = struct (...
                'id',{},...
                'type',{},...
                'hist',{},...
                'box',{},...
                'hit',{},...
                'age',{} );
            OM.hidObj = struct (...
                'id',{},...
                'hist',{},...
                'box',{} );
        end
        
        function [OM,Mobj] = update(OM,box,hist)
            % magix number
            D2Thresh = 3600;
            AgeThresh = 10;
            histEsp = 0.01;
            
            % remove aged object
            i = 1;
            while i <= numel(OM.obj)
                if OM.obj(i).age == AgeThresh
                    % remove object ith
                    % first remove all sub object
                    if OM.obj(i).type > 1
                        for id = OM.obj(i).id
                            OM.hidObj([OM.hidObj.id] == id) = [];
                        end
                    end
                    % then remove this object
                    OM.obj(i) = [];
                    i = i-1;
                end
                i = i+1;
            end
            
            % predict next location of remain objects
            for i = 1:numel(OM.obj)
                box1 = OM.obj(i).box(end-1,:);
                box2 = OM.obj(i).box(end,:);
                OM.obj(i).box(end+1,:) = nextLocation(box1,box2);
                OM.obj(i).hit = 0;
                OM.obj(i).age = OM.obj(i).age + 1;
            end
            
            % predict next location of hidden objects
            for i = 1:numel(OM.hidObj)
                box1 = OM.hidObj(i).box(end-1,:);
                box2 = OM.hidObj(i).box(end,:);
                OM.hidObj(i).box(end+1,:) = nextLocation(box1,box2);
            end
            
            % distance matrix D
            D = inf(numel(OM.obj),size(box,1));
            for i = 1:numel(OM.obj)
                for j = size(box,1)
                    D(i,j) = distanceSqr(OM.obj(i).box(end,:),box(j,:));
                end                
            end
            D(D<D2Thresh) = inf;
            
            % distribute objects
            TMmatch = [];
            Mobj = [];
            Tobj = [];
                                    
            while (true)
                J = zeros(size(D));
                % find nearest in row
                for r = 1:size(J,1)
                    row = D(r,:);
                    smallest = find(row == min(row));
                    smallest = smallest(row(smallest) ~= inf);
                    J(r,smallest) = J(r,smallest) + 1;
                end
                % find nearest in collumn
                for c = 1:size(J,2)
                    col = D(:,c);
                    smallest = find(col == min(col));
                    smallest = smallest(col(smallest) ~= inf);
                    J(smallest,c) = J(smallest,c) + 1;
                end
                [r,c] = find(J==2);
                for i = 1:numel(r)
                    o = r(i); b = c(i);
                    if histMatch(OM.obj(o).hist,hist(b,:),histEsp)
                        TMmatch(end+1,1:2) = [o, b];
                    end
                    D(o,b) = inf;
                end
                if isempty(r), break; end
            end
            
            if ~isempty(TMmatch)
                Tobj = setdiff(1:numel(OM.obj),(TMmatch(:,1))');
                Mobj = setdiff(1:size(box,1),(TMmatch(:,2))');
            else
                Tobj = 1:numel(OM.obj);
                Mobj = 1:size(box,1);
            end
%             disp(TMmatch);
            
            % Temporary Queue
            rmObj = false(1,numel(OM.obj));
            rmHid = [];
            new = [];
            save2hid = [];
            
            % handle occlusion
            % Merge objects
            MergeObject();    
            HandleMatchingObject();    
            % Split Objects
            SplitObject();
            
            % create new object
            CreateNewObject();    
            
            % Insert and remove data from tmp queue
            HandleTempData();	
            
%             if OM.maxId > 2, pause(1);end
            
            %% Core functions
            function MergeObject()
                for m = Mobj
                    merge = [];
                    % find joining box
                    for t = Tobj
                        if childBox(OM.obj(t).box(end,:),box(m,:))
                            merge(end+1) = t;
                        end
                    end
                    
                    % merge join box
                    if numel(merge) == 1
                        % if there is only 1 join box, consider it is a
                        % fine tracked object
                        TMmatch(end+1,1:2) = [merge(1), m];
                    elseif numel(merge) > 1
                        % if there are more than 1 join box, merge them all
                        % Fisrt create a tmp object
                        tmpObj = newTmpObj();
                        % loop for all object to be merge
                        for ind = merge
                            rmObj(ind) = 1;
                            if OM.obj(ind).type == 1
                                % if this is an ordinary object, save its
                                % to hidden and add its id
                                tmpObj.id = unique([OM.obj(ind).id,tmpObj.id]);
                                tmpObj.type = tmpObj.type +1;
                                save2hid = [save2hid,OM.obj(ind)];
                            else
                                % if this is a group, union their ids
                                tmpObj.id = union(tmpObj.id,OM.obj(ind).id);
                                tmpObj.type = tmpObj.type + OM.obj(ind).type;
                            end
                        end
                        tmpObj.box = [box(m,:);box(m,:)];
                        tmpObj.hist = hist(m,:);
                        % push tmp object to temporary queue of New Object
                        new = [new,tmpObj];
                        
                        % remove merge object to not be acces later
                        Tobj = setdiff(Tobj,merge);
                        Mobj = setdiff(Mobj,m);
                    end                    
                end
            end
            
            function SplitObject()
                for t = Tobj
                    split = [];
                    for m = Mobj
                        if childBox(box(m,:),OM.obj(t).box(end-1,:))
                            split(end+1) = m;
                        end
                    end                    
                    
                    if numel(split) > 1 && OM.obj(t).type == 1
                        disp(['splitting ',num2str(split)]);
                        
                        OM.obj(t).box(end,:) = box(split(1),:);
                        OM.obj(t).hist = hist(split(1),:);
                        OM.obj(t).hit = 1;
                        OM.obj(t).age = 0;
                        
                        for ind = split(2:end)
                            OM.maxId = OM.maxId + 1;
                            tmpObj = newTmpObj();
                            tmpObj.id = OM.maxId;
                            tmpObj.type = 1;
                            tmpObj.hist = hist(ind,:);
                            tmpObj.box = [box(ind,:);box(ind,:);];
                            new = [new,tmpObj];
                        end  
                    elseif numel(split) > 1
                        disp(['splitting ',num2str(split)]);
                        remain = split;
                        for Mi = split
                            for Hi = OM.obj(t).id
                                hidden = OM.hidObj([OM.hidObj.id] == Hi);
                               if ~isempty(hidden) && histMatch(hist(Mi,:),hidden.hist,histEsp)                                   
                                   OM.obj(t).id = setdiff(OM.obj(t).id,hidden.id);
                                   disp(['split remain: ',num2str(OM.obj(t).id)]);
                                   rmHid(end+1) = hidden.id;
                                   tmpObj = newTmpObj();
                                   tmpObj.id = hidden.id;
                                   tmpObj.type = 1;
                                   tmpObj.hist = hist(Mi,:);
                                   tmpObj.box = [hidden.box;box(Mi,:)];
                                   new = [new,tmpObj];
                                   remain(remain == Mi) = [];
                                   break;
                               end
                            end
                        end
                        
                        if numel(remain) == 1
                            OM.obj(t).type = numel(OM.obj(t).id);
                            OM.obj(t).box(end,:) = box(remain,:);
                            OM.obj(t).hist = hist(remain,:);
                            OM.obj(t).hit = 1;
                            OM.obj(t).age = 0;
                        else                        
                            rmObj(t) = 1;
                        end
                    end
                    % remove merge object to not be acces later
                    Tobj = setdiff(Tobj,t);
                    Mobj = setdiff(Mobj,split);
                end
            end
            
            function CreateNewObject()
                for m = Mobj
                    OM.maxId = OM.maxId + 1;
                    tmpObj = newTmpObj();
                    tmpObj.id = OM.maxId;
                    tmpObj.type = 1;
                    tmpObj.hist = hist(m,:);
                    tmpObj.box = [box(m,:);box(m,:);];
                    new = [new,tmpObj]; 
                    disp(['create : ',num2str(tmpObj.id)]);
                end
            end
            
            function HandleMatchingObject()
                for iter = 1:size(TMmatch,1)
                    track = TMmatch(iter,1);
                    mesure = TMmatch(iter,2);
                    OM.obj(track).box(end,:) = box(mesure,:);
                    OM.obj(track).hist = hist(mesure,:);
                    OM.obj(track).hit = 1;
                    OM.obj(track).age = 0;
                end
            end
            
            function HandleTempData()
                % Remove deleted objects
                iter = 1;
                for rm = rmObj
                    if rm == 1
                        disp(['remove object ',num2str(OM.obj(iter).id)]);
                        OM.obj(iter) = [];
                        iter = iter-1;
                    end
                    iter = iter+1;
                end
                
                % Remove deleted hidden objects
                for hid = rmHid
                    disp(['remove hidden ',num2str(hid)]);
                    OM.hidObj([OM.hidObj.id] == hid) = [];
                end
                
                % Insert new object from tmp queue
                for newObj = new
                    OM.obj(end+1) = newObj;
%                     disp(['create : ',num2str(newObj.id)]);
                end
                
                % Inserthidden object from tmp queue
                for hObj = save2hid
                    indx = numel(OM.hidObj)+1;
                    OM.hidObj(indx).id = hObj.id;
                    OM.hidObj(indx).hist = hObj.hist;
                    OM.hidObj(indx).box = hObj.box;
                end
            end
            
            %% Helper function
            
            % predict next location of object
            function box = nextLocation(b1,b2)
                v = [b2(1)-b1(1)+floor((b2(3)-b1(3))/2), b2(2)-b1(2)+floor((b2(4)-b1(4))/2)];
                box = [b2(1)+v(1), b2(2)+v(2),b2(3), b2(4)];
            end
            
            % compare two histogram
            function match = histMatch(h1,h2,esp)
                nh1 = h1./sum(h1);
                nh2 = h2./sum(h2);
                match = sum((nh1-nh2).^2) < esp;
                %disp(match);
            end
            
            % return square distance between two box's centre
            function d = distanceSqr(b1,b2)
                x1 = round(b1(1)+b1(3)/2);
                y1 = round(b1(2)+b1(4)/2);
                x2 = round(b2(1)+b2(3)/2);
                y2 = round(b2(2)+b2(4)/2);
                d = (x1-x2)^2 + (y1-y2)^2;
            end
            
            % return true if te centre of b1 is within b2
            function r = childBox(b1,b2)
                cx1 = round(b1(1)+b1(3)/2);
                cy1 = round(b1(2)+b1(4)/2);
                r = cx1>b2(1) && cx1<b2(1)+b2(3) &&...
                    cy1>b2(2) && cy1<b2(2)+b2(4);
            end
            
            % return a new template object
            function o = newTmpObj()
                o.id = [];
                o.type = 0;
                o.hist = [];
                o.box = [];
                o.hit = 1;                
                o.age = 0;
            end
            
            function save2hidden(obj)
                ind = numel(save2hid)+1;
                save2hid(ind).id = obj.id;
                save2hid(ind).hist = obj.hist;
                save2hid(ind).box = obj.box;
            end
        end
    end
    
end