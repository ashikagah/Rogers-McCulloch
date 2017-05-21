%       ***************************************************
%       *  Copyright (C) 2017, Hiroshi Ashikaga, MD, PhD  *
%       *  hashika1@jhmi.edu                              *
%       *  Cardiac Arrhythmia Service                     *
%       *  Johns Hopkins University School of Medicine    *
%       *  Baltimore, Maryland, USA                       *
%       ***************************************************

%% Identify phase singularities (= rotors) of spiral waves

clear all
close all

load phase.mat;
ps = zeros(size(p));        % Final matrix size = 120x120x4500 (~500MB)

for frame=1:size(p,3)
    mat = topcharge(p(:,:,frame));  % +1 (white) - counterclockwise spiral wave
    ps(:,:,frame) = mat;            % -1 (black) - clockwise spiral wave
end
clear p
save(['singularity.mat'],'ps');

% Show frames
i0 = zeros(size(ps(:,:,1)));
ih = imagesc(i0); caxis([-1 1]);
colormap(gray); axis image off; 
set(gcf,'position',[500 600 512 512],'color',[1 1 1])
for frame=1:size(ps,3)
    set(ih,'cdata',ps(:,:,frame));
    drawnow
    mov(frame) = getframe;
end

% Make a movie
writerObj = VideoWriter(['singularity_movie.avi'],'Motion JPEG AVI');
writerObj.FrameRate = 120;
open(writerObj);
writeVideo(writerObj,mov);
close(writerObj);
close all
clear mov

function singularity = topcharge(phase_map)

[nrows,ncols] = size(phase_map);

% Topological charge is marked on the top left corner of 2-by-2 regions.
phase1 = phase_map;
phase2 = zeros(nrows,ncols); phase2(1:nrows-1,:) = phase_map(2:nrows,:);
phase3 = zeros(nrows,ncols); phase3(1:nrows-1,1:ncols-1) = phase_map(2:nrows,2:ncols);
phase4 = zeros(nrows,ncols); phase4(:,1:ncols-1) = phase_map(:,2:ncols);

% Wrap the phase differences as we loop around the 2 by 2 blocks
nt1 = mod(phase1 - phase2 + pi, 2*pi) - pi;          
nt2 = mod(phase2 - phase3 + pi, 2*pi) - pi;
nt3 = mod(phase3 - phase4 + pi, 2*pi) - pi;
nt4 = mod(phase4 - phase1 + pi, 2*pi) - pi;

temp_charge = nt1 + nt2 + nt3 + nt4;    % Sum the phase differences. Positive residues appear as 2*pi, negative as -2*pi.
charge = (temp_charge>=6);              % Assign 1 to positive residue (= 2*pi)
charge = charge - (temp_charge<=-6);    % Assign -1 to negative residues (= -2*pi)
charge(:,ncols)=0; charge(nrows,:)=0;   % Zero pad the border residues
charge(:,1)=0; charge(1,:)=0; 
singularity = charge;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                               %
%   phase1---nt4---phase4       %
%      |              |         %
%     nt1           nt3         %
%      |              |         %
%   phase2---nt2---phase3       %
%                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



