// CSV file with all results
name = "2510-15_";

path_results_concat = "/Users/mikhajlo/Documents/Institut_Curie/paper/submission/submission2/maria-distance2edge/data/dense/" + name + ".csv";
//+ toString(name) + toString(.csv);

// the first time creates the "headers" line
if( !File.exists(path_results_concat) )// adds: Mean value cell norm map, threshold bright particles
	File.append("name, x, y", path_results_concat);

// clears everything
roiManager("reset");
run("Clear Results");
run("Close All");

// the user chooses his image
file_name = File.openDialog("Choose your image");
open(file_name);
img_tit = getTitle();
dir_img = getDirectory("image");
filelist = getFileList(dir_img);
name_noext = substring(file_name,lastIndexOf(file_name, File.separator)+1,indexOf(file_name, "."));
getDimensions(width, height, channels, slices, frames);

//if do not want to keep the previsous selection
run("Select None");
run("Remove Overlay");

run("Duplicate...", "title=orig_image duplicate");

img_tit = getTitle();
// searches for ROI file 
nbROIfile = 0;
ROI_file = "";

for (i_file = 0; i_file < lengthOf(filelist); i_file++) {
	
	if( startsWith(filelist[i_file],"ROIs_cropCell") ){
		ROI_file = dir_img+filelist[i_file];
		nbROIfile++;
	}

}

roiManager("open", ROI_file);
roiManager("Select", 0);

getSelectionCoordinates(x, y);
		
Length = x.length;
//info_file = 0;

for (i = 0; i < Length; i++){

	print(x[i]+','+y[i]);
	info_file = toString(file_name) + ", " + toString(x[i]) + ", "+ toString(y[i]);
	File.append(info_file, path_results_concat);
	}