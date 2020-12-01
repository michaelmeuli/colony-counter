// https://github.com/MontpellierRessourcesImagerie/imagej_macros_and_scripts/wiki/MRI_Count_Spot_Populations_Tool


// Petri-dish segmentation parameters
var _REDUCTION_FACTOR = 7;

// DoG parameters
var _CONTRAST_CHOICES = newArray("Normal", "Invert", "Auto");
var _CONTRAST_CHOICE = "Auto";
var _INVERT = true;
var _AUTO_FIND_CONTRAST = true;
var _MIN_DIAMETER = 2;
var _MAX_DIAMETER = 25;
var _USE_FIXED_THRESHOLD_FOR_PETRIDISH = false;
var _THRESHOLD_FOR_PETRIDISH = 1000;

// Spot Segmentation parameters
var _THRESHOLD_METHODS = newArray("Default", "Intermodes");
var _THRESHOLD_METHOD = _THRESHOLD_METHODS[0];
var _MIN_SIZE = PI*(_MIN_DIAMETER/2)*(_MIN_DIAMETER/2);
var _MIN_CIRCULARITY = 0.3;
var _FIT_ELLIPSE = true;

// Clustering parameters 
var _NUMBER_OF_CLUSTERS = 2;	// Do not change the number of clusters in this context.
var _FEATURES = "Area";
var _PARTS = split(_FEATURES, ",");
var _MAIN_FEATURE = _PARTS[0];

// Visualization parameters
var _COLORS = newArray("black", "blue", "cyan", "darkGray", "gray", "green", "lightGray", "magenta", "orange", "pink", "red", "white", "yellow");
var _COLOR_CLUSTER_ONE = "cyan";
var _COLOR_CLUSTER_TWO = "magenta"
var _COLOR_HISTOGRAM = "blue";
var _HIST_BINS = 10;
var _DIST_LINE_WIDTH = 3;


// Parameters in selectPetriZone()
var _PETRI_ZONE_FACTOR = 0;

// Parameters in selectPetridishImageQuant()
var _PETRI_CIRCLE_REDUCTION_FACTOR = 0.98;
var _PETRI_CIRCLE_AREA_FACTOR = 0;

//Hogenkamp
var _FIND_MAXIMA_PROMINENCE = 16000;
var _CONSTANT_BRIGHTNESS_VALUE = 8000;

//sortByFeature()
var _REVERSE = false;

//countAndColorBrightClonesImageQuant()
var _THRESHOLD_BRIGHT_CLONES = 10000;

//Debug:
//dogFilterAction(2, 25);


init();
//Table.create("Colony counts");
//input = getDirectory("Choose the folder with the pictures.");
//output = input;
//processFolder(input);


mainMRI();
//mainImageQuantVolker();
//mainImageQuantHogekamp();


// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	suffix = ".tif";
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
//	print("Processing: " + input + File.separator + file);
	if (isOpen("Results")) run("Clear Results");
	close("*"); // Closes all image windows.
	open("" + input + File.separator + file);
	mainImageQuantVolker();
	waitForUser("Click OK for next image");
//	print("Saving to: " + output);
}



function mainMRI() {
	//define ROI:
	//makeRectangle(2140, 972, 1820, 1660);  // works with example image 1
	//if (_REDUCTION_FACTOR>0) selectInnerZone(_REDUCTION_FACTOR);
	selectPetriZone();
	detectSpotsDoG(_MIN_DIAMETER, _MAX_DIAMETER);
	runEMClusterAnalysis();
	countAndColorClusters();
}

function mainImageQuantVolker() {
	_INVERT = true;
	_AUTO_FIND_CONTRAST = false;
	_MIN_DIAMETER = 10;
	_MAX_DIAMETER = 40;
	_MAIN_FEATURE = "Mean";
	_REVERSE = true;
	_USE_FIXED_THRESHOLD_FOR_PETRIDISH = true;
	_THRESHOLD_FOR_PETRIDISH = 1500;
	_MIN_CIRCULARITY = 0.8;
	_FIT_ELLIPSE = true;
	_PETRI_CIRCLE_REDUCTION_FACTOR = 0.99;
	_THRESHOLD_BRIGHT_CLONES = 15000;
	run("Set Scale...", "distance=0 known=0 unit=pixel");
	selectPetridishImageQuant();
	detectSpotsDoG(_MIN_DIAMETER, _MAX_DIAMETER);
	countAndColorBrightClonesImageQuant();
}

function mainImageQuantHogekamp() {  // "works" with example image ImageQuant.tif
	selectPetridishImageQuant();
	hogekamp();
}
	
function dogFilterAction(minDiameter, maxDiameter) {
	init();
//	if (_AUTO_FIND_CONTRAST) autoSetContrast();
	if (_INVERT) run("Invert");
	sigmaMin = 	floor((minDiameter)/2.5);
	sigmaMax =  ceil((maxDiameter)/2.5);
	run("16-bit");
	if (_INVERT) {
		run("Invert");
		run("Invert LUT");
	}
	DoGFilter(sigmaMin, sigmaMax);
}

function init() {
	run("Select None");
	roiManager("reset");
	if (isOpen("Results")) run("Clear Results");
}

function detectSpotsDoG(minDiameter, maxDiameter) {
	run("Duplicate...", " ");
	imageID = getImageID();
	run("Duplicate...", " ");
	// autoSetContrast() sets _INVERT to false or true
	// dark spots: _INVERT = false;  
	// bright spots: _INVERT = true;
	if (_AUTO_FIND_CONTRAST) autoSetContrast();
	sigmaMin = 	floor((minDiameter)/2.5);
	sigmaMax =  ceil((maxDiameter)/2.5);
	run("16-bit");
	if (_INVERT) {
		run("Invert");
		// ImageQuant images are opened with inverted LUT
		// Either invert LUT here again or do setAutoThreshold("Default"); instead of setAutoThreshold("Default dark");
		run("Invert LUT");
	}
	DoGFilter(sigmaMin, sigmaMax);
	resetThreshold();
	if (_USE_FIXED_THRESHOLD_FOR_PETRIDISH) 
		setThreshold(_THRESHOLD_FOR_PETRIDISH, 65535);  	// setAutoThreshold does not work with complete Petri dish
	else
		setAutoThreshold(_THRESHOLD_METHOD + " dark");   
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Fill Holes");
	run("Analyze Particles...", "size="+_MIN_SIZE+"-Infinity show=Masks in_situ");
	run("Watershed");
	run("Analyze Particles...", "size="+_MIN_SIZE+"-Infinity circularity="+_MIN_CIRCULARITY+"-1.00 show=Nothing exclude add");
	if (_FIT_ELLIPSE) fitEllipses();
	roiManager("Show All");
	close();
	close();
	selectImage(imageID);
	roiManager("measure");
	sortByFeature(_MAIN_FEATURE, _REVERSE);
	roiManager("show all without labels");
}

function fitEllipses() {
	count = roiManager("count");
	for (i = 0; i < count; i++) {
		roiManager("select", i);
		run("Fit Ellipse");
		roiManager("select", i);
		run("Restore Selection");
		roiManager("Update");
	}
}

function autoSetContrast() {
	getStatistics(area, mean);
	mode = getMode();
	if (mean<=mode) {
		// dark spots
		_INVERT = false;
	} else {
	    // bright spots
		_INVERT = true;
	}
}

function DoGFilter(sigmaMin, sigmaMax) {
	imageID = getImageID();
	run("Duplicate...", " ");
	run("Gaussian Blur...", "sigma="+sigmaMin);  // sigmaMin = 0;
	rename("DoGImageSmallSigma");
	selectImage(imageID);
	run("Duplicate...", " ");
	run("Gaussian Blur...", "sigma="+sigmaMax);  // sigmaMax = 10
	rename("DoGImageBigSigma");
	imageCalculator("Subtract create", "DoGImageBigSigma","DoGImageSmallSigma");
	selectImage("DoGImageSmallSigma");
	close();
	selectImage("DoGImageBigSigma");
	close();
	selectWindow("Result of DoGImageBigSigma");
}

function sortByFeature(FEATURE, REVERSE) {
	column = newArray(nResults);
	for (i=0; i<nResults; i++) {
		column[i] = getResult(FEATURE, i);
	}
	positions = Array.rankPositions(column);
	if (REVERSE) Array.reverse(positions);
	ranks = Array.rankPositions(positions);
	// Your code starts after this line
	for (i=0; i<roiManager("count"); i++) {
		/* select the element number i in the roi manager*/
		roiManager("select", i);
		/* Rename the selected roi in the roi manager to its position in the sorted list, that is rename it to IJ.pad(ranks[i], 4) */
		roiManager("Rename", IJ.pad(ranks[i], 4)); 
	}
	/* Deselect all rois in the roi-manager */
	roiManager("Deselect");
	/* Sort the rois in the roi-manager according to their names */
	roiManager("Sort");
	run("Clear Results");
	roiManager("Show None");
	roiManager("Show All");
	/* Measure the rois in the roi manager*/
	roiManager("Measure");
}

function ceil(number) {
	result =  floor(number)+1;
	if ((result - (number) == 1)) result = result - 1;
	return result
}

function getMode() {
	getHistogram(values, counts, 255);
	maxIndex = -1;
	max = -1;
	for(i=0; i<values.length; i++) {
		value = counts[i];
		if (value>max) {
			max = value;
			maxIndex = i;
		}
	}
	mode = values[maxIndex];
	return mode;
}

function selectInnerZone(reductionFactor) {
	w = getWidth();
	h = getHeight();
	minArea = (w*h)/4;
	roiManager("reset");
	run("Duplicate...", " ");
	run("16-bit");
	setAutoThreshold("Default dark");

	run("Analyze Particles...", "size="+minArea+"-Infinity add");
	roiManager("select", 0)
	getSelectionBounds(x, y, width, height);
	
	borderSize = (reductionFactor*width) / 100;
	
	run("Fit Circle");
	incribedRectangle();
	run("Enlarge...", "enlarge=-"+borderSize);
	roiManager("reset");
	roiManager("Add");
	close();
	roiManager("select", 0);
	roiManager("reset");
}

function incribedRectangle() {
	getSelectionBounds(x, y, width, height);
	rWidth = (width) / sqrt(2);
	x = x + (width / 2);
	y = y + (width / 2);
	x = x - (rWidth / 2);
	y = y - (rWidth / 2);
	makeRectangle(x, y, rWidth, rWidth);
}

function runEMClusterAnalysis() {
	macrosDir = getDirectory("macros");
	script = File.openAsString(macrosDir + "/toolsets/results_table-clusterer.py");
	parameter = "numberOfClusters="+_NUMBER_OF_CLUSTERS+", features="+_FEATURES;
	call("ij.plugin.Macro_Runner.runPython", script, parameter); 
}

function countAndColorClusters() {
	selectWindow("clusters");
	threshold = Table.get("intersection", 0);
	classOneCounter = 0;
	classTwoCounter = 0;
	for (i = 0; i < nResults; i++) {
		area = getResult(_MAIN_FEATURE, i);
		if (area<threshold) classOneCounter++;
		else classTwoCounter++;
	}
	Table.set("count", 0, classOneCounter);
	Table.set("count", 1, classTwoCounter);
	Table.update();
	indices = newArray(classOneCounter);
	for (i = 0; i < classOneCounter; i++) {
		indices[i]=i; 
	}
	count = roiManager("count");
	if (count>0) {
		roiManager("Select", indices);
		roiManager("Set Color", _COLOR_CLUSTER_ONE);
	    roiManager("Set Line Width", 0);
	    indices = newArray(classTwoCounter);
		for (i = 0; i < classTwoCounter; i++) {
			indices[i]=classOneCounter + i; 
		}
		roiManager("Select", indices);
		roiManager("Set Color", _COLOR_CLUSTER_TWO);
	    roiManager("Set Line Width", 0);
	}
    if (nImages > 0) run("Select None");
}

function selectPetriZone() {
	imageID = getImageID();
	run("Duplicate...", "title=showPetridish.JPG");
	selectImage(imageID);
	roiManager("reset");
	selectInnerZone(2);
	roiManager("Add");
	getSelectionBounds(x, y, width, height);
	rWidth = (width) / sqrt(2);
	petriA = PI * (rWidth * rWidth);
	makeOval(x+(width/2)-rWidth, y+(width/2)-rWidth, 2 * rWidth, 2 * rWidth);
	roiManager("Add");
	roiManager("select", 0);
	borderSize = (5*width) / 100;
	run("Enlarge...", "enlarge=-"+borderSize);
	getSelectionBounds(x, y, width, height);
	roiManager("Add");
	roiManager("Show None");
	roiManager("select", 2);
	area = width * height;
	_PETRI_ZONE_FACTOR = (petriA/area);
	print("_PETRI_ZONE_FACTOR: "+_PETRI_ZONE_FACTOR);
	selectWindow("showPetridish.JPG");
	roiManager("Show None");
	roiManager("select", 1);
	roiManager("reset");
	selectImage(imageID);
}

function selectPetridishImageQuant() {
	w = getWidth();
	h = getHeight();
	minArea = (w*h)/10;
	roiManager("reset");
	run("Duplicate...", " ");
	run("16-bit");
	setAutoThreshold("Default");
	run("Analyze Particles...", "size="+minArea+"-Infinity pixel add");
	roiManager("select", 0)
	getSelectionBounds(x, y, width, height);
	borderSize = (2*width) / 100;
	run("Fit Circle");
	run("Enlarge...", "enlarge=-"+borderSize);
	roiManager("reset");
	roiManager("Add");
	getSelectionBounds(x, y, width, height);
	r1 = width / 2;
	petriA = PI * (r1* r1);
	r2 = _PETRI_CIRCLE_REDUCTION_FACTOR * r1;
	shift = r1-r2;
	makeOval(x + shift, y + shift, 2*r2, 2*r2);
	roiManager("Add");
	petriB = PI * (r2 * r2);
	_PETRI_CIRCLE_AREA_FACTOR = (petriA/petriB);
	print("_PETRI_CIRCLE_AREA_FACTOR: "+_PETRI_CIRCLE_AREA_FACTOR);
	close();
//	imageID = getImageID();
//	run("Duplicate...", " ");
//	roiManager("select", 0);
//	selectImage(imageID);
	roiManager("select", 1);
	roiManager("reset");
}

function hogekamp() {
	run("Duplicate...", " ");
	run("16-bit");
	run("Subtract Background...", "rolling=40 light");
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	run("Median...", "radius=6");
	setMinAndMax(_CONSTANT_BRIGHTNESS_VALUE, 65535);
	run("Find Maxima...", "prominence="+_FIND_MAXIMA_PROMINENCE+" light output=[Point Selection]");
}

function countAndColorBrightClonesImageQuant() {
	bright = 0;
	printImage = false;
	for (i = 0; i < nResults; i++) {
		mean = getResult("Mean", i);
		if (mean > _THRESHOLD_BRIGHT_CLONES) {	
			bright++;
			printImage = true;
			roiManager("Select", i);
			roiManager("Set Color", _COLOR_CLUSTER_TWO);
	    	roiManager("Set Line Width", 2);
	    	run("Add Selection...");
		}
		else {
			roiManager("Select", i);
			roiManager("Set Color", _COLOR_CLUSTER_ONE);
	    	roiManager("Set Line Width", 2);
	    	run("Add Selection...");
		}
	}
//	Table.create("Colony counts");
 	selectWindow("Colony counts");
 	currentTableSize = Table.size;
	Table.set("File", currentTableSize, getTitle);
	Table.set("Total", currentTableSize, nResults);
	Table.set("Positive", currentTableSize, bright);
	Table.setLocationAndSize(1000, 100, 800, 1000);
	Table.update;
	addFilenameOverlay();
	run("Hide Overlay");
	run("Show Overlay");
	setMinAndMax(0, 40000);
	selectWindow("Colony counts");
//	close("\\Others"); // Closes all images except for the front image.
	if (printImage)  run("Print...");
//	close("*"); // Closes all image windows.
}

function addFilenameOverlay() {
    fontSize = 24;
    x = 10;
    y = fontSize;
    setColor("black");
    setFont("SansSerif", fontSize);
    name = getInfo("image.filename");
//  Overlay.remove;
    Overlay.drawString(name, x, y);
    Overlay.show;
}
	