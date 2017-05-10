--Setting up TAZ, County and State level control tables for PopSynIII (Idaho Statewide Travel Demand Model)
--Sriram Narayanamoorthy, narayanamoorthys@pbworld.com, 112013
--Sujan  Sikder, sikders@pbworld.com, 08/13/2014

--This implementation of PopSyn uses these geographies
--	TAZ (ZONEGEOID)
--	County (COUNTYGEOID)
--	State (STATEFIPS)
--------------------------------------------------------------------
USE ITDPopSyn
GO

SET NOCOUNT ON;	

--Removing existing tables from previous runs
IF OBJECT_ID('dbo.control_totals_taz') IS NOT NULL 
	DROP TABLE control_totals_taz;
IF OBJECT_ID('dbo.control_totals_county') IS NOT NULL 
	DROP TABLE control_totals_county;
IF OBJECT_ID('dbo.control_totals_state') IS NOT NULL 
	DROP TABLE control_totals_state;
IF OBJECT_ID('tempdb..#zonalData') IS NOT NULL
	DROP TABLE #zonalData;
IF OBJECT_ID('tempdb..#countyData') IS NOT NULL 
	DROP TABLE #countyData;
IF OBJECT_ID('tempdb..#geographicCWalk') IS NOT NULL 
	DROP TABLE #geographicCWalk;
IF OBJECT_ID('tempdb..#stateData') IS NOT NULL 
	DROP TABLE #stateData;
		
/*###################################################################################################*/
--									INPUT FILE LOCATIONS
/*###################################################################################################*/

DECLARE @zonalData_File VARCHAR(256);
DECLARE @countyData_File VARCHAR(256);
DECLARE @geographicCWalk_File VARCHAR(256);
DECLARE @query VARCHAR(1000);

--Input files
SET @zonalData_File = (SELECT filename FROM csv_filenames WHERE dsc = 'zonalData_File');
SET @countyData_File = (SELECT filename FROM csv_filenames WHERE dsc = 'countyData_File');
SET @geographicCWalk_File = (SELECT filename FROM csv_filenames WHERE dsc = 'geographicCWalk_File');

/*###################################################################################################*/
--							  SETTING UP TEMPORARY TABLES FOR RAW INPUTS
/*###################################################################################################*/

CREATE TABLE #zonalData ([STATEFPS] INT
	,[COUNTYFPS] INT   
	,[CNTYIDFP00] INT  /*created from statefips and countyfips*/
	,[ZONEID] INT
	,[TOTPOP] REAL  
	,[TOTHH] REAL
	,[HHSIZE1] REAL
	,[HHSIZE2] REAL
	,[HHSIZE3] REAL
	,[HHSIZE4] REAL
	,[HHSIZE5] REAL
	,[HHSIZE6] REAL
	,[HHSIZE7] REAL
	,[HHWORK0] REAL
	,[HHWORK1] REAL
	,[HHWORK2] REAl
	,[HHWORK3] REAL
	,[CATINC1] REAL
	,[CATINC2] REAL
	,[CATINC3] REAL
	,[HHSIZE1_O] REAL
	,[HHWORK0_O] REAL
	,[HHINC1] REAL
	,[HHINC2] REAL
	,[HHINC3] REAL
	,[HHINC4] REAL
	,[HHINC5] REAL
	,[HHINC6] REAL
	,[HHINC7] REAL
	,[HHINC8] REAL
	,[HHINC9] REAL
	,[HHINC10] REAL
	,[HHINC11] REAL
	,[HHINC12] REAL
	,[HHINC13] REAL
	,[HHINC14] REAL
	,[HHINC15] REAL
	,[HHINC16] REAL
	
	CONSTRAINT [PK tempdb.zonalData County,ZoneID] PRIMARY KEY CLUSTERED (CNTYIDFP00,ZONEID)
);

SET @query = ('BULK INSERT #zonalData FROM ' + '''' + @zonalData_File + '''' + ' WITH (FIELDTERMINATOR = ' + 
				''',''' + ', ROWTERMINATOR = ' + '''\n''' + ', FIRSTROW = 2, MAXERRORS = 0, TABLOCK);');
EXEC(@query);


CREATE TABLE #countyData ( [CNTYIDFP00] INT 
	,[CTYPOP] INT
	,[AGE1] REAL
	,[AGE2] REAL
	,[AGE3] REAL
	,[AGE4] REAL
	,[AGE5] REAL
	,[AGE6] REAL
	,[AGE7] REAL
	,[AGE8] REAL
	,[AGE9] REAL
	,[AGE10] REAL
	,[AGE11] REAL
	,[AGE12] REAL
	,[OCCP1] REAL
	,[OCCP2] REAL
	,[OCCP3] REAL
	,[OCCP4] REAL
	,[OCCP5] REAL
	,[OCCP6] REAL
	,[OCCP7] REAL
	,[OCCP8] REAL
	,[OCCP9] REAL

);

SET @query = ('BULK INSERT #countyData FROM ' + '''' + @countyData_File + '''' + ' WITH (FIELDTERMINATOR = ' + 
				''',''' + ', ROWTERMINATOR = ' + '''\n''' + ', FIRSTROW = 2, MAXERRORS = 0, TABLOCK);');
EXEC(@query);


--Loading the geographic correspondence county->PUMA->state
CREATE TABLE #geographicCWalk([STATEFPS] INT, 
    [COUNTYFPS] INT,
	[CNTYIDFP00] INT,  
    [PUMA5CE00] INT,
	[PUMA] BIGINT,
)

SET @query = ('BULK INSERT #geographicCWalk FROM ' + '''' + @geographicCWalk_File + '''' + ' WITH (FIELDTERMINATOR = ' + 
				''',''' + ', ROWTERMINATOR = ' + '''\n''' + ', FIRSTROW = 2, MAXERRORS = 0, TABLOCK);');
EXEC(@query);

/*###################################################################################################*/
--									CREATING TAZ CONTROL TABLE
/*###################################################################################################*/
--Creating TAZ Controls
SELECT STATEFPS,COUNTYFPS,CNTYIDFP00,ZONEID,TOTPOP,TOTHH
        ,HHSIZE1,HHSIZE2,HHSIZE3,HHSIZE4,HHSIZE5,HHSIZE6,HHSIZE7
		,HHWORK0, HHWORK1, HHWORK2, HHWORK3
        ,CATINC1,CATINC2,CATINC3  
		 INTO control_totals_taz
FROM #zonalData

ALTER TABLE dbo.control_totals_taz
ADD  PUMACE00 INT
	,COUNTYGEOID BIGINT
	,ZONEGEOID BIGINT
	,PUMA INT
GO


ALTER TABLE dbo.control_totals_taz
	ADD CONSTRAINT [PK dbo.control_totals_taz County,ZoneID] 
	PRIMARY KEY (CNTYIDFP00,ZONEID)
GO

/*###################################################################################################*/
--									CREATING COUNTY CONTROL TABLE
/*###################################################################################################*/

ALTER TABLE #countyData
	ADD POP INT
	 ,pcAGE1 REAL 
	 ,pcAGE2 REAL 
	 ,pcAGE3 REAL 
	 ,pcAGE4 REAL 
	 ,pcAGE5 REAL 
	 ,pcAGE6 REAL 
	 ,pcAGE7 REAL 
	 ,pcAGE8 REAL 
	 ,pcAGE9 REAL 
	 ,pcAGE10 REAL
	 ,pcAGE11 REAL
	 ,pcAGE12 REAL
	 ,pcOOCP1 REAL
	 ,pcOOCP2 REAL
	 ,pcOOCP3 REAL
	 ,pcOOCP4 REAL
	 ,pcOOCP5 REAL
	 ,pcOOCP6 REAL
	 ,pcOOCP7 REAL
	 ,pcOOCP8 REAL
	 ,pcOOCP9 REAL
	 ,STATEFPS INT
	 ,PUMA INT
	 ,COUNTYGEOID BIGINT
	
GO

UPDATE #countyData
	SET pcAGE1  = (AGE1/CTYPOP)
	 ,pcAGE2  = (AGE2/CTYPOP)
	 ,pcAGE3  = (AGE3/CTYPOP)
	 ,pcAGE4  = (AGE4/CTYPOP)
	 ,pcAGE5  = (AGE5/CTYPOP)
	 ,pcAGE6  = (AGE6/CTYPOP)
	 ,pcAGE7  = (AGE7/CTYPOP)
	 ,pcAGE8  = (AGE8/CTYPOP)
	 ,pcAGE9  = (AGE9/CTYPOP)
	 ,pcAGE10 = (AGE10/CTYPOP)
	 ,pcAGE11 = (AGE11/CTYPOP)
	 ,pcAGE12 = (AGE12/CTYPOP)
	 ,pcOOCP1 = (OCCP1/CTYPOP)
	 ,pcOOCP2 = (OCCP2/CTYPOP)
	 ,pcOOCP3 = (OCCP3/CTYPOP)
	 ,pcOOCP4 = (OCCP4/CTYPOP)
	 ,pcOOCP5 = (OCCP5/CTYPOP)
	 ,pcOOCP6 = (OCCP6/CTYPOP)
	 ,pcOOCP7 = (OCCP7/CTYPOP)
	 ,pcOOCP8 = (OCCP8/CTYPOP)
	 ,pcOOCP9 = (OCCP9/CTYPOP)

UPDATE #countyData
	SET POP = t1.POP
	FROM (SELECT SUM(TOTPOP) AS POP, CNTYIDFP00 FROM control_totals_taz GROUP BY CNTYIDFP00) AS t1, 
		#countyData t2
	WHERE (t1.CNTYIDFP00 = t2.CNTYIDFP00)

UPDATE #countyData
	SET STATEFPS = t1.STATEFPS,
		PUMA = t1.PUMA
	FROM (SELECT DISTINCT STATEFPS, COUNTYFPS, CNTYIDFP00, PUMA5CE00, PUMA FROM #geographicCWalk) AS t1, 
		#countyData t2
	WHERE (t1.CNTYIDFP00 = t2.CNTYIDFP00)


SELECT STATEFPS,COUNTYGEOID,CNTYIDFP00,PUMA,POP,
	ROUND((POP*pcAGE1),0)  AS AGE1,
	ROUND((POP*pcAGE2),0)  AS AGE2,
	ROUND((POP*pcAGE3),0)  AS AGE3,
	ROUND((POP*pcAGE4),0)  AS AGE4,
	ROUND((POP*pcAGE5),0)  AS AGE5,
	ROUND((POP*pcAGE6),0)  AS AGE6,
	ROUND((POP*pcAGE7),0)  AS AGE7,
	ROUND((POP*pcAGE8),0)  AS AGE8,
	ROUND((POP*pcAGE9),0)  AS AGE9,
	ROUND((POP*pcAGE10),0) AS AGE10,
	ROUND((POP*pcAGE11),0) AS AGE11,
	ROUND((POP*pcAGE12),0) AS AGE12,
	ROUND((POP*pcOOCP1),0) AS OCCP1,
	ROUND((POP*pcOOCP2),0) AS OCCP2,
	ROUND((POP*pcOOCP3),0) AS OCCP3,
	ROUND((POP*pcOOCP4),0) AS OCCP4,
	ROUND((POP*pcOOCP5),0) AS OCCP5,
	ROUND((POP*pcOOCP6),0) AS OCCP6,
	ROUND((POP*pcOOCP7),0) AS OCCP7,
	ROUND((POP*pcOOCP8),0) AS OCCP8,
	ROUND((POP*pcOOCP9),0) AS OCCP9
INTO dbo.control_totals_county
FROM #countyData


/*###################################################################################################*/
--								CREATING STATE CONTROL TABLE
/*###################################################################################################*/

SELECT STATEFPS
	,SUM(TOTHH) AS TOTHH
INTO dbo.control_totals_state
FROM dbo.control_totals_taz
GROUP BY STATEFPS
ORDER BY STATEFPS

/*###################################################################################################*/
--							CREATING UNIQUE GEOGRAPHIC IDENTIFIERS 
/*###################################################################################################*/
UPDATE control_totals_county
	SET COUNTYGEOID = t1.CNTYIDFP00
	FROM (SELECT DISTINCT CNTYIDFP00 FROM #geographicCWalk) AS t1, 
		control_totals_county t2
	WHERE (t1.CNTYIDFP00 = t2.CNTYIDFP00)

UPDATE control_totals_taz
	SET COUNTYGEOID = t1.CNTYIDFP00,
		PUMA = t1.PUMA
	FROM (SELECT DISTINCT STATEFPS, COUNTYFPS, CNTYIDFP00, PUMA5CE00, PUMA FROM #geographicCWalk) AS t1, 
		control_totals_taz t2
	WHERE (t1.CNTYIDFP00 = t2.CNTYIDFP00)

UPDATE control_totals_taz SET ZONEGEOID = (COUNTYGEOID*10000)+ZONEID

/*Geographic identifiers for use within PopSyn
  NOTE: PopSyn needs identifiers to be of INT type Maximum value:2,147,483,648
		This is violated by the GEOID used by the Census Bureau to uniquely 
		identify geographies*/
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
ALTER TABLE dbo.control_totals_taz
   ADD MAZ INT IDENTITY 
   CONSTRAINT [UQ dbo.control_totals_taz MAZ] UNIQUE
   GO
COMMIT TRANSACTION
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
ALTER TABLE dbo.control_totals_county
   ADD TAZ INT IDENTITY 
   CONSTRAINT [UQ dbo.control_totals_county TAZ] UNIQUE
   GO
COMMIT TRANSACTION
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

--Some housekeeping
ALTER INDEX ALL ON dbo.control_totals_taz
REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON,
              STATISTICS_NORECOMPUTE = ON);
GO

ALTER INDEX ALL ON dbo.control_totals_county
REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON,
              STATISTICS_NORECOMPUTE = ON);
GO

ALTER INDEX ALL ON dbo.control_totals_state
REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON,
              STATISTICS_NORECOMPUTE = ON);
GO

--Linking zones to counties based on the geographic ID just generated
ALTER TABLE dbo.control_totals_taz
   ADD TAZ INT 
   GO

UPDATE B
SET TAZ = T.TAZ
FROM dbo.control_totals_county AS T
JOIN dbo.control_totals_taz AS B
    ON T.COUNTYGEOID = B.COUNTYGEOID
OPTION (LOOP JOIN);

SELECT * FROM control_totals_taz
SELECT * FROM control_totals_county
SELECT * FROM control_totals_state