/*
The macro asks for a folder; give the one containing the z-stack GFP and Cy3.
 *  Steps:
 *  - searches for images
 *  - searches for results folder and ROI file
 *  - for each cell segmented before: splits the clusters/computes area and mean intensity on green projection/
 *  reslice on a line that is the diagonal of the image/computes binary on lipid image reslice and height
 *  								  
 *  deals with "non splittable" ROIs (using the function Roi.getType())								  
 */

// clears everything
roiManager("reset");
run("Close All");
run("Clear Results");
run("Set Measurements...", "area mean bounding stack redirect=None decimal=3");

xy_pix_size_um = 0.11;
z_step_um = 0.3;
z_size_px = 11;
 
dir_img = getDirectory("Choose your directory");
filelist = getFileList(dir_img);

nbGFP = 0;
nbCy3 = 0;
nbResFolder = 0; 

//by default lipid channel is Cy3, but if "405" choose the following line with 405;
//chan_lipid = "Cy3";
chan_lipid = "405";

// searches for: GFP image, lipid image, results folder
for (i_file = 0; i_file < lengthOf(filelist); i_file++) {
	if( indexOf(filelist[i_file],"GFP") != -1 ){
		nbGFP++;
		imgGFP = dir_img+filelist[i_file];
	}

	if( indexOf(filelist[i_file],chan_lipid) != -1 ){
		nbCy3++;
		imgCy3 = dir_img+filelist[i_file];
	}

	if (File.isDirectory(dir_img+filelist[i_file])){
		if( startsWith(filelist[i_file],"Threshold_Results_") ){
			nbResFolder++;
			folderRes = dir_img+filelist[i_file];
		}
	}
}
print(nbCy3);
print(nbGFP);

if( nbGFP==0 || nbCy3 == 0 || nbGFP > 1 || nbCy3 > 1)
	exit("Your initial folder has either no GFP no "+chan_lipid+" or more than one containing the name GFP or "+chan_lipid);

if( nbResFolder > 1 )
	exit("More than one result folder");

// resultat folder: contains a subfolder for each cell
file_subFolder = getFileList(folderRes);

// searches for ROI file 
nbROIfile = 0;
ROI_file = "";
for (i_file = 0; i_file < lengthOf(file_subFolder); i_file++) {
	if( endsWith(file_subFolder[i_file],".zip") ){
		print(file_subFolder[i_file]);
		ROI_file = folderRes+file_subFolder[i_file];
		nbROIfile++;
	}
}

if( nbROIfile > 1 )
	print("Several ROI files found, only the last one will be studied: "+ROI_file);

roiManager("open", ROI_file);
nbCell = roiManager("count");

// GFP image and the projection (for mean and area)
open(imgGFP);
tit_imgGFP = getTitle();
run("Z Project...", "projection=[Max Intensity]");
tit_img_zproj_GFP = getTitle();

// lipid image
open(imgCy3);
tit_imgCy3 = getTitle();

// table for clusters in ALL cells of the image
arrayAreaCluster_AllImg = newArray(1);
arrayMeanCluster_AllImg = newArray(1);
arrayHeightCluster_AllImg = newArray(1);
arrayHeightClusterNet_AllImg = newArray(1);
arrayCellNumber_AllImg = newArray(1);
arrayClusterNumber_AllImg = newArray(1);
arrayGFPbackgound_AllImg = newArray(1);

roiManager("reset");
for(i_roi = 0; i_roi < nbCell; i_roi++){
	roiManager("open", ROI_file);

// duplicates cell of interest on GFP and Cy3
	selectWindow(tit_imgGFP);
	roiManager("select", i_roi);
	run("Duplicate...", "title=cropGFP duplicate");
	selectWindow(tit_imgCy3);
	roiManager("select", i_roi);
	run("Duplicate...", "title=cropLipid duplicate");
	
	selectWindow(tit_img_zproj_GFP);
	makeRectangle(1000, 350, 150, 300);
	roiManager("Add");
	roiManager("Select", roiManager("count")-1);
	roiManager("measure");
	roiManager("Delete");
	mean_background = getResult("Mean", 0);
	run("Clear Results");
	
	roiManager("select", i_roi);
	run("Duplicate...", "title=cropzprojGFP duplicate");

	// merge colors
	run("Merge Channels...", "c1=cropLipid c2=cropGFP create");
	merged_img_name = getTitle();

	roiManager("select", i_roi);
	name_roi = Roi.getName();
	// opens the folder associated to the cell thanks to the ROI name
	roi_clusters = folderRes+name_roi+File.separator+"ROI_GFP_big_ROIs_cropCell_"+i_roi+1+".zip";

	//
	folderRes2 = folderRes+name_roi+File.separator;
	file_subFolder2 = getFileList(folderRes2);
	for (i_file = 0; i_file < lengthOf(file_subFolder2); i_file++) {
		
		if( startsWith(file_subFolder2[i_file],"crop_normalized_Cell") ){
		imgCrop = folderRes2+file_subFolder2[i_file];
	}
	}

	// folder that will contain the reslice
	dir_cluster_Z = folderRes+name_roi+File.separator+"Cluster_Z_reslice"+File.separator;
	File.makeDirectory(dir_cluster_Z);

	// opens the cluster ROIs, combined -> need to split them
	roiManager("reset");
	roiManager("open",roi_clusters);
	roiManager("select", 0);
	if(Roi.getType == "composite") { // if combination: splits, otherwise ROIs remains like that
		roiManager("Split");
		roiManager("select", 0);
		roiManager("Delete");
	}
	
	nbClusters = roiManager("count");
	print("number of clusters="+nbClusters);

	roiManager("deselect");
	selectWindow("cropzprojGFP"); // measure on the Z-projection for green intensity
	roiManager("measure");

	arrayAreaCluster_curImg = newArray(nbClusters);
	arrayMeanCluster_curImg = newArray(nbClusters);
	arrayHeightCluster_curImg = newArray(nbClusters);
	arrayHeightClusterNet_curImg = newArray(nbClusters);
	arrayCellNumber_curImg = newArray(nbClusters);
	arrayClusterNumber_curImg = newArray(nbClusters);
	arrayGFPbackgound_curImg = newArray(nbClusters);

	run("Clear Results");

	open(imgCrop);
	tit_imgCrop = getTitle();
	selectWindow(tit_imgCrop);
	roiManager("measure");
	
	for(i_cl = 1; i_cl <= nbClusters; i_cl++){

		arrayAreaCluster_curImg[i_cl-1] = getResult("Area",i_cl-1);
		mean = getResult("Mean",i_cl-1);
		arrayMeanCluster_curImg[i_cl-1] = mean;
		arrayCellNumber_curImg[i_cl-1] = i_roi+1;
		arrayClusterNumber_curImg[i_cl-1] = i_cl;
		arrayGFPbackgound_curImg[i_cl-1] = mean_background;
	}
	close();
	run("Clear Results");

//Arrays image sizes in lz plane
	arrayClusterLsize_curImg = newArray(nbClusters);
	arrayClusterZsize_curImg = newArray(nbClusters);
	arrayClusterLsizeSmall_curImg = newArray(nbClusters);

	arrayResliceNames = newArray(4);
	arrayResliceTubeArea = newArray(4);
	
	for(i_cl = 1; i_cl <= nbClusters; i_cl++){
		
		selectWindow(merged_img_name);

		roiManager("select",i_cl-1);
		run("Scale... ", "x=3 y=3 centered");
		run("Duplicate...", "title=cluster"+i_cl+" duplicate");
		rename(arrayClusterNumber_curImg[i_cl-1]);
		
		getDimensions(width_crop, height_crop, channels_crop, slices_crop, frames_crop);

//make several reslices along lines passing through the center of mass of the cluster ROI
		
		// line from up-left corner to low-right corner
		makeLine(0,0, width_crop-1, height_crop-1);
		run("Reslice [/]...", "output=1.000 slice_count=1");
		rename("reslice1_"+i_cl+"_cluster.tif");
		arrayResliceNames[0] = getTitle();


		selectWindow(arrayClusterNumber_curImg[i_cl-1]);
		// line from low-left corner to up-right corner
		makeLine(0,height_crop-1, width_crop-1, 0);
		run("Reslice [/]...", "output=1.000 slice_count=1");
		rename("reslice2_"+i_cl+"_cluster.tif");
		arrayResliceNames[1] = getTitle();



		selectWindow(arrayClusterNumber_curImg[i_cl-1]);
		// vertical line
		makeLine(Math.round((width_crop-1)/2),0, Math.round((width_crop-1)/2), height_crop-1);
		run("Reslice [/]...", "output=1.000 slice_count=1");
		rename("reslice3_"+i_cl+"_cluster.tif");
		arrayResliceNames[2] = getTitle();



		selectWindow(arrayClusterNumber_curImg[i_cl-1]);
		// horizontal line
		makeLine(0,Math.round((height_crop-1)/2), width_crop-1, Math.round((height_crop-1)/2));
		run("Reslice [/]...", "output=1.000 slice_count=1");
		rename("reslice4_"+i_cl+"_cluster.tif");
		arrayResliceNames[3] = getTitle();

//to get the best reslice (with highest signal of the membrane along z direction)

for(i_reslice=0; i_reslice<lengthOf(arrayResliceTubeArea); i_reslice++){
	selectWindow(arrayResliceNames[i_reslice]);
	run("Duplicate...", "title=binary_lipid_cluster_"+i_cl+"_reslice"+i_reslice+1+" duplicate channels=1");
	binaryReslice = getTitle();
	getDimensions(width_crop_z, height_crop_z, channels_crop_z, slices_crop_z, frames_crop_z);

	run("Auto Threshold", "method=RenyiEntropy white");
	run("Analyze Particles...", "add");
	array = newArray(roiManager("count")-nbClusters);
	for(j=0; j<roiManager("count")-nbClusters;j++){
		array[j] = j + nbClusters;
		}

//if cannot combine the ROIs of clusters
	if(lengthOf(array)==1){
		roiManager("Select", array);
		run("Measure");
		arrayResliceTubeArea[i_reslice] = getResult("Area", 0);
		run("Clear Results");
		roiManager("Select", roiManager("count")-1);
		roiManager("Delete");
		}
	else{
		roiManager("Select", array);
		roiManager("Combine");
		roiManager("Add");
		roiManager("Select", roiManager("count")-1);
		run("Measure");
	
		arrayResliceTubeArea[i_reslice] = getResult("Area", 0);
		run("Clear Results");
		roiManager("Select", roiManager("count")-1);
		roiManager("Delete");
		roiManager("Select", array);
		roiManager("Delete");
		}

		selectWindow(binaryReslice);
		close();
		
	}

	TubeAreaMax = 0;
	IndexTubeAreaMax = 0;
	for(i_reslice=0; i_reslice<lengthOf(arrayResliceTubeArea); i_reslice++){
		if(arrayResliceTubeArea[i_reslice]>TubeAreaMax){
			TubeAreaMax = arrayResliceTubeArea[i_reslice];
			IndexTubeAreaMax = i_reslice;
			}
		}

//close all windows of not the main reslice
	for(i_reslice=0; i_reslice<lengthOf(arrayResliceTubeArea); i_reslice++){
		if(i_reslice != IndexTubeAreaMax){
			selectWindow(arrayResliceNames[i_reslice]);
			close();
			}
		}

		selectWindow(arrayResliceNames[IndexTubeAreaMax]);

		resliceImage = getTitle();
		run("Duplicate...", "title=binary_lipid_cluster"+i_cl+" duplicate channels=1");

		getDimensions(width_crop_z, height_crop_z, channels_crop_z, slices_crop_z, frames_crop_z);
	
		arrayClusterLsize_curImg[i_cl-1] = width_crop_z;
		//when the SLB is in the center
		arrayClusterZsize_curImg[i_cl-1] = height_crop_z;
		//arrayClusterZsize_curImg[i_cl-1] = 21;
		arrayClusterZsize_curImg[i_cl-1] = 21;
		arrayClusterLsizeSmall_curImg[i_cl-1] = Math.round(width_crop_z/3);
		
		run("Auto Threshold", "method=RenyiEntropy white");
		selectWindow(resliceImage);
		saveAs("tiff",dir_cluster_Z+"Merged_2colors_cluster"+i_cl+".tif");
		resliceImage = getTitle();
		
		makeRectangle( Math.round(arrayClusterLsize_curImg[i_cl-1]/2-arrayClusterLsizeSmall_curImg[i_cl-1]/2)-1, 0, Math.round(arrayClusterLsizeSmall_curImg[i_cl-1])+1, arrayClusterZsize_curImg[i_cl-1]);
		//makeRectangle( Math.round(arrayClusterLsize_curImg[i_cl-1]/3)-1, 0, Math.round(arrayClusterLsize_curImg[i_cl-1]/3)+1, arrayClusterZsize_curImg[i_cl-1]);
		
		roiManager("Add");
		roiManager("select", roiManager("count")-1);
		
		run("Duplicate...", "title=Merged_2colors_cluster_small"+i_cl+" duplicate channels=1-2");
		saveAs("tiff",dir_cluster_Z+"Merged_2colors_cluster_small"+i_cl+".tif");
		close();

		selectWindow(resliceImage);
		close();

		roiManager("select", roiManager("count")-1);
		roiManager("Delete");
		
		selectWindow("binary_lipid_cluster"+i_cl);
		saveAs("tiff",dir_cluster_Z+"Binary_cluster"+i_cl+".tif");
		resliceImageBinary = getTitle();
		
		makeRectangle( Math.round(arrayClusterLsize_curImg[i_cl-1]/3)-1, 0, Math.round(arrayClusterLsize_curImg[i_cl-1]/3)+1, arrayClusterZsize_curImg[i_cl-1]);
		roiManager("Add");
		roiManager("select", roiManager("count")-1);
		run("Duplicate...", "title=Binary_cluster_small"+i_cl+" duplicate channels=1");
		saveAs("tiff",dir_cluster_Z+"Binary_cluster_small"+i_cl+".tif");
		getDimensions(width_crop_small_z, height_crop_small_z, channels_crop_small_z, slices_crop_small_z, frames_crop_small_z);
		
		arrayClusterLsizeSmall_curImg[i_cl-1] = width_crop_small_z;
			
		close();

		selectWindow(resliceImageBinary);
		close();

		roiManager("select", roiManager("count")-1);
		roiManager("Delete");

		selectWindow(arrayClusterNumber_curImg[i_cl-1]);
		close();
	}

	roiManager("reset");
	selectWindow(merged_img_name);
	close();

	for(i_cl = 1; i_cl <= nbClusters; i_cl++){
		open(dir_cluster_Z+"Binary_cluster_small"+i_cl+".tif");
		run("Analyze Particles...", "add");

		indexROI = newArray(roiManager("count"));
		for(i_r = 0; i_r < roiManager("count"); i_r++)
			indexROI[i_r] = i_r;
		
		if( roiManager("count") > 1 ){
			roiManager("select", indexROI);
			roiManager("combine");
			roiManager("add");
			roiManager("Deselect");
			
			N = roiManager("count");
			for(i=0;i<N-1; i++){
				roiManager("select", 0);
				roiManager("Delete");
				}
		}

j=0;
for(i=1; i<=arrayClusterZsize_curImg[i_cl-1]; i++){

makeRectangle(0, i-1, arrayClusterLsizeSmall_curImg[i_cl-1], 1);
roiManager("Add");

roiManager("Select", newArray(0,1));
roiManager("AND");

if (selectionType > -1){
	j++;
	}

run("Select All");
roiManager("Deselect");

roiManager("Select", 1);

roiManager("Delete");

}

arrayHeightClusterNet_curImg[i_cl-1] = j;
print("j="+arrayHeightClusterNet_curImg[i_cl-1]);

		roiManager("select", roiManager("count")-1);
		roiManager("measure");
		roiManager("reset");
		close();
	}

	for(i_cl = 1; i_cl <= nbClusters; i_cl++)
		arrayHeightCluster_curImg[i_cl-1] = getResult("Height", i_cl-1);

	arrayAreaCluster_AllImg = Array.concat(arrayAreaCluster_AllImg,arrayAreaCluster_curImg);
	arrayMeanCluster_AllImg = Array.concat(arrayMeanCluster_AllImg,arrayMeanCluster_curImg);
	arrayHeightCluster_AllImg = Array.concat(arrayHeightCluster_AllImg,arrayHeightCluster_curImg);
	//
	arrayHeightClusterNet_AllImg = Array.concat(arrayHeightClusterNet_AllImg,arrayHeightClusterNet_curImg);	
	arrayCellNumber_AllImg = Array.concat(arrayCellNumber_AllImg,arrayCellNumber_curImg);
	arrayClusterNumber_AllImg= Array.concat(arrayClusterNumber_AllImg,arrayClusterNumber_curImg);
	arrayGFPbackgound_AllImg= Array.concat(arrayGFPbackgound_AllImg,arrayGFPbackgound_curImg);

	selectWindow("cropzprojGFP");
	close();

	run("Clear Results");

}

arrayAreaCluster_AllImg = Array.deleteIndex(arrayAreaCluster_AllImg, 0);
arrayMeanCluster_AllImg = Array.deleteIndex(arrayMeanCluster_AllImg, 0);
arrayHeightCluster_AllImg = Array.deleteIndex(arrayHeightCluster_AllImg, 0);
arrayHeightClusterNet_AllImg = Array.deleteIndex(arrayHeightClusterNet_AllImg, 0);
arrayCellNumber_AllImg = Array.deleteIndex(arrayCellNumber_AllImg, 0);
arrayClusterNumber_AllImg = Array.deleteIndex(arrayClusterNumber_AllImg, 0);
arrayGFPbackgound_AllImg = Array.deleteIndex(arrayGFPbackgound_AllImg, 0);

for (i_res = 0; i_res < lengthOf(arrayAreaCluster_AllImg); i_res++) {
	setResult("Cell number",i_res,arrayCellNumber_AllImg[i_res]);
	setResult("Cluster number",i_res,arrayClusterNumber_AllImg[i_res]);
	setResult("Area Cluster",i_res,arrayAreaCluster_AllImg[i_res]);
	setResult("Integrin density um-2 (from GFP-max projection)",i_res,arrayMeanCluster_AllImg[i_res]);
	setResult("Height Cluster",i_res,arrayHeightCluster_AllImg[i_res]);
	setResult("Height Cluster Net",i_res,arrayHeightClusterNet_AllImg[i_res]);
	setResult("GFP background",i_res,arrayGFPbackgound_AllImg[i_res]);
}

saveAs("Results",folderRes+"Results_height_mean_area_clustersAllCells_new.xls");
