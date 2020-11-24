
//selectPetridishBackgroundWhiteImageQuant()
var _PETRI_CIRCLE_REDUCTION_FACTOR = 1;
var _PETRI_CIRCLE_AREA_FACTOR = 0;

//hogekamp()
var _FIND_MAXIMA_PROMINENCE = 30000;
var _CONSTANT_BRIGHTNESS_VALUE = 5000;

	
init();
input = getDirectory("Choose the folder with the pictures.");
output = input;
processFolder(input);
cleanUp();


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
	open("" + input + File.separator + file);
	mainImageQuantHogekamp();
//	print("Saving to: " + output);
}

function mainImageQuantHogekamp() {  // "works" with example image ImageQuant.tif
	run("Set Scale...", "distance=0 known=0 unit=pixel");
	selectPetridishBackgroundWhiteImageQuant();
	hogekamp();
}
	

function init() {
	run("Select None");
	roiManager("reset");
	run("Clear Results");
}

function selectPetridishBackgroundWhiteImageQuant() {
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
//	waitForUser("adjust ROI if needed");
	run("Duplicate...", " ");
	run("16-bit");
//	run("Subtract Background...", "rolling=40 light");
//	run("Enhance Contrast", "saturated=0.35");
//	run("Apply LUT");
	run("Median...", "radius=6");
	setMinAndMax(_CONSTANT_BRIGHTNESS_VALUE, 65535);
//	run("Find Maxima...", "prominence="+_FIND_MAXIMA_PROMINENCE+" light output=Count");
	run("Find Maxima...", "prominence="+_FIND_MAXIMA_PROMINENCE+" light output=[Point Selection]");
	run("Measure");
	print("nResults: "+nResults);
	 if (nResults>0) {
//		selectWindow("Log");
		selectWindow("Results");
      	waitForUser("found possible SCO");
   }
//	run("Clear Results");
}



// Closes the "Results" and "Log" windows and all image windows
function cleanUp() {
    requires("1.30e");
    if (isOpen("Results")) {
         selectWindow("Results"); 
         run("Close" );
    {
    if (isOpen("Log")) {
         selectWindow("Log");
         run("Close" );
    }
    while (nImages()>0) {
          selectImage(nImages());  
          run("Close");
    }
}