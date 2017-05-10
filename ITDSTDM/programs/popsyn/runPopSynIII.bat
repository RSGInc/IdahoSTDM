
REM # Batch file to run PopSynIII
REM # Sriram Narayanamoorthy, narayanamoorthys@pbworld.com, 2013-12-10
REM # Sujan Sikder, sikders@pbworld.com, 08/13/2014
REM # Ben Stabler, ben.stabler@rsginc.com, 02/10/15
REM ###########################################################################

SET MY_PATH=%CD%
SET pumsHH_File='%MY_PATH%/inputs/popsyn/ss11hid.csv'
SET pumsPersons_File='%MY_PATH%/inputs/popsyn/ss11pid.csv'
SET countyData_File='%MY_PATH%/inputs/popsyn/countyData.csv'
SET geographicCWalk_File='%MY_PATH%/inputs/popsyn/geographicCWalk.csv'
SET swOccup_File='%MY_PATH%/inputs/popsyn/swOccupCat.csv'
SET zonalData_File='%MY_PATH%/outputs/zonalData.csv'

REM ###########################################################################

@ECHO OFF
ECHO Idaho Statewide PopSyn III

ECHO Processing input tables...
MKDIR outputs
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "IF OBJECT_ID('dbo.csv_filenames') IS NOT NULL DROP TABLE csv_filenames;" -o "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "CREATE TABLE csv_filenames(dsc varchar(100), filename varchar(256));" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "INSERT INTO csv_filenames(dsc, filename) VALUES ('pumsHH_File', %pumsHH_File%);" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "INSERT INTO csv_filenames(dsc, filename) VALUES ('pumsPersons_File', %pumsPersons_File%);" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "INSERT INTO csv_filenames(dsc, filename) VALUES ('swOccup_File', %swOccup_File%);" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "INSERT INTO csv_filenames(dsc, filename) VALUES ('zonalData_File', %zonalData_File%);" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "INSERT INTO csv_filenames(dsc, filename) VALUES ('countyData_File', %countyData_File%);" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "INSERT INTO csv_filenames(dsc, filename) VALUES ('geographicCWalk_File', %geographicCWalk_File%);" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -i "%MY_PATH%\programs\popsyn\PUMS Table creation.sql" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -i "%MY_PATH%\programs\popsyn\importControls.sql" >> "%MY_PATH%\outputs\serverLog"

REM ###########################################################################

ECHO %startTime%%Time%
ECHO Running population synthesizer...
SET CLASSPATH=runtime\config;runtime\*;runtime\lib\*;runtime\lib\JPFF-3.2.2\JPPF-3.2.2-admin-ui\lib\*
SET LIBPATH=runtime\lib

CD programs\popsyn
java -showversion -server -Xms256m -Xmx2048m -cp %CLASSPATH% -Djppf.config=jppf-clientLocal.properties -Djava.library.path=%LIBPATH% popGenerator.PopGenerator ..\..\outputs\settings.xml 
ECHO Population synthesis complete...
CD ..\..

REM ###########################################################################

ECHO Create %SCENARIO% schema and output CSV files
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "IF OBJECT_ID('%SCENARIO%.control_totals_taz') IS NOT NULL DROP TABLE %SCENARIO%.control_totals_taz;" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "IF OBJECT_ID('%SCENARIO%.control_totals_county') IS NOT NULL DROP TABLE %SCENARIO%.control_totals_county;" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "IF OBJECT_ID('%SCENARIO%.control_totals_state') IS NOT NULL DROP TABLE %SCENARIO%.control_totals_state;" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "IF OBJECT_ID('%SCENARIO%.households') IS NOT NULL DROP TABLE %SCENARIO%.households;" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "IF OBJECT_ID('%SCENARIO%.persons') IS NOT NULL DROP TABLE %SCENARIO%.persons;" >> "%MY_PATH%\outputs\serverLog"

SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "IF EXISTS (SELECT * FROM sys.schemas WHERE name = '%SCENARIO%') DROP SCHEMA %SCENARIO%;" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "CREATE SCHEMA %SCENARIO%;" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -i "%MY_PATH%\programs\popsyn\outputs.sql" >> "%MY_PATH%\outputs\serverLog"

SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "SELECT * INTO %SCENARIO%.control_totals_taz FROM dbo.control_totals_taz;" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "SELECT * INTO %SCENARIO%.control_totals_county FROM dbo.control_totals_county;" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "SELECT * INTO %SCENARIO%.control_totals_state FROM dbo.control_totals_state;" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "SELECT * INTO %SCENARIO%.persons FROM dbo.persons;" >> "%MY_PATH%\outputs\serverLog"
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -Q "SELECT * INTO %SCENARIO%.households FROM dbo.households;" >> "%MY_PATH%\outputs\serverLog"

REM # remove row with ----- in SQL tables
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -s, -W -Q "SET NOCOUNT ON; SELECT * FROM dbo.persons" >  "%MY_PATH%\outputs\persons.tmp"
TYPE %MY_PATH%\outputs\persons.tmp | findstr /r /v ^\-[,\-]*$ > %MY_PATH%\outputs\persons2.tmp 
REM # Replace NULL with -9 and N.A. with -8
@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion
(FOR /f "tokens=*" %%f IN (%MY_PATH%\outputs\persons2.tmp) DO IF NOT "%%f"=="" (
        SET "line=%%f"
        SET "line=!line:NULL=-9!"
        SET "line=!line:N.A.=-8!"
        ECHO(!line!
)) > %MY_PATH%\outputs\persons.csv
ENDLOCAL
DEL %MY_PATH%\outputs\persons.tmp
DEL %MY_PATH%\outputs\persons2.tmp

SQLCMD -S %SQLSERVER% -d %DATABASE% -E -s, -W -Q "SET NOCOUNT ON; SELECT * FROM dbo.households" >  "%MY_PATH%\outputs\households.tmp"
TYPE %MY_PATH%\outputs\households.tmp | findstr /r /v ^\-[,\-]*$ > %MY_PATH%\outputs\households2.tmp
REM # Replace NULL with -9 and N.A. with -8
@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion
(FOR /f "tokens=*" %%f IN (%MY_PATH%\outputs\households2.tmp) DO IF NOT "%%f"=="" (
        SET "line=%%f"
        SET "line=!line:NULL=-9!"
        SET "line=!line:N.A.=-8!"
        ECHO(!line!
)) > %MY_PATH%\outputs\households.csv
ENDLOCAL
DEL %MY_PATH%\outputs\households.tmp
DEL %MY_PATH%\outputs\households2.tmp

REM # Creating a cross walk between Census GEOIDs and PopSyn geographies
SQLCMD -S %SQLSERVER% -d %DATABASE% -E -s, -W -Q "SET NOCOUNT ON; SELECT STATEFPS, COUNTYFPS, COUNTYGEOID, ZONEGEOID, MAZ, TAZ, ZONEID FROM dbo.control_totals_taz" >  "%MY_PATH%\outputs\CW_CensusID.tmp"
TYPE %MY_PATH%\outputs\CW_CensusID.tmp | findstr /r /v ^\-[,\-]*$ > %MY_PATH%\outputs\CW_CensusID.csv 
DEL %MY_PATH%\outputs\CW_CensusID.tmp
