;Free flow time and distance skims for Idaho STDM
;Sujan Sikder, sikders@pbworld.com,6/26/15
;Ben Stabler, ben.stabler@rsginc.com,02/10/15
;Input file: itd.net,taz_area.csv
;Output file: offpeakprev.mat TIME, DISTANCE, ZEROS; cc.csv  
  
NZONES = 6035 
GAPEND = 6000 

RUN PGM=HIGHWAY 
  
  NETI="%OUTPUT_FOLDER%/itd.net"
  MATO[1]="%OUTPUT_FOLDER%/preoffpeakprev.mat",MO=1-3,NAME=TIME,DISTANCE,ZEROS
  
  ZONES=%NZONES%
  
  PHASE = LINKREAD
    T0 = (LI.MILES/LI.SPEED)*60
    LW.IMPEDA  = T0 
  ENDPHASE
     
  PHASE=ILOOP
    PATHLOAD PATH=COST,MW[1]=pathtrace(LW.IMPEDA),MW[2]=pathtrace(LI.MILES)
    COMP MW[1][I]= 0.5 * lowest(1,3,0.001,9999,I)/max(1,lowcnt)
    COMP MW[2][I]= 0.5 * lowest(2,3,0.001,9999,I)/max(1,lowcnt)
    COMP MW[3][I]= 0
    
    ccmileI =  MW[2][I]
    
    print, file="%OUTPUT_FOLDER%\cc1.csv", CSV = T,LIST = I,CCMILEI(10.7)
    
  ENDPHASE
   
ENDRUN

RUN PGM=NETWORK

   nodei[1]="%INPUT_FOLDER%\taz_area.csv" VAR=STDM_TAZ,Area,RENAME=STDM_TAZ-N
   linki[1]="%OUTPUT_FOLDER%\itd.net"
  
   ;put data into arrays for later
   array _tazarea =@NZONES@ ;area
   array _ccmile =@NZONES@ ;connector length
 
  phase=input filei=ni.1

     IF(N<=%NZONES%)
     
         _K=_K
         _tazarea[_K] = Area
         _ccmile[_K] = 0.9015*(SQRT((_tazarea[_K]*0.000000386)/3.141592653)) ;area = pi*r^2
       
         PRINT FILE="%OUTPUT_FOLDER%\cc2.csv",CSV = T,LIST = N,_ccmile[_K](10.7)
       
     ENDIF
    
   endphase
      
   phase=linkmerge  
    
     IF(A<=%NZONES%)     
        ccspeed = LI.1.SPEED ;connector speed
        PRINT FILE="%OUTPUT_FOLDER%\cc3.csv", CSV = T, LIST = A, ccspeed         
     ENDIF
      
	 endphase
	
ENDRUN

RUN PGM=NETWORK
   
   NODEI[1] = "%OUTPUT_FOLDER%\cc1.csv" VAR=N,CCMILEI
   NODEI[2] = "%OUTPUT_FOLDER%\cc2.csv" VAR=N,CCMILET 
   NODEI[3] = "%OUTPUT_FOLDER%\cc3.csv" VAR=N,CCSPEED 
   
   NODEO="%OUTPUT_FOLDER%\cc.csv"
   
   MERGE RECORD = FALSE
   
    PHASE=NODEMERGE 
     
      IF(N <@GAPEND@)
         CCMILE = MIN(CCMILEI,CCMILET)
      ELSE
         CCMILE = CCMILEI ;since external zones do not have physical area       
      ENDIF      
      
      IF((CCSPEED > 0)&(CCMILE > 0))
         CCTIME = (CCMILE/CCSPEED)*60
         Z = N
      ELSE
         CCTIME = 0
         Z = N
      ENDIF
       
    ENDPHASE
            
  print,file="%OUTPUT_FOLDER%\cc.csv",list=N,CCMILEI,CCMILET,CCSPEED,CCMILE,CCTIME,Z
  
ENDRUN

RUN PGM=MATRIX

    MATI[1] = "%OUTPUT_FOLDER%\preoffpeakprev.mat"  
    FILEI ZDATI[1] = "%OUTPUT_FOLDER%\cc.csv"
    MATO[1]="%OUTPUT_FOLDER%\offpeakprev.mat",MO=1-3,NAME=TIME,DISTANCE,ZEROS
     
    ZONES=%NZONES%
    
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

;create copies for first iteration of model run
*XCOPY "%OUTPUT_FOLDER%\offpeakprev.mat" "%OUTPUT_FOLDER%\offpeakcur.mat"* /Y
*XCOPY "%OUTPUT_FOLDER%\offpeakprev.mat" "%OUTPUT_FOLDER%\peakprev.mat"* /Y
*XCOPY "%OUTPUT_FOLDER%\offpeakprev.mat" "%OUTPUT_FOLDER%\peakcur.mat"* /Y

CONVERTMAT FROM="%OUTPUT_FOLDER%\offpeakcur.mat" TO="%OUTPUT_FOLDER%\offpeakcur.OMX" COMPRESSION=4
CONVERTMAT FROM="%OUTPUT_FOLDER%\peakcur.mat" TO="%OUTPUT_FOLDER%\peakcur.OMX" COMPRESSION=4
 