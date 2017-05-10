# Quick script to repackage the flows into trip matrices by two truck types
require(data.table)
require(dplyr)

# Load the final trip list
FN <- "outputs/ct-combined-truck-trips.csv"
skims_added <- fread(FN)

# Define the truck types
SUT <- c("SU", "TT")
MUT <- c("CS", "DBL", "TPT")

# Grab the AM peak
ampeak <- filter(skims_added, dep_time>=0700 & dep_time<=0859)
ampeak_sut <- ampeak %>% filter(truck_type %in% SUT) %>%
    group_by(origin, destination) %>% summarise(trips = n())
write.table(ampeak_sut, file="outputs/ampeak-sut.csv", sep=',', row.names=FALSE,
    quote=FALSE)
print(paste(sum(ampeak_sut$trips), "SUT trips in AM peak"), quote=FALSE)

ampeak_mut <- ampeak %>% filter(truck_type %in% MUT) %>%
    group_by(origin, destination) %>% summarise(trips = n())
write.table(ampeak_mut, file="outputs/ampeak-mut.csv", sep=',', row.names=FALSE,
    quote=FALSE)
print(paste(sum(ampeak_mut$trips), "MUT trips in AM peak"), quote=FALSE)

# Grab the MD period
mdpeak <- filter(skims_added, dep_time>=0900 & dep_time<=1559)
mdpeak_sut <- mdpeak %>% filter(truck_type %in% SUT) %>%
    group_by(origin, destination) %>% summarise(trips = n())
write.table(mdpeak_sut, file="outputs/mdpeak-sut.csv", sep=',', row.names=FALSE,
    quote=FALSE)
print(paste(sum(mdpeak_sut$trips), "SUT trips in MD peak"), quote=FALSE)

mdpeak_mut <- mdpeak %>% filter(truck_type %in% MUT) %>%
    group_by(origin, destination) %>% summarise(trips = n())
write.table(mdpeak_mut, file="outputs/mdpeak-mut.csv", sep=',', row.names=FALSE,
    quote=FALSE)
print(paste(sum(mdpeak_mut$trips), "MUT trips in MD peak"), quote=FALSE)

# Grab the PM peak
pmpeak <- filter(skims_added, !(dep_time>=1600 & dep_time<=1759))
pmpeak_sut <- pmpeak %>% filter(truck_type %in% SUT) %>%
    group_by(origin, destination) %>% summarise(trips = n())
write.table(pmpeak_sut, file="outputs/pmpeak-sut.csv", sep=',', row.names=FALSE,
    quote=FALSE)
print(paste(sum(pmpeak_sut$trips), "SUT trips in PM peak"), quote=FALSE)

pmpeak_mut <- pmpeak %>% filter(truck_type %in% MUT) %>%
    group_by(origin, destination) %>% summarise(trips = n())
write.table(pmpeak_mut, file="outputs/pmpeak-mut.csv", sep=',', row.names=FALSE,
    quote=FALSE)
print(paste(sum(pmpeak_mut$trips), "MUT trips in PM peak"), quote=FALSE)

# Grab the NT period
ntpeak <- filter(skims_added, !(dep_time>=0700 & dep_time<=1759))
ntpeak_sut <- ntpeak %>% filter(truck_type %in% SUT) %>%
    group_by(origin, destination) %>% summarise(trips = n())
write.table(ntpeak_sut, file="outputs/ntpeak-sut.csv", sep=',', row.names=FALSE,
    quote=FALSE)
print(paste(sum(ntpeak_sut$trips), "SUT trips in NT peak"), quote=FALSE)

ntpeak_mut <- ntpeak %>% filter(truck_type %in% MUT) %>%
    group_by(origin, destination) %>% summarise(trips = n())
write.table(ntpeak_mut, file="outputs/ntpeak-mut.csv", sep=',', row.names=FALSE,
    quote=FALSE)
print(paste(sum(ntpeak_mut$trips), "MUT trips in NT peak"), quote=FALSE)