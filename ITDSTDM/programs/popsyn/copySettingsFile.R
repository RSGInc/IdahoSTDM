
#Copy popsyn settings file from inputs to outputs and replace
#%SQLSERVER% and %DATABASE% tokens with values from DOS variables
#Ben Stabler, ben.stabler@rsginc.com, 02/13/15
############################################################

INPUT_FOLDER <- Sys.getenv("INPUT_FOLDER")
OUTPUT_FOLDER <- Sys.getenv("OUTPUT_FOLDER")

fileName = paste(INPUT_FOLDER, "/popsyn/settings.xml", sep = "")
outFileName = paste(OUTPUT_FOLDER, "/settings.xml", sep = "")

settings = scan(fileName,what="", sep="\n")
settings = gsub("%SQLSERVER%",Sys.getenv("SQLSERVERJAVA"), settings, fixed=T)
settings = gsub("%DATABASE%",Sys.getenv("DATABASE"), settings)
writeLines(settings, outFileName)
