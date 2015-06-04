//Close all active windows before starting
close("*");

// Set batch mode true to prevent user from messing with the images while processing
setBatchMode(true);

//Ask user to choose the input and output directories
directory = getDirectory("Choose input directory");
fileList = getFileList(directory);
outputDirectory = getDirectory("Choose output directory");

//Select images one by one 
for (a=0; a<fileList.length; a++) {

	//Show/update progress to user in a bar 
	progress = a/fileList.length;
	showProgress(progress);
	

//----------------------Open file and align stack------------------------------------------------------	
	//Look for the image in the input file 
	file = directory + fileList[a];
	
	//Open files in directory one at a time to be analyzed
	open(file);

	// Align images through Stackreg
	//NOTE: Samples may have shifted during imaging, so align via rotation (e.g. Rigid Body) as well
	showStatus("Please wait for stack alignment of image " + fileList[a]);
	run("StackReg", "transformation=[Rigid Body]");


//-----------------------------Crop stack to remove black (0 intensity) pixels from aligned stack----------------------
	
	//Count images
	x = nImages;
	
	//NOTE: 0 intensity pixels generated from the alignment tool need to be cropped so that they don't interfere with the EDF 
	//Make minimum intensity projection 
	run("Z Project...", "projection=[Min Intensity]");

	// Wait until the MIN window is available 
	//Commands computer to wait until there is Output inage
	while(x == nImages) {
         wait(1000);
    }
        
	//Select MIN window 
	selectWindow("MIN_" + fileList[a]);

	//Adjust contrast to make image binary 
	//NOTE: Set min and max displayed pixel values 
	setMinAndMax(0,1);
	run("Apply LUT");

	//Select bounding box for computer to automatically select cropping window for the image 
	run("Select Bounding Box (guess background color)");

	////Double check whether the crop is successful or not 
	getStatistics(voxelCount, mean, min, max, stdDev);
	
	// Shrinking the selection bound to the center until min is no longer 0 intensity 
	while( min==0) {

		//Locate the selection bound for shrinking
		getSelectionBounds(x, y, width, height);

		//Reduce selection bounds by 1 pixel at a time on all sides 
		//NOTE: Width and Height must subtract 2 from them because when you move one side in 1 pixel in (x,y), you have to subtract
		//2 from the width and height to make up for the difference 
		makeRectangle((x+1),(y+1), (width-2),(height-2));
		
		//Double check whether the crop is successful or not 
		getStatistics(voxelCount, mean, min, max, stdDev);
	}

	
	//Select original stack window 
	selectWindow(fileList[a]); 
	
	//Apply cropping window to the stack image 
	run("Restore Selection");

	//Crop the image 
	run("Crop");

	
	//Count images
	x = nImages;

	//Set batch mode false to prevent EDF from crashing
	setBatchMode(false);
	//Run EDF for the images 
	run("Extended Depth of Field (Easy mode)...", "quality='4' topology='0' show-topology='off' show-view='off'");

	//Initialize EDF counter for status bar update to user
	EDF_Timer = 0;

	//Set output check so that the computer will recognize the current window
	outputCheck = getTitle();
	
	//Commands computer to wait until there is Output image
	while(outputCheck != "Output") {

			//Rechecking which current image is opened
			outputCheck = getTitle();
		
		//Inform user of the time/progress of EDF
		 showStatus("Please wait for EDF: " + EDF_Timer + " seconds elapsed");
         wait(1000);
         EDF_Timer = EDF_Timer +1; 
    }
        
	//Create output file name that incorprorates EDF  
	//Remove file extension
	dotIndex = indexOf(fileList[a], ".");
	title = substring(fileList[a], 0, dotIndex); 
	Outputfile = outputDirectory + title + " - EDF";

	//Select output window from EDF
	selectWindow("Output");
	
	//Save output image
	saveAs("tiff", Outputfile);

	//Close all images 
	//NOTE: * means wildcard which closes anything on the desktop
	close("*");
	setBatchMode(true);
}
//Turns batch mode off 
setBatchMode(false);
