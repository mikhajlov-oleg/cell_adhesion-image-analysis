%%%%%%%%%%%%%%%%%%
DEMONSTRATION
%%%%%%%%%%%%%%%%%%

Run the file example.m to see the output of the calculation for two sample cells with a circular and an irregular shape. 

%%%%%%%%%%%%%%%%%%
HOW TO USE
%%%%%%%%%%%%%%%%%%

The main function is **distance2edge.m**
It computes the expected distance of uniformly distributed points (clusters) to the edge of a polygon (cell boundary). 

The following subroutines are called on by the main function:
- averaged2edge.m
- isInsidePolygon.m
- shortestDistance.m

To run the code, use the command

d = distance2edge(x,y)

where x, y are vectors with the x- and y-coordinates of the cell boundary (in the correct order, so that neighbouring points on the cell boundary appear as consecutive entries in the x, y vectors).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DESCRIPTION OF MATLAB FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function d = averaged2edge(x,y,N)
%AVERAGED2EDGE Average distance to edge of polygon for points distributed 
%on N x N square grid over polygon with vertices (x,y)
%   x, y are linear arrays representing x,y coords of polygon vertices
%   N is the size of the grid
%   d is the expected distance of a point from the edge of the polygon, if
%   the points are uniformly distributed inside the shape
% N.B. x and y must be column vectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



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
% TEST 3 - unit circle (almost) should give close to 1/3
% x = cos(linspace(0,2*pi,100)); y = sin(linspace(0,2*pi,100));
% distance2edge(x(2:end),y(2:end))
%
% For these two tests, error is confirmed to be < 0.1%,
% consistent with default relative error tolerance, errortol = 1e-3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



function [I, XPin, YPin] = isInsidePolygon(XP,YP,x,y)
%ISINSIDEPOLYGON Checks if points (XP,YP) are inside/outside a polygon with
%vertices (x,y) 
%   x, y are linear arrays representing x,y coords of polygon vertices
%   XP, YP are linear arrays representing x,y coords of rectangular grid
% N.B. x,y,XP,YP must be column vectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Method: ray casting algorithm 
% Source: https://www.youtube.com/watch?v=RSXM9bgqxJM&ab_channel=Insidecode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



function shortestd = shortestDistance(XP,YP,x,y)
%SHORTESTDISTANCE Compute shortest distance from points (XP,YP) to any edge
%of a polygon (x,y)
%   x, y are linear arrays representing x,y coords of polygon vertices
%   XP, YP are linear arrays representing x,y coords of rectangular grid
% N.B. x,y,XP,YP must be column vectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Method: calculate distance from point to edge (*line segment*)
% First, calculate distance to *line* via algorithm [where r = (x,y)]
%   a = r1 - r2;
%   b = rp - r2;
%   d = norm(cross(a,b)) / norm(a);
% Next, calculate distance to edge end points (vertices) as well, and only 
% use the distance to the line if the max of the end point distances is 
% smaller than the length of the line segment.
% Source: https://uk.mathworks.com/matlabcentral/answers/95608-is-there-a-function-in-matlab-that-calculates-the-shortest-distance-from-a-point-to-a-line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

