# This version of truck trip generation works with CT3A, as modified to work
# with the Idaho statewide model. It accepts two data tables as inputs. One is a
# list of synthetic firms, however defined. Each record must have a firmID that
# can be unambiguously tied back to the synthetic population, the sector it is
# in, the traffic analysis zone it is located within, and the number of 
# employees. The second data table contains IO make and use coefficients, with
# the table split between make and use vectors. The resulting trip list retains
# the firmID so that further summarization can be carried out.
# Rick Donnelly | donnellyr@pbworld.com | 24-Jan-2015

local_truck_generation <- function(firms, makeuse) {
    # Introduce yourself and set the random seed
    library(data.table)
    library(dplyr)
    library(stringr)
    library(reshape2)
    library(stringr)
    set.seed(as.integer(RTP[["ct.random.seed"]]))
    print(str_c("------- generate_local_truck_origins -------"), quote=FALSE)
    simulation.start <- proc.time()
    
    # Grab the trip generation parameters and convert them from wide to tall
    # format
    FN <- file.path(RTP[["ct.properties.folder"]], 
        "ct-detailed-generation-probabilities.csv")
    raw <- fread(FN)
    probabilities <- melt(raw, id.vars="Sector", variable.name="truck_type",
        value.name="p_gen") %>% filter(p_gen>0.0)
    
    # We will use the truck types defined in the trip generation parameters, as
    # they will not be already defined for firms. However, we'll use the sectors
    # as defined in the firms, rather than trip generation parameters, so that 
    # we can flag sectors without corresponding trip generation parameters.
    truck_types <- unique(probabilities$truck_type)
    sectors <- sort(unique(firms$Sector))
    
    # Generate a data table with sampled origins, using employment as the weight
    # in sampling. We will build up a data table of trip records from the list
    # of selected origins for each sector and truck type.
    results <- data.table()
    for (this_sector in sectors) {
        # If this sector isn't found in the parameters then let us know about
        # it, and continue to next sector.
        t_probabilities <- probabilities[probabilities$Sector==this_sector,]
        if (nrow(t_probabilities)==0) {
            print(paste("No trip parameters found for sector=", this_sector,
                "(no trips generated)"), quote=FALSE)
            next
        }
        
        # Pull the firms for this sector
        t_firms <- firms[firms$Sector==this_sector,]
        
        for (this_truck_type in truck_types) {
            # This truck type might not be defined for this sector, which is not
            # an abnormal condition (e.g., combination trucks are not generated
            # by households).
            TP <- t_probabilities[t_probabilities$truck_type==this_truck_type,]
            if (nrow(TP)==0) next
            
            # Otherwise generate the total number of trips
            total_trips <- round(sum(t_firms$Employees, na.rm=TRUE)*TP$p_gen, 0)
            
            # Sample the origins and create a data table that reports total 
            # number of trips generated in each by each firmID. Append current
            # sector and truck type to that table.
            t_origins <- sample(t_firms$firmID, size=total_trips, replace=TRUE,
                prob=t_firms$Employees)
            z <- data.table(firmID=t_origins) %>% group_by(firmID) %>%
                summarise(daily_trips = n()) %>%
                mutate(Sector = this_sector, truck_type = this_truck_type)
            
            # Finally, add these trips to those already computed
            results <- rbind(results, z)            
        }
    }
    
    # Show us the results
    print("Daily local truck origins by sector and truck type:", quote=FALSE)
    print(addmargins(xtabs(daily_trips~Sector+truck_type, data=results)))
    
    # At this point we have number of trips by "firm" (employment by each 
    # combination of zone and sector). We need to create a record for each
    # individual trip at this point.
    expanded <- data.table()
    for (i in (1:nrow(results))) {
        N <- results$daily_trips[i]
        zed <- data.table(firmID = results$firmID[i], trip_number = 1:N,
            Sector = results$Sector[i], truck_type = results$truck_type[i])
        expanded <- rbind(expanded, zed)
    }
    
    # Add commodity, weight, and value parameters as a function of the
    # originating sector. For a trip-based approach we have no idea what the 
    # value is, so insert missing value so that we have placeholder for when we
    # gain data on it.
    expanded$sctg2 <- NA
    for (this_sector in sectors) {
        # Get the make coefficients associated with this sector and the number
        # of firms associated with it. If none then skip this sector.
        N <- nrow(expanded[expanded$Sector==this_sector,])
        if (N==0) next
        
        # If the sum of the coefficients are zero or they simply do not exist at
        # all report that outcome and code the commodities as unknown. Otherwise
        # sample from the commodities using the make coefficient as the weight.
        t_make <- makeuse$make[makeuse$make[["Activity"]]==this_sector,]
        if (nrow(t_make)==0 | sum(t_make$Coefficient, na.rm=TRUE)<=0.0) {
            commodities <- rep(99, N)    # sctg2=99 is code for unknown cargo
            print(str_c("Make coefficients not found for ", this_sector, ", ",
                N, " shipments coded to unknown (sctg2=99)"), quote=FALSE)
        } else {
            # If there is only one commodity associated with this sector (i.e.,
            # coefficient=1) then sample will crash with unhelpful message, so
            # we will handle this case as well.
            if (nrow(t_make)==1) {
                commodities <- rep(t_make$sctg2, N)
            } else {
                commodities <- as.integer(sample(t_make$sctg2, size=N,
                    replace=TRUE, prob=t_make$Coefficient))
            }
        }
        
        # Write the commodities to the trip records for this sector
        expanded$sctg2[expanded$Sector==this_sector] <- commodities
    }

    # Next add the weight and value to each record. Ideally we would add these
    # from sampling distributions by commodity and truck type from microdata,
    # but we're still waiting on access from them. So for now by sampling from
    # distribution where max payload value has been gleaned from ODOT WIM data
    # and roadside interviews at truck ports of entry.
    expanded$tons <- NA
    expanded$value <- NA   # Placeholder even though we won't populate it now
    TW <- data.table(truck_type = c("SU", "TT", "CS", "DBL", "TPT"),
        max_short_tons = c(15.7, 22.3, 24.75, 25.35, 34.75))
    for (this_truck_type in truck_types) {
        N <- nrow(expanded[expanded$truck_type==this_truck_type,])
        tons <- round(runif(N, 1, 
            TW$max_short_tons[TW$truck_type==this_truck_type]), 2)
        expanded$tons[expanded$truck_type==this_truck_type] <- tons
    }
    
    # Finally, grab the TAZ associated with each firm and append it the results
    # as the origin.
    expanded <- merge(expanded, select(firms, firmID, Azone), by="firmID",
        all.x=TRUE)
    sorted <- rename(expanded, origin = Azone)
    
    # Write the resulting trip list to CSV format if the user wants to save the
    # intermediate outputs
    if (RTP[["ct.extended.trace"]]=="TRUE") {
        FN <- file.path(RTP[["ct.working.folder"]], "ct-local-truck-origins.csv")
        write.table(sorted, file=FN, sep=',', quote=FALSE, row.names=FALSE)
        print(str_c(nrow(sorted), " truck origins saved in ", FN), quote=FALSE)
    }
    
    # Wrap up
    simulation.stop <- proc.time()
    elapsed_seconds <- round((simulation.stop-simulation.start)[["elapsed"]], 1)
    print(str_c("Simulation time=", elapsed_seconds, " seconds"), quote=FALSE)
    print("", quote=FALSE) # Put whitespace between this report and the next one
    
    # Return the generated trips
    sorted
}
