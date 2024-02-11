// General description

// set path to the .csv file with results (quantification on the cell level)
path_results_concat = "PATH-to-the-results.csv-file";

// the first time creates the "headers" line
if( !File.exists(path_results_concat) )
	File.append("File name, Name image, cell number, area cell um2, area adhesion zone um2, cluster area um2, number of clusters, Circ cell, adhesion zone to cell area ratio, cluster area to adhesion zone area ratio, Total amount of fluors in adhesion zone, Fluors density in adhesion zone um-2, GFP background, GFP threashold um-2, Mean value other channel (optional)", path_results_concat);

// clears everything
roiManager("reset");
run("Clear Results");
run("Close All");

//F_values are the calibration factors
//2nd channel - mCherry
F_value_mainChannel = 5.33;
F_value_secondChannel = 1;
F_value_thirdChannel = 1;

// the user chooses the image to analyse
file_name = File.openDialog("Choose your image");
open(file_name);
img_tit = getTitle();
dir_image = getDirectory("image");
name_noext = substring(file_name,lastIndexOf(file_name, File.separator)+1,indexOf(file_name, "."));
getDimensions(width, height, channels, slices, frames);

//if do not want to keep the previsous selection
run("Select None");
run("Remove Overlay");

run("Duplicate...", "title=orig_image duplicate");

// identification of channels in the image
choices = newArray(channels);
for (i=0; i<channels; i++){
	a="C"+(i+1);
	choices[i] = a;
}

run("Split Channels");
string_concat = "";
for (i=0; i<channels; i++){
	selectWindow('C'+i+1+'-'+"orig_image");
	run("Enhance Contrast", "saturated=0.35");
	run("RGB Color");
	run("Label...", "format=Text starting=0 interval=1 x=5 y=20 font=70 text=C"+i+1);
	rename("C"+i+1+".tif");
	string_concat += "image"+i+1+"=[C"+i+1+".tif] ";
}
run("Concatenate...", "  title=[Stack] "+string_concat);
run("Make Montage...", "columns="+channels+" rows=1 scale=1 border=1");

// asks the user the channel correspondance
Dialog.create("Channel for the integrin cluster analysis");
Dialog.addChoice("Choose the channel for analysis", choices);
Dialog.addChoice("Choose the channel for cell detection", choices);
Dialog.addChoice("Choose the channel for normalization", choices);
choices = append_tab_beg(choices, "None");
Dialog.addChoice("Choose the (optional) second channel for analysis", choices);
Dialog.show();
Result = Dialog.getChoice();
Result_chanAnalyse=substring(Result, 1, 2);
Result = Dialog.getChoice();
Result_chanCell=substring(Result, 1, 2);
Result = Dialog.getChoice();
Result_chanNorm=substring(Result, 1, 2);
Result = Dialog.getChoice();
if( Result == "None")
	Result_chanAnalyse2 = -1;
else 
	Result_chanAnalyse2 = substring(Result, 1, 2);

Result_chanAnalyse3 = -1;

selectWindow("Montage");
close();
selectWindow("Stack");
close();

// 1st step : cell detection
selectWindow(img_tit);
run("Duplicate...", "duplicate channels="+Result_chanCell+"-"+Result_chanAnalyse);

title_cell_img = getTitle();
detectCells(title_cell_img);
n_cells = roiManager("count");

// creation of the result folder
Dirp= dir_image + "Threshold_Results_" + name_noext+ "_" + n_cells +"cells";
File.makeDirectory(Dirp);
print("Results save in: "+Dirp);
roiManager("deselect");
roiManager("save", Dirp+File.separator+"ROIs"+name_noext+".zip");

roiManager("deselect");
roiManager("save",Dirp+"ROIs_cell.zip");

//roiManager("reset");

// 2nd step: creation of the normalization map
selectWindow(img_tit);
run("Duplicate...", "duplicate channels="+Result_chanNorm+"-"+Result_chanNorm);
computeNormalization(getTitle());

//n_cells_treated = checkCellsWithMap();
n_cells_treated = n_cells;

cell_mean_normMap = cellMeanValue_normMap();

if( n_cells_treated == 0 )
	exit("There is no cell to treat (all on defaults of the map)");

print(n_cells_treated);
circEnlargedCells = newArray(n_cells_treated);
computeCircEnlargedCells(circEnlargedCells,n_cells_treated);

roiManager("reset");

// 3rd step: analysis of the clusters
selectWindow(img_tit);
roiManager("show all");
roiManager("show none");
run("Duplicate...", "duplicate channels="+Result_chanAnalyse+"-"+Result_chanAnalyse);
img_chan_ana = getTitle();
run("Enhance Contrast", "saturated=0.35");

print("Channel analyse:"+Result_chanAnalyse);
print("Channel cell:"+Result_chanCell);
print("Channel normalize:"+Result_chanNorm);

run("Set Measurements...", "mean area min shape display redirect=None decimal=7");
run("Clear Results");
selectWindow(img_chan_ana);
makeRectangle(1000, 200, 150, 700);
run("Measure");
mean_background=getResult("Mean",0);
print("Value bg ="+mean_background);

computeNormalizedChan(img_chan_ana,mean_background,F_value_mainChannel,"Normalized_channel");
roiManager("reset");

if( Result_chanAnalyse2 != -1 ){
	selectWindow(img_tit);
	roiManager("show all");
	roiManager("show none");
	run("Duplicate...", "duplicate channels="+Result_chanAnalyse2+"-"+Result_chanAnalyse2);
	img_chan_opt = getTitle();

	selectWindow(img_chan_opt);
	makeRectangle(1000, 200, 150, 700);
	run("Measure");
	mean_background_2nchan=getResult("Mean",0);
	print("Value bg second channel="+mean_background_2nchan);
		
	computeNormalizedChan(img_chan_opt,mean_background_2nchan,F_value_secondChannel,"Normalized_channel_optional");
}

selectWindow("norm_map");
close();

// if norm bilayer > 1 (tube or defect) => normalize to 1
for (i_roi = 0; i_roi < n_cells_treated; i_roi++) {
	roiManager("open",StoN_Dirp+"ROIs_cell.zip");

	roiManager("select", i_roi);
	name_roi = Roi.getName;
	
	// creates the results folder
	Dir = Dirp+File.separator+name_roi;
	File.makeDirectory(Dir);

// set path to the .csv file with results (quantification on the individual cluster level)
path_results_indi_clusters_concat = Dir+File.separator+name_roi+"_individual_clusters.csv";
if( !File.exists(path_results_indi_clusters_concat) )
	File.append("File name, Name image, cell number, cluster number, cluster size um2, cluster density um-2", path_results_indi_clusters_concat);
	
	selectWindow(img_tit);
	roiManager("select", i_roi);
	run("Duplicate...", "title=img_crop duplicate");
	saveAs("Tif", Dir+ File.separator+"crop_multicolor_"+name_roi+"_"+img_tit);
	//saveAs("Tif", Dir+ File.separator+"crop_multicolor_"+name_roi+"_"+Result+"_"+img_tit);
	
	selectWindow(img_chan_ana);
	roiManager("select", i_roi);
	name_roi = Roi.getName;
	run("Duplicate...", "title=img_crop");
	roiManager("add"); // roi on the cropped image

	if( Result_chanAnalyse2 != -1 ){
		selectWindow("Normalized_channel_optional");
		roiManager("select", i_roi);
		name_roi = Roi.getName;
		run("Duplicate...", "title=img_crop_otherChan");
	}


	selectWindow("Normalized_channel");
	roiManager("select", i_roi);
	run("Duplicate...", "title=img_crop_norm");

	for (i = 0; i < n_cells_treated; i++) { // last one is the cell in the cropped image
		roiManager("select", 0);
		roiManager("delete");
	}

//ROI has only 1 entry - cell ROI
//threashold RenyiEntropy on Cy3

	if( Result_chanAnalyse2 != -1 ){
		selectWindow("img_crop_otherChan");		
		run("Duplicate...", "title=bright_particles_cy3");
		setAutoThreshold("RenyiEntropy dark");
		getThreshold(lower_th_red,upper);

		// auto threshold red
		run("Auto Threshold", "method=RenyiEntropy white");	
		run("Analyze Particles...", "size=0-Infinity show=Overlay display add");
		selectWindow("img_crop_otherChan");
		roiManager("Show all without labels");

		roiManager("deselect");
		
		tab_index_cy3 = newArray(roiManager("count")-1);
		for (i = 1; i <= roiManager("count")-1; i++) { // first one = whole cell
			tab_index_cy3[i-1] = i;
		}

		roiManager("select", tab_index_cy3);
		roiManager("combine");
		roiManager("add");
		roiManager("select", roiManager("count")-1);
		roiManager("rename", "Bright particles cy3"+name_roi);
		
		nbParticules_cy3 = roiManager("count");
		print(nbParticules_cy3);
		for (i = 0; i < nbParticules_cy3-2; i++) { // leaves only the first and combination black/bright
		roiManager("select", 1);
		roiManager("delete");
		}
		
		roiManager("deselect");
		roiManager("save", Dir+File.separator+"ROIs_crop_cy3_"+name_roi+".zip");

		nbParticules = roiManager("count");
		for (i = 0; i < nbParticules-1; i++) { // leaves only the first whole cell ROI
			roiManager("select", 1);
			roiManager("delete");
		}
	}
	
// cluster segmentatiob
	selectWindow("img_crop");
	run("Duplicate...", "title=bright_particles");
	setAutoThreshold("RenyiEntropy dark");
	getThreshold(lower_th_green,upper);

	// auto threshold and offer manual if uncorrect
	run("Auto Threshold", "method=RenyiEntropy white");
	res_th = getBoolean("Are you satisfied by the automatic segmentation? (if no manual threshold will be done)");
	if( res_th == false ){
		selectWindow("bright_particles");
		close();
		selectWindow("img_crop");
		run("Duplicate...", "title=bright_particles");
		run("Threshold...");
		waitForUser("Change the threshold to the value that suits your image");
		setOption("BlackBackground", true);
		getThreshold(lower_th_green,upper);
		run("Convert to Mask");
		run("Select All");
	}	
	
	run("Analyze Particles...", "size=0-Infinity show=Overlay display add");
	selectWindow("img_crop");
	roiManager("Show all without labels");

	roiManager("deselect");
	tab_index = newArray(roiManager("count")-1);
	for (i = 1; i <= roiManager("count")-1; i++) { // first one = whole cell
		tab_index[i-1] = i;
	}
	roiManager("select", tab_index);
	roiManager("combine");
	roiManager("add");
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "Bright particles "+name_roi);
//
	nbParticules = roiManager("count");
	for (i = 0; i < nbParticules-2; i++) { // leaves only the first and combination black/bright
		roiManager("select", 1);
		roiManager("delete");
	}

	roiManager("Select", newArray(0,1));
	roiManager("XOR");
	roiManager("Add");
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "XOR Bright particles "+name_roi);

	selectWindow("img_crop");
	close();
	selectWindow("bright_particles");
	close();
	
	selectWindow("img_crop_norm");
	
	roiManager("deselect");
	run("Clear Results");
	roiManager("measure");

	// 1st ROI cell, 2nd ROI bright particles, 3rd ROI: cell outside particles
	mean_clusters = getResult("Mean",1);
	area_clusters = getResult("Area",1);
	density_threashold = getResult("Min",1);
	
	mean_outside_clusters=getResult("Mean",2);
	print("Mean outside cluster: "+mean_outside_clusters);
	
	area_cell = getCellArea();
	area_convexhull_bp = getBrightParticleConvexHullArea();

	info_file = file_name +", "+ img_tit+", "+name_roi;
	info_file += ", "+ toString(area_cell*0.11*0.11);
	info_file += ", "+ toString(area_convexhull_bp*0.11*0.11);
	info_file += ", "+ toString(area_clusters*0.11*0.11);
	info_file += ", "+ toString(nbParticules);
	info_file += ", "+ toString(circEnlargedCells[i_roi]);
	info_file += ", "+ toString(area_convexhull_bp/area_cell);
	info_file += ", "+ toString(area_clusters/area_convexhull_bp);
	info_file += ", "+ toString(mean_clusters*area_clusters*0.11*0.11);
	info_file += ", "+ toString(mean_clusters);
	info_file += ", "+ toString(mean_background);
	info_file += ", "+ toString(density_threashold);
	
	// 
	if( Result_chanAnalyse2 != -1 ){
		selectWindow("img_crop_otherChan");
		roiManager("select", 1); // bright particles
		roiManager("measure");
		info_file += ", "+ toString(getResult("Mean", nResults-1));
		run("Clear Results");
		selectWindow("img_crop_otherChan");
		run("Remove Overlay");
		saveAs("Tif", Dir+ File.separator+"crop_normalized_cy3_"+name_roi+"_"+Result+"_"+img_tit);
		close();
	}
	
	File.append(info_file, path_results_concat);

	roiManager("deselect");
	roiManager("save", Dir+File.separator+"ROIs_crop"+name_roi+".zip");
//
	roiManager("select", 0);
	roiManager("delete");
	roiManager("select", 1);
	roiManager("delete");
	roiManager("select", 0);
	roiManager("Split");
	roiManager("Select", 0);
	roiManager("Delete");

run("Set Measurements...", "area mean min centroid shape display redirect=None decimal=7");

N_clusters = roiManager("count");

selectWindow("img_crop_norm");

for(i=0;i<N_clusters;i++){
	info_file_clusters = file_name +", "+ img_tit+", "+name_roi;
	roiManager("Select", 0);
	roiManager("Measure");
	cluster_area = getResult("Area", i);
	cluster_density = getResult("Mean", i);
	info_file_clusters += ", "+ toString(i+1);
	info_file_clusters += ", "+ toString(0.11*0.11*cluster_area);
	info_file_clusters += ", "+ toString(cluster_density);
	
	roiManager("Select", 0);
	roiManager("Delete");
	File.append(info_file_clusters, path_results_indi_clusters_concat);
	}

	roiManager("reset");

	selectWindow("img_crop_norm");
	//saveAs("Tif", Dir+ File.separator+"crop_normalized_"+name_roi+"_"+Result+"_"+img_tit);
	saveAs("Tif", Dir+ File.separator+"crop_normalized_"+name_roi+"_"+img_tit);
	close();


}
File.delete(Dirp+"ROIs_cell.zip");

selectWindow(img_chan_ana);
close();

// computes the Cell Areas
function getCellArea(){
	roiManager("select", 0);
	roiManager("measure");
	area_cell = getResult("Area", 0);
	run("Clear Results");
	return area_cell;
}

// for the bright particle ROI creates the convex hull
function getBrightParticleConvexHullArea(){
	run("Clear Results");
	roiManager("Select", 1);
	run("Convex Hull");
	roiManager("Add");
	roiManager("Select", roiManager("count")-1);
	roiManager("Measure");
	area_convexHull_brightpart = getResult("Area", 0);
	run("Clear Results");
	roiManager("select", roiManager("count")-1);
	roiManager("delete");
	return area_convexHull_brightpart;
}

// for each ROI enlarges the ROI and computes the circularity
function computeCircEnlargedCells(circ_table,n_cells){
	run("Clear Results");
	run("Set Measurements...", "mean area shape display redirect=None decimal=7");
	for (i_roi = 0; i_roi < n_cells; i_roi++) {
		roiManager("select", i_roi);
		//run("Enlarge...", "enlarge=5");
		//roiManager("add");
		//roiManager("select", roiManager("count")-1);
		roiManager("measure");
		circ_table[i_roi] = getResult("Circ.", 0);
		run("Clear Results");
		//roiManager("select", roiManager("count")-1);
		//roiManager("delete");
	}
}

//manual segmentation of cells in the brightfield channel
function detectCells(title_img){
	
	ans =  getBoolean("Do you want to draw cells (circle or polygon)?");
	while( ans == true ){
		setTool("polygon");
		nbROIbef = roiManager("count");
		waitForUser("Draw your cell: 3 points (circle approximation) or polygon (and in the ROI Manager)");
		if( roiManager("count") > nbROIbef ){
			roiManager("select", roiManager("count")-1);
			if( selectionType() == 10 ) // points selection
				findCircles();
			
		}
		else
			print("You did not create a ROI");
		ans =  getBoolean("Do you want to draw cells?");
	}
	
	for (i = 0; i < roiManager("count"); i++) {
		roiManager("select", i);
		roiManager("rename","Cell_"+i+1);
	}

	selectWindow(title_img);
	close();
}

// finds the circle passing by 3 points drawn by the user
function findCircles(){
	run("Set Measurements...", "centroid display redirect=None decimal=7");
	run("Clear Results");
	roiManager("select", roiManager("count")-1);
	roiManager("Measure");
	res = true; 

	// check that 3 points were drawn
	if( nResults > 3 )
		print("Only 3 first points taken into account");
	if( nResults < 3 ){
		print("Less than 3 points, no computation performed");
		res = false;
		// removes the points ROI
		roiManager("select", roiManager("count")-1);
		roiManager("delete");
	}

	if( res == true ){
		x_coord = newArray(3);
		y_coord = newArray(3);
		// reads the point coordinates
		for (i = 0; i < 3; i++) {
			x_coord[i] = getResult("X", i);
			y_coord[i] = getResult("Y", i);
		}
		// computes the center of the circle
		yO = -((x_coord[0]*x_coord[0]+y_coord[0]*y_coord[0])-(x_coord[2]*x_coord[2]+y_coord[2]*y_coord[2])+(x_coord[2]-x_coord[0])/(x_coord[1]-x_coord[0])*( x_coord[1]*x_coord[1]+y_coord[1]*y_coord[1] - (x_coord[0]*x_coord[0]+y_coord[0]*y_coord[0])))/(2*((y_coord[0]-y_coord[1])*(x_coord[2]-x_coord[0])/(x_coord[1]-x_coord[0])+(y_coord[2]-y_coord[0])));
		xO = ((x_coord[1]*x_coord[1]+y_coord[1]*y_coord[1])-(x_coord[0]*x_coord[0]+y_coord[0]*y_coord[0]))/(2*(x_coord[1]-x_coord[0]))+yO*(y_coord[0]-y_coord[1])/(x_coord[1]-x_coord[0]);
		// computes the radius
		r = sqrt((x_coord[0]-xO)*(x_coord[0]-xO)+(y_coord[0]-yO)*(y_coord[0]-yO));
		// draw the circle and removes the points ROI
		makeOval(xO-r, yO-r, 2*r, 2*r);
		roiManager("add");
		roiManager("select", roiManager("count")-2);
		roiManager("delete");
	}
	
	return res;
}

// computes the normalization map on the image with name given as parameter
// if so
function computeNormalization(name_img_norm){
	run("Set Measurements...", "mean min display redirect=None decimal=7");

	selectWindow(name_img_norm);
	run("Spectrum");
	setTool("rectangle");
	waitForUser("Draw the ROI representing the middle of the pattern (no intense spot)");

	run("Clear Results");
	roiManager("add");
	roiManager("select", roiManager("count")-1);
	roiManager("measure");
	mean_val = getResult("Mean", 0);
	
	roiManager("select", roiManager("count")-1);
	roiManager("delete");
	
	selectWindow(name_img_norm);
	roiManager("show all");
	roiManager("show none");
	run("32-bit");
	run("Divide...", "value="+mean_val);
	run("Macro...", "code=v=v-(v-1)*(1-(v<1))");
	resetMinAndMax();

	selectWindow(name_img_norm);
	saveAs("Tif", Dirp+ "/"+"normalization_map.tif");
	rename("norm_map");

}

// checks for each cell that there are no defects on the normalization map (i.e. no value higher than 1)
function checkCellsWithMap(){
	run("Set Measurements...", "min redirect=None decimal=7");
	run("Clear Results");
	
	roiManager("open",Dirp+"ROIs_cell.zip");
	
	selectWindow("norm_map");
	roiManager("measure");

	for (i = nResults-1; i >= 0 ; i--) { 
		if( getResult("Max", i) > 1 ){
			roiManager("select", i);
			roiManager("delete");
			print("Cell "+i+1+" deleted because default on normalization map");
		}
	}

	n_cells_treated = roiManager("count");

	if (n_cells_treated > 0) {
		roiManager("save",Dirp+"ROIs_cell.zip");
	}

	return n_cells_treated;
}

// computes the mean value in the norm_map of the cells
function cellMeanValue_normMap(){
	run("Set Measurements...", "mean min redirect=None decimal=7");
	run("Clear Results");

	roiManager("deselect");
	selectWindow("norm_map");
	roiManager("measure");

	mean_norm = newArray(roiManager("count"));

	for (i = 0; i < nResults; i++)
		mean_norm[i] = getResult("Mean", i);
	
	run("Clear Results");

	return mean_norm;
}

// function that computes the normalization channel of analysis
function computeNormalizedChan(max_int_img,grey_val_bg,F_value,name_normMap) {
	selectWindow(max_int_img);
	roiManager("show all");
	roiManager("show none");
	run("Duplicate...", "title=orig_img_32b");
	run("32-bit");
	run("Subtract...", "value="+grey_val_bg);
	imageCalculator("Divide create", "orig_img_32b","norm_map");
	rename("GFP_normalized");
	run("Multiply...", "value="+F_value);
	rename(name_normMap);

	selectWindow("orig_img_32b");
	close();
}

// adds a value at the beginning of the table
function append_tab_beg(arr, value){
 	arr2 = newArray(arr.length+1);
 	arr2[0] = value;
 	for (i=0; i<arr.length; i++)
 		arr2[i+1] = arr[i];
 	return arr2;
}