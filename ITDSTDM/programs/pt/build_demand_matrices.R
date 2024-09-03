
#build OMX matrices from PT trip lists
#Ben Stabler, ben.stabler@rsginc.com, 02/10/15
#Updated for paths, Andrew Rohne, andrew.rohne@rsginc.com, 7/18/24
#######################################################################

#load open matrix library
source("programs/pt/omx.R") 

INPUT_FOLDER <- Sys.getenv("INPUT_FOLDER")
OUTPUT_FOLDER <- Sys.getenv("OUTPUT_FOLDER")

#########################################################################
#functions
#########################################################################

#create vectorized indexes - watch out for duplicates on the left side of assignment
vectorIndex = function(fromIndex, toIndex, nrow) {
  return((toIndex-1)*nrow+fromIndex)
}

#time period functions
isAM = function(x) { x > 699 & x < 900 }
isMD = function(x) { x > 899 & x < 1600 }
isPM = function(x) { x > 1599 & x < 1800 }
isNT = function(x) { x > 1799 | x < 700 }

#########################################################################
#Get tazs and create OMX matrix to store results
#########################################################################

#get taz names
tazs = 1:(as.integer(commandArgs()[6])) #Cube sequential zone numbers
print(paste("num tazs:", length(tazs)))

#sample rate for scaling matrices
sampleRate = as.double(commandArgs()[7]) #PT sample rate
print(paste("sample rate 1 in ", sampleRate))

#omx file name
omxFileName = file.path(OUTPUT_FOLDER, "pt_trips.omx")
createFileOMX(omxFileName, length(tazs), length(tazs))

#########################################################################
#Process Trips_SDT
#########################################################################

#read and process trip file
trips = read.csv(file.path(OUTPUT_FOLDER, "SDTPersonTrips.csv"))

#remove extra fields to save memory
trips = trips[,c("origin","destination","tripStartTime","tripPurpose","tripMode")]

#calc tod
trips$tod[isAM(trips$tripStartTime)] = "AM"
trips$tod[isMD(trips$tripStartTime)] = "MD"
trips$tod[isPM(trips$tripStartTime)] = "PM"
trips$tod[isNT(trips$tripStartTime)] = "NT"

#add quantity field by tod
trips$amtrips = 0 
trips$mdtrips = 0 
trips$pmtrips = 0 
trips$nttrips = 0 
trips$amtrips[trips$tod == "AM"] = 1 
trips$mdtrips[trips$tod == "MD"] = 1 
trips$pmtrips[trips$tod == "PM"] = 1 
trips$nttrips[trips$tod == "NT"] = 1

#create indexes
from_SDT_Index = match(trips$origin,tazs)
to_SDT_Index = match(trips$destination,tazs)
sdtIndex = vectorIndex(from_SDT_Index, to_SDT_Index, length(tazs))  

i=1
SDTModes = c("BIKE","DA","DR_TRAN","SCHOOL_BUS","SR2","SR3P","WALK","WK_TRAN")
for(aMode in SDTModes) {
  
  #create OD matrices
  for(tod in c("am","md","pm","nt")) {
  
    #create empty matrix
    mat = matrix(0, length(tazs), length(tazs)) 
    
    #calculate matrix volumes
    sdtVolumes = trips[,paste(tod, "trips", sep="")][trips$tripMode == aMode]
    sdtIndexTemp = sdtIndex[trips$tripMode == aMode]
    sdtVolumes = tapply(sdtVolumes, sdtIndexTemp, sum) #sum by duplicate index 
    
    #convert to vehicle trips for shared ride modes
    if(aMode == "SR2") {
      sdtVolumes = sdtVolumes / 2
    } else if (aMode == "SR3P") {
      sdtVolumes = sdtVolumes / 3.33
    } 
    
    #add to matrix
    if(length(sdtVolumes) > 0) {
      mat[as.integer(names(sdtVolumes))] = mat[as.integer(names(sdtVolumes))] + sdtVolumes
    }
    
    #scale matrix by sample rate
    mat = mat * sampleRate
    
    #save to OMX file
    matName = paste("s", tod, aMode, sep="")
    print(paste(matName, "sum", sum(mat)))
    writeMatrixOMX(omxFileName, mat, matName)
    writeMatrixAttribute(omxFileName, matName, "CUBE_MAT_NUMBER", i)
    i=i+1
  }
}
rm(trips)


#########################################################################
#Process Trips_LDT
#########################################################################

#Trips_LDTVehicle contains all the trips (Trips_LDTPerson does not)
TripsLDT = read.csv(file.path(OUTPUT_FOLDER, "LDTVehicleTrips.csv"))

TripsLDT$amVol = 0
TripsLDT$mdVol = 0
TripsLDT$pmVol = 0
TripsLDT$ntVol = 0

TripsLDT$amVol[isAM(TripsLDT$tripStartTime)] = 1
TripsLDT$mdVol[isMD(TripsLDT$tripStartTime)] = 1
TripsLDT$pmVol[isPM(TripsLDT$tripStartTime)] = 1
TripsLDT$ntVol[isNT(TripsLDT$tripStartTime)] = 1

#create indexes
from_LDT_Index = match(TripsLDT$origin,tazs)
to_LDT_Index = match(TripsLDT$destination,tazs)
ldtIndex = vectorIndex(from_LDT_Index, to_LDT_Index, length(tazs))  

#create LDT and add to SDT matrices
LDTModes = c("DA","SR2","SR3P")
for(aMode in LDTModes) {
  
  for(tod in c("am","md","pm","nt")) {
  
    #create empty matrix
    mat = matrix(0, length(tazs), length(tazs)) 
  
    #LDT Volumes
    ldtVolumes = TripsLDT[,paste(tod, "Vol", sep="")][TripsLDT$tripMode == aMode]
    ldtIndexTemp = ldtIndex[TripsLDT$tripMode == aMode]
    ldtVolumes = tapply(ldtVolumes, ldtIndexTemp, sum) #sum by duplicate index 
    
    #convert to vehicle trips for shared ride modes
    if(aMode == "SR2") {
      ldtVolumes = ldtVolumes / 2
    } else if (aMode == "SR3P") {
      ldtVolumes = ldtVolumes / 3.33
    } 
    
    #Add to matrix
    if(length(ldtVolumes) > 0) {
      mat[as.integer(names(ldtVolumes))] = mat[as.integer(names(ldtVolumes))] + ldtVolumes
    }

    #save to OMX file
    matName = paste("l", tod, aMode, sep="")
    print(paste(matName, "sum", sum(mat)))
    writeMatrixOMX(omxFileName, mat, matName)
    writeMatrixAttribute(omxFileName, matName, "CUBE_MAT_NUMBER", i)
    i=i+1
  }
}
