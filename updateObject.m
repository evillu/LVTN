function objsFinal = updateObject( objs,boxxes,hists )
    ageThresh = 20;
    histEsp = 0.1;
    global gId;


    sizeObjs = size(objs,2);
    i = 1;
    
    while i <= sizeObjs
        objs(i).age = objs(i).age + 1;

        % predict new location
        box1 = objs(i).box(end-1,:);
        box2 = objs(i).box(end,:);
        objs(i).box(end+1,:) = nextBox(box1,box2);
        objs(i).hit = 0;        

        % measure location in current frame
        found = false;
        for h = 1:size(hists,1)
            if histMatch(objs(i).hists,hists(h,:),histEsp)
                found = true;
                objs(i).hists = hists(h,:);
                objs(i).age = 1;
                objs(i).box(end,:) = boxxes(h,1:4); 
                objs(i).hit = 1;
                break;
            end
        end
%         disp(found);
        
        if size(objs(i).box,1) > 10
            objs(i).box = objs(i).box(2:end,:);
        end
        if objs(i).age > ageThresh
            objs(i) = [];
            sizeObjs = sizeObjs - 1;
        end
        i = i + 1;
    end


    if size(objs,2) == 0
        for i = 1:size(boxxes,1)
            gId = gId + 1;
            objs(end + 1).id = gId;
            objs(end).type = 1;
            objs(end).box(end + 1,:) = boxxes(i,1:4);
            objs(end).box(end + 1,:) = boxxes(i,1:4);
            objs(end).hit = 0;
            objs(end).hists = hists(i,:);
            objs(end).age = 1;
        end
    end
    function match = histMatch(h1,h2,esp)
        nh1 = h1./sum(h1);
        nh2 = h2./sum(h2);
        sh = sum(abs(nh1-nh2));
        match = sh < esp;
        disp(match);
    end

    function box = nextBox(b1,b2)
        v = [floor((b2(1)+b2(3)-b1(1)-b1(3))/2), floor((b2(2)+b2(4)-b1(2)-b1(4))/2)];
        box = [b2(1)+v(1), b2(2)+v(2),b2(3)+v(1), b2(4)+v(2)];
    end

    objsFinal = objs;
end

