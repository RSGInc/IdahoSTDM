# Carry out temporal allocation for both intercity and local truck trips
# @author{Rick Donnelly} @version{0.9} @date{18-Oct-2014}

truck_trip_temporal_allocation <- function(local_daily_trucks,
    long_distance_daily_trucks) {
    # Introduce yourself and set the random seed
    require(data.table)
    require(dplyr)
    require(stringr)
    set.seed(as.integer(RTP[["ct.random.seed"]]))
    print(str_c("------- truck_trip_temporal_allocation -------"), quote=FALSE)
    
    # We'll first combine the two trip lists, keeping only those fields that we
    # care about
    combined <- rbind(
        select(local_daily_trucks, dataset, datasetID, truckID, truck_type,
            origin, destination, status, value, tons, sctg2),
        select(long_distance_daily_trucks, dataset, datasetID, truckID,
            truck_type, origin, destination, status, value, tons, sctg2)
    )
    
    # Read the temporal allocation factors, which denote the hour the truck
    # will start its trip. Factors are defined for each truck type in the
    # simulation.
    FN <- file.path(RTP[["ct.properties.folder"]], "/ct-truck-temporal-distributions.csv")
    temporal <- fread(FN)
    
    # Append the departure time to each record
    truck_types <- unique(combined$truck_type)
    combined$dep_time <- NA
    
    # Process each truck type in turn
    for (t in truck_types) {
        N <- nrow(combined[combined$truck_type==t])
        print(str_c("Sampling departure times for ", N, " ", t, " trucks"), quote=FALSE)
        hour <- sample(temporal$hour[temporal$truck_type==t], N,
            prob=temporal$share[temporal$truck_type==t], replace=TRUE)
        minute <- sample(0:59, N, replace=TRUE)
        combined$dep_time[combined$truck_type==t] <- (hour*100)+minute        
    }
    
    # Return the combined truck trip list with departure times appended
    combined
}
