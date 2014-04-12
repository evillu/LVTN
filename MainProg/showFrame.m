function showFrame(OM,BDM,Im)
    %% left axis
    subplot(1,2,1);
    imshow(Im);
%     for i = 1:size(OM.objs,2)
%         box = OM.objs(i).box(end,:);
%         rectangle('Position', box, 'LineWidth', 1, 'EdgeColor', 'r');
%         text(box(1), box(2), num2str(OM.objs(i).id));
%     end
    
    %% right axis
    subplot(1,2,2);
    imshow(BDM);
    
    axis off;
    drawnow;
end