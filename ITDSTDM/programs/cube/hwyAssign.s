; Run highway assignment and generate congested network LOS matrices
; Sujan Sikder, sikders@pbworld.com, 09/22/2014
; Ben Stabler, ben.stabler@rsginc.com, 02/24/15
; Revised 09/22/15 for four time periods

; Step 1: Aggregate trip matrices by user class and time-of-day
; Step 2:(a) Tag links based on facility and area type
;        (b) Use a lookup table to assign capacity to each link
; Step 3: Assign auto and truck trips to the network
; Step 4: Calculate congested speed by time-of-day
; Step 5: Create intra- and inter-zonal highway skims for feedback loop

; Hourly capacity(vph/ln) table
;   Area Type          Facility Type        Capacity(vph/ln)
;    Urban               Freeway               1900
;    Urban          Principal Arterial          900
;    Urban            Minor Arterial            700
;    Urban              Collector               525
;    Urban                Local                 500
;    Urban                Ramp                  850
;    Urban          Centroid Connector         9999
;
;    Rural               Freeway               1900
;    Rural          Principal Arterial         1200
;    Rural           Minor Arterial            1200
;    Rural              Collector              1000
;    Rural                Local                1000
;    Rural                Ramp                 1000
;    Rural           Centroid Connector        9999

; Volume delay functions table 
; LNKGRP       CONICAL FUNCTION       BPR FUNCTION        Other    
;                      A             ALPHA     BETA
; 1                    7               -        - 
; 2                    4               -        - 
; 3                    4               -        - 
; 4                    4               -        - 
; 5                    4               -        - 
; 6                    4               -        - 
; 7                    -               -        -         constant
; 8                    -              0.60     3.5 
; 9                    -              0.83     2.5  
; 10                   -              0.83     2.5
; 11                   -              0.83     2.5
; 12                   -              0.83     2.5 
; 13                   -              0.83     2.5
; 14                   -                -       -         constant   

;----------------------------------------------------------------------------------------------
; Input files and parameters

itdNet = "%OUTPUT_FOLDER%/itd.net"
auOpCost = 0.12 ; auto operating cost $0.12/mile
trOpCost = 0.12 ; truck operating cost $0.12/mile 
maxIterns = %ASSIGN_ITER% ; maximum number of iterations
nZones = %NZONES% ; maximum number of zones
trkDmdOnly = 0 ;assign truck demand only
GAPEND = 6000 ;end internal TAZ id
trkPCU = 1.7 ; truck passenger car units
gap = 0.0001 ; relative gap setting
numthreads = %assign_threads% ; number of threads for assignment

; time period specific settings
pkAuVot = 25 ; peak hour value of time - auto: $25/hr
pkTrVot = 30 ; peak hour value of time - truck: $30/hr
ofpkAuVot = 20 ; off-peak hour value of time - auto: $20/hr
ofpkTrVot = 25 ; off-peak hour value of time - truck: $25/hr

amPeakExtFactor = 0.1; percent of daily external that is AM peak
mdPeakExtFactor = 0.6; percent of daily external that is MD offpeak
pmPeakExtFactor = 0.1; percent of daily external that is PM peak
ntPeakExtFactor = 0.2; percent of daily external that is NT offpeak

amHourFactor = 1.42 ; AM two hour capacity factor
mdHourFactor = 4.00 ; MD period capacity factor
pmHourFactor = 1.42 ; PM two hour capacity factor
ntHourFactor = 4.00 ; NT period capacity factor
 
;----------------------------------------------------------------------------------------------
; Aggregate trip matrices by mode and time-of-day

; AM Peak Period
RUN PGM = MATRIX MSG = "Aggregate AM peak trip matrices by user class"
  
  MATI[1] = "%OUTPUT_FOLDER%\pt_trips.mat"
  FILEI MATI[2] = "%OUTPUT_FOLDER%\exported_truck_trips.csv", PATTERN=IJM:V FIELDS=#1,2,0,4,3 SKIPRECS=1
  MATI[3] = "%OUTPUT_FOLDER%\externals.mat"
  FILEO MATO[1]= "%OUTPUT_FOLDER%\ampeaktrips.mat", MO=1-9, DEC=5*5, Name=SOVS,HOV2S,HOV3PS,SUT,MUT,EXT,SOVL,HOV2L,HOV3PL

  MW[1]=mi.1.SAMDA  
  MW[2]=mi.1.SAMSR2
  MW[3]=mi.1.SAMSR3P
  MW[4]=mi.2.1    ;use first V field from matrix 2 (CT) which happens to be the forth field in the MATI[2] statement
  MW[5]=mi.2.2    ;use second V field from matrix 2 (CT) which happens to be the fifth field in the MATI[2] statement
  MW[6]=mi.3.EXTERNALS * @amPeakExtFactor@
  MW[7]=mi.1.LAMDA 
  MW[8]=mi.1.LAMSR2 
  MW[9]=mi.1.LAMSR3P
   
  ;zero out non-truck demand
  IF(@trkDmdOnly@=1)
    MW[1]=0
    MW[2]=0
    MW[3]=0
    MW[6]=0
	MW[7]=0
	MW[8]=0
	MW[9]=0
  ENDIF

ENDRUN

; MD Off-peak Period
RUN PGM = MATRIX MSG = "Aggregate MD trip matrices by user class"
  
  MATI[1] = "%OUTPUT_FOLDER%\pt_trips.mat"
  ;MATI[2] = "%OUTPUT_FOLDER%\truck_trips.mat"
  FILEI MATI[2] = "%OUTPUT_FOLDER%\exported_truck_trips.csv", PATTERN=IJM:V FIELDS=#1,2,0,6,5 SKIPRECS=1
  MATI[3] = "%OUTPUT_FOLDER%\externals.mat"
  FILEO MATO[1]= "%OUTPUT_FOLDER%\mdpeaktrips.mat", MO=1-9, DEC=5*5, Name=SOVS,HOV2S,HOV3PS,SUT,MUT,EXT,SOVL,HOV2L,HOV3PL

  MW[1]=mi.1.SMDDA
  MW[2]=mi.1.SMDSR2
  MW[3]=mi.1.SMDSR3P
  MW[4]=mi.2.1
  MW[5]=mi.2.2
  MW[6]=mi.3.EXTERNALS * @mdPeakExtFactor@
  MW[7]=mi.1.LMDDA
  MW[8]=mi.1.LMDSR2
  MW[9]=mi.1.LMDSR3P
 
  ;zero out non-truck demand
  IF(@trkDmdOnly@=1)
    MW[1]=0
    MW[2]=0
    MW[3]=0
    MW[6]=0
	MW[7]=0
	MW[8]=0
	MW[9]=0
  ENDIF
  
ENDRUN 

; PM Peak Period
RUN PGM = MATRIX MSG = "Aggregate PM peak trip matrices by user class"
  
  MATI[1] = "%OUTPUT_FOLDER%\pt_trips.mat"
  ;MATI[2] = "%OUTPUT_FOLDER%\truck_trips.mat"
  FILEI MATI[2] = "%OUTPUT_FOLDER%\exported_truck_trips.csv", PATTERN=IJM:V FIELDS=#1,2,0,10,9 SKIPRECS=1
  MATI[3] = "%OUTPUT_FOLDER%\externals.mat"
  FILEO MATO[1]= "%OUTPUT_FOLDER%\pmpeaktrips.mat", MO=1-9, DEC=5*5, Name=SOVS,HOV2S,HOV3PS,SUT,MUT,EXT,SOVL,HOV2L,HOV3PL

  MW[1]=mi.1.SPMDA  
  MW[2]=mi.1.SPMSR2
  MW[3]=mi.1.SPMSR3P
  MW[4]=mi.2.1
  MW[5]=mi.2.2
  MW[6]=mi.3.EXTERNALS * @pmPeakExtFactor@
  MW[7]=mi.1.LPMDA 
  MW[8]=mi.1.LPMSR2 
  MW[9]=mi.1.LPMSR3P
   
  ;zero out non-truck demand
  IF(@trkDmdOnly@=1)
    MW[1]=0
    MW[2]=0
    MW[3]=0
    MW[6]=0
	MW[7]=0
	MW[8]=0
	MW[9]=0
  ENDIF

ENDRUN

; NT Off-peak Period
RUN PGM = MATRIX MSG = "Aggregate NT trip matrices by user class"
  
  MATI[1] = "%OUTPUT_FOLDER%\pt_trips.mat"
  ;MATI[2] = "%OUTPUT_FOLDER%\truck_trips.mat"
  FILEI MATI[2] = "%OUTPUT_FOLDER%\exported_truck_trips.csv", PATTERN=IJM:V FIELDS=#1,2,0,8,7 SKIPRECS=1
  MATI[3] = "%OUTPUT_FOLDER%\externals.mat"
  FILEO MATO[1]= "%OUTPUT_FOLDER%\ntpeaktrips.mat", MO=1-9, DEC=5*5, Name=SOVS,HOV2S,HOV3PS,SUT,MUT,EXT,SOVL,HOV2L,HOV3PL

  MW[1]=mi.1.SNTDA 
  MW[2]=mi.1.SNTSR2 
  MW[3]=mi.1.SNTSR3P 
  MW[4]=mi.2.1
  MW[5]=mi.2.2
  MW[6]=mi.3.EXTERNALS * @ntPeakExtFactor@
  MW[7]=mi.1.LNTDA
  MW[8]=mi.1.LNTSR2  
  MW[9]=mi.1.LNTSR3P 
 
  ;zero out non-truck demand
  IF(@trkDmdOnly@=1)
    MW[1]=0
    MW[2]=0
    MW[3]=0
    MW[6]=0
	MW[7]=0
	MW[8]=0
	MW[9]=0
  ENDIF
  
ENDRUN 

;----------------------------------------------------------------------------------------------
; Tag links based on facility and area types
RUN PGM=NETWORK MSG = "Tag links and assign hourly link capacity"
   
   NETI = "%OUTPUT_FOLDER%\itd.net"
   NETO = "%OUTPUT_FOLDER%\itdcap.net"
   
   ; Area types: 1 Rural, 2 Urban, 3 CBD
   ; Facility Types: Centroid, Local, Collector, Expressway, Freeway, Highway, 
   ;  Minor Arterial, Principal Arterial, Ramp
    
 PHASE=LINKMERGE
  
    ; Combine expressway, highway, and freeway into freeway for now; expressway and highway 
    ;      are available only in SRTC network
      
   IF (((TYP='Expressway')|(TYP='Highway')|(TYP='Freeway')) & ((AT = 2)|(AT = 3)))
         LNKGRP = 1                
         CAPACITY = 1900     
   ELSE
   IF ((TYP='Principal Arterial') & ((AT = 2)|(AT = 3)))
         LNKGRP = 2                
         CAPACITY = 900 
   ELSE
   IF ((TYP='Minor Arterial') & ((AT = 2)|(AT = 3)))
         LNKGRP = 3                
         CAPACITY = 700 
   ELSE
   IF ((TYP='Collector') & ((AT = 2)|(AT = 3)))
         LNKGRP = 4                
         CAPACITY = 525 
   ELSE
   IF ((TYP='Local') & ((AT = 2)|(AT = 3)))
         LNKGRP = 5                
         CAPACITY = 500 
   ELSE
   IF ((TYP='Ramp') & ((AT = 2)|(AT = 3)))
         LNKGRP = 6                
         CAPACITY = 850 
   ELSE
   IF ((TYP='Centroid') & ((AT = 2)|(AT = 3)))
         LNKGRP = 7                
         CAPACITY = 9999 
   ELSE
   IF (((TYP='Expressway')|(TYP='Highway')|(TYP='Freeway')) & (AT = 1))
         LNKGRP = 8                
         CAPACITY = 1900     
   ELSE
   IF ((TYP='Principal Arterial') & (AT = 1))
         LNKGRP = 9                
         CAPACITY = 1200
   ELSE
   IF ((TYP='Minor Arterial') & (AT = 1))
         LNKGRP = 10                
         CAPACITY = 1200 
   ELSE
   IF ((TYP='Collector') & (AT = 1))
         LNKGRP = 11                
         CAPACITY = 1000 
   ELSE
   IF ((TYP='Local') & (AT = 1))
         LNKGRP = 12                
         CAPACITY = 1000 
   ELSE
   IF ((TYP='Ramp') & (AT = 1))
         LNKGRP = 13                
         CAPACITY = 1000 
   ELSE
   IF ((TYP='Centroid') & (AT = 1))
         LNKGRP = 14                
         CAPACITY = 9999 
   ENDIF
   ENDIF
   ENDIF
   ENDIF
   ENDIF
   ENDIF
   ENDIF
   ENDIF
   ENDIF
   ENDIF
   ENDIF
   ENDIF
   ENDIF
   ENDIF
    
 ENDPHASE
   
ENDRUN 

;start cluster nodes
*Cluster.exe ITD 1-@numthreads@ start exit

;----------------------------------------------------------------------------------------------
; Assign auto and truck trips to the network
 
RUN PGM=HIGHWAY MSG = "AM peak highway assignment"

   NETI = "%OUTPUT_FOLDER%\itdcap.net"
   MATI = "%OUTPUT_FOLDER%\ampeaktrips.mat"
   NETO = "%OUTPUT_FOLDER%\itdamassign.net"
   ZONES=@nZones@

   DistributeIntrastep processid='ITD', processlist=1-@numthreads@

  PHASE = LINKREAD

    ; Set volume/speed curves by linkgroups.
    LINKCLASS = LI.LNKGRP

    ; Coded link capacity represents 1 hour, but trips are for X hours.
    ; Apply capacity factor for this period. 
    ; Multiply by the number of lanes to get overall capacity for this period.  
    C = LI.CAPACITY * @amHourFactor@ * LI.LANES
    DISTANCE = LI.MILES
    T0 = (LI.MILES/LI.SPEED)*60
    ZONES=@nZones@
    
    ; Compute pathbuilding impedance. Define it in terms of time. 
    ; Impedance = free flow time + value of time(min/$)*operating cost*distance
    ; No toll
    LW.IMPEDA = T0 + (60/@pkAuVot@)*@auOpCost@*LI.MILES ; auto 
    LW.IMPEDT = T0 + (60/@pkTrVot@)*@trOpCost@*LI.MILES ; truck
    
  ENDPHASE
    
  ; Load Auto and Truck trips to their appropriate paths

  PHASE = ILOOP
    PATHLOAD VOL[1] = MI.1.SOVS, PATH = LW.IMPEDA
    PATHLOAD VOL[2] = MI.1.HOV2S, PATH = LW.IMPEDA
    PATHLOAD VOL[3] = MI.1.HOV3PS, PATH = LW.IMPEDA
    PATHLOAD VOL[4] = MI.1.SUT, PATH = LW.IMPEDT
    PATHLOAD VOL[5] = MI.1.MUT, PATH = LW.IMPEDT
    PATHLOAD VOL[6] = MI.1.EXT, PATH = LW.IMPEDA
    PATHLOAD VOL[7] = MI.1.SOVL, PATH = LW.IMPEDA
    PATHLOAD VOL[8] = MI.1.HOV2L, PATH = LW.IMPEDA
    PATHLOAD VOL[9] = MI.1.HOV3PL, PATH = LW.IMPEDA
    ; Bi-conjugate equilibrium assignment
    PARAMETERS ZONEMSG=100,  MAXITERS=@maxIterns@, COMBINE=EQUI, ENHANCE=2, RELATIVEGAP=@gap@
  ENDPHASE 
  
  PHASE = ADJUST

    ; Define volume to be used for V/C calculation
    FUNCTION V = VOL[1] + VOL[2] + VOL[3] + VOL[4]*@trkPCU@ + VOL[5]*@trkPCU@ + VOL[6] + VOL[7] + VOL[8] + VOL[9]

    FUNCTION {
      TC[1] = MIN(T0*(2+((((7^2)*(1-(V/C))^2)+(((2*7)-1)/((2*7)-2))^2)^(1/2))-7*(1-(V/C))-(((2*7)-1)/((2*7)-2))),T0*20)
      TC[2] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[3] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[4] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[5] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[6] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[7] = MIN(T0,T0*20)
      TC[8] = MIN(T0*(1+0.60*(V/C)^3.5),T0*20)
      TC[9] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[10] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[11] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[12] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[13] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[14] = MIN(T0,T0 * 20)
    }
    
    ; Update impedance using capacity-restrained times
    LW.IMPEDA = TIME + (60/@pkAuVot@)*@auOpCost@*LI.MILES ; auto
    LW.IMPEDT = TIME + (60/@pkTrVot@)*@trOpCost@*LI.MILES ; truck
    
  ENDPHASE
  
ENDRUN

RUN PGM=HIGHWAY MSG = "MD offpeak highway assignment"

   NETI = "%OUTPUT_FOLDER%\itdcap.net"
   MATI = "%OUTPUT_FOLDER%\mdpeaktrips.mat"
   NETO = "%OUTPUT_FOLDER%\itdmdassign.net"
   ZONES=@nZones@

  PHASE = LINKREAD

     ; Set volume/speed curves by linkgroups.
    LINKCLASS = LI.LNKGRP
      
    ; Coded link capacity represents 1 hour, but trips are for X hours.
    ; Apply capacity factor for this period. 
    ; Multiply by the number of lanes to get overall capacity for this period.  
    C = LI.CAPACITY * @mdHourFactor@ * LI.LANES
    DISTANCE = LI.MILES
    T0 = (LI.MILES/LI.SPEED)*60
    ZONES=@nZones@
     
    DistributeIntrastep processid='ITD', processlist=1-@numthreads@
   
    ; Compute pathbuilding impedance. Define it in terms of time. 
    ; Impedance = free flow time + value of time(min/$)*operating cost*distance
    ; No toll
    LW.IMPEDA = T0 + (60/@ofpkAuVot@)*@auOpCost@*LI.MILES ; auto 
    LW.IMPEDT = T0 + (60/@ofpkTrVot@)*@trOpCost@*LI.MILES ; truck
     
  ENDPHASE
    
  PHASE = ILOOP
    PATHLOAD VOL[1] = MI.1.SOVS, PATH = LW.IMPEDA
    PATHLOAD VOL[2] = MI.1.HOV2S, PATH = LW.IMPEDA
    PATHLOAD VOL[3] = MI.1.HOV3PS, PATH = LW.IMPEDA
    PATHLOAD VOL[4] = MI.1.SUT, PATH = LW.IMPEDT
    PATHLOAD VOL[5] = MI.1.MUT, PATH = LW.IMPEDT
    PATHLOAD VOL[6] = MI.1.EXT, PATH = LW.IMPEDA
    PATHLOAD VOL[7] = MI.1.SOVL, PATH = LW.IMPEDA
    PATHLOAD VOL[8] = MI.1.HOV2L, PATH = LW.IMPEDA
    PATHLOAD VOL[9] = MI.1.HOV3PL, PATH = LW.IMPEDA
	
    ; Bi-conjugate equilibrium assignment
    PARAMETERS ZONEMSG=100,  MAXITERS=@maxIterns@, COMBINE=EQUI, ENHANCE=2, RELATIVEGAP=@gap@
  ENDPHASE 
  
  PHASE = ADJUST

    ; Define volume to be used for V/C calculation
    FUNCTION V = VOL[1] + VOL[2] + VOL[3] + VOL[4]*@trkPCU@ + VOL[5]*@trkPCU@ + VOL[6] + VOL[7] + VOL[8] + VOL[9]

    FUNCTION {
      TC[1] = MIN(T0*(2+((((7^2)*(1-(V/C))^2)+(((2*7)-1)/((2*7)-2))^2)^(1/2))-7*(1-(V/C))-(((2*7)-1)/((2*7)-2))),T0*20)
      TC[2] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[3] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[4] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[5] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[6] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[7] = MIN(T0,T0*20)
      TC[8] = MIN(T0*(1+0.60*(V/C)^3.5),T0*20)
      TC[9] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[10] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[11] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[12] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[13] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[14] = MIN(T0,T0 * 20)
    }
    
    ; Update impedance using capacity-restrained times
    LW.IMPEDA = TIME + (60/@ofpkAuVot@)*@auOpCost@*LI.MILES ; auto
    LW.IMPEDT = TIME + (60/@ofpkTrVot@)*@trOpCost@*LI.MILES ; truck
    
  ENDPHASE
  
ENDRUN 

RUN PGM=HIGHWAY MSG = "PM peak highway assignment"

   NETI = "%OUTPUT_FOLDER%\itdcap.net"
   MATI = "%OUTPUT_FOLDER%\pmpeaktrips.mat"
   NETO = "%OUTPUT_FOLDER%\itdpmassign.net"
   ZONES=@nZones@

   DistributeIntrastep processid='ITD', processlist=1-@numthreads@

  PHASE = LINKREAD

    ; Set volume/speed curves by linkgroups.
    LINKCLASS = LI.LNKGRP

    ; Coded link capacity represents 1 hour, but trips are for X hours.
    ; Apply capacity factor for this period. 
    ; Multiply by the number of lanes to get overall capacity for this period.  
    C = LI.CAPACITY * @pmHourFactor@ * LI.LANES
    DISTANCE = LI.MILES
    T0 = (LI.MILES/LI.SPEED)*60
    ZONES=@nZones@
    
    ; Compute pathbuilding impedance. Define it in terms of time. 
    ; Impedance = free flow time + value of time(min/$)*operating cost*distance
    ; No toll
    LW.IMPEDA = T0 + (60/@pkAuVot@)*@auOpCost@*LI.MILES ; auto 
    LW.IMPEDT = T0 + (60/@pkTrVot@)*@trOpCost@*LI.MILES ; truck
    
  ENDPHASE
    
  ; Load Auto and Truck trips to their appropriate paths

  PHASE = ILOOP
    PATHLOAD VOL[1] = MI.1.SOVS, PATH = LW.IMPEDA
    PATHLOAD VOL[2] = MI.1.HOV2S, PATH = LW.IMPEDA
    PATHLOAD VOL[3] = MI.1.HOV3PS, PATH = LW.IMPEDA
    PATHLOAD VOL[4] = MI.1.SUT, PATH = LW.IMPEDT
    PATHLOAD VOL[5] = MI.1.MUT, PATH = LW.IMPEDT
    PATHLOAD VOL[6] = MI.1.EXT, PATH = LW.IMPEDA
    PATHLOAD VOL[7] = MI.1.SOVL, PATH = LW.IMPEDA
    PATHLOAD VOL[8] = MI.1.HOV2L, PATH = LW.IMPEDA
    PATHLOAD VOL[9] = MI.1.HOV3PL, PATH = LW.IMPEDA
    ; Bi-conjugate equilibrium assignment
    PARAMETERS ZONEMSG=100,  MAXITERS=@maxIterns@, COMBINE=EQUI, ENHANCE=2, RELATIVEGAP=@gap@
  ENDPHASE 
  
  PHASE = ADJUST

    ; Define volume to be used for V/C calculation
    FUNCTION V = VOL[1] + VOL[2] + VOL[3] + VOL[4]*@trkPCU@ + VOL[5]*@trkPCU@ + VOL[6] + VOL[7] + VOL[8] + VOL[9]

    FUNCTION {
      TC[1] = MIN(T0*(2+((((7^2)*(1-(V/C))^2)+(((2*7)-1)/((2*7)-2))^2)^(1/2))-7*(1-(V/C))-(((2*7)-1)/((2*7)-2))),T0*20)
      TC[2] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[3] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[4] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[5] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[6] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[7] = MIN(T0,T0*20)
      TC[8] = MIN(T0*(1+0.60*(V/C)^3.5),T0*20)
      TC[9] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[10] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[11] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[12] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[13] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[14] = MIN(T0,T0 * 20)
    }
    
    ; Update impedance using capacity-restrained times
    LW.IMPEDA = TIME + (60/@pkAuVot@)*@auOpCost@*LI.MILES ; auto
    LW.IMPEDT = TIME + (60/@pkTrVot@)*@trOpCost@*LI.MILES ; truck
    
  ENDPHASE
  
ENDRUN

RUN PGM=HIGHWAY MSG = "NT offpeak highway assignment"

   NETI = "%OUTPUT_FOLDER%\itdcap.net"
   MATI = "%OUTPUT_FOLDER%\ntpeaktrips.mat"
   NETO = "%OUTPUT_FOLDER%\itdntassign.net"
   ZONES=@nZones@

  PHASE = LINKREAD

     ; Set volume/speed curves by linkgroups.
    LINKCLASS = LI.LNKGRP
      
    ; Coded link capacity represents 1 hour, but trips are for X hours.
    ; Apply capacity factor for this period. 
    ; Multiply by the number of lanes to get overall capacity for this period.  
    C = LI.CAPACITY * @ntHourFactor@ * LI.LANES
    DISTANCE = LI.MILES
    T0 = (LI.MILES/LI.SPEED)*60
    ZONES=@nZones@
     
    DistributeIntrastep processid='ITD', processlist=1-@numthreads@
   
    ; Compute pathbuilding impedance. Define it in terms of time. 
    ; Impedance = free flow time + value of time(min/$)*operating cost*distance
    ; No toll
    LW.IMPEDA = T0 + (60/@ofpkAuVot@)*@auOpCost@*LI.MILES ; auto 
    LW.IMPEDT = T0 + (60/@ofpkTrVot@)*@trOpCost@*LI.MILES ; truck
     
  ENDPHASE
    
  PHASE = ILOOP
    PATHLOAD VOL[1] = MI.1.SOVS, PATH = LW.IMPEDA
    PATHLOAD VOL[2] = MI.1.HOV2S, PATH = LW.IMPEDA
    PATHLOAD VOL[3] = MI.1.HOV3PS, PATH = LW.IMPEDA
    PATHLOAD VOL[4] = MI.1.SUT, PATH = LW.IMPEDT
    PATHLOAD VOL[5] = MI.1.MUT, PATH = LW.IMPEDT
    PATHLOAD VOL[6] = MI.1.EXT, PATH = LW.IMPEDA
    PATHLOAD VOL[7] = MI.1.SOVL, PATH = LW.IMPEDA
    PATHLOAD VOL[8] = MI.1.HOV2L, PATH = LW.IMPEDA
    PATHLOAD VOL[9] = MI.1.HOV3PL, PATH = LW.IMPEDA
	
    ; Bi-conjugate equilibrium assignment
    PARAMETERS ZONEMSG=100,  MAXITERS=@maxIterns@, COMBINE=EQUI, ENHANCE=2, RELATIVEGAP=@gap@
  ENDPHASE 
  
  PHASE = ADJUST

    ; Define volume to be used for V/C calculation
    FUNCTION V = VOL[1] + VOL[2] + VOL[3] + VOL[4]*@trkPCU@ + VOL[5]*@trkPCU@ + VOL[6] + VOL[7] + VOL[8] + VOL[9]

    FUNCTION {
      TC[1] = MIN(T0*(2+((((7^2)*(1-(V/C))^2)+(((2*7)-1)/((2*7)-2))^2)^(1/2))-7*(1-(V/C))-(((2*7)-1)/((2*7)-2))),T0*20)
      TC[2] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[3] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[4] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[5] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[6] = MIN(T0*(2+((((4^2)*(1-(V/C))^2)+(((2*4)-1)/((2*4)-2))^2)^(1/2))-4*(1-(V/C))-(((2*4)-1)/((2*4)-2))),T0*20)
      TC[7] = MIN(T0,T0*20)
      TC[8] = MIN(T0*(1+0.60*(V/C)^3.5),T0*20)
      TC[9] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[10] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[11] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[12] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[13] = MIN(T0*(1+0.83*(V/C)^2.5),T0*20)
      TC[14] = MIN(T0,T0 * 20)
    }
    
    ; Update impedance using capacity-restrained times
    LW.IMPEDA = TIME + (60/@ofpkAuVot@)*@auOpCost@*LI.MILES ; auto
    LW.IMPEDT = TIME + (60/@ofpkTrVot@)*@trOpCost@*LI.MILES ; truck
    
  ENDPHASE
  
ENDRUN 

*Cluster.exe ITD 1-@numthreads@ close exit

;----------------------------------------------------------------------------------------------
; Calculate congested speed by time-of-day

RUN PGM = NETWORK MSG = "Calculate AM peak congested time and speed"

  NETI[1]="%OUTPUT_FOLDER%\itdamassign.net"
  NETO="%OUTPUT_FOLDER%\itdamassignfinal.net", exclude = V_1,VC_1,V1_1,V2_1,V3_1,V4_1,V5_1,V6_1,V7_1,V8_1,V9_1,VT_1,V1T_1,V2T_1,V3T_1,V4T_1,V5T_1,V6T_1,V7T_1,V8T_1,V9T_1,VOL,TIME_1
  
  SOVAMS = LI.1.V1_1
  HOV2AMS = LI.1.V2_1
  HOV3PAMS = LI.1.V3_1
  SUTAM = LI.1.V4_1
  MUTAM = LI.1.V5_1
  EXTAM = LI.1.V6_1
  SOVAML = LI.1.V7_1
  HOV2AML = LI.1.V8_1
  HOV3PAML = LI.1.V9_1  
  
  VOLAM = SOVAMS + HOV2AMS + HOV3PAMS + SUTAM + MUTAM + EXTAM + SOVAML + HOV2AML + HOV3PAML 
  CAPAM = LI.1.CAPACITY * LI.1.LANES * @amHourFactor@
  VCAM = VOLAM / CAPAM
  
  ;Calculate congested time and speed
  CTIMEAM  = LI.1.TIME_1
  CSPEEDAM = 0.0
  IF (CTIMEAM > 0) 
    CSPEEDAM = 60 * LI.1.MILES/CTIMEAM
  ENDIF

ENDRUN

RUN PGM = NETWORK MSG = "Calculate MD offpeak congested time and speed"

  NETI = "%OUTPUT_FOLDER%\itdmdassign.net"
  NETO="%OUTPUT_FOLDER%\itdmdassignfinal.net", exclude = V_1,VC_1,V1_1,V2_1,V3_1,V4_1,V5_1,V6_1,V7_1,V8_1,V9_1,VT_1,V1T_1,V2T_1,V3T_1,V4T_1,V5T_1,V6T_1,V7T_1,V8T_1,V9T_1,VOL,TIME_1
  
  SOVMDS  = LI.1.V1_1
  HOV2MDS = LI.1.V2_1
  HOV3PMDS = LI.1.V3_1
  SUTMD =  LI.1.V4_1
  MUTMD =  LI.1.V5_1
  EXTMD =  LI.1.V6_1
  SOVMDL  = LI.1.V7_1
  HOV2MDL = LI.1.V8_1
  HOV3PMDL = LI.1.V9_1
  
  VOLMD = SOVMDS + HOV2MDS + HOV3PMDS + SUTMD + MUTMD + EXTMD + SOVMDL + HOV2MDL + HOV3PMDL
  
  CAPMD = LI.1.CAPACITY * LI.1.LANES * @mdHourFactor@
  VCMD = VOLMD / CAPMD
  
  ;Calculate congested time and speed
  CTIMEMD  = LI.1.TIME_1
  CSPEEDMD = 0.0
  IF (CTIMEMD > 0) 
    CSPEEDMD = 60 * LI.1.MILES/CTIMEMD
  ENDIF

ENDRUN 

RUN PGM = NETWORK MSG = "Calculate PM peak congested time and speed"

  NETI[1]="%OUTPUT_FOLDER%\itdpmassign.net"
  NETO="%OUTPUT_FOLDER%\itdpmassignfinal.net", exclude = V_1,VC_1,V1_1,V2_1,V3_1,V4_1,V5_1,V6_1,V7_1,V8_1,V9_1,VT_1,V1T_1,V2T_1,V3T_1,V4T_1,V5T_1,V6T_1,V7T_1,V8T_1,V9T_1,VOL,TIME_1
  
  SOVPMS = LI.1.V1_1
  HOV2PMS = LI.1.V2_1
  HOV3PPMS = LI.1.V3_1
  SUTPM = LI.1.V4_1
  MUTPM = LI.1.V5_1
  EXTPM = LI.1.V6_1
  SOVPML = LI.1.V7_1
  HOV2PML = LI.1.V8_1
  HOV3PPML = LI.1.V9_1  
  
  VOLPM = SOVPMS + HOV2PMS + HOV3PPMS + SUTPM + MUTPM + EXTPM + SOVPML + HOV2PML + HOV3PPML 
  CAPPM = LI.1.CAPACITY * LI.1.LANES * @pmHourFactor@
  VCPM = VOLPM / CAPPM
  
  ;Calculate congested time and speed
  CTIMEPM  = LI.1.TIME_1
  CSPEEDPM = 0.0
  IF (CTIMEPM > 0) 
    CSPEEDPM = 60 * LI.1.MILES/CTIMEPM
  ENDIF

ENDRUN

RUN PGM = NETWORK MSG = "Calculate NT offpeak congested time and speed"

  NETI = "%OUTPUT_FOLDER%\itdntassign.net"
  NETO="%OUTPUT_FOLDER%\itdntassignfinal.net", exclude = V_1,VC_1,V1_1,V2_1,V3_1,V4_1,V5_1,V6_1,V7_1,V8_1,V9_1,VT_1,V1T_1,V2T_1,V3T_1,V4T_1,V5T_1,V6T_1,V7T_1,V8T_1,V9T_1,VOL,TIME_1
  
  SOVNTS  = LI.1.V1_1
  HOV2NTS = LI.1.V2_1
  HOV3PNTS = LI.1.V3_1
  SUTNT =  LI.1.V4_1
  MUTNT =  LI.1.V5_1
  EXTNT =  LI.1.V6_1
  SOVNTL  = LI.1.V7_1
  HOV2NTL = LI.1.V8_1
  HOV3PNTL = LI.1.V9_1
  
  VOLNT = SOVNTS + HOV2NTS + HOV3PNTS + SUTNT + MUTNT + EXTNT + SOVNTL + HOV2NTL + HOV3PNTL
  
  CAPNT = LI.1.CAPACITY * LI.1.LANES * @ntHourFactor@
  VCNT = VOLNT / CAPNT
  
  ;Calculate congested time and speed
  CTIMENT  = LI.1.TIME_1
  CSPEEDNT = 0.0
  IF (CTIMENT > 0) 
    CSPEEDNT = 60 * LI.1.MILES/CTIMENT
  ENDIF

ENDRUN 
;----------------------------------------------------------------------------------------------
; Create intra- and inter-zonal highway skims for feedback loop

RUN PGM = HIGHWAY MSG = "AM Peak highway skims"

  NETI = "%OUTPUT_FOLDER%\itdamassignfinal.net"
  MATO = "%OUTPUT_FOLDER%\prepeakcur.mat",MO=1-3,NAME=TIME,DISTANCE,ZEROS     
  ZONES=@nZones@
  ZONEMSG=100
  
  PHASE = LINKREAD
    ; Time using congested speed        
    DISTANCE = LI.MILES
    T0 = 60*LI.MILES/LI.CSPEEDAM
    LW.IMPEDA  = T0 + (60/@pkAuVot@)*@auOpCost@*LI.MILES ; auto
  ENDPHASE

  ; Skim paths
  PHASE = ILOOP
    PATHLOAD PATH = LW.IMPEDA, MW[1] = PATHTRACE(TIME,1), MW[2] = PATHTRACE(LI.MILES)
    COMP MW[1][I]= 0.5 * LOWEST(1,3,0.001,9999,I)/MAX(1,LOWCNT) 
    COMP MW[2][I]= 0.5 * LOWEST(2,3,0.001,9999,I)/MAX(1,LOWCNT)
    COMP MW[3][I]= 0
  ENDPHASE
  
ENDRUN

RUN PGM=MATRIX

    MATI[1] = "%OUTPUT_FOLDER%\prepeakcur.mat"
    FILEI ZDATI[1] = "%OUTPUT_FOLDER%\cc.csv"
    MATO[1]="%OUTPUT_FOLDER%\peakcur.mat",MO=1-3,NAME=TIME,DISTANCE,ZEROS
     
    ZONES=@nZones@
    
    MW[1] = MI.1.1 
    MW[2] = MI.1.2 
    MW[3] = MI.1.3 
    
    IF(I<@GAPEND@)
       COMP MW[1][I]= zi.1.CCTIME 
       COMP MW[2][I]= zi.1.CCMILE        
     ELSE 
        COMP MW[1][I]= MW[1][I]
        COMP MW[2][I]= MW[2][I]
    ENDIF
    
ENDRUN

RUN PGM = HIGHWAY MSG = "MD Offpeak highway skims"

  NETI = "%OUTPUT_FOLDER%\itdmdassignfinal.net"
  MATO = "%OUTPUT_FOLDER%\preoffpeakcur.mat",MO=1-3,NAME=TIME,DISTANCE,ZEROS     
  ZONES=@nZones@
  ZONEMSG=100

  PHASE = LINKREAD
    ; Time using congested speed        
    DISTANCE = LI.MILES
    T0 = 60*LI.MILES/LI.CSPEEDMD
    LW.IMPEDA  = T0 + (60/@ofpkAuVot@)*@auOpCost@*LI.MILES ; auto
  ENDPHASE

  ; Skim paths
  PHASE = ILOOP
    PATHLOAD PATH = LW.IMPEDA, MW[1] = PATHTRACE(TIME,1), MW[2] = PATHTRACE(LI.MILES)
    COMP MW[1][I]= 0.5 * LOWEST(1,3,0.001,9999,I)/MAX(1,LOWCNT) 
    COMP MW[2][I]= 0.5 * LOWEST(2,3,0.001,9999,I)/MAX(1,LOWCNT)
    COMP MW[3][I]= 0
  ENDPHASE
  
ENDRUN 

RUN PGM=MATRIX

    MATI[1] = "%OUTPUT_FOLDER%\preoffpeakcur.mat"  
    FILEI ZDATI[1] = "%OUTPUT_FOLDER%\cc.csv"
    MATO[1]="%OUTPUT_FOLDER%\offpeakcur.mat",MO=1-3,NAME=TIME,DISTANCE,ZEROS
     
    ZONES=@nZones@
    
    MW[1] = MI.1.1 
    MW[2] = MI.1.2 
    MW[3] = MI.1.3 
    
    IF(I<@GAPEND@)
       COMP MW[1][I]= zi.1.CCTIME 
       COMP MW[2][I]= zi.1.CCMILE        
     ELSE 
        COMP MW[1][I]= MW[1][I]
        COMP MW[2][I]= MW[2][I]
    ENDIF
    
ENDRUN


