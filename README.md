# This is the readme file #

This repository contains image analysis scripts that were used in the "Cell adhesion and spreading on fluid membranes through microtubules-dependent mechanotransduction" paper. Each script has an associate folder with example images that can be used to test the script.

## Cluster detection with manual and automatic thresholdings ##

This script takes a multi-channel image of cells adhered on supported lipid bilayers (SLBs) as in input. The following channels of the input image should be identified by the user: brightfield, integrin and SLB.

The script provides two segmentations as an output. First, it asks the user to segment cells (manually) using a polygone tool in the brightfield channel in ImageJ. Second, for each segmented cell it detects clusters in the integrin channel. This segmentation is performed automatically by either setting up the threshold value or using the "Rényi Entropy" theshold algorithm. 

Both segmentations (cells and integrin clusters) are quantified with ImageJ. The results are incrementied in the .csv file.

## Tube detection script ##

Indentification of "big" clusters.

## Distance from clusters to the border ##

This script calculates the distances from integrin clusters to the cell border were calculated as the shortest path from the cluster edge to the cell border. 
For each cell, these distances were averaged using a weighted mean, accounting for the number of integrins in each cluster. 
This weighted mean was normalized to a reference value representing the average distance expected if clusters were uniformly distributed throughout the cell. 
To calculate this reference distance, the cell area was divided into a fine rectangular mesh. This mesh was used to simulate a uniform distribution of clusters, 
and the average distance from these simulated clusters to the cell border was computed. 
This mesh was iteratively refined until the error in the calculated distances fell below 1% in a self-convergence test.



