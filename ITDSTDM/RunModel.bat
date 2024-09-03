@ECHO OFF
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

SET INPUT_FOLDER=inputs2020
SET OUTPUT_FOLDER=outputs_2020

:: Run PopSyn? TRUE or FALSE if FALSE, make sure you have the base or future person/hh info in the output file
SET POPSYN=TRUE

:: The model year for TREDIS and externals
SET MODEL_YEAR=2020

:: The number of tazs, FALSE!  It is the HIGHEST TAZ ID, not the number of them !!
SET NZONES=6035

:: The location of 64-bit java, RunTpp (Cube), and R
SET JAVA_PATH=C:\Program Files\Java\jre1.8.0_201\bin
SET TPP_PATH=C:\Program Files (x86)\Citilabs\CubeVoyager
SET R_PATH=C:\Program Files\R\R-4.4.1\bin

:: Number of max model feedback iterations and assignment iterations
SET MAX_ITER=3
SET ASSIGN_ITER=100
SET assign_threads=20


:: Set PT household sample rate by iteration (every 1 in Nth)
SET SAMPLERATE_ITERATION1=4
SET SAMPLERATE_ITERATION2=2
SET SAMPLERATE_ITERATION3=1
SET SAMPLERATE_ITERATION4=1
SET SAMPLERATE_ITERATION5=1

:: PopSyn database settings
SET SCENARIO=BaseYear
SET SQLSERVER=localhost\SQLEXPRESS
SET DATABASE=ITDPopSynIII

:: Setup system path
SET WORKDIR=%CD%
SET OLD_PATH=%PATH%
SET PATH=%JAVA_PATH%;%TPP_PATH%;%R_PATH%;%OLD_PATH%

:: Create the output directory
IF NOT EXIST %OUTPUT_FOLDER% MKDIR %OUTPUT_FOLDER%

:: First Input Check - 
 
call C:\Users\%USERNAME%\AppData\Local\anaconda3\Scripts\activate.bat py312
python .\programs\python\input_checker.py --group=1
IF NOT ERRORLEVEL 0 GOTO DONE
conda deactivate

runtpp programs\cube\unbuild_net.s
GOTO DONE

:: -----------------------------------------------------------------------------
::
:: Step 1:  Build Properties Files and Process Files
::
:: -----------------------------------------------------------------------------
GOTO starthere
:: Date and time of the model start
ECHO STARTED MODEL RUN  %DATE% %TIME%
SET ERRORLEVEL=0
Rscript programs/pt/createTazDataFiles.R
IF NOT ERRORLEVEL 0 GOTO DONE

:: -----------------------------------------------------------------------------
::
:: Step 2:  Run PopSyn if needed
::
:: -----------------------------------------------------------------------------

:: Run population synthesizer with new TAZ data
IF %POPSYN% == TRUE (
  SET ERRORLEVEL=0
  ECHO RUN POPSYN  %DATE% %TIME%
  REM Rscript programs/popsyn/copySettingsFile.R
  IF NOT ERRORLEVEL 0 GOTO DONE
  REM CALL programs/popsyn/runPopSynIII.bat
  IF NOT ERRORLEVEL 0 GOTO DONE
  Rscript programs/popsyn/PopSynIII_to_PopSyn0_V3.R
  IF NOT ERRORLEVEL 0 GOTO DONE
)

:: -----------------------------------------------------------------------------
::
:: Step 3:  Generate initial hwy skims
::
:: -----------------------------------------------------------------------------

:: Code link area type for capacity calculation
:: Run offpeak highway skimming and copy for peak and assigned version
runtpp programs/cube/link_area_type.s
IF ERRORLEVEL 2 GOTO DONE
runtpp programs/cube/offPeakSkims.s
IF ERRORLEVEL 2 GOTO DONE

:: -----------------------------------------------------------------------------
::
:: Step 4:  Run freight demand model
::
:: -----------------------------------------------------------------------------

:: Convert Cube skims to OMX
programs\cube\cube2omx.exe  %OUTPUT_FOLDER%\offpeakcur.mat
IF ERRORLEVEL 2 GOTO DONE
programs\cube\cube2omx.exe  %OUTPUT_FOLDER%\peakcur.mat
IF ERRORLEVEL 2 GOTO DONE

:: Run the freight demand model
:: Write the parameters (to allow for different input and output folders)
ECHO scenario_folder = "./%OUTPUT_FOLDER%" > "%INPUT_FOLDER%\CT\prelim_parameters.txt"
ECHO synthetic_firms = "./%INPUT_FOLDER%/ct/idaho_pseudo_firms.csv" >> "%INPUT_FOLDER%\CT\prelim_parameters.txt"
ECHO faf_regional_database = "./%INPUT_FOLDER%/ct/FAF4.4.1.zip" >> "%INPUT_FOLDER%\CT\prelim_parameters.txt"
ECHO faf_outer_regions = "./%INPUT_FOLDER%/ct/idaho_outer_states.csv" >> "%INPUT_FOLDER%\CT\prelim_parameters.txt"
ECHO faf_region_equivalencies = "./%INPUT_FOLDER%/ct/faf44_zonal_equivalencies.csv" >> "%INPUT_FOLDER%\CT\prelim_parameters.txt"
ECHO truck_allocation_factors = "./%INPUT_FOLDER%/ct/faf35_truck_allocation_factors.csv" >> "%INPUT_FOLDER%\CT\prelim_parameters.txt"
ECHO truck_equivalency_factors = "./%INPUT_FOLDER%/ct/faf35_truck_equivalency_factors.csv" >> "%INPUT_FOLDER%\CT\prelim_parameters.txt"
ECHO empty_truck_factors = "./%INPUT_FOLDER%/ct/faf35_empty_truck_factors.csv" >> "%INPUT_FOLDER%\CT\prelim_parameters.txt"
ECHO generation_probabilities = "./%INPUT_FOLDER%/ct/qrfm2_generation_rates.csv" >> "%INPUT_FOLDER%\CT\prelim_parameters.txt"
ECHO temporal_distributions = "./%INPUT_FOLDER%/ct/truck_temporal_distributions.csv" >> "%INPUT_FOLDER%\CT\prelim_parameters.txt"
ECHO skim_matrices = "./%OUTPUT_FOLDER%/offpeakcur.omx" >> "%INPUT_FOLDER%\CT\prelim_parameters.txt"
ECHO trip_length_targets = "./%INPUT_FOLDER%/ct/fitted_trip_length_distributions.csv" >> "%INPUT_FOLDER%\CT\prelim_parameters.txt"

:: Run the freight demand model
SET ERRORLEVEL=0
REM Rscript programs/ct/run_idaho.R %MODEL_YEAR%
IF NOT ERRORLEVEL 0 GOTO DONE

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
IF ERRORLEVEL 2 GOTO DONE

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

IF EXIST "%OUTPUT_FOLDER%/fileMonitor_event.log" DEL "%OUTPUT_FOLDER%/fileMonitor_event.log"
IF EXIST "%OUTPUT_FOLDER%/node0_event.log" DEL "%OUTPUT_FOLDER%/node0_event.log"
IF EXIST "%OUTPUT_FOLDER%/JavaLog.log" DEL "%OUTPUT_FOLDER%/JavaLog.log"

SET ERRORLEVEL=0
Rscript programs/pt/copyPropertiesFile.R
IF NOT ERRORLEVEL 0 GOTO DONE

START "-Dnode = 0" java -cp "programs/pt/pt_idaho.jar;programs/pt" "-Dlog4j.configuration=info_log4j_fileMonitor.xml" -server com.pb.common.daf.admin.FileMonitor "programs/pt/commandFile.txt" "programs/pt/startnode0.properties"
CMD /C "ping 127.0.0.1 -n 10 > NUL"
IF ERRORLEVEL 2 GOTO DONE
java -cp "programs/pt/pt_idaho.jar;programs/pt" -Xmx250m "-Dlog4j.configuration=info_log4j.xml" -server com.pb.idaho.ao.ModelEntry PT "property_file=%OUTPUT_FOLDER%/pt.properties"
IF ERRORLEVEL 2 GOTO DONE
TASKKILL /IM "java.exe" /F

::DEBUG
:starthere
:: -----------------------------------------------------------------------------
::
:: Step 7:  Build demand matrices
::
:: -----------------------------------------------------------------------------

SET ERRORLEVEL=0
Rscript programs/pt/build_demand_matrices.R %NZONES% %PTSAMPLERATE%
IF NOT ERRORLEVEL 0 GOTO DONE
programs\cube\cube2omx.exe "%OUTPUT_FOLDER%/pt_trips.omx"
IF ERRORLEVEL 2 GOTO DONE

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
:: Step 10:  Output a single network with all the time periods + LOS and copy to shapefile
::
:: -----------------------------------------------------------------------------

:: Combine networks AM,MD,PM,NT into a single network
:: Create a shapefile version of this single network
runtpp programs/cube/netmerge.s
IF ERRORLEVEL 2 GOTO DONE
runtpp programs/cube/net2shp.s
IF ERRORLEVEL 2 GOTO DONE

:: -----------------------------------------------------------------------------
::
:: Done
::
:: -----------------------------------------------------------------------------

ECHO MODEL COMPLETE
GOTO SUCCESS

:: Complete target
:DONE
ECHO MODEL ERROR AND DID NOT FINISH SUCCESSFULLY > "model_error.txt"

:SUCCESS
ECHO MODEL FINISH SUCCESSFULLY > "model_success.txt"
:: Reset the system PATH
SET PATH=%OLD_PATH%

ECHO FINISHED
