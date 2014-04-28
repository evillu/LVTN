function showFrame(VM,OM,Im)
    %% left axis
    subplot(1,2,1);
    imshow(Im);
    line(VM.PMask(:,1),VM.PMask(:,2));
    for i = 1:size(OM.objs,2)
        b = OM.objs(i).box(end,:);
        lColor = 'g';
        if OM.objs(i).type > 1, lColor = 'r'; end
        if ~OM.objs(i).hit, lColor = 'b'; end
        rectangle('Position', b, 'LineWidth', 1, 'EdgeColor', lColor);
        text(b(1), b(2), num2str(OM.objs(i).id),'Color','y');
    end
    
    %% right axis
    subplot(1,2,2);
    imshow(VM.OM);
    for i = 1:size(VM.iBox,1)
        box = VM.iBox(i,:);
        rectangle('Position', box, 'LineWidth', 1, 'EdgeColor', 'r');
    end
    
    axis off;
    drawnow;
    pause(0.01);
end