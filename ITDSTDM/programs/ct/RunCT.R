library(stringr)
library(doParallel)
library(data.table)

# (1) Create runtime properties
ROOT_DIR <- getwd()
RTP <- new.env()
RTP[["ct.code.folder"]] <- file.path(ROOT_DIR, "programs/ct")
RTP[["ct.properties.folder"]] <- file.path(ROOT_DIR, "inputs/ct")
RTP[["ct.working.folder"]] <- file.path(ROOT_DIR, "outputs")
RTP[["taz.csv"]] <- file.path(ROOT_DIR, "inputs/tazs.csv")
RTP[["ct.extended.trace"]] <- "TRUE"
RTP[["ct.random.seed"]] <- 630730
RTP[["base.year"]] <- as.integer(Sys.getenv("MODEL_YEAR"))
RTP[["ct.external.scaling.factor"]] <- 2.4
RTP[["ct.weeks.per.year"]] <- 50
RTP[["ct.target.week"]] <- 23
RTP[["ct.target.day"]] <- 4
RTP[["ct.truck.trips"]] <- "ct-combined-truck-trips.csv"
properties_FN <- file.path(RTP[["ct.working.folder"]], "ct-runtime-parameters.RData")
print(str_c("Saving CT runtime properties to ", properties_FN), quote=FALSE)
save(RTP, file=properties_FN)

# (2) Start the doParallel cluster that several of the modules will use
ctCluster <- makeCluster(detectCores())
registerDoParallel(ctCluster)
print(str_c("doParallel cluster instance started with ", getDoParWorkers(),
    " cores"), quote=FALSE)

# (3) Load functions
functions <- functions <- c("create_Idaho_firms.R", "local_truck_generation2.R",
    "create_FAF_annual_truckloads.R", "sample_FAF_weekly_trucks.R",
    "Idaho_FAF_allocation.R", "omx.r", "sample_local_truck_destinations.R",
    "truck_trip_temporal_allocation.R")
for (f in functions) source(file.path(RTP[["ct.code.folder"]], f))

# (4) Create the IO coefficients in a format compatible with previous uses of CT
mu <- fread(file.path(RTP[["ct.properties.folder"]], "ct-makeuse-coefficients.csv"))
mu$MorU <- ifelse(mu$MorU=="M", "make", "use")
makeuse <- split(mu, mu$MorU)

# (5) Create synthetic firms and local truck travel associated with them
firms <- create_synthetic_firms()
local_truck_origins <- local_truck_generation(firms, makeuse)
skimsFN <- file.path(RTP[["ct.working.folder"]], "offpeakcur.omx")
skim_distances <- readMatrixOMX(skimsFN, "DISTANCE")
local_daily_trucks <- sample_local_truck_destinations(local_truck_origins,
    skim_distances)

# (6) Run the FAF side of the model first, which will create daily truck trips
# based upon the annual sample for the target year.
faf35_data <- file.path(RTP[["ct.properties.folder"]], "faf35-idaho.csv")
faf_annual_trucks <- create_FAF_annual_truckloads(faf35_data)
faf_daily_regional_trucks <- sample_FAF_weekly_trucks(faf_annual_trucks)
faf_daily_alpha_trucks <- allocate_daily_FAF_to_firms(firms, faf_daily_regional_trucks)

# (7) Append the departure time for each trip in the tour. We will use the same
# temporal characteristics for both internal and external truck trips.
times_appended <- truck_trip_temporal_allocation(local_daily_trucks,
    faf_daily_alpha_trucks)

# (8) We will append the skim distance between origin and destination for all 
# truck trips, and then write the results to the final output file. It's orders
# of magnitude faster to dump the skim matrix to a data table and merge it than
# to look up each skim value in turn...
highest_zone_number <- dim(skim_distances)[1]
skim_table <- data.table(
    distance = as.vector(skim_distances),
    destination = as.integer(rep(1:highest_zone_number), highest_zone_number),
    origin = as.integer(rep(1:highest_zone_number, each=highest_zone_number))
)
skims_added <- merge(times_appended, skim_table, by=c("origin", "destination"),
    all.x=TRUE)

# (9) Finally, write the results to CSV file for the network assignment pre-
# processor to morph into trip matrices by time of day
final_results <- file.path(RTP[["ct.working.folder"]], RTP[["ct.truck.trips"]])
write.table(skims_added, file=final_results, sep=',', quote=FALSE, row.names=FALSE)
print(str_c(nrow(skims_added), " CT truck trips written to ", final_results), quote=FALSE)

# We are done. It's perhaps superfluous, but shut down the doParallel cluster
# before exiting stage left
stopCluster(ctCluster)
