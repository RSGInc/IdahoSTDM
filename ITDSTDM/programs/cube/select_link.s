;Link Selector ... adapted from the External model
;Ben Stabler, ben.stabler@rsginc.com, 02/10/15
;Sujan Sikder, sikders@pbworld.com, 03/2/15,3/13/2015,3/17/2015
;David Coladner, david.coladner@itd.idaho.gov, 05/07/2019

;Input files: 
; 1) Adjusted_Trips.MAT(phase-1 model output matrix) or seed.mat (if application mode, seed is input instead of created)
; 2) itd.net(itd network)

;Output file: 
; 1) selectlinks.mat ;contains I-E, E-I and E-E trips in matrix format
; 2) selectlinkTrips.csv ;total trips by selectlink stations in table format

;Steps:
;  Create seed
; 1) Aggregate the phase-1 model trip tables
; 2) Get the O-D flows that use each external station link 
; 9) Output the total trips that use the selected link(s)

;----------------------------------------------------------------------------------------------
;Parameters
;----------------------------------------------------------------------------------------------
 
 NZONES = 5727 ;no. of zones
 MAXITERANS = 100 ;no. of iterations in the assignment proecedure 
 HWYNET = 'itd_baseline.net' ;itd network file
 gap = 0.0001 ; relative gap setting
numthreads = 36 ; number of threads for assignment

 COMP all_zones = '1-%NZONES%';external stations

;----------------------------------------------------------------------------------------------
;Step 1: Aggregate the phase-1 model trip tables
;----------------------------------------------------------------------------------------------

 RUN PGM=MATRIX

    ;FILEI MATI[1]= inputs\Adjusted_Trips.mat
    ;FILEI MATI[1]= outputs\AMPeakTrips.mat
    ;FILEI MATI[2]= outputs\MDPeakTrips.mat
    ;FILEI MATI[3]= outputs\PMPeakTrips.mat
    ;FILEI MATI[4]= outputs\NTPeakTrips.mat
    FILEI MATI[1]= outputs\PMPeakTrips_baseline.mat
    FILEO MATO[1]= outputs\total.mat,MO=1,Name = TOTAL

    ;MW[1] = MI.1.1 + MI.1.2 + MI.1.3 + MI.1.4 + MI.1.5 ;auto(1-4)+truck(5)
    MW[1] = MI.1.1 + MI.1.2 + MI.1.3 + MI.1.4 + MI.1.5 + MI.1.6 + MI.1.7 + MI.1.8 + MI.1.9 ;auto(1-3,7-9)+truck(4-5)+EXT(6)
    ;MW[1] = MI.1.1 + MI.1.2 + MI.1.3 + MI.1.4 + MI.1.5 + MI.1.6 + MI.1.7 + MI.1.8 + MI.1.9 +
    ; MI.2.1 + MI.2.2 + MI.2.3 + MI.2.4 + MI.2.5 + MI.2.6 + MI.2.7 + MI.2.8 + MI.2.9 +
    ; MI.3.1 + MI.3.2 + MI.3.3 + MI.3.4 + MI.3.5 + MI.3.6 + MI.3.7 + MI.3.8 + MI.3.9 +
    ; MI.4.1 + MI.4.2 + MI.4.3 + MI.4.4 + MI.4.5 + MI.4.6 + MI.4.7 + MI.4.8 + MI.4.9 ;auto(1-3,7-9)+truck(4-5)+EXT(6)
   
 ENDRUN

;----------------------------------------------------------------------------------------------
;Step 2: Get the O-D flows that use selected link(s) 
;----------------------------------------------------------------------------------------------
; selectlink=(L=11585-11603,140878-140867) for I-84 between Glens Ferry and Bliss
; selectlink=(L=79784-79785*) for I-84 Business in front of Karcher Mall
; selectlink=(L=83683-83686*) for US-20 in front of HP
; selectlink=(L=109808-109827*) for SH-75 spur (Sun Valley side of city boundary with Ketchum)
; selectlink=(L=134098-134101,134166-134160) for Myrtle/Front Street at Ada County Bldg
; selectlink=(L=130461-130475*) for Glenwood St in Boise
; selectlink=(L=135919-135929*) for SH-55 N of State St
; selectlink=(L=87397-87407*) for SH-33 in Rexburg
; selectlink=(L=98957-98966*) for US-93 Snake River Crossing (N=98955...normally I'd expect this to be the first of the nodes in the link, but I picked a link a bit too far north)
; selectlink=(L=113546-113565*) for SH-50 Snake River Crossing (N=113546)
; selectlink=(L=133603-133623*) for SH-46 Snake River Crossing (N=133603)
; selectlink=(N=4582) for TAZ select zone 4582
;----------------------------------------------------------------------------------------------

;start cluster nodes
*Cluster.exe ITD 1-@numthreads@ start exit

  RUN PGM=HIGHWAY

   MATI = outputs\total.mat
   NETI = inputs\@HWYNET@
   NETO = outputs\loaded.net
   MATO = outputs\selectlinks.mat,MO=1-2,dec=2 ;in MO, 1st matrix is select link trip matrix, 2nd matrix is basically the input matrix 'total.mat'
  ;MATO = outputs\selectlinks.mat,MO=1,dec=2 ;if you want only select link trip matrix, use this instead of the above line; also comment out line 48
   
   ZONES=@NZONES@
   
   DistributeIntrastep processid='ITD', processlist=1-@numthreads@

    ;Set run PARAMETERS and Controls
    
    PHASE=ILOOP
	
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[1] = MI.1.1, selectlink=(N=133603),
                          VOL[2] = MW[1] ; WM[1] is the trip matrix used by the select link
                          
      MW[2] = MI.1.1 ;MW[2] contains all the trips in the input matrix (i.e., total.mat), comment it out if you do not want this in the 2nd table of the output matrix
      
      ; Bi-conjugate equilibrium assignment
      PARAMETERS ZONEMSG=100, MAXITERS=@MAXITERANS@, COMBINE=EQUI, ENHANCE=2, GAP=@gap@
    ENDPHASE                  
                       
    PHASE=ADJUST 
      FUNCTION  COST = (Li.MILES/Li.SPEED)*60
      FUNCTION { V = VOL[1] }    
    ENDPHASE
   
 ENDRUN
 
*Cluster.exe ITD 1-@numthreads@ close exit

;----------------------------------------------------------------------------------------------
;Step 9: Output the total trips by external stations
;---------------------------------------------------------------------------------------------- 
 RUN PGM=MATRIX
 
    MATI[1] = outputs\selectlinks.mat
    
    ZONES = @NZONES@
    
    SET VAL = 0, VARS = P,A,T
    
    IF((i = @all_zones@)) 
      JLOOP       
           P = P + mi.1.1[J]  
           A = A + mi.1.1.T[J] ;transpose the matrix
           T = P + A
      ENDJLOOP    
      
      PRINT FILE = "outputs\selectlinkTrips.csv" CSV=T, LIST = I, P, A, T ;external station, production, attraction, total trips           
    ENDIF
  
 ENDRUN

