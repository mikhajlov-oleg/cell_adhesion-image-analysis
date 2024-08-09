The main function is ***distance2edge.m***
It computes the expected distance of uniformly distributed points (clusters) to the edge of a polygon (cell boundary). 

The following subroutines are called on by the main function:
- averaged2edge.m
- isInsidePolygon.m
- shortestDistance.m

You should save all the functions in the same folder (or on MATLAB's Path).

To run the code, use the command

d = distance2edge(x,y)

where x, y are vectors with the x- and y-coordinates of the cell boundary (in the correct order, so that neighbouring points on the cell boundary appear as consecutive entries in the x, y vectors).

