
#Copy PT properties file from inputs to outputs and replace
#%WORKDIR% and %PTSAMPLERATE% tokens with values from DOS variables
#Ben Stabler, ben.stabler@rsginc.com, 02/13/15
############################################################

fileName = "inputs/pt.properties"
outFileName = "outputs/pt.properties"

pt = scan(fileName,what="", sep="\n")
pt = gsub("%WORKDIR%",Sys.getenv("WORKDIR"), pt, fixed=T)
pt = gsub("%PTSAMPLERATE%",Sys.getenv("PTSAMPLERATE"), pt)
writeLines(pt, outFileName)