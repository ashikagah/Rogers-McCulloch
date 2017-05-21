%       ***************************************************
%       *  Copyright (C) 2017, Hiroshi Ashikaga, MD, PhD  *
%       *  hashika1@jhmi.edu                              *
%       *  Cariac Arrhythmia Service                      *
%       *  Johns Hopkins University School of Medicine    *
%       *  Baltimore, Maryland, USA                       *
%       *  5/21/2017                                      *
%       ***************************************************

function make_movie(ts,outfilename)
%% Generate a movie of 2-D time series

% INPUT:    
%   ts          ... 2-D time series [N x M x time]
%   outfilename ... Filename of movie file (e.g. 'orig_movie.avi')
%

% Show frames
i0 = zeros(size(ts(:,:,1)));
ih = imagesc(i0(:,:,1)); caxis([0 1]);
colormap(jet); axis image off; 
set(gcf,'position',[500 600 512 512],'color',[1 1 1])
for frame=1:size(ts,3)
    set(ih,'cdata',ts(:,:,frame));
    drawnow
    mov(frame) = getframe;
end

% Make a movie
writerObj = VideoWriter(outfilename,'Motion JPEG AVI');
writerObj.FrameRate = 120;
open(writerObj);
writeVideo(writerObj,mov);
close(writerObj);
close all
clear mov