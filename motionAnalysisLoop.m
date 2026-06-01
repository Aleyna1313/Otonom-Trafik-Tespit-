function motionAnalysisLoop(source, cfg)
    reader = VideoReader(source);
    
    opticFlow = opticalFlowFarneback(); 
    
    hFig = figure('Name', 'Otonom Trafik - Kutu, Ok ve Durum', 'NumberTitle', 'off');
    hAx = axes('Parent', hFig);
    
    if hasFrame(reader)
        prevFrame = readFrame(reader);
        prevGray = im2gray(prevFrame);
    else
        return;
    end
    
    bgTracker = vision.PointTracker('MaxBidirectionalError', 1, 'NumPyramidLevels', 3);
    bgPoints = detectMinEigenFeatures(prevGray, 'MinQuality', 0.1);
    initialize(bgTracker, bgPoints.Location, prevGray);
    
    while hasFrame(reader) && ishandle(hFig)
        frame = readFrame(reader);
        grayFrame = im2gray(frame);
        
        flow = estimateFlow(opticFlow, grayFrame);
        
        [currPts, valid] = bgTracker(grayFrame);
        prevPts = bgPoints.Location(valid, :);
        
        aracSayisi = 0;
        mask = false(size(grayFrame)); 
        
        if sum(valid) > 10
            try
                tform = estimateGeometricTransform2D(prevPts, currPts(valid,:), 'rigid');
                alignedPrev = imwarp(prevGray, tform, 'OutputView', imref2d(size(grayFrame)));
                
                [h, w] = size(grayFrame);
                margin = 20;
                merkezMaske = false(h, w);
                merkezMaske(margin:h-margin, margin:w-margin) = true;
                
                diff = abs(int16(grayFrame) - int16(alignedPrev));
                mask = (diff > 25) & merkezMaske; 
                
               
                mask = imopen(mask, strel('disk', 2)); 
                
                mask = imclose(mask, strel('rectangle', [35 35])); 
                
                mask = imfill(mask, 'holes'); 
                
                mask = bwareaopen(mask, 80); 
                
                cc = bwconncomp(mask);
                aracSayisi = cc.NumObjects;
            catch
                cc = [];
            end
        end
        
        release(bgTracker);
        bgPoints = detectMinEigenFeatures(grayFrame, 'MinQuality', 0.1);
        if ~isempty(bgPoints)
            initialize(bgTracker, bgPoints.Location, grayFrame);
        end
        prevGray = grayFrame;
        
        if aracSayisi == 0
            durumText = 'BOS YOL'; boxColor = 'white';
        elseif aracSayisi <= 5
            durumText = 'AKICI'; boxColor = 'green';
        elseif aracSayisi <= 12
            durumText = 'HAREKETLI'; boxColor = 'cyan';
        elseif aracSayisi <= 25
            durumText = 'YOGUN'; boxColor = 'yellow';
        else
            durumText = 'SIKISIK'; boxColor = 'red';
        end
        
        imshow(frame, 'Parent', hAx); hold(hAx, 'on');
        
        step = cfg.flow.gridStep; 
        [X, Y] = meshgrid(1:step:size(frame,2), 1:step:size(frame,1));
        U = flow.Vx(1:step:end, 1:step:end) * cfg.flow.arrowScale;
        V = flow.Vy(1:step:end, 1:step:end) * cfg.flow.arrowScale;
        
        linearIndices = sub2ind(size(mask), Y(:), X(:));
        validArrows = mask(linearIndices);
        U(~validArrows) = 0; 
        V(~validArrows) = 0;
        
        quiver(hAx, X, Y, U, V, 0, 'Color', [1 0.5 0], 'LineWidth', 1.2);
        
        if aracSayisi > 0 && exist('cc', 'var') && ~isempty(cc)
            props = regionprops(cc, 'BoundingBox');
            for i = 1:length(props)
                rectangle(hAx, 'Position', props(i).BoundingBox, 'EdgeColor', 'g', 'LineWidth', 2);
            end
        end
        
        infoStr = sprintf('Durum: %s\nTespit Edilen Arac: %d', durumText, aracSayisi);
        text(hAx, 10, 30, infoStr, 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold', ...
             'BackgroundColor', 'black', 'EdgeColor', boxColor, 'LineWidth', 2, 'Margin', 5);
             
        hold(hAx, 'off');
        drawnow;
    end
end