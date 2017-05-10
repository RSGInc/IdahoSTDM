# The STDM uses a focused rather than windowed approach, so we can unambiguously
# map external zones with distant FAF regions. This component maps FAF regions
# to corresponding STDM zones, using sampling for zones with Idaho based on the
# same weights we used in local truck generation.

allocate_daily_FAF_to_firms <- function(firms, daily_regional_trucks) {
    # Report in and start working
    library(data.table)
    library(dplyr)
    library(stringr)
    library(reshape2)
    set.seed(as.integer(RTP[["ct.random.seed"]]))
    print(str_c("------- allocate_daily_FAF_to_firms -------"), quote=FALSE)
    simulation.start <- proc.time()
    
    # Import daily trucks (can probably be abstracted out at some point by 
    # simply coding vehicle_type as truck_type consistently, even though FAF
    # uses the former)
    daily_trucks <- rename(faf_daily_regional_trucks, truck_type = vehicle_type)
    
    # READ FAF REGION EQUIVALENCIES
    # The equivalencies between FAF regions and external regions are exogenously
    # defined and static.
    faf_equiv <- fread(file.path(RTP[["ct.properties.folder"]],
        "faf35-region-equivalencies.csv"))
    
    # CREATE ZONAL ATTRACTION FACTORS BY SECTOR AND TRUCK TYPE
    # The simplest thing that can work is to calculate weighted attractiveness
    # for each TAZ that is product of trip generation rate and employees by
    # sector. We will create these for each truck type defined in the detailed
    # generation probabilities (DGP).
    DGP <- fread(file.path(RTP[["ct.properties.folder"]],
        "ct-detailed-generation-probabilities.csv"))
    tall <- melt(DGP, id.vars="Sector", variable.name="truck_type",
        value.name="px")
    
    # Now append these data to the firm employment by sector for each truck type
    # in turn
    attractors <- data.table()
    truck_types <- unique(tall$truck_type)
    for (t in truck_types) {
        zed <- merge(filter(firms, faf_region==160), filter(tall, truck_type==t),
            by="Sector", all.x=TRUE)
        zed$gamma <- zed$Employees*zed$px
        collapsed <- zed %>% group_by(Azone, truck_type) %>%
            summarise(gamma = sum(gamma, na.rm=TRUE))
        attractors <- rbind(attractors, collapsed)
    }
    # We need to remove zero entries, as sampling will trip up on them
    attractors <- filter(attractors, gamma>0.0)
    
    # MAP FAF REGIONS TO STDM TAZs
    # Recode FAF regions outside of Idaho to corresponding external TAZs. Since
    # ID (and HI) are coded as missing values for equivalencies we will wind up
    # with missing values for internal origins or destinations encountered. To
    # make the join easier we'll create temporary version of FAF region
    # equivalencies with the appropriate column heading.
    FE <- faf_equiv %>% select(-description, -state) %>%
        rename(dms_orig = fafregion, origin = STDM_TAZ)
    daily_trucks <- merge(daily_trucks, FE, by="dms_orig", all.x=TRUE)
    # Repeat same process, but for the destination end of the trip
    FE <- faf_equiv %>% select(-description, -state) %>%
        rename(dms_dest = fafregion, destination = STDM_TAZ)
    daily_trucks <- merge(daily_trucks, FE, by="dms_dest", all.x=TRUE)
    
    # Because we coded the TAZ for the Idaho FAF region (160) as missing value
    # those records that have remaining missing values for origin or destination
    # must be internal, so we will sample the internal zone number using the
    # attractors calculated above. We will have to do this by truck type, as the
    # attractors are different for each.
    for (t in truck_types) {
        # Start with the origins
        N <- nrow(filter(daily_trucks, is.na(origin), truck_type==t))
        if (N>0) {
            W <- sample(attractors$Azone, N, replace=T, prob=attractors$gamma)
            daily_trucks$origin[is.na(daily_trucks$origin) &
                daily_trucks$truck_type==t] <- W    
        }
        
        # Do the same thing for missing destinations
        N <- nrow(filter(daily_trucks, is.na(destination), truck_type==t))
        if (N>0) {
            W <- sample(attractors$Azone, N, replace=T, prob=attractors$gamma)
            daily_trucks$destination[is.na(daily_trucks$destination) &
                daily_trucks$truck_type==t] <- W
        }
    }
    
    # WRITE THE RESULTS
    # We now have TAZ origins and destinations for all of the daily FAF truck
    # flows. Write them out to comma-separated text value and exit stage left.
    if (RTP[["ct.extended.trace"]]=="TRUE") {
        FN <- file.path(RTP[["ct.working.folder"]], "ct-long-distance-trucks.csv")
        write.table(daily_trucks, file=FN, quote=FALSE, sep=',', row.names=FALSE)
        print(str_c(nrow(daily_trucks), " records written to ", FN), quote=FALSE)
    }
    
    print(str_c(nrow(daily_trucks), " daily FAF trucks allocated to STDM zones"),
        quote=FALSE)
    simulation.stop <- proc.time()
    elapsed_seconds <- round((simulation.stop-simulation.start)[["elapsed"]], 1)
    print(str_c("Simulation time=", elapsed_seconds, " seconds"), quote=FALSE)
    print("", quote=FALSE)   # Add whitespace between this and next report
    
    # Return final FAF truck trip list, which now has OD at TAZ added. We will
    # put the data table into a format that is comparable with the CT output so
    # that we have less file reconciliation to do at the end.
    daily_trucks$dataset <- "FAF"
    daily_trucks <- rename(daily_trucks, datasetID = fafID)
    daily_trucks
}