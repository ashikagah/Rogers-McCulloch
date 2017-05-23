%       ***************************************************
%       *  Copyright (C) 2017, Hiroshi Ashikaga, MD, PhD  *
%       *  hashika1@jhmi.edu                              *
%       *  Cardiac Arrhythmia Service                     *
%       *  Johns Hopkins University School of Medicine    *
%       *  Baltimore, Maryland, USA                       *
%       *  5/21/2017                                      *
%       ***************************************************

%% Generate spiral waves using Rogers-McCulloch model of cardiac action potentials
% Rogers JM and McCulloch AD. A collocation-Galerkin finite element model of cardiac 
% action potential propagation. IEEE Trans Biomed Eng 41: 743-57, 1994

function ts = rm_spirals(time_units,stimfilename)
% INPUT:    
%   time_units   ... Total time units of time series (0.63ms/unit); 
%                    e.g. 20,000units = 20,000 x 0.63ms/unit = 12,600ms = 12.6sec
%   stimfilename ... Name of stimulation file (e.g. 'stim.mat')
%
% OUTPUT:
%   ts           ... 2-D time series of excitation variable v [N x M x time]

% Model geometry
ncols = 120;                    % Number of columns in the 2-D lattice; 120 unit x 0.99 mm/unit = 118.8 mm
nrows = 120;                    % Number of rows in the 2-D lattice; 120 unit x 0.99 mm/unit = 118.8 mm
h = 2;                          % 2-D lattice size for finite difference method; 2 units = 2 x 0.99 mm/unit = 1.98 mm
h2 = h^2;

% Model parameters
a = 0.13; b = 0.013; c1 = 0.26; c2 = 0.1; d = 1.0;  
v = zeros(nrows,ncols);         % Initialize voltage array
r = v;                          % Initialize refractoriness array
mu = 1; Dx = 1; Dy = Dx * mu;   % Isotropic diffisivity

% Integration Parameters
dt = 0.1;                       % Duration of each time step; 0.1unit x 0.63ms/unit = 0.063ms
time_steps = time_units/dt;     % Total time steps; 20,000units/0.1 = 200,000steps
si = 4/dt;                      % Final sampling interval; 4/0.1 = 40steps = 40 x 0.063ms = 2.52ms/frame
                                % Final sampling rate = 1,000ms/2.52ms ~ 400Hz
ts = zeros(ncols,nrows,floor(time_steps/si));  
                                % Final matrix size = 120x120x5000 (~550MB)

% External current parameters
Iex = 20;                       % Amplitude of external current
iex = zeros(nrows,ncols);       % Initial values

% Stimulations to induce spiral waves
Ns = 40;                        % Number of point stimulations

if nargin >1
    load(stimfilename)
else
    radius = 10;                % Radius (pixels) of point stimulations
    [xx yy] = meshgrid(1:ncols,1:nrows); C = sqrt((xx-ncols/2).^2+(yy-nrows/2).^2)<=radius;
    stim_array  = zeros(ncols*nrows,Ns,'single');
    mat = zeros(ncols,nrows);  
    mat(C==1) = 1; 
    for i=1:Ns  
        cx = randi(ncols - radius *2);
        cy = randi(nrows - radius *2);
        stim_array(:,i) = reshape(circshift(mat,[cx cy]),1,[]);
    end
    stim_sites = reshape(stim_array,[ncols nrows Ns]);
    stim_window = 2000/dt;      % 2000 time units = 2000 x 0.63ms/unit = 0.63 sec
    stim_time = floor(sort(stim_window*rand(1,Ns)));
    % save(['stim.mat'],'stim_sites','stim_window','stim_time'); % Uncomment if you want to save the stimulation file
end
    
% Rogers-McCulloch Model Main
s = 1;                          % Flag for stimulation

for ti = 1:time_steps
%%%%%%%%%%%%%%%%%%%%%%   Random stimulations x Ns   %%%%%%%%%%%%%%%%%%%%%%
    if s<=Ns
        if ti == stim_time(s); iex(stim_sites(:,:,s)==1)=Iex; end
        if ti == stim_time(s)+15/dt; iex=zeros(nrows,ncols); s=s+1; end
    end
%%%%%%%%%%%%%%%%%%%%%%          Main Loop           %%%%%%%%%%%%%%%%%%%%%%          
    % Padded v matrix for Newman boundary conditions 
    vv = [[0 v(2,:) 0];[v(:,2) v v(:,end-1)];[0 v(end-1,:) 0]];
    
    % Diffusion term
    vxx = (vv(2:end-1,1:end-2) + vv(2:end-1,3:end) -2*v)/h2; 
    vyy = (vv(1:end-2,2:end-1) + vv(3:end,2:end-1) -2*v)/h2;
    
    % dv/dt - excitation variable (~ transmembrane potential)
    vdot = c1*v.*(v-a).*(1-v)-c2*v.*r+iex+Dx*vxx+Dy*vyy; 
    v_new = v + vdot*dt;        % Explicit Euler
    
    % dr/dt - relaxation variable
    rdot = b*(v-d*r);
    r = r + rdot*dt;            % Explicit Euler
    v = v_new; clear v_new
    
    % Store v at sampling interval
    if rem(ti,si)==0
        l = floor(ti/si);
        ts(:,:,l)=v;
        fprintf('%1.0f percent completed ...\n',100*ti/time_steps);
    end
end


