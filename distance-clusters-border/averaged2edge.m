function d = averaged2edge(x,y,N)
%AVERAGED2EDGE Average distance to edge of polygon for points distributed 
%on N x N square grid over polygon with vertices (x,y)
%   x, y are linear arrays representing x,y coords of polygon vertices
%   N is the size of the grid
%   d is the expected distance of a point from the edge of the polygon, if
%   the points are uniformly distributed inside the shape
% N.B. x and y must be column vectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Determine mesh
xp = linspace(min(x),max(x),N);
yp = linspace(min(y),max(y),N);
[XP,YP] = meshgrid(xp,yp);
XP = XP(:);
YP = YP(:);

% Determine which points are inside polygon
[~, XPin, YPin] = isInsidePolygon(XP,YP,x,y);

% Determine shortest distance from each point to the edge of the polygon
shortestd = shortestDistance(XPin,YPin,x,y);

% Average to find d
d = mean(shortestd);

end