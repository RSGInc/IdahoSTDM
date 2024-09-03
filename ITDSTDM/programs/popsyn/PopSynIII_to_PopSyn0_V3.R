#Translate PopSynIII to PopSyn0

#Sujan Sikder
#sikders@pbworld.com  2/13/2015; 3/2/2015

#--------------------------------------------------------------------------------------------------------
# Input and Output Files 
#--------------------------------------------------------------------------------------------------------
# This script works in 6 steps
# Step 1: Read and review the input data
# Step 2: Get the original TAZ IDs 
# Step 3: Get the NAISC codes for the industries
# Step 4: Get the occupation codes for work occupation categories
# Step 5: Recode the attribute names and their categories to match with those in the PopSyn0 files 
# Step 6: Write out to csv files 

#Input Files:
# 1) households.csv: PopSynIII hosuehold file
# 2) persons.csv: PopSynIII person file(without industry information)
# 3) CW_CensusID.csv: geographic cross-walk table(one of the PopSynIII outputs)
# 4) Industry_Code.csv: cross-walk table for the industries
# 5) Work_Occupation_Code.csv: cross-walk table for work occupation categories
#    Work Occupation Categories: 1 - Manager, 2 - Professional Non-Retail, 3 - Retail
#                                4 - Industrial, 5 - Other     
    
#Output Files:
# 1) PopSyn0_HH.csv: PopSyn0 household file 
# 2) PopSyn0_Per.csv: PopSyn0 person file 

INPUT_FOLDER <- Sys.getenv("INPUT_FOLDER")
OUTPUT_FOLDER <- Sys.getenv("OUTPUT_FOLDER")

#--------------------------------------------------------------------------------------------------------
#Step 1: Read and review the input data
#--------------------------------------------------------------------------------------------------------
households <- read.csv(file.path(OUTPUT_FOLDER, "households.csv"),header = T)
names(households)

persons <- read.csv(file.path(OUTPUT_FOLDER, "persons.csv"),header = T)
names(persons)

crossWalk <- read.csv(file.path(OUTPUT_FOLDER, "CW_CensusID.csv"),header = T)
names(crossWalk)

indCode <- read.csv(file.path(INPUT_FOLDER, "popsyn/Industry_Code.csv"),header=T)
names(indCode)

occupCode <- read.csv(file.path(INPUT_FOLDER, "popsyn/Work_Occupation_Code_upd.csv"),header=T)
names(occupCode)

#--------------------------------------------------------------------------------------------------------
#Step 2: Get the original TAZ IDs from the cross-walk file
#--------------------------------------------------------------------------------------------------------
households$STDM_TAZ <- crossWalk$ZONEID[match(households$maz,crossWalk$MAZ)]
names(households)

persons$STDM_TAZ <- crossWalk$ZONEID[match(persons$maz,crossWalk$MAZ)]
names(persons)

#--------------------------------------------------------------------------------------------------------
#Step 3: Get the NAISC codes for the industries
#--------------------------------------------------------------------------------------------------------
persons$indCom0207 <- persons$indp02
persons$indCom0207[is.na(persons$indCom0207)] <- 0 
persons$indCom0207[persons$indCom0207 == -8] <- 0

persons$indCom0207 <- ifelse(((persons$indCom0207 == 0)&(persons$employed == 1)),persons$indp07,persons$indCom0207)
persons$indCom0207 <- ifelse((persons$employed == 0),0,persons$indCom0207)

persons$INDUSTRY <- 0
persons$INDUSTRY <- indCode$IndustryCode[match(persons$indCom0207,indCode$X2007CensusCode)]
persons$INDUSTRY[is.na(persons$INDUSTRY)] <- 0

#--------------------------------------------------------------------------------------------------------
#Step 4: Get the occupation codes for work occupation categories
#--------------------------------------------------------------------------------------------------------
persons$occpCom0210 <- persons$occp02
persons$occpCom0210[is.na(persons$occpCom0210)] <- 0 
persons$occpCom0210[persons$occpCom0210 == -8] <- 0

persons$occpCom0210 <- ifelse(((persons$occpCom0210 == 0)&(persons$employed == 1)),persons$occp10,persons$occpCom0210)
persons$occpCom0210 <- ifelse((persons$employed == 0),0,persons$occpCom0210)

persons$WORK_OCC <- 0
persons$WORK_OCC <- occupCode$work_occ[match(persons$occpCom0210,occupCode$occpCode)]
persons$WORK_OCC[is.na(persons$WORK_OCC)] <- 0

#--------------------------------------------------------------------------------------------------------
#Step 5: Recode the attribute names and their categories to match with those in the PopSyn0 files 
#--------------------------------------------------------------------------------------------------------
#--household file
households$HH_ID <- households$HHID
households$PERSONS <- households$np
households$STDM_TAZ <- households$STDM_TAZ
households$UNITS1 <- households$bld
households$AUTOS <- households$veh
households$RHHINC <- households$hhincAdj
households$Azone <- households$maz

#---recode the auto categories 
households$AUTOS[is.na(households$AUTOS)] <- 0
households$AUTOS[households$veh == 0] <- 1 
households$AUTOS[households$veh == 1] <- 2 
households$AUTOS[households$veh == 2] <- 3 
households$AUTOS[households$veh == 3] <- 4 
households$AUTOS[households$veh == 4] <- 5 
households$AUTOS[households$veh == 5] <- 6 
households$AUTOS[households$veh == 6] <- 7 
households$AUTOS[households$veh == 7] <- 8 

#---keep only the required columns 
households <- households[,c("HH_ID","PERSONS","STDM_TAZ","UNITS1","AUTOS","RHHINC","Azone")]
											
#--person file
persons$HH_ID <- persons$HHID
persons$PERS_ID <- persons$PERID
persons$SEX <- persons$sex
persons$AGE <- persons$agep
persons$SCHOOL <- persons$sch
persons$RLABOR <- persons$esr
persons$OCCUP <- 0
persons$SW_UNSPLIT_IND <- 0
persons$SW_OCCUP <- persons$occp
persons$SW_SPLIT_IND <- 0

#---recode the age categories
#table(persons$agep)
#sum(table(persons$agep))
#table(persons$AGE)
#sum(table(persons$AGE))
persons$AGE[persons$agep >= 90] <- 90
#table(persons$AGE)

#---recode the gender categories
#table(persons$sex)
#table(persons$SEX)
persons$SEX[persons$sex == 1] <- 0
persons$SEX[persons$sex == 2] <- 1
#table(persons$SEX)

#---recode the employment status categories
#table(persons$esr)
#table(persons$RLABOR)
persons$RLABOR[persons$esr == -9] <- 0
#table(persons$RLABOR)

#---recode the occupation categories
persons$SW_OCCUP[persons$occp == 9] <- 0
persons$SW_OCCUP[persons$occp == 999] <- 0

#---keep only the required columns 
persons <- persons[,c("HH_ID","PERS_ID","STDM_TAZ","SEX","AGE","SCHOOL","RLABOR","INDUSTRY","OCCUP","SW_UNSPLIT_IND","SW_OCCUP","SW_SPLIT_IND","WORK_OCC")]

#--------------------------------------------------------------------------------------------------------
#Step 6: Write out to csv files 
#--------------------------------------------------------------------------------------------------------
write.csv(households,file = file.path(OUTPUT_FOLDER, "PopSyn0_HH.csv"),row.names = F, quote=F)
write.csv(persons,file = file.path(OUTPUT_FOLDER, "PopSyn0_Per.csv"),row.names = F, quote=F)



