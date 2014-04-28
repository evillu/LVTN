classdef ObjectManager
    %OBJECTMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        maxId;
        obj; 
        hidObj;
    end
    
    methods
        function OM = ObjectManager()
            OM.maxId = 0;
            OM.objs = struct (...
                'id',{},...
                'type',{},...
                'hist',{},...
                'box',{},...
                'hit',{},...
                'age',{} );
            OM.hidObj = struct (...
                'id',{},...
                'hist',{} );
        end
        
        function OM = update(OM,box,hist)
            % magix number
            DThresh = 50;
            AgeThresh = 10;
            
            % remove aged object
            i = 1;
            while i <= size(OM.obj,2)
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
            for i = 1:size(OM.obj,2)
                box1 = OM.objs(i).box(end-1,:);
                box2 = OM.objs(i).box(end,:);
                OM.objs(i).box(end+1,:) = nextLocation(box1,box2);
                OM.objs(i).hit = 0;
                OM.objs(i).age = OM.objs(i).age + 1;
            end
            
            % distance matrix D
            D = inf(size(OM.obj,2),size(box,1));
            for i = 1:size(OM.obj,2)
                for j = size(box,1)
                    D(i,j) = distanceSqr(OM.obj(i).box(end,:),box(j,:));
                end                
            end
            D(D<DThresh) = inf;
            
            % distribute objects
            TMmatch = [];
            
            J = zeros(size(D));            
            while (true)
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
                    smallest = smallest(row(smallest) ~= inf);
                    J(smallest,c) = J(smallest,c) + 1;
                end
                [r,c] = find(J==2);
                for i = 1:numel(r)
                    TMmatch(end+1,1:2) = [r(i), c(i)];
                    D(r(i),c(i)) = inf;
                end
                if isempty(r), break; end
            end
            
            Tobj = setdiff(1:size(OM.obj,2),TMmatch(:,1));
            Mobj = setdiff(1:size(box,1),TMmatch(:,2));
            
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
        end
    end
    
end