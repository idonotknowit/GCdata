	# Step 1 - Unzip the archive, load the data files
	archiveName <- "getdata_projectfiles_UCI HAR Dataset.zip"
	# check if the archive exists
	if(file.exists(archiveName) == FALSE) stop ("File not found.")
	
	# when it exists, directly read the data from the archive
	trainSubjectDT <- read.table ( unz (archiveName, "UCI HAR Dataset/train/subject_train.txt"), header = FALSE, colClasses="integer")
	trainXDT <- read.table ( unz (archiveName, "UCI HAR Dataset/train/X_train.txt"), header = FALSE, colClasses="numeric")
	trainYDT <- read.table ( unz (archiveName, "UCI HAR Dataset/train/y_train.txt"), header = FALSE, colClasses="integer")

	#trainSubjectDT <- read.table ("./UCI HAR Dataset/train/subject_train.txt", header = FALSE, colClasses="integer")	
	testSubjectDT <- read.table ( unz (archiveName, "UCI HAR Dataset/test/subject_test.txt"), header = FALSE, colClasses="integer")
	testXDT <- read.table ( unz (archiveName, "UCI HAR Dataset/test/X_test.txt"), header = FALSE, colClasses="numeric")
	testYDT <- read.table ( unz (archiveName, "UCI HAR Dataset/test/y_test.txt"), header = FALSE, colClasses="integer")
	
	# Step 2 - build the large block, merge the training and the test sets to create one data set
	# we don't build the complete block here, because the variable names will change,
	# and we'd have to remember to rename the subject and activity
	subjectDT <- rbind (trainSubjectDT, testSubjectDT)
	featureDataDT <- rbind (trainXDT, testXDT)
	activityDT <- rbind (trainYDT, testYDT)
	
	# free some memory and remove no longer needed data tables
	rm (trainSubjectDT, trainXDT, trainYDT, testSubjectDT, testXDT, testYDT)
	
	# read the names of the features
	varNamesDT <-read.table ( unz (archiveName, "UCI HAR Dataset/features.txt"), sep = " ")
	# the second column contains the feature names
	featureNames <- as.character (varNamesDT[,2])
	rm (varNamesDT) # again, free some memory
	names(featureDataDT) <- featureNames
	names(subjectDT) <- c("Subject")
	names(activityDT) <- c("Activity")
	
	# Step 3 - Extract only the measurements on the mean and standard deviation for each measurement
	# these can be identified via mean() respectively std() in the variable names, this excludes variables like meanFreq or angle
	selectedFeatureDT <- featureDataDT[, grep("mean\\()|std\\()", featureNames)]
	# Step 3b, was step 5 - Rename the variables, use descriptive variable names
	# lets convert the variables/features like this: variableNameAndMore
	# first, we convert mean() and std() to Mean and Std
	names(selectedFeatureDT) <- gsub("mean\\()", "Mean", names(selectedFeatureDT))
	names(selectedFeatureDT) <- gsub("std\\()", "Std", names(selectedFeatureDT))
	
	# remove all "-"
	names(selectedFeatureDT) <- gsub("-", "", names(selectedFeatureDT))
	
	# expand abbr, also this makes the variable names very long
	names(selectedFeatureDT) <- gsub("^f", "frequency", names(selectedFeatureDT))
	names(selectedFeatureDT) <- gsub("^t", "time", names(selectedFeatureDT))
	names(selectedFeatureDT) <- gsub("Acc", "Acceleration", names(selectedFeatureDT))
	names(selectedFeatureDT) <- gsub("Gyro", "Gyroscope", names(selectedFeatureDT))
	
	# now we add the activities and subjects to the features, for the complete block
	# test if all the blocks have the same length?
	selectedFeatureDT <- cbind(selectedFeatureDT, subjectDT, activityDT)
	# and free some memory
	rm (featureDataDT, subjectDT, activityDT)
	
	# Step 4 - Uses descriptive activity names to name the activities in the data set
	# read the labels from file
	actLabels <- read.table ( unz (archiveName, "UCI HAR Dataset/activity_labels.txt"), header = FALSE, stringsAsFactors = FALSE)
	# now apply the labels to the data
	selectedFeatureDT$Activity <- factor(selectedFeatureDT$Activity, levels = actLabels[,1], labels = actLabels[,2])
	
	# Step 6 - Create a tidy data set with the average of each variable for each activity and each subject
	# load the library
	library(reshape)
	# first, melt the data, using the variables for Mean and Std
	measures <- grep ("Mean|Std", names (selectedFeatureDT), value = TRUE)
	moltenDT <- melt(selectedFeatureDT, id.vars = c("Subject", "Activity"), measure.vars = measures)
	# then cast the the data into the wanted form
	tidyDT <- cast(moltenDT, Subject + Activity ~ variable, mean)
	
	# Step 7 - Write the data to a csv file
	# we use write.csv as a wrapper for write.table; it uses "." for the decimal point and a comma for the separator
      write.table(tidyDT, file = "tidyData.txt",append = FALSE,row.names = FALSE,col.names = TRUE)
	
	# do some cleaning
	rm(actLabels, moltenDT, selectedFeatureDT, tidyDT)
	rm(archiveName, featureNames, measures)
	message("Script finished, CSV file written.")
