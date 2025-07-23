//#######################################################################################################################
//#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
//#																														#
//# Author: M. Oger (U.I/D.PRT/IRBA), M. Cherrière (IRBA/INERIS)														#
//# Date of creation: 01/09/2023																						#
//# Date of last modification: 15/12/2023																				#
//#																														#
//# Macro name: Foci_detection.ijm																						#
//#																														#
//# Macro function: 																									#
//# ## Macro allowing: 																									#
//# ## 1- to create a "focus" image from a stack of images 																#
//# ## 2- to process the recreated image and then binarize it															#
//# ## 3- to remove the cells undergoing apoptosis from the analysis													#
//# ## 4- to keep only the "foci" that are co-localized with the nuclei (eliminates points that are in the background) 	#
//# ## 5- to perform an analysis of the binary image to count the foci													#
//#																														#
//#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
//#######################################################################################################################


//~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~ Global variables ~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~
var iv = false;														// In vivo if true, in vitro if false


//~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~ Local functions  ~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~

function selection_apoptosis(titleFITCoutput){
	// Select the cells undergoing apoptosis.
	// input:	- titleFITCoutput 	= output image title.
	// output:	- 
	selectWindow(titleFITCoutput);
	run("Duplicate...", "title=mask_apoptosis");
	//##~~ Threshold of the image
	setThreshold(8000, 65535);
	run("Convert to Mask");
	run("Area Opening", "pixel=100");								// Delete all objects smaller than 100 pixels.
	close("mask_apoptosis");
	selectWindow("mask_apoptosis-areaOpen");
	rename("mask_apoptosis");
}


function suppress_apoptosis(titleFITC) {
	// Suppress the cells undergoing apoptosis.
	// The nuclei of cells undergoing apoptosis are detected at the same time as the foci. They must therefore be selected and removed from the analysis.
	// input:	- titleFITC 		= title of the image channel where foci can be detected.
	// output:	- 
	run("Morphological Reconstruction", "marker=["+titleFITC+"_mask_apoptosis] mask=["+titleFITC+"-Threshold] type=[By Dilation] connectivity=8");
	rename("apoptosis_WTH");
	imageCalculator("XOR create", titleFITC+"-Threshold","apoptosis_WTH");
	temp = getTitle();
	close(titleFITC+"-Threshold");
	selectWindow(temp);
	rename(titleFITC+"-Threshold");
	imageCalculator("OR create", titleFITC+"_mask_apoptosis","apoptosis_WTH");
	rename(titleFITC+"_apoptosis");
}


function analyzeFITC(titleFITC, titleFITCoutput, titleDAPIoutput, titleDAPIbin){
	// Analyze the foci image to extract all the foci and suppress the cells undergoing the apoptosis
	selectImage(titleFITC);
	run("Z Project...", "projection=[Average Intensity]");			// Z-projection of the Z stack (3D-> 2D)
	rename(titleFITCoutput);
	selectImage(titleFITCoutput);
	selection_apoptosis(titleFITCoutput);							// Selection of cells undergoing apoptosis
	selectWindow("mask_apoptosis");
	rename(titleFITC+"_mask_apoptosis");
	selectImage(titleFITCoutput);
	//##~~ Image enhance contrast to ease the foci detetion
	run("Morphological Filters", "operation=[White Top Hat] element=Disk radius=5");
	run("Enhance Contrast", "saturated=0.35");
	titleMorpho = getTitle();
	selectImage(titleMorpho);
	run("Duplicate...", "title=["+titleFITC+"-Threshold]");
	//##~~ Threshold choice that must be greater than 1000 on cell cultures images, greater than 150 on iv images (background noise value on negative control images).
	setAutoThreshold("Yen dark no-reset");
	getThreshold(lower, upper);
	print("initial threshold: " + lower);
	if(iv == true){
		setThreshold(maxOf(lower,150), upper);
	}
	else{
		setThreshold(maxOf(lower,1000), upper);
	}
	getThreshold(lower, upper);
	print("final threshold: " + lower);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	//##~~ Remove the cells undergoing apoptosis from the analysis
	suppress_apoptosis(titleFITC);
	selectWindow(titleFITC+"-Threshold");
	run("Analyze Particles...", "  show=[Count Masks] exclude summarize");	// Labelling of each detected foci
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~   Main program   ~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~

arg = getArgument();
arg = split(arg, " ");
arg = arg[0];
if (arg == "true"){iv = true;}
title = getTitle();													// Retrieval of the active FITC image title
title2 = title+"_output";											// Initialization of the FITC image title
titleDAPI = replace(replace(title,"SVCC","LVCC"), "C=1", "C=0");	// Retrieval of the DAPI image title
titleDAPIbin = titleDAPI+"_binaire";								// Retrieval of the binary DAPI image title

analyzeFITC(title, title2, titleDAPI+"_output", titleDAPIbin);