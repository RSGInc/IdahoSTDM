:: RunModel.bat
:: DOS batch file to execute the ITD Statewide Travel Demand Model
:: Ben Stabler, ben.stabler@rsginc.com 02/09/15
:: 
:: Steps
:: 0) File and Folder Setup
:: 1) Build Properties Files and Process Files
:: 2) Run PopSyn if needed
:: 3) Generate initial hwy skims
:: 4) Run freight demand model
:: 5) Run external model
:: Loop up to MAX_ITER
::   6) Run person demand model
::   7) Build demand matrices
::   8) Run hwy assignment
:: 9) TREDIS output report

:: -----------------------------------------------------------------------------
:: 
:: Step 0:  File and Folder Setup
:: 
:: -----------------------------------------------------------------------------

:: Run PopSyn? TRUE or FALSE
SET POPSYN=FALSE

:: The model year for TREDIS and externals
SET MODEL_YEAR=2010

:: The HIGHEST TAZ ID
SET NZONES=6035

:: The location of 64-bit java, RunTpp (Cube), and R
SET JAVA_PATH=C:\Program Files\Java\jre1.8.0_31\bin
SET TPP_PATH=C:\Program Files (x86)\Citilabs\CubeVoyager
SET R_PATH=C:\Program Files\R\R-3.1.2\bin

:: Number of max model feedback iterations and assignment iterations
SET MAX_ITER=3
SET ASSIGN_ITER=100

:: Set PT household sample rate by iteration (every 1 in Nth)
SET SAMPLERATE_ITERATION1=4
SET SAMPLERATE_ITERATION2=2
SET SAMPLERATE_ITERATION3=1
SET SAMPLERATE_ITERATION4=1
SET SAMPLERATE_ITERATION5=1

:: PopSyn database settings
SET SCENARIO=BaseYear
SET SQLSERVER=ITD9HPLPC217218\SQLEXPRESS
SET DATABASE=ITDPopSyn

:: Setup system path
SET WORKDIR=%CD%
SET OLD_PATH=%PATH%
SET PATH=%JAVA_PATH%;%TPP_PATH%;%R_PATH%;%OLD_PATH%

:: Create the output directory
MKDIR outputs

:: -----------------------------------------------------------------------------
::
:: Step 1:  Build Properties Files and Process Files
::
:: -----------------------------------------------------------------------------

:: Date and time of the model start
ECHO STARTED MODEL RUN  %DATE% %TIME%
Rscript programs/pt/createTazDataFiles.R

:: -----------------------------------------------------------------------------
::
:: Step 2:  Run PopSyn if needed
::
:: -----------------------------------------------------------------------------

:: Run population synthesizer with new TAZ data
IF %POPSYN%==TRUE (
  ECHO RUN POPSYN  %DATE% %TIME%
  Rscript programs/popsyn/copySettingsFile.R
  CALL programs/popsyn/runPopSynIII.bat
  Rscript programs/popsyn/PopSynIII_to_PopSyn0_V3.R   
)

:: -----------------------------------------------------------------------------
::
:: Step 3:  Generate initial hwy skims
::
:: -----------------------------------------------------------------------------

:: Code link area type for capacity calculation
:: Run offpeak highway skimming and copy for peak and assigned version
runtpp programs/cube/link_area_type.s
runtpp programs/cube/offPeakSkims.s
IF ERRORLEVEL 2 GOTO DONE

:: -----------------------------------------------------------------------------
::
:: Step 4:  Run freight demand model
::
:: -----------------------------------------------------------------------------

:: Convert Cube skims to OMX
programs\cube\cube2omx.exe  outputs\offpeakcur.mat
programs\cube\cube2omx.exe  outputs\peakcur.mat

:: Run the freight demand model
Rscript programs/ct/RunCT.R 
Rscript programs/ct/buildTripMatrices.R
Rscript programs/ct/build_truck_matrices_omx.R
programs\cube\cube2omx.exe  outputs\truck_trips.omx

:: -----------------------------------------------------------------------------
::
:: Step 5:  Run external model
::
:: -----------------------------------------------------------------------------

:: Build external travel demand
runtpp programs/cube/external.s
IF ERRORLEVEL 2 GOTO DONE

:: -----------------------------------------------------------------------------
::
:: Loop
::
:: -----------------------------------------------------------------------------

SET /A ITERATION=0
:ITER_START
SET /A ITERATION+=1
ECHO ****MODEL ITERATION %ITERATION%

:: Method of Successive Average Network LOS Skims
runtpp programs/cube/msaSkims.s

:: -----------------------------------------------------------------------------
::
:: Step 6:  Run person demand model
::
:: -----------------------------------------------------------------------------

IF %ITERATION% EQU 1 SET PTSAMPLERATE=%SAMPLERATE_ITERATION1%
IF %ITERATION% EQU 2 SET PTSAMPLERATE=%SAMPLERATE_ITERATION2%
IF %ITERATION% EQU 3 SET PTSAMPLERATE=%SAMPLERATE_ITERATION3%
IF %ITERATION% EQU 4 SET PTSAMPLERATE=%SAMPLERATE_ITERATION4%
IF %ITERATION% EQU 5 SET PTSAMPLERATE=%SAMPLERATE_ITERATION5%

IF EXIST "outputs/fileMonitor_event.log" DEL "outputs/fileMonitor_event.log"
IF EXIST "outputs/node0_event.log" DEL "outputs/node0_event.log"
IF EXIST "outputs/JavaLog.log" DEL "outputs/JavaLog.log"

Rscript programs/pt/copyPropertiesFile.R

START "-Dnode = 0" java -cp "programs/pt/pt_idaho.jar;programs/pt" "-Dlog4j.configuration=info_log4j_fileMonitor.xml" -server com.pb.common.daf.admin.FileMonitor "programs/pt/commandFile.txt" "programs/pt/startnode0.properties"
CMD /C "ping 127.0.0.1 -n 10 > NUL"
java -cp "programs/pt/pt_idaho.jar;programs/pt" -Xmx250m "-Dlog4j.configuration=info_log4j.xml" -server com.pb.idaho.ao.ModelEntry PT "property_file=outputs/pt.properties"
TASKKILL /IM "java.exe" /F

:: -----------------------------------------------------------------------------
::
:: Step 7:  Build demand matrices
::
:: -----------------------------------------------------------------------------

Rscript programs/pt/build_demand_matrices.R %NZONES% %PTSAMPLERATE%
programs\cube\cube2omx.exe outputs/pt_trips.omx

:: -----------------------------------------------------------------------------
::
:: Step 8:  Run hwy assignment
::
:: -----------------------------------------------------------------------------

runtpp programs/cube/hwyAssign.s
IF ERRORLEVEL 2 GOTO DONE

IF %ITERATION% LSS %MAX_ITER% GOTO ITER_START

:: -----------------------------------------------------------------------------
::
:: Step 9:  TREDIS output report
::
:: -----------------------------------------------------------------------------

::tredis inputs script 
runtpp programs/cube/tredis_inputs.s
IF ERRORLEVEL 2 GOTO DONE

:: -----------------------------------------------------------------------------
::
:: Done
::
:: -----------------------------------------------------------------------------

ECHO MODEL COMPLETE

:: Complete target
:DONE

:: Reset the system PATH
SET PATH=%OLD_PATH%

ECHO FINISHED
