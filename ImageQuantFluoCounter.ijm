
//selectPetridishBackgroundWhiteImageQuant()
var _PETRI_CIRCLE_REDUCTION_FACTOR = 1;
var _PETRI_CIRCLE_AREA_FACTOR = 0;

//hogekamp()
var _FIND_MAXIMA_PROMINENCE = 30000;
var _CONSTANT_BRIGHTNESS_VALUE = 5000;



init();
mainImageQuantHogekamp();

function mainImageQuantHogekamp() {  // "works" with example image ImageQuant.tif
	selectPetridishBackgroundWhiteImageQuant();
	hogekamp();
}
	
function dogFilterAction() {
	init();
	if (_AUTO_FIND_CONTRAST) autoSetContrast();
	sigmaMin = 	(_MIN_DIAMETER/2)/2.5;
	sigmaMax =  (_MAX_DIAMETER/2)/2.5;
	run("16-bit");
	if (_INVERT) run("Invert");
	DoGFilter(sigmaMin, sigmaMax);
}

function init() {
	run("Select None");
	roiManager("reset");
	run("Clear Results");
	run("Set Scale...", "distance=0 known=0 unit=pixel");
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
	makeOval(x + shift, y + shift, 2*r2, 2*r2)
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
}