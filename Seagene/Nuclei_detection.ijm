//#######################################################################################################################
//#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
//#																														#
//# Author: M. Oger (U.I/D.PRT/IRBA), M. Cherrière (IRBA/INERIS)														#
//# Date of creation: 01/09/2023																						#
//# Date of last modification: 15/03/2024																				#
//#																														#
//# Macro name : Nuclei_detection.ijm																					#
//#																														#
//# Macro function:																										#
//# ## Macro allowing: 																									#
//# ## 1- to create a "focused" image from a stack of images															#
//# ## 2- to process the recreated image and then binarize it															#
//# ## 3- to perform an analysis of the binary image to count objects with a sufficient area			 				#
//#																														#
//#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
//#######################################################################################################################


//~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~ Global variables ~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~

title = getTitle();						// Retrieval of the active DAPI image title
title2 = title+"_output";				// Create the output title
print(title2);
bin = title+"_binary_ini";				// Create the binary image title
listImages = getList("image.titles");
proj = false;							// Initialize the "proj" variable (true if the Z-projection was done, false if not)
stardist = false;						// Initialize the "stardist" variable (true if the StarDist computation was done, false if not)
batchmode = true;


//~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~ Local Functions ~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~


function depthOfField() { 
	// Create a "focused" image from a Z-stack of images (3D -> 2D)
	nImages1 = nImages;
	run("Extended Depth of Field (Easy mode)...", "quality='4' topology='1' show-topology='off'");
	while (nImages == nImages1){wait(1000);}
	return "end";
}


//~~~~~~~~~~~~~~~~~~~~~~
//~~~~ Main program ~~~~
//~~~~~~~~~~~~~~~~~~~~~~

//##~~ Search if the Z-projection and/or the StarDist computation was done on the images (proj and stardist -> true)
for(l=0; l < listImages.length; l++){
	if(listImages[l] == title2){
		selectWindow(title2);
		proj = true;
	}
	else if(listImages[l] == bin){
		stardist = true;
}	}

print("proj = "+proj);
print("stardist = "+stardist);
//setBatchMode("exit and display");

//##~~ If "proj" is "false": compute the Z-projection (3D -> 2D)
if(!proj){
	tempend = depthOfField();
	selectWindow("Output");
	rename(title2);
	//setBatchMode("hide");
}

//##~~ If "stardist" is "false": run the StarDist plugin to find the nuclei inside the DAPI image
if(!stardist){
	//setBatchMode("exit and display");
	selectWindow(title2);
	seuilproba = 0.005;
	degresuperpos = 0.6;
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'"+title2+"', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'"+seuilproba+"', 'nmsThresh':'"+degresuperpos+"', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'true'], process=[false]");
//	setBatchMode("hide");
	rename(title+"_LabImg");
	run("Duplicate...", "title=Label_Image_bis duplicate");
	setThreshold(1, 65535);
	setOption("BlackBackground", true);
	run("Convert to Mask");
}
else {
	selectWindow(bin);
	rename("Label_Image_bis");
}
setThreshold(1, 255);
run("Select None");

run("Analyze Particles...", "size=205-Infinity show=Masks display summarize add");
run("Invert LUT");
if(!stardist){selectWindow("Probability/Score Image");}
setBatchMode("hide");
