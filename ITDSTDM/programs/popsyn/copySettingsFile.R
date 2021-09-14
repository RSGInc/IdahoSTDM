
#Copy popsyn settings file from inputs to outputs and replace
#%SQLSERVER% and %DATABASE% tokens with values from DOS variables
#Ben Stabler, ben.stabler@rsginc.com, 02/13/15
############################################################

fileName = "inputs/popsyn/settings.xml"
outFileName = "outputs/settings.xml"

settings = scan(fileName,what="", sep="\n")
settings = gsub("%SQLSERVER%",Sys.getenv("SQLSERVERJAVA"), settings, fixed=T)
settings = gsub("%DATABASE%",Sys.getenv("DATABASE"), settings)
writeLines(settings, outFileName)
