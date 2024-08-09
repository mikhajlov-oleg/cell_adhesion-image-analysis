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

% For each point-edge pair, check if ray cast rightward from the point
% crosses the edge
cond1 = (yp < max(y1, y2)) & (yp > min(y1, y2)); 
xpdash = x1.*(yp-y2)./(y1-y2) + x2.*(y1-yp)./(y1-y2);
cond2 = xp < xpdash;
raycrosses = cond1 & cond2;

% Reshape into matrix, each point corresponds to a column
raycrosses = reshape(raycrosses,size(meshgrid(pts,edg)));
% size(raycrosses) = number of edges x number of points

% How many edges does the ray from each point cross?
numbcrosses = sum(raycrosses,1);

% Is point *on* the edge?
onTheEdge = (xp == xpdash);
onTheEdge = reshape(onTheEdge,size(meshgrid(pts,edg)));
onTheEdge = max(onTheEdge,[],1);

% If sum is odd, and point not *on* the edge, then point inside the polygon 
isInside = mod(numbcrosses,2) & ~onTheEdge;
I = find(isInside);

% Determine which points are inside the polygon
XPin = XP(I);
YPin = YP(I);

% % Uncomment to check that algorithm is correct
% figure
% hold on
% plot(XPin,YPin,'rx')
% plot([x; x(1)],[y; y(1)],'b-','LineWidth',0.8)
end