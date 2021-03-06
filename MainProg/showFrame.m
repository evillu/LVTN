function showFrame(VM,OM,Im)
    %% left axis
    subplot(1,2,1);
    imshow(Im);
    line(VM.PMask(:,1),VM.PMask(:,2));
    for i = 1:numel(OM.obj)
        b = OM.obj(i).box(end,:);
        lColor = 'g';
        if OM.obj(i).type > 1, lColor = 'r'; end
        if ~OM.obj(i).hit, lColor = 'b'; end
        rectangle('Position', b, 'LineWidth', 1, 'EdgeColor', lColor);
        text(b(1), b(2)-5, num2str(OM.obj(i).id),'Color','y','FontSize',14,'FontWeight','bold');
    end
    
    %% right axis
    subplot(1,2,2);
    imshow(VM.IOM);
    for i = 1:size(VM.iBox,1)
        box = VM.iBox(i,:);
        rectangle('Position', box, 'LineWidth', 1, 'EdgeColor', 'r');
    end
    
    axis off;
    drawnow;
    pause(0.01);
end