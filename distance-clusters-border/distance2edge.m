function d = distance2edge(x,y)
%DISTANCE2EDGE Expected distance to polygon edge for uniformly distributed
%points inside a polygon with vertices (x,y)
%   x, y are linear arrays representing x,y coords of polygon vertices
%   d is the expected distance of a point from the edge of the polygon, if
%   the points are uniformly distributed inside the shape
%
% N.B. this routine turns x, y into column vectors, for use by subroutines
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Validation tests
% TEST 1 - square of side length 1
% distance2edge([0 0 1 1], [0 1 1 0]) should give 1/6
% TEST 2 - equilateral triangle of side length 1
% distance2edge([0 1 0.5], [0 0 sqrt(3)/2]) should give 1/(6*sqrt(3))
%
% For these two tests, error is confirmed to be < 0.1%,
% consistent with default relative error tolerance, errortol = 1e-3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
starttime = cputime;

% Make x and y column vectors (subroutines require col vectors)
address = ['/Users/mikhajlo/Documents/Institut_Curie/paper/submission/submission2/maria-distance2edge/'];
num = xlsread([address '0711-1-30min-7-1.xlsx']);
x = num(:,1); y= num(:,2);

% Default parameters
gridsize = 2^7; % grid size for initial mesh
errortol = 1e-3; % relative error tolerance

% First estimate
d1 = averaged2edge(x,y,gridsize); 
disp(['first iteration complete, running time: ' num2str((cputime-starttime)) 's'])

% Iterate until convergence or grid size too big
keepgoing = 1;
niterations = 1;

while keepgoing
    gridsize = gridsize*2; % increase grid resolution
    d2 = averaged2edge(x,y,gridsize); % re-compute average distance to edge

    % Stop if satisfy error tolerance or grid size too big (memory issues)
    if abs((d2-d1)/d2) < errortol || log2(gridsize) > 12
        keepgoing = 0; 
        if abs((d2-d1)/d2) >= errortol
            disp('Solution has not converged')
        end
    end
    niterations = niterations + 1;
    disp([num2str(niterations) 'th iteration complete, running time: ' num2str((cputime-starttime)/60) 'min'])
    d1 = d2;
end

% Final estimate
d = d2;

% Display number of iterations (for curiosity)
disp(['number of iterations: ' num2str(niterations)])
end