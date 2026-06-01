clear; clc; close all;
fprintf('Proje baslatiliyor...\n');

cfg = getConfig();
videoSource = '9700462-hd_1920_1080_30fps.mp4';

motionAnalysisLoop(videoSource, cfg);