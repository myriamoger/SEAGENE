//#######################################################################################################################
//#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
//#																														#
//# Author: M. Oger (U.I/D.PRT/IRBA), M. Cherrière (IRBA/INERIS)														#
//# Date of creation: 01/09/2023																						#
//# Date of last modification: 06/02/2025																				#
//#																														#
//# Project name: SEAGENE																								#
//# Macro name: Main_Foci_detection.ijm																					#
//#																														#
//# Macro function:																										#
//# ## Interactive macro allowing: 																						#
//# ## 1- to choose the folder containing the images 																	#
//# ## 2- to process images ending with "_finale.lif" to extract cell nuclei and foci									#
//# ## 3- to create one results table per slide (5 or 10 positions) that will be saved in the "Resultats" folder 		#
//#																														#
//#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
//#######################################################################################################################


//~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~ Global variables ~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~

sep 			= File.separator;							// Character allowing the separation of different directories of the path
//macro_rep 		= File.getDirectory(getInfo("macro.filepath"));			// Doesn't work on FIJI
dirPlugins 		= getDir("plugins");
macro_rep 		= replace(dirPlugins,"plugins","scripts")+"Plugins"+sep+"Seagene"+sep;
															// Directory of Seagene
source_dir 		= getDirectory("Choose the images directory");			// Directory of the images to process
batchmode		= false;									// Change to "true" to enable the batchmode

//##~~ Creation of a dialog box for user
Dialog.create("Foci Detection");
Dialog.addDirectory("Macros Path", macro_rep);
Dialog.addDirectory("Images Path", source_dir);
Dialog.addRadioButtonGroup("Origin of images:", newArray("Histological slide (In vivo): 10 images", "Cell culture (Ex vivo): 5 images"), 2, 1, "Histological slide (In vivo): 10 images");
Dialog.addMessage("\nAuthors: M. Oger (Imagery Unit, IRBA, France), \n                M. Cherrière (INERIS/IRBA, France)");
Dialog.show();

//##~~ Get user input values
macro_rep 		= Dialog.getString();
source_dir		= Dialog.getString();
origin 			= Dialog.getRadioButton();
if(indexOf(origin, "In vivo")>0){
	invivo = true;
	numImg = 10;
}
else{
	invivo = false;
	numImg = 5;
}

source_dir_split 	= split(source_dir, "\\");
dest_dir 		= source_dir+sep+"Results";					// Results saving directory
dest_img_dir 		= source_dir+sep+"Images";				// Images saving directory
if (!(File.exists(dest_dir))){								// Creation of the results saving directory (if needed)
	File.makeDirectory(dest_dir);
}
if (!(File.exists(dest_img_dir))){							// Creation of the images saving directory (if needed)
	File.makeDirectory(dest_img_dir);
}
finFichier 			= "_finale.lif";						// substring specific to the images to be processed
numLame				= 0;									// Slide number
numPos 				= 0;									// Position number
index 				= -1; 									// Index of the table

nBins 				= 65536;								// Number of bins to be computed for histograms



//~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~ Local Functions ~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~


function listFilesLif(rep, finFich) { 
	// Function listing all the files ending with 'finFich' which are in the directory 'rep' and all its subdirectories.
	// input:	- rep 		= directory in which to search for files ending with 'finFich'.
	//			- finFich 	= substring to search at the end of each filename.
	// output:	- listLif 	= string containing all the filenames ending with 'finFich'. 
	//				  			The filenames are separated by '@'.
	filelist = getFileList(rep);							// List of files in 'rep'
	listLif = "";											// Initialization of 'listLif'
	for (file = 0; file < filelist.length; file++) {
		//##~~ The following two lines allow for the homogenization of folder separators.
		filename = replace(filelist[file], "\\", sep);
		filename = replace(filename, "/", sep);
	    if (endsWith(filename, sep)) { 						// if the current 'filename' is a folder
	    	listLif = listLif + "@"+ listFilesLif(""+rep+filename, finFich); 	// recursive call of the function 'listFilesLif'
	    }
	    else if(endsWith(filename, finFich)){				// if the current 'filename' ends with 'finFich'
	    	listLif = listLif + "@"+rep+filename;			// Add the current 'filename' to 'listLif' string
	}   }
	return listLif;											// Return the 'listLif' string
}


function getInfosFromName(fname, indtab){
	// Function to retrieve information from the image file name
	// input:	- fname 	= name of the current image
	// output:	- string with the slide and position numbers separated with " "
	// global variables:
	//		- numLame 	= current slide
	//		- numPos 	= current position
	selectWindow("table_analysis");							// Selection of the results table 'table_analysis'
	infoName = split(fname, '_');							// Split of the string using "_". each fragment is save in 'infoName'
	numLame  = infoName[0];									// Slide number is the first part of the title stored in 'infoName'
	Table.set("ID_Lame", indtab, substring(numLame,4));		// Initialization of the table line 'table_analysis'
	for(f=1; f < infoName.length; f++){						// Loop going through 'infoName'
		ind = indexOf(infoName[f], "Position ");			// Search of the substring "Position "
		if (ind > 0){										// When the substring is found, the position number is stored in 'table_analysis'
			numPos = substring(infoName[f], ind+lengthOf("Position "));
			Table.set("Position", indtab, numPos);
	}	}
	Table.update;											// Update of the table display 'table_analysis'
	return ""+numLame+" "+numPos;
}


function supprImages(imagesToKeep){
	// Function to close the images unneeded for further processing
	// input:	- imagesToKeep 	= list of the images to keep
	listImages = getList("image.titles");
	for(l=0; l < listImages.length; l++){
		suppr = 1;
		for(im = 0; im < imagesToKeep.length; im++){
			if(listImages[l] == imagesToKeep[im]){
				suppr = 0;
		}	}
		if(suppr > 0){
			close(listImages[l]);							// If the current image is not needed: close it
}	}	}


function addInTable_Number(tab_name, param, param_name, nb_line, ind){
	// Function to add a number from the table 'tab_name' in the table "table_analysis"
	// input:	- tab_name 		= name of the table in which to fetch the parameter
	//			- param 		= parameter to be found in the table 'tab_name'
	//			- param_name 	= name to give to the parameter in the table "table_analysis"
	//			- nb_line 		= number/index of the current line in the table 'tab_name'
	//			- ind 			= number of lines in the table "table_analysis"
	selectWindow(tab_name);
	nb = Table.get(param, nb_line);							// Copy the value of the parameter 'param' for the current line 'nb_line' from table 'tab_name'
	selectWindow("table_analysis");
	Table.set(param_name, ind, nb);							// Paste the value previously copied in the table "table_analysis" at line 'nb_line + ind'
	Table.update;
}


function addInTable_String(tab_name, param, param_name, nb_line, ind){
	// Function to add a string coming from table 'tab_name' in table "table_analysis"
	// input:	- tab_name 		= name of the table in which to fetch the parameter
	//			- param 		= parameter to be found in the table 'tab_name'
	//			- param_name 	= name to give to the parameter in the table "table_analysis"
	//			- nb_line 		= number/index of the current line in the table 'tab_name'
	//			- ind 			= number of lines in the table "table_analysis"
	selectWindow(tab_name);
	txt = Table.getString(param, nb_line);					// Copy of the string 'param' for the current line 'nb_line' from table 'tab_name'
	selectWindow("table_analysis");
	Table.set(param_name, ind, txt);						// Paste the string previously copied in the table "table_analysis" at line 'nb_line + ind'
	Table.update;
}


function addInTable_Histogram(nBins, title){
	// Function to create the tables of histograms
	// input:	- nBins 	= Number of bins to compute for the image histogram
	//			- title 	= Title of the current image
	stack = getImageID();									// Store the name of the current image
	Table.create("table_histogram");						// Creation of the table
	row   = 0;
	getDimensions(width, height, channels, slices, frames);
	if(slices>1){
		for (plan = 1; plan <= nSlices; plan++) {			// for each slice of the current image
			selectImage(stack);
			setSlice(plan);
			run("Duplicate...","title=temp");				// Duplicate the image, computate the histograms and close the duplicated image
		    getHistogram(values, counts, nBins, 0, nBins-1);
		    close();
		    selectWindow("table_histogram");
		    for (bin = 0; bin < nBins; i=bin++){			// fill the table
		    	Table.set("Slice", row, plan);
		    	Table.set("Valeurs", row, bin);
		    	Table.set("NbPixels", row, counts[bin]);
		    	row++;
	}	}	}
	else{													// if the current image has only one slice
		selectImage(stack);
	    getHistogram(values, counts, nBins, 0, nBins-1); 	// compute the histogram
	    selectWindow("table_histogram");
	    for (bin = 0; bin < nBins; i=bin++){				// fill the table
	    	Table.set("Valeurs", row, bin);
	    	Table.set("NbPixels", row, counts[bin]);
	    	row++;
	}	}
	Table.update;
	Table.save(title);
	selectImage(stack);
}


function saveImg2Keep(imagesToKeep) { 
	// Function to save the images during process
	// input: 	- imagesToKeep 	= images to keep open since necessary for the process
	listImages = getList("image.titles");					// List of all open images
	for(l=0; l < listImages.length; l++){					// For each open image:
		suppr = 1;
		for(im = 0; im < imagesToKeep.length; im++){		// if the file name is in the list ImagesToKeep
			if(listImages[l] == imagesToKeep[im]){			// 'suppr' = 0 
				suppr = 0;
		}	}
		if(suppr > 0){										// if 'suppr' is not 0
			close(listImages[l]);							// the image is closed
		} else{												// if 'suppr' is 0
			selectWindow(listImages[l]);					// the image is saved on the disk
			titre = getTitle();
			titre = replace(titre, ".lif - ", "_");
			titre = replace(titre, " ", "_");
			saveAs("tiff", dest_img_dir+sep+titre);
}	}	}


function getListPos(listImages){
	// Function to get the list of positions in the lif file.
	// input:	- listImages 	= list of images in the lif file
	// output:	- list with the position numbers separated by ";"
	posIni = 0;
	indPos = 0;
	position = newArray(numImg);							// Initialization of the array containing the position numbers. Its size depends on the number of images initialy defined (5 for cell cultures, 10 for histology)
	for(nom=0; nom<lengthOf(listImages);nom++){
		name = listImages[nom];
		infoName = split(name, '_');						// Split the title at each "_", each part is stored in 'infoName'
		for(f=1; f < infoName.length; f++){					// Loop accross 'infoName'
			ind = indexOf(infoName[f], "Position ");		// Search of the substring "Position "
			if (ind > 0){									// When the substring is found, the position number is appended/added to the position list
				numPos = parseInt(substring(infoName[f], ind+lengthOf("Position ")));
				for(p = 0; p<lengthOf(position); p++){
					if(position[p] == numPos){posIni = numPos; break;}
				}
				if(posIni != numPos){
					position[indPos] = numPos;
					posIni = numPos;
					indPos++;
	}	}	}	}
	return String.join(position, ";");
}


function lanceAnalyse(repertoire, index) { 
	// Function to run the process (process of DAPI images, then FITC images) on each file of the directory.
	// The analysis results are stored in the 'table_analysis' table, saved in the 'Resultats' directory as '.csv' file.
	// In the 'table_analysis' table, all the positions will be listed, with the corresponding results, for each slide.
	// The positions order in the table is the order of image recording in the '_finale.lif' file.
	// input: 	- source_dir 	= directory to process

	filelistFinale 	= listFilesLif(repertoire, finFichier);	// String with the entire list of '_finale.lif' files in the 'repertoire' directory and its subdirectories.
	filelistFinale 	= split(filelistFinale, "@");			// Split the previous string using "@" to obtain a list of '.lif' to process.
		
	for (file = 0; file < filelistFinale.length; file++) {	// Loop to process all the files on the list
	//for (file = filelistFinale.length-1; file > 0; file--) {			// Loop to process all the files on the list (reverse)
		close("*");											// Close all the images
		Table.reset("Summary");								// Reset of 'Summary' table
		Table.update;										// Update of 'Summary' table display
		Table.reset("table_analysis");						// Reset of 'table_analysis' table
		Table.update;										// Update of 'table_analysis' table display
		index = -1;											// Create an index for the filling of the 'table_ananlysis' table
		roiManager("reset");								// Reset of the ROIManager
		image 		= filelistFinale[file];					// Select the image name at the index 'file' in the 'filelistFinale' list 

		for(i = 0; i < numImg; i++){						// Loop to process the 'numImg' positions in ascending order
		//for(i = numImg-1; i >= 0; i--){					// Loop to process the 'numImg' positions in descending order
			img2Keep 	= newArray();						// Reset of the list of images to keep
			close("*");										// Close all images
			if(batchmode == true){setBatchMode("hide");}
			index 		= index+1;							// New position, add 1 at the 'table_analysis' table index
			n 		= (5*i);								// Create an index for 'Summary' table
			run("Bio-Formats Importer", "open="+image+" split_channels open_all_series");	// Import all the images from the ".lif" file
			getPixelSize(unit, pixelWidth, pixelHeight);	// Read and store the image resolution to use it in area computation
			listImages = getList("image.titles");			// Create the list of images open in the software
			listPos = getListPos(listImages);
			listPos = split(listPos, ";");
			if(listPos[i] != 0){							// If the current position is not 0 (equivalent to 'there is an image')
				for(l = 0; l < listImages.length; l++){		// Loop on the liste of open images
					if(indexOf(listImages[l], "Position "+listPos[i]+"_")>0){	// If the current image is the wanted position
						if(listImages[l].endsWith("LVCC - C=0")){		// If the image name ends with "LVCC - C=0"
							imgDAPI = listImages[l];		// The DAPI channel is kept and the image name is stored on the list of images to keep
							img2Keep = Array.concat(img2Keep,newArray(imgDAPI));
						}
						else if(listImages[l].endsWith("SVCC - C=1")){ 		// If the image name ends with "SVCC - C=1"
							imgFITC = listImages[l];		// The FITC channel is kept and the image name is stored on the list of images to keep
							img2Keep = Array.concat(img2Keep,newArray(imgFITC));
				}	}	}
				supprImages(img2Keep);						// Close the unneeded images
				selectWindow(imgDAPI);						// Selection of the DAPI channel

				infos = getInfosFromName(imgDAPI, index);	// Get infos from DAPI image name and store them in 'table_analysis' table
				infos = split(infos,' ');
				numLame = infos[0];
				numPos = infos[1];
				showStatus("Current slide: "+numLame+" Position: "+numPos+"/"+numImg);
				showProgress(file, filelistFinale.length);
				infos = getInfosFromName(imgFITC, index);	// Get infos from FITC image name and store them in 'table_analysis' table
				infos = split(infos,' ');
				if((infos[0] != numLame) || (infos[1] != numPos)){	// If infos from DAPI and infos from FITC are different, stop the macro
					getBoolean("The 2 open images don't come from the same position!\nThe process is stoped.", "OK", "Cancel");
					return;
				}
				addInTable_Histogram(65536, dest_dir+sep+numLame+"_position"+numPos+"_histo_par_plan.csv");
				imgDAPItemp = replace(imgDAPI, ".lif - ", "_");
				imgDAPItemp = replace(imgDAPItemp, " ", "_");
				//##~~ If the process to detect the nuclei has already been done: open the saved images
				if(File.exists(dest_img_dir+sep+imgDAPItemp+"_binaire_ini.tif")){
					open(dest_img_dir+sep+imgDAPItemp+"_binaire_ini.tif");
					rename(imgDAPI+"_binaire_ini");
					Stack.setXUnit("pixel");
					run("Properties...", "channels=1 slices=1 frames=1 pixel_width=1 pixel_height=1 voxel_depth=1.0000000");
	
				}
				if(File.exists(dest_img_dir+sep+imgDAPItemp+"_output.tif")){
					open(dest_img_dir+sep+imgDAPItemp+"_output.tif");
					rename(imgDAPI+"_output");
					run("Remove Overlay");
					Stack.setXUnit("pixel");
					run("Properties...", "channels=1 slices=1 frames=1 pixel_width=1 pixel_height=1 voxel_depth=1.0000000");
				}
				selectWindow(imgDAPI);
				runMacro(macro_rep+"Nuclei_detection.ijm"); 	// Call the macro for detection of nuclei and mesure of their area
				if(batchmode==true){setBatchMode("exit and display");}
				listImages2 = getList("image.titles");			// Create the list of open images in the software
				mask = 0;
				//##~~ Check if the image named "Mask of Label_Image_bis" is present. If not, create it.
				for (img = 0; img < lengthOf(listImages2); img++) {
					if("Mask of Label_Image_bis" == listImages2[img]){
						mask = 1;
					}
				}
				if(mask == 0){
					run("Analyze Particles...", "size=205-Infinity show=Masks");
					run("Invert LUT");
				}
				selectWindow("Mask of Label_Image_bis");
				rename(imgDAPI+"_binaire");						// Rename the image from the previous macro and add it to the images to keep list
				setVoxelSize(pixelWidth, pixelHeight, 1, "µm");
				img2Keep = Array.concat(img2Keep,newArray(imgDAPI+"_binaire"));
				run("Duplicate...","title=["+imgDAPI+"_binaire_ini]");
				img2Keep = Array.concat(img2Keep,newArray(imgDAPI+"_binaire_ini"));
				img2Keep = Array.concat(img2Keep,newArray(imgDAPI+"_LabImg"));
				if(batchmode == true){setBatchMode("hide");}
				selectWindow(imgDAPI+"_output");
				setVoxelSize(pixelWidth, pixelHeight, 1, "µm");
				img2Keep = Array.concat(img2Keep,newArray(imgDAPI+"_output"));
				addInTable_Histogram(65536, dest_dir+sep+numLame+"_position"+numPos+"_histo_projection.csv");
	
				//##~~ Add the results in "table_analysis" table
				selectWindow("table_analysis");
				print(n, index);
				addInTable_Number("Summary", "Total Area", "Total_Area_Nuclei_px²", n, index);
				Table.set("Total_Area_Nuclei_µm²", index, Table.get("Total_Area_Nuclei_px²", index)*pow(pixelWidth,2));
				addInTable_Number("Summary", "%Area", "%Area_Nuclei", n, index);
				Table.update;
	
				supprImages(img2Keep);							// Delete non needed images
				selectWindow(imgFITC);							// Select FITC image
				//##~~ Run macro to detect the foci
		                runMacro(macro_rep+"Foci_detection.ijm", invivo);
				//##~~ Neighborhood of 20px radius i.e. 6.52µm diameter (ok for 19µm large cells)
				setVoxelSize(pixelWidth, pixelHeight, 1, "µm");
				rename(imgFITC+"_count");
				if(batchmode == true){setBatchMode("exit and display");} //setBatchMode("hide");
				selectWindow(imgFITC+"_apoptosis");
				setVoxelSize(pixelWidth, pixelHeight, 1, "µm");
				rename(imgFITC+"_apoptosis_ini");
				selectWindow(imgFITC+"-Threshold");
				setVoxelSize(pixelWidth, pixelHeight, 1, "µm");
				rename(imgFITC+"_binaire");
				runMacro(macro_rep+"Neighborhood.ijm","20");
				rename(imgFITC+"_P-NbHood_20");
				img2Keep = Array.concat(img2Keep,newArray(imgFITC+"_output",imgFITC+"_binaire",imgFITC+"_P-NbHood_20"));
				//##~~ Keep only particules with at least 5 neighbors in a 20px radius
				setThreshold(5, 65535);
				run("Analyze Particles...", "size=5.5-Infinity show=Masks");
				rename(imgFITC+"_apoptosis");
				selectWindow(imgFITC+"_apoptosis_ini");
				imageCalculator("OR create", imgFITC+"_apoptosis",imgFITC+"_apoptosis_ini");
				temp = getTitle();
				close(imgFITC+"_apoptosis");
				close(imgFITC+"_apoptosis_ini");
				selectWindow(temp);
				rename(imgFITC+"_apoptosis");
				selectWindow(imgFITC+"_P-NbHood_20");
				run("Duplicate...","title=["+imgFITC+"_P-NbHood_20_bin]");
				setThreshold(5, 65535);
				run("Convert to Mask");
				run("Morphological Reconstruction", "marker=["+imgFITC+"_P-NbHood_20_bin] mask=["+imgFITC+"_apoptosis] type=[By Dilation] connectivity=8");
				rename("apoptosis_tot");
				imageCalculator("XOR create", imgFITC+"_P-NbHood_20","apoptosis_tot");
				temp = getTitle();
				close(imgFITC+"_P-NbHood_20");
				selectWindow(temp);
				rename(imgFITC+"_P-NbHood_20");
				imageCalculator("OR create", imgFITC+"_apoptosis","apoptosis_tot");
				temp = getTitle();
				close(imgFITC+"_apoptosis");
				close("apoptosis_tot");
				selectWindow(temp);
				rename(imgFITC+"_apoptosis");
				img2Keep = Array.concat(img2Keep,newArray(getTitle()));
				run("Analyze Particles...", "summarize");
				if(batchmode == true){setBatchMode("exit and display");}
				selectWindow(imgFITC+"_P-NbHood_20");
				setThreshold(5, 65535);
				//##~~ Keep particules of at least 2 pixels surface
				run("Analyze Particles...", "size=0.0512-Infinity show=[Count Masks]");
				imgFITC_lbl = getTitle();
				imgFITC_lbl = replace(imgFITC_lbl, "Count Masks of ", "");
				imgFITC_lbl = imgFITC_lbl+"_Count_Masks";
				rename(imgFITC_lbl);
				img2Keep = Array.concat(img2Keep,newArray(getTitle()));
				selectImage(imgDAPI+"_binaire");
				run("Connected Components Labeling", "connectivity=8 type=[16 bits]");
				setVoxelSize(pixelWidth, pixelHeight, 1, "µm");
				//##~~ Analyze only particules with are colocalized with a nucleus on the Z-project image
				imageCalculator("AND create", imgDAPI+"_binaire",imgFITC_lbl);
				setThreshold(1, 65535);
				run("Analyze Particles...", "size=0.0-Infinity exclude summarize");
				rename(imgFITC_lbl+"_temp");
				run("Morphological Reconstruction", "marker=["+imgFITC_lbl+"_temp] mask=["+imgFITC_lbl+"] type=[By Dilation] connectivity=4");
				close(imgFITC_lbl);
				rename(imgFITC_lbl);
				setThreshold(1, 65535);
				run("Analyze Particles...", "size=0.0512-Infinity exclude summarize");
				//run("Analyze Particles...", "size=0-Infinity exclude summarize");
				img2Keep = Array.concat(img2Keep,newArray(getTitle()));
	
				//##~~ Add results in "table_analysis" table
				selectWindow("table_analysis");
				print("n ",n+1, " index ", index);
				addInTable_Number("Summary", "Count", "Number_of_Apoptotic_nuclei", n+2, index);
				addInTable_Number("Summary", "Total Area", "Area_of_Apoptotic_nuclei_µm²", n+2, index);
				addInTable_Number("Summary", "Count", "Number_of_Foci_before_neighbor", n+1, index);
				addInTable_Number("Summary", "Count", "Number_of_Foci", n+4, index);		// Number of foci inside nuclei
				Table.set("Nb_Foci_by_µm²", index, Table.get("Number_of_Foci", index)/Table.get("Total_Area_Nuclei_µm²", index));
				addInTable_Number("Summary", "Total Area", "Area_of_Foci_µm²", n+3, index);
				Table.set("Area_Foci_by_µm²", index, Table.get("Area_of_Foci_µm²", index)/Table.get("Total_Area_Nuclei_µm²", index));
				Table.update;
				roiManager("save", dest_img_dir+imgDAPI+"_RoiSet.zip");
				roiManager("Delete");
				if(batchmode == true){setBatchMode("exit and display");}
				run("Set Measurements...", "area mean modal min integrated display redirect=None decimal=3");
				selectWindow(img2Keep[lengthOf(img2Keep)-1]);
				run("Select None");
				run("Analyze Particles...", "size=0.0-Infinity add");
				selectImage(imgFITC+"_output");
				roiManager("Show All without labels");
				roiManager("Measure");
				list_wind = getList("window.titles");
				continuer = 0;
				for(l=0; l<lengthOf(list_wind); l++){
					if("Results" == list_wind[l]){
						continuer = 1;
					}
				}
				if(continuer == 1){
					//waitForUser("Table");
					Table.rename("Results", "Results-FITC");
				}
				run("Select None");
				selectImage(imgDAPI+"_output");
				roiManager("Show All");
				roiManager("Measure");
				run("Select None");
				list_wind = getList("window.titles");
				continuer2 = 0;
				for(l=0; l<lengthOf(list_wind); l++){
					if("Results" == list_wind[l]){
						continuer2 = 1;
					}
				}
				if(continuer2 == 1){
					selectWindow("Results");
					mean_DAPI = Table.getColumn("Mean");
				}
				else{ mean_DAPI = 0;}
				if(continuer == 1){
					selectWindow("Results-FITC");
					Table.setColumn("Mean_DAPI", mean_DAPI);
					for (mn = 0; mn < nResults(); mn++) {
					    v = getResult("Mean", mn);
					    Table.set("Mean_FITC/Mean_DAPI", mn, Table.get("Mean", mn)/v);
					}
					Table.update;
					Table.save(dest_dir+sep+numLame+"_position"+numPos+"_mean_FITC_DAPI.csv");
					Table.reset("Results-FITC");
					Table.update;
					close("Results-FITC");
				}
				saveImg2Keep(img2Keep);
		}	}
		selectWindow("table_analysis");
		Table.save(dest_dir+sep+numLame+".csv");				// Save of 'table_analysis' table
}	}


//~~~~~~~~~~~~~~~~~~~~~~
//~~~~ Main program ~~~~
//~~~~~~~~~~~~~~~~~~~~~~

if(File.exists(source_dir)){				// If the source directory exists
	Table.create("Summary");				// Create the "Summary" table
	Table.update;
	Table.create("table_analysis");			// Create the "table_analysis" table which will contain the results
	Table.update;
	lanceAnalyse(source_dir, index);		// Run the process
	run("Close All");						// Close all images
}