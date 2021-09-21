# Run pcvmodr for Idaho statewide model
library(tidyverse); library(pcvmodr); library(doParallel); library(rhdf5)
library(omxr)

# Read arguments
faf_year <- 2013
args = commandArgs(trailingOnly=TRUE)
if(length(args)){
	faf_year <- as.integer(args[1])
}

# Read the runtime parameters
runtime_parameters <- "./inputs/ct/prelim_parameters.txt"
RTP <<- pcvmodr::get_runtime_parameters(runtime_parameters)

# Start the doParallel cluster
myCluster <- parallel::makeCluster(min(parallel::detectCores(),as.integer(RTP[["ct_parallel_cores"]])),
  outfile = file.path(RTP[["scenario_folder"]], "myCluster.log"))
doParallel::registerDoParallel(myCluster)
print(paste("doParallel cluster instance started with", getDoParWorkers(),
  "cores"), quote = FALSE)

# Read the FAF v4.x database for the given year and associated files
outer_regions <- RTP[["faf_outer_regions"]] %>%
  readr::read_csv(comment = '#') %>%
  dplyr::select(-description, -state) %>%
  dplyr::mutate(entry = NA, exit = NA)
faf_flows <- pcvmodr::preprocess_faf4_database(RTP[["faf_regional_database"]], 
  faf_year, FALSE, 160, outer_regions)

# Create annual and daily FAF truckload equivalents
annual_trucks <- pcvmodr::create_faf4_annual_truckloads(faf_flows)
daily_trucks <- pcvmodr::sample_faf4_daily_trucks(annual_trucks)

# Allocate the truck flows from FAF regions to traffic analysis zones for
# assignment.
synthetic_firms <- pcvmodr::read_file(RTP[["synthetic_firms"]])
generation_rates <- pcvmodr::read_file(RTP[["generation_probabilities"]])
zonal_attractions <- pcvmodr::calculate_zonal_attractions(synthetic_firms,
  generation_rates)
zonal_equivalencies <- pcvmodr::read_file(RTP[["faf_region_equivalencies"]])
allocated_trips <- pcvmodr::allocate_faf4_truckloads(daily_trucks, 160,
  zonal_attractions, zonal_equivalencies)
temporal_distributions <- pcvmodr::read_file(RTP[["temporal_distributions"]])
interregional_trips <- pcvmodr::trip_temporal_allocation(allocated_trips,
  temporal_distributions)

# Calculate the local truck tour components
local_origins <- pcvmodr::qrfm2_truck_generation(synthetic_firms,
  generation_rates)
trip_length_targets <- pcvmodr::read_file(RTP[["trip_length_targets"]])
skim_distances <- RTP[["skim_matrices"]] %>%
  omxr::read_omx(., "DISTANCE") %>%
  omxr::long_matrix()
add_destinations <- pcvmodr::sample_local_destinations(local_origins,
  skim_distances, trip_length_targets)
local_trips <- pcvmodr::trip_temporal_allocation(add_destinations,
  temporal_distributions)

# Export them to file format required for Cube import
combined_trips <- dplyr::bind_rows(interregional_trips, local_trips)
exported <- pcvmodr::export_trip_matrices(combined_trips)
filename <- file.path(RTP[["scenario_folder"]], "exported_truck_trips.csv")
pcvmodr::write_file(exported, filename)

# When we're done shut down the doParallel cluster
stopCluster(myCluster)
