//Close all active windows before starting
close("*");

//Set  directory and input 
directory = getDirectory("Choose input directory");
outputDirectory = getDirectory("Choose output directory");


//Remove scale bar reference image
//NOTE: This step is only necessary during debugging and for macro force quit
delTest = File.delete(directory + "Scale bar text reference.tif");

fileList = getFileList(directory);

//Clear results table for actual measurements
run("Clear Results"); 

//+++++++++++++++++++++++++++++++++++++++Sort data into 3 corresponding arrays and check that all data is accounted for++++++++++++++++++++++

//Initialize index counters for the 3 image subarrays
Side1Index = 0;
Side2Index = 0;
TopIndex = 0;
fileCounter = 0;

//Set Side 1 subarray for the images
for (a=0; a<fileList.length; a++) {
	if(startsWith(fileList[a], "Side1")) {
		setResult("Side1", Side1Index, fileList[a]);
		Side1Index++;
		fileCounter++;
		
//Set side 2 subarray for the images
//NOTE: start search after current Side 1

		//Replacing Side 1 filename with Side 2 file name 
		Side2Name = replace(fileList[a], "Side1_", "Side2_");
		Side2Name = replace(Side2Name, "_001.tif", "_002.tif");

		//Searching file list for corresponding side 2 filename
		for (b=a; b<fileList.length; b++) {
			if(Side2Name == fileList[b]) {
				setResult("Side2", Side2Index, Side2Name);
				Side2Index++;
				fileCounter++;

				//Once the desired image is found, stop looking until the end of fileList 
				b = fileList.length+3;
			}

			//Set the "empty" subarray if no corresponding Side 2 is found
			if (b == fileList.length-1) {
				setResult("Side2", Side2Index, "Empty");
				Side2Index++;
			}
		}
//Set top subarray for the images 

		//Replacing Side 1 filename with Side 2 file name 
		TopName = replace(fileList[a], "Side1_", "Top_");
		TopName = replace(TopName, "_001.tif", "_003.tif");

		//Searching file list for corresponding side 2 filename
		for (c=a; c<fileList.length; c++) {
			if(TopName == fileList[c]) {
				setResult("Top", TopIndex, TopName);
				TopIndex++;
				fileCounter++;

				//Once the desired image is found, stop looking until the end of fileList 
				c = fileList.length+3;
			}

			//Set the "empty" subarray if no corresponding Side 2 is found
			if (c == fileList.length-1) {
				setResult("Top", TopIndex, "Empty");
				TopIndex++;
			}
		}

	}
	
}
updateResults();

//Convert results column into separate arrays
//Initialize arrays
Side1Array = newArray(nResults);
Side2Array = newArray(nResults);
TopArray = newArray(nResults);

//Assemble arrays
for (d=0; d<nResults; d++) {
	 Side1Array[d] = getResultString("Side1", d);
	 Side2Array[d] = getResultString("Side2", d);
	 TopArray[d] = getResultString("Top", d);
}

//Clear results table for actual measurements
run("Clear Results"); 

//Combine arrays to allow for comparison against master file list
combinedArray = Array.concat(Side1Array,Side2Array);
combinedArray = Array.concat(combinedArray,TopArray);

//Look for files in the master list that do not exist in the arrays and report to user
for (e=0; e<fileList.length; e++) {
	for (f=0; f<combinedArray.length; f++) {
		if (fileList[e] == combinedArray[f]) {
			f = combinedArray.length + 3;
		}
		if (f == combinedArray.length-1) {
			setResult("Missing Files", nResults, fileList[e]);
		}
	}
}

//If there are unaccounted for files, exit so user can remedy problem.
if (nResults != 0) {
	exit("There are files in the directory that are not in the arrays.  See results window.");
}

// Set batch mode false to allow for user interaction
setBatchMode(false);

//++++++++++++++++++++++++++++++++++++++++++Open side files one at a time+++++++++++++++++++++++++++++++++++++++++++++++++++++	
//Select images one by one 
for (a=0; a<Side1Array.length; a++) {
	//Repeat twice, once for each side
	for (sideLoop = 0; sideLoop < 2; sideLoop++){

		//Based on sideLoop counter open either Side1 image or Side2 image for analysis
		if(sideLoop == 0){
			file = directory + Side1Array[a];
		}
		else {
			file = directory + Side2Array[a];
		}

		//If the data in the array is an image, open and analyze
		if(!endsWith(file, "Empty")) {
			//Open files in directory one at a time to be analyzed
			open(file);
		
			//Get name of opened image
			title = getTitle();
				
			//Split Channels
			run("Split Channels");
					
			//Close Green window after Split Channel
			close ("*(green)");
		
		//++++++++++++++++++++Scale images automatically according to scale bar in blue channel+++++++++++++++++++++++++++++++++++++
		
			
		
			//Select blue window to scale image
			blueChannel = title + " (blue)"; 
			selectWindow(blueChannel);
			
			//Set threshold for the blue window to get scale bar 
			setThreshold(254, 255);
			
			//Create scale bar selection and crop it to get scale bar 
			run("Create Selection");
			run("Crop");
			
			//Measure scale bar for image 
			getDimensions(width, height, channels, slices, frames);
			scaleBarWidth = width;
			
			//Ask user to enter in the number and unit for scale bar
			//NOTE: Assume the number will stay the same  
			//Initialize scaleApproved to zero so user can confirm and retry entering scale bar information
			scaleApproved = 0;
			
			while (a == 0 && scaleApproved == 0 && sideLoop == 0) {
				
				//Enter in the number and unit on scale bar 
				scaleBarLength= getNumber("Please enter number on scale bar.", 1);
				scaleBarUnit= getString ("Plese enter unit on scale bar.", "um");
		
				//Get user's approval on the value 
				scaleApproved = getBoolean("The scale bar value is: " + scaleBarLength + " " + scaleBarUnit + ". Do you wish to keep this?");
		
				
				//Check to see if the text has the same area (i.e. same number) as before
				//Select just the text and crop scale bar from image
				makeRectangle(0, 0, scaleBarWidth, 12);
				run("Crop");
			
				//Set threshhold and create selection of just the remaining text and crop to just the text
				setThreshold(254, 255);
				run("Create Selection");
				run("Crop");
				
				//Save the approved value for the other images 
				saveAs("tiff", directory + "Scale bar text reference");
		
				//close scale bar windows
				close("Scale bar text reference.tif");
			}
		
			//After the first round, check to make sure the scale bar text is the same in every subsequent image
			if (a>0) {
				//Check to see if the text has the same area (i.e. same number) as before
				//Select just the text and crop scale bar from image
				makeRectangle(0, 0, scaleBarWidth, 12);
				run("Crop");
			
				//Set threshhold and create selection of just the remaining text
				setThreshold(254, 255);
				run("Create Selection");
				run("Crop");
			
				//See if scale bar text matches original saved text
				open (directory + "Scale bar text reference.tif");
				imageCalculator("Difference create", "Scale bar text reference.tif", blueChannel);
				selectWindow("Result of Scale bar text reference.tif");
			
				//Make sure there are no differences between the two images (i.e. max is 0 as any diff would be >0)
				getStatistics(area, mean, min, max);
		
				//Select scale text window so that user can read it
				selectWindow(blueChannel);
		
				//Initialize current scale bar to default to yes
				currentScaleBar = 1;
			
				if (max != 0) {
					currentScaleBar= getBoolean("The current stored scale bar value is: " + scaleBarLength + " " + scaleBarUnit + ". Is this correct?");
			
					//If "No" is chosen, require user to enter a new value
					if (currentScaleBar == 0) {
						//Ask user to enter in the number and unit for scale bar
						//Initialize scaleApproved to zero so user can confirm and retry entering scale bar information
						scaleApproved = 0;
						
						while (scaleApproved == 0) {
							
							//Enter in the number and unit on scale bar 
							scaleBarLength= getNumber("Please enter number on scale bar.", 1);
							scaleBarUnit= getString ("Plese enter unit on scale bar.", "um");
					
							//Get user's approval on the value 
							scaleApproved = getBoolean("The scale bar value is: " + scaleBarLength + " " + scaleBarUnit + ". Do you wish to keep this?");
					
						}
					}
					
					//save new reference image 
					selectWindow(blueChannel);
			
					//Save the approved new text for the other images 
					saveAs("tiff", directory + "Scale bar text reference");	
					close();
				}
			}
		
			
			//Calculate what the pixel dimensions are
			pixelWidth= scaleBarLength/scaleBarWidth;
			
			//Close all but the red window 
			close("*(blue)");
			close("Result of Scale bar text reference.tif");
			close("Scale bar text reference.tif");
		
			//Select red window to scale image
			redChannel = title + " (red)"; 
			selectWindow(redChannel);
		
			//scale red channel image according to scale bar
			run("Properties...", "channels=1 slices=1 frames=1 unit=" + scaleBarUnit + "  pixel_width=" + pixelWidth + " pixel_height=" + pixelWidth + " voxel_depth=1");
		
			//Convert image to color image so user can draw colored lines
			run("RGB Color");
		
			//Ask user to set line color
			if (a==0 && sideLoop == 0) {
				//Stop macro until user is finished with choosing color
				run("Color Picker...");
				waitForUser("Select line color", "Please select the line color you want.  Click OK when finished.");
			
				//Ask user to set line width
				lineWidth = getNumber("Please enter desired line width", 5);
				run("Line Width...", "line=" + lineWidth);
				
			}
		//+++++++++++++++++++++++++++++++User interface for measuring of lobes++++++++++++++++++++++++++++++++++++++++++++++++
		
			//Ask user to rate the quality of image 
			rateImage= getNumber("How clear is this image on the scale of 1-10 (1=cannot measure lobe, 5= hard to measure, 10= easy to measure)?", 0);
				
			//This allows user to draw 2 reference lines on the image
				for (b= 1; b<3; b++) {
					
					//Keep prompting for a line, until a line is drawn.
					selectionCheck = -1;
					while(selectionCheck != 5) {
						//Clear selection after drawing reference line
						run("Select None");
						
						//Make a line
						setTool("line");
			
						//Wait for user to draw reference lines
						waitForUser("Make selection", "Please make reference line #" + b + ".");

						selectionCheck = selectionType(); 
					}
					//Draw the line 
					run("Fill", "slice"); 

					//Clear selection after drawing reference line
					run("Select None");
				}
		
				//Keep prompting for a polygon, until a polygon is drawn.
				selectionCheck = -1;
				while(selectionCheck != 2) {
					//Clear selection after drawing reference line
					run("Select None");
					
					//Draw the lobe 
					setTool("polygon");
					
					//Wait for user to make polygon 
					waitForUser("Make selection", "Please draw your polygon.");
					selectionCheck = selectionType(); 
				}

		
				//Clear the outside of the lobe 
				run("Clear Outside");
			
				//Set measurements for lobe
				run("Set Measurements...", "area mean centroid perimeter bounding fit shape feret's stack redirect=None decimal=9");
				
				//Measure the lobe
				run("Measure");
		
				//Add image score and file name to spreadsheet
				setResult("Image Score", nResults-1, rateImage);
				setResult("Measured lobe", nResults-1, title);
				updateResults();
			
				//Crop the lobe image
				run("Crop");
		
				//Set output file name for the cropped images
				Outputfile = outputDirectory + title + "-croppedlobe";
		
		
				//Save the cropped lobe image into output directory
				saveAs("tiff", Outputfile);
		
				//Close the cropped image
				close();
			}
			//Save lobe measurement every single time 
			if (nResults==0) {
				showMessage("Empty Results Table"," No measurements are found in Results Table.");
			}
			//Set date for the saved data set 
			else {
				getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
				//Add 1 to month count because command starts counting at 0 
				month = month+1;
	
				//Add 0 to the single digit month 
				if (month < 10){
					month = "0" + month;
				}
				
				//Add " " so that the computer knows that date is a string and not numerical value
				//NOTE: Add hour and minute to string to create unique identifier number to allow multiple spreadsheets in a single day
				date = "" + year + month + dayOfMonth + "-" + hour + "" + minute;
			
				//Save results into data table
				pathExcel =outputDirectory+ date + " lobe measurements.xls";
				saveAs("Results", pathExcel);
			}
		}

	//Ask user if they want to continue measuring
	//NOTE: This will cause macro to exit if user clicks "No"
	measureAgain = getBoolean("Would you like to keep measuring?");
	if(!measureAgain){
		a= Side1Array.length+3;
	
	}
			
}
			
//Remove scale bar reference image
a = File.delete(directory + "Scale bar text reference.tif");


	
	
