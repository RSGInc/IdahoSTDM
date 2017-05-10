# @tag{doParallel+foreach matrix solution for CT destination choice}
# @author{Rick Donnelly} @version{0.8.1}  @date{17-Feb-2015}
# This variant of destination choice for the Idaho statewide model uses matrix
# manipulations to get at the answer, which will hopefully be substantially
# quicker solution.

sample_local_truck_destinations <- function(truck_origins, skim_distances) {
    # Announce yourself
    library(data.table)
    library(dplyr)
    library(stringr)
    set.seed(as.integer(RTP[["ct.random.seed"]]))
    print(str_c("------- sample_local_truck_destinations -------"), quote=FALSE)
    simulation.start <- proc.time()
    
    # The ITD skim distance matrix is provided without row and column labels,
    # which is fine because the TAZ number matches the subscript. We will create
    # a list of those zones, as we only want to sample destinations from those
    # zones that are included in the skim matrix.
    dzones <- 1:dim(skim_distances)[1]
    
    # Check to make sure that we don't have trips originating from zones that
    # are not in the skim matrix. If so, stop the simulation.
    CTO <- sort(unique(truck_origins$origi))
    problem_children <- list()
    for (c in CTO) {
        if (!c %in% dzones) problem_children <- c(problem_children, c)
    }
    if (length(problem_children>0)) stop(paste("Alpha zones in trip list",
        "with no corresponding skim:", problem_children))
    
    # Sum the attractors by zone. We will need to have data defined for each of 
    # the zones defined in the skim matrix, even if some have zero truck trips
    # associated with it. Thus, we'll substitute any missing values with zeros.
    attractors <- truck_origins %>% group_by(origin, truck_type) %>%
        summarise(attractors = n())
    attractors$destination <- attractors$origin  # Bug in dplyr's rename() 
    
    # Read the utility parameters by truck type
    FN <- file.path(RTP[["ct.properties.folder"]], "ct-destination-utility-parameters.csv")
    alphas <- fread(FN)
    
    # Read the ideal trip length probabilities by truck type. These data are in
    # wide format, and we need to first append rows for distances in the skim
    # matrix but not included in the ideal distribution data. Then we'll convert
    # it to tall format to make process it easier.
    FN <- file.path(RTP[["ct.properties.folder"]], "ct-idealized-trip-length-distribution.csv")
    ideal <- fread(FN)
    max_skim_distance <- round(max(skim_distances), 0)
    # Add 1 because we'll use offset referencing because R doesn't have zero-
    # based matrix indexing
    x <- data.table(distance = 0:max_skim_distance+1)
    ideal <- merge(ideal, x, by="distance", all.y=TRUE)
    ideal[is.na(ideal)] <- 0.0   # Replace missing values with zeros
    
    # RUN THE MODEL
    # The ideal distributions and alpha parameters differ by truck type, so we
    # will handle each one differently. At the end of handling each truck type
    # we will add those results to a final data table that will have OD flows.
    destinations <- data.table()
    truck_types <- unique(truck_origins$truck_type)
    for (t in truck_types) {
        print(str_c("Sampling destinations for ", nrow(filter(truck_origins,
            truck_type==t)), " ", t, " origins"), quote=FALSE)
        # We first need to multiply the skim matrix by ideal propbabilities,
        # which is harder in R than it should be. We'll convert the matrix into
        # vector format, morph skims into probabilities, and put it back into a
        # matrix format.
        t_ideal <- ideal[[t]]
        X <- round(as.vector(skim_distances), 0)+1
        # Convert to ideal probabilities and optionally scale them
        X <- t_ideal[X]
        X <- X*alphas$alpha1[alphas$truck_type==t]
        # Finally, write the results back to matrix format so that we can 
        # multiply them by the attractors, which of course varies by zone
        t_skims <- matrix(X, nrow=length(dzones), ncol=length(dzones),
            byrow=FALSE, dimnames=list(dzones, dzones))
        
        # Next construct a matrix of attractors. Since not all zones have
        # attractors we'll need to include missing destination zones and set 
        # their attractors to zero.
        A <- merge(data.table(destination = dzones),
            filter(attractors, truck_type==t), by="destination", all.x=TRUE)
        A$attractors[is.na(A$attractors)] <- 0
        # Apply the scaling factor
        A$attractors <- A$attractors*alphas$alpha2[alphas$truck_type==t]
        
        # Calculate the weighted probabilities. A nifty feature of sample() is
        # that it is too lame to ignore zero values, so when it finds instances
        # of zero probabilities it throws an error. So we'll have to replace
        # zeroes with really low probabilities.        
        W <- sweep(t_skims, 2, as.vector(A$attractors), '*')
        W[W==0] <- 1e-9
        
        # Finally, now sample the destinations for the origins. Start by summing
        # total origins by zone, which will be the number of samples we will 
        # draw for destinations.
        t_origins <- truck_origins %>% filter(truck_type==t) %>% 
            group_by(origin) %>% summarise(total_origins = n())
        ###t_origins <- rename(t_origins, origin = Azone)
        results <- lapply(1:nrow(t_origins), 
            function(i) {
                this_origin <- t_origins$origin[i]
                these_trips <- t_origins$total_origins[i]
                sample(dzones, these_trips, prob=W[as.character(this_origin),], replace=TRUE)
            }
        )
        
        # Create a data table for this truck type that includes each OD pair. We
        # let foreach do the row binding, so it builds up the results on the
        # fly.
        t_destinations <- foreach(i=1:nrow(t_origins), .combine="rbind") %do%
            data.table(origin_2 = t_origins$origin[i], destination = results[[i]],
                truck_type_2 = t)
        destinations <- rbind(destinations, t_destinations)
    }
    
    # At this point our destination list only has origin, destination, and truck
    # type. But the number of destinations by origin and truck type should match
    # those on the input truck origins, so we just need to column bind the two
    # data tables. We'll sort them both by origin and truck type to ensure that
    # the column join works correctly.
    # VERY IMPORTANT: truck_type is a factor, so convert to string before sort
    daily_trips <- cbind(
        arrange(truck_origins, origin, as.character(truck_type)),
        arrange(destinations, origin_2, as.character(truck_type_2))
    )
    
    # Check for mismatch between the two datasets, which would be evident if
    # the truck types are different or the origins don't match. If either are 
    # true then stop the simulation.
    defect1 <- filter(daily_trips, origin!=origin_2 | truck_type!=truck_type_2)
    if (nrow(defect1)>0) {
        PC <- file.path(RTP[["ct.working.folder"]], "ct-mismatched-destinations.csv")
        write.table(defect1, file=PC, sep=',', quote=FALSE, row.names=FALSE)
        stop(str_c(nrow(defect1), " mismatched destination records written to ", FN))
    }
    
    # Drop the unneeded fields from the daily trip list. For some reason dplyr
    # trips up if we chain select and mutate together in one line, so we'll do
    # it separately to make it happy.
    daily_trips <- select(daily_trips, -truck_type_2, -origin_2)
    daily_trips <- rename(daily_trips, datasetID = firmID)
    daily_trips <- mutate(daily_trips, dataset = "CT3", status = "Loaded")
    daily_trips$truckID <- 1:nrow(daily_trips)
    
    # Write the intermediate results to disk if the user has so requested that
    if (RTP[["ct.extended.trace"]]=="TRUE") {
        FN <- file.path(RTP[["ct.working.folder"]], "ct-daily-truck-trips.csv")
        write.table(daily_trips, file=FN, sep=',', row.names=FALSE, quote=FALSE)
        print(str_c("Saving ", nrow(daily_trips), " daily truck trips to ", FN),
            quote=FALSE)        
    }
    
    # Shut down
    simulation.stop <- proc.time()
    elapsed_seconds <- round((simulation.stop-simulation.start)[["elapsed"]], 1)
    print(str_c("Simulation time=", elapsed_seconds, " seconds"), quote=FALSE)
    print("", quote=FALSE)  # Add empty line before next report
    
    # Return the daily trips with both trip ends coded
    daily_trips
}
