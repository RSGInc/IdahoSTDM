
#build OMX matrices from truck tables
#Ben Stabler, ben.stabler@rsginc.com, 02/10/15
#######################################################################

#load open matrix library
source("programs/pt/omx.R") 

#########################################################################
#functions
#########################################################################

#create vectorized indexes - watch out for duplicates on the left side
vectorIndex = function(fromIndex, toIndex, nrow) {
  return((toIndex-1)*nrow+fromIndex)
}

#########################################################################
#Get tazs and create OMX matrix to store results
#########################################################################

#get taz names
tazs = read.csv("outputs/SynPop_Taz_Summary.csv")[,1]
tazs = 1:max(tazs) #Cube sequential zone numbers

#omx file name
omxFileName = "outputs/truck_trips.omx"
createFileOMX(omxFileName, length(tazs), length(tazs))

#########################################################################
#Process Trips
#########################################################################

#read and process trip file
am_mut = read.csv("outputs/ampeak-mut.csv")
am_mut$tod = "am"
am_mut$userclass = "mut"

am_sut = read.csv("outputs/ampeak-sut.csv")
am_sut$tod = "am"
am_sut$userclass = "sut"

md_mut = read.csv("outputs/mdpeak-mut.csv")
md_mut$tod = "md"
md_mut$userclass = "mut"

md_sut = read.csv("outputs/mdpeak-sut.csv")
md_sut$tod = "md"
md_sut$userclass = "sut"

pm_mut = read.csv("outputs/pmpeak-mut.csv")
pm_mut$tod = "pm"
pm_mut$userclass = "mut"

pm_sut = read.csv("outputs/pmpeak-sut.csv")
pm_sut$tod = "pm"
pm_sut$userclass = "sut"

nt_mut = read.csv("outputs/ntpeak-mut.csv")
nt_mut$tod = "nt"
nt_mut$userclass = "mut"

nt_sut = read.csv("outputs/ntpeak-sut.csv")
nt_sut$tod = "nt"
nt_sut$userclass = "sut"

trips = rbind(am_mut, am_sut, md_mut, md_sut, pm_mut, pm_sut, nt_mut, nt_sut)

#create indexes
from_Index = match(trips$origin,tazs)
to_Index = match(trips$destination,tazs)
od_Index = vectorIndex(from_Index, to_Index, length(tazs))  

i=1
for(uc in c("mut","sut")) {
  
  #create OD matrices
  for(tod in c("am","md","pm","nt")) {
  
    #create empty matrix
    mat = matrix(0, length(tazs), length(tazs)) 
    
    #calculate matrix volumes
    volumes = trips$trips[trips$userclass==uc & trips$tod==tod]
    indexTemp = od_Index[trips$userclass==uc & trips$tod==tod]
    vols = tapply(volumes, indexTemp, sum) #sum by duplicate index 
    
    #add to matrix
    if(length(vols) > 0) {
      mat[as.integer(names(vols))] = mat[as.integer(names(vols))] + vols
    }
    
    #save to OMX file
    matName = paste(tod, uc, sep="")
    print(paste(matName, "trips", sum(mat)))
    writeMatrixOMX(omxFileName, mat, matName)
    writeMatrixAttribute(omxFileName, matName, "CUBE_MAT_NUMBER", i)
    i=i+1
  }
}
rm(trips)

