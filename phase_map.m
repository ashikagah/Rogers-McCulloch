%       ***************************************************
%       *  Copyright (C) 2017, Hiroshi Ashikaga, MD, PhD  *
%       *  hashika1@jhmi.edu                              *
%       *  Cariac Arrhythmia Service                      *
%       *  Johns Hopkins University School of Medicine    *
%       *  Baltimore, Maryland, USA                       *
%       *  5/21/2017                                      *
%       ***************************************************

%% Generate phase map of spiral waves

clear all
close all

load orig.mat;

ts(:,:,1:500) = [];         % Remove initial periods of random stimulations
offset = 0.4;               % Subtract 0.4 (half the max amplitude) to intentionally 
                            % create negative values to make the Hilbert transform phase [-pi pi]
H = zeros(size(ts));        % Final matrix size = 120x120x4500 (~500MB)
p = zeros(size(ts));

% Hilbert transform of excitation variable   
for m=1:size(ts,1)
    for n=1:size(ts,2)
        H(m,n,:) = hilbert(squeeze(ts(m,n,:))-offset);
    end
    fprintf('%1.0f percent completed ...\n',100*m/size(ts,1));
end

% Calculate phase at each time frame
for frame=1:size(H,3)
    p(:,:,frame) = angle(H(:,:,frame));
end

clear ts H
save(['phase.mat'],'p');    %  

% Show frames
i0 = zeros(size(p(:,:,1)));
ih = imagesc(i0); caxis([-pi pi]);
colormap(jet); axis image off; 
set(gcf,'position',[500 600 512 512],'color',[1 1 1])
for frame=1:size(p,3)
    set(ih,'cdata',p(:,:,frame));
    drawnow
    mov(frame) = getframe;
end

% Make a movie
writerObj = VideoWriter(['phase_movie.avi'],'Motion JPEG AVI');
writerObj.FrameRate = 120;
open(writerObj);
writeVideo(writerObj,mov);
close(writerObj);
close all
clear mov