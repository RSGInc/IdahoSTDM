# @tag{Create CT synthetic firms at the ITD traffic analysis zone level}
# Generate synthetic firms from alpha zone employment data.

create_synthetic_firms <- function() {
    require(data.table)
    require(reshape2)
    require(dplyr)
    require(stringr)
    require(foreign)
    print(str_c("------- create_synthetic_firms -------"), quote=FALSE)
    
    # Read the socioeconomic data
    FN <- RTP[["taz.csv"]]
    employees <- fread(FN, colClasses="integer") ##%>% select(-no_industry, -Total)
    
    # Aggregate employment into categories that we can map to directly. We are
    # not going to use the QRFM2 categories, so ignore the employment data
    # marked for that model. But first replace missing values with zeros.
    # TO-DO: Replace NA with zeros
    keep <- employees %>%
        mutate(EducationF = EduK12+EduHigh+EduOthers,    
            ServiceF = InfoF+FininsF+RealestF+ProftechF+MgmtF+WastadmnF+HealthF+OtherF,
            RetailF = RetailF+ArtsentF+FoodlodgF) %>%
        rename(Azone = STDM_TAZ, hhold = TOTHH_T) %>%
        select(Azone, hhold, AgforF, MiningF, UtilF, ConstrF, ManufF, WhlsaleF,
            RetailF, TrawhseF, EducationF, ServiceF, PublicF)
    
    # Converting from wide to tall format, so that we have a record for every
    # zone+sector pair.
    tall <- melt(keep, id.vars="Azone", variable.name="Sector", value.name="Employees")
    nonzero <- filter(tall, Employees>0)
    print(paste(nrow(tall), "tall records,", nrow(nonzero), "with non-zero values"),
        quote=FALSE)
    
    # Next we'll append the county the alpha zone falls within, from which we
    # can add FAF region
    zones <- read.csv(RTP[["taz.csv"]]) %>%
        filter(State=="Idaho") %>%
        rename(Azone = STDM_TAZ) %>%
        mutate(faf_region = 160, fips = NA) %>%
        select(Azone, faf_region, fips, County)
        
    # Finally, merge FAF region and county name with the socioeconomi data. Note
    # that we are only retaining zones within Idaho at this point.
    firms <- merge(nonzero, zones, by="Azone")
    firms$firmID <- seq(1, nrow(firms))
    print(paste(max(firms$firmID), "synthetic firms created"), quote=FALSE)
    
    # Write the results to CSV file if extended trace is requested
    if (RTP[["ct.extended.trace"]]=="TRUE") {
        FN <- file.path(RTP[["ct.working.folder"]], "ct-synthetic-firms.csv")
        write.table(firms, file=FN, sep=',', quote=FALSE, row.names=FALSE)
        print(str_c("Writing ", nrow(firms), " records to ", FN), quote=FALSE)
    }
    
    # Return the firms data table to the calling program
    print("", quote=FALSE)   # Add space before following report
    firms
}
