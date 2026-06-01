function cfg = getConfig()
    % KLT 
    cfg.klt.maxPoints = 200;
    cfg.klt.blockSize = [31 31];
    
    % OPTICAL FLOW 
    cfg.flow.gridStep = 20;    
    cfg.flow.arrowScale = 5;    
    
    cfg.display.kltColor = [0 1 0]; 
    cfg.display.showTrails = true;
    
    cfg.video.frameSkip = 0;
end