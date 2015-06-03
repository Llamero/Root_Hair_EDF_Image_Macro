//Ask user to choose the input and output directories
directory = getDirectory("Choose input directory");
fileList = getFileList(directory);
outputDirectory = getDirectory("Choose output directory");

//Select images one by one 
for (a=0; a<fileList.length; a++) {
	//Look for the image in the input file 
	file = directory + fileList[a];
	
	//Open files in directory one at a time to be analyzed
	open(file);

	// Align images through Stackreg
	//NOTE: Samples may have shifted during imaging, so align via rotation (e.g. Rigid Body) as well
	run("StackReg", "transformation=[Rigid Body]");
	
	//Count images
	x = nImages;
	
	//Run EDF for the images 
	run("Extended Depth of Field (Easy mode)...", "quality='4' topology='0' show-topology='off' show-view='off'");
	
	//Commands computer to wait until there is Output inage
	while(x == nImages) {
         wait(1000);
    }
        
	//Create output file name that incorprorates EDF  
	Outputfile = outputDirectory + fileList[a] + " - EDF";
	
	//Select output window from EDF
	selectWindow("Output");
	
	//Save output image
	saveAs("tiff", Outputfile);

	//Close all images 
	//NOTE: * means wildcard which closes anything on the desktop
	close("*");
}
