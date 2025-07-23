function NeighborAnalysis(hoodRadius, calibrationbar, createPlot) {
	
	original=getTitle();

	type=is("binary");
	if(type==false) { exit("works only with 8-bit binary images"); }
	getDimensions(width, height, channels, slices, frames);
	run("Options...", "iterations=1 count=1 black edm=Overwrite do=Nothing");
	if(isOpen("Log")==1) { selectWindow("Log"); run("Close"); }
	
	color="white";
	method="Particle Neighborhood";
	//hoodRadius=5;
	watershed=false;
	size="0-Infinity";
	circularity="0.00-1.00";
	dontVisualizeEdges=false;
	excludeEdges=false;
	excludeInclusionParticles=false;
	//calibrationbar=true;
	//createPlot=true;


	selectWindow(original);
	run("Select None");
	if(color=="black") {
		run("Invert");
	}
	if(excludeEdges==true) {
		edges="exclude";
	} else {
		edges="";	
	} 
	//prepare original image for analysis
	run("Analyze Particles...", "size="+size+" circularity="+circularity+" show=Masks "+edges+" clear");
	run("Invert LUT");
	rename(original+"-1");
	original=getTitle();
	
	//*******************************************************************
	setBatchMode(true);
	
	if(method=="Voronoi") {
		run("Duplicate...", "title=[V-Map_"+original+"]");
		voronoi=getTitle();
	} else if(method=="UEP Voronoi") {
		run("Duplicate...", "title=[UEP-V-Map_"+original+"]");
		voronoi=getTitle();
	} else if(method=="Centroid Neighborhood" || method=="Particle Neighborhood") {
		run("Duplicate...", "title=[NbHood_"+original+"]");
		neighborhood=getTitle();
	}
	
	//initial particle watershed if activated
	if(watershed==true) {
		run("Watershed");
	}
	
	//if method==Voronoi
	if(method=="Voronoi") {
		//Analyze voronoi particle number
		selectWindow(voronoi);
		run("Set Measurements...", "  centroid redirect=None decimal=3");
		run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing clear record");
		//define variables
		initialParticles=nResults;
		X=newArray(nResults);
		Y=newArray(nResults);
		neighborArray=newArray(nResults);
		neighbors=0;
		mostNeighbors=0;
		//run voronoi
		run("Voronoi");
		setThreshold(1, 255);
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Invert");
		//retveive particle coordinates
		for(l=0; l<initialParticles; l++) {
			X[l]=getResult("XStart", l);
			Y[l]=getResult("YStart", l);
		}
	
		//set measurements
		run("Set Measurements...", " redirect=None decimal=3");
		
		//analyze neighbors
		selectWindow(voronoi);	
		for(i=0; i<initialParticles; i++) {
			doWand(X[i],Y[i], 0, "8-connected");
			run("Enlarge...", "enlarge=2 pixel");
			run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing clear record");
			neighbors = nResults-1;
			neighborArray[i]=neighbors;
			if(neighbors>mostNeighbors) {
				mostNeighbors=neighbors;
			}
		}
	}
	
	if(method=="UEP Voronoi") {
		//create ultimate points
		selectWindow(voronoi);
		run("Ultimate Points");
		setThreshold(1, 255);
		setOption("BlackBackground", true);
		run("Convert to Mask");
		//analyze UEP number
		run("Set Measurements...", "  centroid redirect=None decimal=3");
		run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing clear record");
		//define variables
		initialParticles=nResults;
		X=newArray(nResults);
		Y=newArray(nResults);
		neighborArray=newArray(nResults);
		neighbors=0;
		mostNeighbors=0;
		//run voronoi
		run("Voronoi");
		setThreshold(1, 255);
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Invert");
		//retveive particle coordinates
		for(l=0; l<initialParticles; l++) {
			X[l]=getResult("XStart", l);
			Y[l]=getResult("YStart", l);
		}
	
		//set measurements
		run("Set Measurements...", "  redirect=None decimal=3");
		
		//analyze neighbors
		selectWindow(voronoi);	
		for(i=0; i<initialParticles; i++) {
			doWand(X[i],Y[i], 0, "8-connected");
			run("Enlarge...", "enlarge=2 pixel");
			run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing clear record");
			neighbors = nResults-1;
			neighborArray[i]=neighbors;
			if(neighbors>mostNeighbors) {
				mostNeighbors=neighbors;
			}
		}
	}
	
	//if method==centroid neighborhood
	if(method=="Centroid Neighborhood") {
		selectWindow(neighborhood);
		run("Set Measurements...", "  centroid redirect=None decimal=3");
		run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing display clear record");
		//define variables
		initialParticles=nResults;
		X=newArray(nResults);
		Y=newArray(nResults);
		centroidX=newArray(nResults);
		centroidY=newArray(nResults);

		neighborArray=newArray(nResults);
		neighbors=0;
		mostNeighbors=0;
		//retveive particle coordinates
		for(l=0; l<initialParticles; l++) {
			X[l]=getResult("XStart", l);
			Y[l]=getResult("YStart", l);
			centroidX[l]=getResult("X", l);
			centroidY[l]=getResult("Y", l);

			toUnscaled(X[l], Y[l]);
			toUnscaled(centroidX[l], centroidY[l]);
		}
		//prepare selector image
		setForegroundColor(255, 255, 255);
		setBackgroundColor(0, 0, 0);
		run("Set Measurements...", " centroid redirect=None decimal=3");
		//run("Wand Tool...", "mode=8-connected tolerance=0");
		run("Options...", "iterations=1 count=1 black edm=Overwrite do=Nothing");
			
		for(hood=0; hood<initialParticles; hood++) {
			//create selector neighborhood
			selectWindow(neighborhood);
			run("Select None");
			run("Duplicate...", "title=[Selector_"+original+"]");
			selector=getTitle();
			fillOval(centroidX[hood]-hoodRadius, centroidY[hood]-hoodRadius, (hoodRadius*2), (hoodRadius*2));
			run("Select None");
			doWand(X[hood], Y[hood], 0, "8-connected");
			selectWindow(neighborhood);
			run("Restore Selection");
			run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing clear record");
			neighbors = nResults-1;
			neighborArray[hood]=neighbors;
			if(neighbors>mostNeighbors) {
				mostNeighbors=neighbors;
			}
			
			close(selector);
		}
		
	}
	
	
	//if method==particle neighborhood
	if(method=="Particle Neighborhood") {
		selectWindow(neighborhood);
		run("Set Measurements...", "  centroid redirect=None decimal=3");
		run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing clear record");
		//define variables
		initialParticles=nResults;
		X=newArray(nResults);
		Y=newArray(nResults);
		neighborArray=newArray(nResults);
		neighbors=0;
		mostNeighbors=0;
		//retreive particle coordinates
		for(l=0; l<initialParticles; l++) {
			X[l]=getResult("XStart", l);
			Y[l]=getResult("YStart", l);
		}
		//prepare selector image
		setForegroundColor(255, 255, 255);
		setBackgroundColor(0, 0, 0);
		run("Set Measurements...", " centroid redirect=None decimal=3");
		run("Wand Tool...", "mode=8-connected tolerance=0");
		run("Options...", "iterations=1 count=1 black edm=Overwrite do=Nothing");
			
		if (excludeInclusionParticles) {	
			selectWindow(neighborhood);
			run("Select None");
			run("Duplicate...", "title=[FilledHoles_"+original+"]");
			filesHoles = getTitle();
			run("Fill Holes");
		}

		
		for(hood=0; hood<initialParticles; hood++) {
			
			//if(hood%(parseInt(""+initialParticles/100)) == 0){
			//	prog = hood/(parseInt(""+initialParticles/100));
			//	print(title_prog,"\\Update:"+prog+"/"+100+" ("+(prog*100)/100+"%)\n"+getBar(prog, 100));
			//}
			showStatus("Analyse du voisinage");
			showProgress(hood, initialParticles);


			//create selector neighborhood
			selectWindow(neighborhood);
			run("Select None");
			run("Duplicate...", "title=[Selector_"+original+"]");
			selector=getTitle();
			doWand(X[hood], Y[hood], 0, "8-connected");
			//print(hood + "(" + X[hood]+"/"+ Y[hood] + ")");
			run("Enlarge...", "enlarge="+hoodRadius + " pixel");
			run("Fill");
			run("Select None");
			doWand(X[hood], Y[hood], 0, "8-connected");

			if (excludeInclusionParticles) {
				selectWindow(filesHoles);
			} else {
				selectWindow(neighborhood);
			}
			
			run("Restore Selection");
			run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing clear record");
			neighbors = nResults-1;
			neighborArray[hood]=neighbors;
			if(neighbors>mostNeighbors) {
				mostNeighbors=neighbors;
			}
			close(selector);
		}
		
	}

	if(mostNeighbors==0) {
		exit("no neighbors detected\ndid you choose the correct particle color?");
	}
	//*******************************************************************
	
	
	//Color coded original features
	

	selectWindow(original);
	if(method=="Voronoi") {
		run("Duplicate...", "title=[Voronoi_"+original+"]");
	} else if(method=="UEP Voronoi") {
		run("Duplicate...", "title=[UEP-V_"+original+"]");
	} else if(method=="Centroid Neighborhood") {
		run("Duplicate...", "title=[C-NbHood_"+hoodRadius+"_"+original+"]");
	} else if(method=="Particle Neighborhood") {
		run("Duplicate...", "title=[P-NbHood_"+hoodRadius+"_"+original+"]");
	}
	particles=getTitle();
	if(watershed==true) {
		run("Watershed");
	}
	selectWindow(particles);
	
	for(mark=0; mark<initialParticles; mark++) {
		showStatus("Labellisation");
		showProgress(mark, initialParticles);
		
		markValue=neighborArray[mark];
		if(markValue==0) {
			doWand(X[mark],Y[mark], 0, "8-connected");
			Roi.setStrokeColor(0);
			run("Add Selection...");
			run("Select None");
		}
		setForegroundColor(markValue, markValue, markValue);
		floodFill(X[mark],Y[mark], "8-connected");
		
	}
	
	run("Select None");		
	run("glasbey");
	setBatchMode("show");
		
	//visually eliminate edge particles (but count them as neighbors)
	if(dontVisualizeEdges) {
		selectWindow(original);
		run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing exclude clear record");
		visibleParticleNumber = nResults;
	}
	

	//create distribution plot
	if(createPlot==true) {
		if(dontVisualizeEdges) {
			selectWindow(original);
			run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 pixel show=Masks exclude clear record add");
			roiManager("Show None");
			masksWithoutEdgeParticles = getTitle();
			run("Select All");
			run("Copy");
			selectWindow(particles);
			setPasteMode("Transparent-white");
			run("Paste");
			setPasteMode("Copy");
			colorIndex = 0;
			neighborList = newArray(mostNeighbors+1);
			for(roi=0; roi<roiManager("Count"); roi++) {
				selectWindow(particles);
				roiManager("Select", roi);
				getStatistics(areaNotNeeded, colorIndex);
				neighborList[colorIndex] = neighborList[colorIndex] + 1;
			}
			particleCount = roiManager("Count");
		} else {
			neighborList = newArray(mostNeighbors+1);
			Array.fill(neighborList, 0);
			for(num=0; num<initialParticles; num++) {
				nextNeighbor = neighborArray[num];
				if(nextNeighbor>0) {
					neighborList[nextNeighbor] += 1;
				} else {
					neighborList[0] += 1;
				}
			}
			particleCount = initialParticles;
		}
		
		
		Plot.create("Distribution: " + particles, "neighbors", "count", neighborList);
		Plot.addText("particles (total) = " + particleCount, 0.01, 0.1);
		setBatchMode("show");
	}
	
	close(original);
	
	//Calibration Bar
	if(calibrationbar==true) {
		stepsize=floor(256/mostNeighbors);
		newImage("Calibration_"+original, "8-bit Black", (stepsize*mostNeighbors+stepsize), 30, 1);
		w=getWidth();
		step=0;
		for(c=0; c<=mostNeighbors+1; c++) {
			makeRectangle(step, 0, step+stepsize, 30);
			setForegroundColor(c, c, c);
			run("Fill");
			step=step+stepsize;
		}
		run("Select None");
		run("glasbey");
		run("RGB Color");
		setForegroundColor(255, 255, 255);
		setBackgroundColor(0, 0, 0);
		run("Canvas Size...", "width="+w+" height=50 position=Top-Center");
		if(mostNeighbors>9) { 
			offset=15;
		} else {
			offset=10;
		}
		drawString("0", 2, 48);
		drawString(mostNeighbors, w-offset, 48);
	}
	setBatchMode(false);
	
	// print(title_prog, "\\Close");
	
	exit();

}

function getBar(p1, p2){
	n = 20;
	bar1 = "--------------------";
	bar2 = "********************";
	index = round(n*(p1/p2));
	if (index<1) index = 1;
	if (index>n-1) index = n-1;
	return substring(bar2, 0, index) + substring(bar1, index+1,n);
}

voisinage = 0;
arg = getArgument();
arg = split(arg, " ");
voisinage = parseInt(arg[0]);
if (voisinage == 0){voisinage = 20;}
NeighborAnalysis(voisinage, arg[1], arg[2]);