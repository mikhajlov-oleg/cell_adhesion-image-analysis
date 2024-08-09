# This is the readme file #

This repository contains image analysis scripts that were used in the "Cell adhesion and spreading on fluid membranes through microtubules-dependent mechanotransduction" paper. Each script has an associate folder with example images that can be used to test the script.

## Script names (manual and automatic thresholdings) ##

This script takes a multi-channel image of cells adhered on supported lipid bilayers (SLBs) as in input. The following channels of the input image should be identified by the user: brightfield, integrin and SLB.

The script provides two segmentations as an output. First, it asks the user to segment cells (manually) using a polygone tool in the brightfield channel in ImageJ. Second, for each segmented cell it detects clusters in the integrin channel. This segmentation is performed automatically by either setting up the threshold value or using the "Rényi Entropy" theshold algorithm. 

Both segmentations (cells and integrin clusters) are quantified with ImageJ. The results are incrementied in the .csv file.

## Tube detection script ##

Indentification of "big" clusters.

## Distance from clusters to the border ##

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


