Project for "Getting and Cleaning Data"
This document explains how the script "run_analysis.R" works.

The script first checks if the ZIP-archive with the dataset exists in the current working directory. In case 

the archive does not exist, the script throws an error and stops. Please notice the name of the archive, this 

must be changed to match the name of your file.

archiveName <- "getdata_projectfiles_UCI HAR Dataset.zip"
if ( file.exists(archiveName) == FALSE) stop ("File not found.")
The next instructions directly read the different data from the archive. The archive is not unzipped 

completely, to avoid having to delete the files after running the script. The script does not read the headers 

and also assumes certain classes for the columns.

trainSubjectDT <- read.table ( unz (archiveName, "UCI HAR Dataset/train/subject_train.txt"), header = FALSE, 

colClasses="integer")
trainXDT <- read.table ( unz (archiveName, "UCI HAR Dataset/train/X_train.txt"), header = FALSE, 

colClasses="numeric")
trainYDT <- read.table ( unz (archiveName, "UCI HAR Dataset/train/y_train.txt"), header = FALSE, 

colClasses="integer")
testSubjectDT <- read.table ( unz (archiveName, "UCI HAR Dataset/test/subject_test.txt"), header = FALSE, 

colClasses="integer")
testXDT <- read.table ( unz (archiveName, "UCI HAR Dataset/test/X_test.txt"), header = FALSE, 

colClasses="numeric")
testYDT <- read.table ( unz (archiveName, "UCI HAR Dataset/test/y_test.txt"), header = FALSE, 

colClasses="integer")
Now we build three large blocks, as we have three different data sets, both available for training and testing. 

The script does not build one large block, but simply combines the the train and test data. The big block is 

build later, because the variable names will change; and combining the subject and activity data later makes 

this easier to accomplish. The script also frees some memory and removes no longer needed data tables.

subjectDT <- rbind (trainSubjectDT, testSubjectDT)
featureDataDT <- rbind (trainXDT, testXDT)
activityDT <- rbind (trainYDT, testYDT)

# free some memory and remove no longer needed data tables
rm (trainSubjectDT, trainXDT, trainYDT, testSubjectDT, testXDT, testYDT)
Now it's time to read the variable/feature names. Once again, the variable names are read directly from the zip 

archive. The script then sets the names for the variables/features as well as for subject and activity.

# read the names of the features
varNamesDT <-read.table ( unz (archiveName, "UCI HAR Dataset/features.txt"), sep = " ")
# the second column contains the feature names
featureNames <- as.character (varNamesDT[,2])
rm (varNamesDT) # again, free some memory
names(featureDataDT) <- featureNames
names(subjectDT) <- c("Subject")
names(activityDT) <- c("Activity")
Now we select only the variables that contain a mean oder std value. These can be easily identified using the 

variable names the script read before. Please note that the script only selects those variables whose names 

contain either "mean()" or "std()". This excludes variables like "meanFreq()", which contains the "weighted 

average of the frequency components to obtain a mean frequency".

selectedFeatureDT <- featureDataDT[, grep("mean\\()|std\\()", featureNames)]
Let's make the variable names more descriptive. The script uses camelCase for the variable names, which is more 

readable than just lower case variable names. First, the script substitutes "mean()" and "std()" with "Mean" 

and "Std". Then it removes all hyphens. It's discussible if the abbreviations "f", "t", "Acc", and "Gyrr" have 

to be expanded. The script does so, but this could also make the variables too long.

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
The script finally builds one large data frame, which contains all selected variables as well as the activity 

and subject variable.

# now we add the activities and subjects to the features, for the complete block
selectedFeatureDT <- cbind(selectedFeatureDT, subjectDT, activityDT)
# and free some memory
rm (featureDataDT, subjectDT, activityDT)
Then we load the labels for the activities directly from the zip file and apply the labels to the data.

actLabels <- read.table ( unz (archiveName, "UCI HAR Dataset/activity_labels.txt"), header = FALSE, 

stringsAsFactors = FALSE)
# now apply the labels to the data
selectedFeatureDT$Activity <- factor(selectedFeatureDT$Activity, levels = actLabels[,1], labels = actLabels

[,2])
We now create a tidy data set with the average of each variable for each activity and each subject. The library 

"reshape" is loaded first, as it contains the functions "melt" and "cast". Then the data is melt, using mean 

and std as variables. Then the molten data frame is cast into its final form. This contains the mean for each 

variable for each activity and every subject.

# load the library
library(reshape)
# first, melt the data, using the variables for Mean and Std
measures <- grep ("Mean|Std", names (selectedFeatureDT), value = TRUE)
moltenDT <- melt(selectedFeatureDT, id.vars = c("Subject", "Activity"), measure.vars = measures)
# then cast the the data into the wanted form
tidyDT <- cast(moltenDT, Subject + Activity ~ variable, mean)
In the last step, the script writes the tidy data to a csv file. It uses "write.csv()" as a wrapper for 

"write.table()"; write.csv uses "." for the decimal point and a comma for the separator. The script finishes 

with cleaning up, removes the remaining variables and data frames from memory, and prints a message that it is 

finished.

write.table(tidyDT, file = "tidyData.txt", row.names = FALSE)

# do some cleaning
rm(actLabels, moltenDT, selectedFeatureDT, tidyDT)
rm(archiveName, featureNames, measures)
message("Script finished, CSV file written.")
