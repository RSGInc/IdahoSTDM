
#Copy PT properties file from inputs to outputs and replace
#%WORKDIR% and %PTSAMPLERATE% tokens with values from DOS variables
#Ben Stabler, ben.stabler@rsginc.com, 02/13/15
#Updated for paths, Andrew Rohne, andrew.rohne@rsginc.com, 7/18/24
############################################################

INPUT_FOLDER <- Sys.getenv("INPUT_FOLDER")
OUTPUT_FOLDER <- Sys.getenv("OUTPUT_FOLDER")
WORK_DIR <- Sys.getenv("WORKDIR")

file_names1 = c("pt.properties")
file_names2 = c("info_log4j.xml", "info_log4j_fileMonitor.xml", "info_log4j_node0.xml", "RunParams.properties")

for(f in file_names1){
	fileName = file.path(INPUT_FOLDER, f)
	outFileName = file.path(OUTPUT_FOLDER, f)
	pt = scan(fileName,what="", sep="\n")
	pt = gsub("%WORKDIR%",WORK_DIR, pt, fixed=T)
	pt = gsub("%INPUT_FOLDER%",INPUT_FOLDER, pt, fixed=T)
	pt = gsub("%OUTPUT_FOLDER%",Sys.getenv("OUTPUT_FOLDER"), pt, fixed=T)

	pt = gsub("%PTSAMPLERATE%",Sys.getenv("PTSAMPLERATE"), pt)
	writeLines(pt, outFileName)
}

for(f in file_names2){
	fileName = file.path(INPUT_FOLDER, f)
	outFileName = file.path(WORK_DIR, "programs", "pt", f)
	pt = scan(fileName,what="", sep="\n")
	pt = gsub("%WORKDIR%",WORK_DIR, pt, fixed=T)
	pt = gsub("%INPUT_FOLDER%",INPUT_FOLDER, pt, fixed=T)
	pt = gsub("%OUTPUT_FOLDER%",OUTPUT_FOLDER, pt, fixed=T)

	pt = gsub("%PTSAMPLERATE%",Sys.getenv("PTSAMPLERATE"), pt)
	writeLines(pt, outFileName)
}