
#Create sub-model specific TAZ input files
#Ben Stabler, ben.stabler@rsginc.com, 02/13/15
############################################################

tazFileName = "inputs/tazs.csv"

popSynFields = c("STATEFPS","COUNTYFPS","CNTYIDFP00","ZONEID",
  "TOTPOP_T","TOTHH_T","HHSIZE1","HHSIZE2","HHSIZE3","HHSIZE4",
  "HHSIZE5","HHSIZE6","HHSIZE7","HHWORK0","HHWORK1","HHWORK2",
  "HHWORK3","CATINC1","CATINC2","CATINC3","HHSIZE1_O","HHWORK0_O",
  "HHINC1","HHINC2","HHINC3","HHINC4","HHINC5","HHINC6","HHINC7",
  "HHINC8","HHINC9","HHINC10","HHINC11","HHINC12","HHINC13",
  "HHINC14","HHINC15","HHINC16")
popSynFileName = "outputs/zonalData.csv"

synpopSummaryFields = c("STDM_TAZ","TotalHHs")
synpopSummaryFileName = "outputs/SynPop_Taz_Summary.csv"

ptTazFields = c("STDM_TAZ","State","County","COUNTYFPS","MPO",
  "IsMPO","ITDDist","Area","DayPark","HourPark","destinationChoiceDistrict")
ptTazFileName = "outputs/Taz_Data.csv"

ptEmploymentFields = c("STDM_TAZ","TotEmp","sdtRetail","sdtOtherServ","sdtHealth",
  "sdtTransportation","sdtK12Ed","sdtHigherEd","sdtOtherEd","sdtPublicAdmin",
  "sdtOther","ldtAgriMining","ldtConst","ldtManu","ldtTransportation",
  "ldtWholesale","ldtRetail","ldtOtherService","ldtHealth","ldtEducation",
  "ldtFinance","ldtPublicAdmin","ldtHotel","ldtOther")
ptEmploymentFileName = "outputs/Employment.csv"

ptShadowPriceFields = c("TAZ","ShadowPrice")
ptShadowPriceFileName = "outputs/InitialShadowPriceByTaz.csv"

############################################################

#read master file
tazs = read.csv(tazFileName)

# create popsyn file
tazs$ZONEID = tazs$STDM_TAZ
popSynData = tazs[tazs$STATEFPS>0,popSynFields] #only internal zones
write.csv(popSynData, popSynFileName, row.names=F)

#create synpop summary file
tazs$TAZ = tazs$STDM_TAZ
tazs$TotalHHs = tazs$TOTHH_T
synpopSummaryData = tazs[,synpopSummaryFields]
write.csv(synpopSummaryData, synpopSummaryFileName, row.names=F)

# create pt taz file
ptTazData = tazs[,ptTazFields]
write.csv(ptTazData, ptTazFileName, row.names=F)

# create pt employment file -SDT and LDT
tazs$sdtRetail = tazs$RetailF
tazs$sdtOtherServ = tazs$ProftechF + tazs$MgmtF + tazs$WastadmnF + 
  tazs$ArtsentF + tazs$FoodlodgF + tazs$OtherF
tazs$sdtHealth = tazs$HealthF 
tazs$sdtTransportation = tazs$TrawhseF
tazs$sdtK12Ed = tazs$EduK12
tazs$sdtHigherEd = tazs$EduHigh
tazs$sdtOtherEd = tazs$EduOthers
tazs$sdtPublicAdmin = tazs$PublicF
tazs$sdtOther = tazs$AgforF + tazs$MiningF + tazs$ConstrF + tazs$ManufF +
  tazs$InfoF + tazs$UtilF + tazs$WhlsaleF + tazs$FininsF + tazs$RealestF

tazs$ldtAgriMining = tazs$AgforF + tazs$MiningF
tazs$ldtConst = tazs$ConstrF
tazs$ldtManu = tazs$ManufF
tazs$ldtTransportation = tazs$TrawhseF + tazs$InfoF + tazs$UtilF
tazs$ldtWholesale = tazs$WhlsaleF
tazs$ldtRetail = tazs$RetailF
tazs$ldtOtherService = tazs$OtherF
tazs$ldtHealth = tazs$HealthF
tazs$ldtEducation = tazs$EduK12 + tazs$EduHigh + tazs$EduOthers
tazs$ldtFinance = tazs$RealestF + tazs$FininsF
tazs$ldtPublicAdmin = tazs$PublicF
tazs$ldtHotel = tazs$FoodlodgF
tazs$ldtOther = tazs$ProftechF + tazs$MgmtF + tazs$WastadmnF + tazs$ArtsentF

ptEmploymentData = tazs[,ptEmploymentFields]
write.csv(ptEmploymentData, ptEmploymentFileName, row.names=F)

# create pt shadow price file with all sequential zone numbers
ptSPData = tazs[,ptShadowPriceFields]
skippedTAZs = (1:max(ptSPData$TAZ))[!(1:max(ptSPData$TAZ) %in% ptSPData$TAZ)]
extraRows = data.frame(TAZ=skippedTAZs,ShadowPrice=1)
ptSPData = rbind(ptSPData, extraRows)
ptSPData = ptSPData[order(ptSPData$TAZ),]
write.csv(ptSPData, ptShadowPriceFileName, row.names=F)
