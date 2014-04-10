function objs = updateObject( objs,boxxes,hists )
    ageThresh = 20;
    histEsp = 0.00001;
    for i = 1:size(objs,2)
        objs(i).age = objs(i).age + 1;
        
        % predict new location
        box1 = objs(i).box(end-1,:);
        box2 = objs(i).box(end,:);
        objs(i).box(end+1,:) = nextBox(box1,box2);
        objs(i).hit = 0;        
        
        % measure location in current frame
        found = false;
        for h = 1:size(hists,1)
            if histMatch(objs(i).hists,hists(h),histEsp)
                found = true;
                objs(i).hists = hists(h);
                objs(i).age = 1;
                objs(i).box(end,:) = boxxes(h,1:4); 
                objs(i).hit = 1;
                break;
            end
        end
        
        if size(objs(i).box,1) > 10
            objs(i).box = objs(i).box(2:end,:);
        end
    end
    
    function match = histMatch(h1,h2,esp)
        nh1 = h1./sum(h1);
        nh2 = h2./sum(h2);
        match = sum((nh1-nh2).^2) < esp;
    end

    function box = nextBox(b1,b2)
        v = [floor((b2(1)+b2(3)-b1(1)-b1(3))/2), floor((b2(2)+b2(4)-b1(2)-b1(4))/2)];
        box = [b2(1)+v(1), b2(2)+v(2),b2(3)+v(1), b2(4)+v(2)];
    end
end

