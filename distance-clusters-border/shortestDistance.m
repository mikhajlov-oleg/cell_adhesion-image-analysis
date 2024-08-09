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
% Next, calculate distance to edge end points (verticles) as well, and only 
% use the distance to the line if the max of the end point distances is 
% smaller than the length of the line segment.
% Source: https://uk.mathworks.com/matlabcentral/answers/95608-is-there-a-function-in-matlab-that-calculates-the-shortest-distance-from-a-point-to-a-line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make grid with point index and edge index
pts = 1:1:length(XP);
edg = 1:1:length(x);
[PTS,EDG] = meshgrid(pts,edg);
PTS = PTS(:); % for each point-edge pair, indicates which point (XP, YP)
EDG = EDG(:); % for each point-edge pair, indicates which edge (x, y)

% Determine edge vertices (x1,y1) and (x2,y2) for each point-edge pair
x1 = x(EDG); 
y1 = y(EDG);
x2 = x(mod(EDG,length(x))+1);
y2 = y(mod(EDG,length(x))+1);
% Determine points (xp,yp) for each point-edge pair
xp = XP(PTS);
yp = YP(PTS);

% For each point-edge pair, calculate distance to *line*
%   dline = norm(cross(a,b))/ norm(a);
dline = abs((x1-x2).*(yp-y2)-(y1-y2).*(xp-x2))./sqrt((x1-x2).^2+(y1-y2).^2);

% Determine if perpendicular distance from point (xp,yp) to the line
% actually falls on the line segment (x1,y1) to (x2,y2) (if not, obtuze)
dot1 = (x2-x1).*(xp-x1)+(y2-y1).*(yp-y1); % (r2-r1).(rp-r1)
dot2 = (x1-x2).*(xp-x2)+(y1-y2).*(yp-y2); % (r1-r2).(rp-r2)
obtuze = (dot1<0) | (dot2<0);

% If obtuze triangle, shortest distance is not the distance to the *line* 
% but the minimum distance to the end points of the edge (*line segment*)
d1 = sqrt((x1-xp).^2+(y1-yp).^2);
d2 = sqrt((xp-x2).^2+(yp-y2).^2);
dvertx = min(d1,d2);
    
% Calculate shortest distance to the edge (*line segment*)
d = dline;
d(obtuze==1) = dvertx(obtuze==1);

% Reshape into matrix, each point corresponds to a column
d = reshape(d,size(meshgrid(pts,edg)));
% size(d) = number of edges x number of points

% Shortest distance for each point
shortestd = min(d,[],1);

end