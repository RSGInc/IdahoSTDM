; Average network LOS matrices to ensure overall system convergence
; Ben Stabler, ben.stabler@rsginc.com, 02/24/15
; Matrix = Current * (1/iteration) + Previous * ((iteration-1)/iteration)

RUN PGM = MATRIX MSG = "Average network LOS matrices"
  
  ;current
  MATI[1] = "%OUTPUT_FOLDER%\peakcur.mat"
  MATI[2] = "%OUTPUT_FOLDER%\offpeakcur.mat"
  
  ;previous
  MATI[3] = "%OUTPUT_FOLDER%\peakprev.mat"
  MATI[4] = "%OUTPUT_FOLDER%\offpeakprev.mat"
  
  ;output
  FILEO MATO[1]= "%OUTPUT_FOLDER%\peakavg.mat", MO=1-3, DEC=5*5, Name=TIME,DISTANCE,ZEROS
  FILEO MATO[2]= "%OUTPUT_FOLDER%\offpeakavg.mat", MO=4-6, DEC=5*5, Name=TIME,DISTANCE,ZEROS

  IF(%ITERATION%==1) 
    MW[1]=mi.1.TIME * 0.0 + mi.3.TIME * 1.0
    MW[2]=mi.1.DISTANCE * 0.0 + mi.3.DISTANCE * 1.0
    MW[3]=0
    MW[4]=mi.2.TIME * 0.0 + mi.4.TIME * 1.0
    MW[5]=mi.2.DISTANCE * 0.0 + mi.4.DISTANCE * 1.0
    MW[6]=0
  ENDIF
  
  IF(%ITERATION%==2) 
    MW[1]=mi.1.TIME * 0.5 + mi.3.TIME * 0.5
    MW[2]=mi.1.DISTANCE * 0.5 + mi.3.DISTANCE * 0.5
    MW[3]=0
    MW[4]=mi.2.TIME * 0.5 + mi.4.TIME * 0.5
    MW[5]=mi.2.DISTANCE * 0.5 + mi.4.DISTANCE * 0.5
    MW[6]=0
  ENDIF
  
  IF(%ITERATION%==3) 
    MW[1]=mi.1.TIME * 0.333 + mi.3.TIME * 0.666
    MW[2]=mi.1.DISTANCE * 0.333 + mi.3.DISTANCE * 0.666
    MW[3]=0
    MW[4]=mi.2.TIME * 0.333 + mi.4.TIME * 0.666
    MW[5]=mi.2.DISTANCE * 0.333 + mi.4.DISTANCE * 0.666
    MW[6]=0
  ENDIF
  
  IF(%ITERATION%==4) 
    MW[1]=mi.1.TIME * 0.25 + mi.3.TIME * 0.75
    MW[2]=mi.1.DISTANCE * 0.25 + mi.3.DISTANCE * 0.75
    MW[3]=0
    MW[4]=mi.2.TIME * 0.25 + mi.4.TIME * 0.75
    MW[5]=mi.2.DISTANCE * 0.25 + mi.4.DISTANCE * 0.75
    MW[6]=0
  ENDIF
  
  IF(%ITERATION%==5) 
    MW[1]=mi.1.TIME * 0.2 + mi.3.TIME * 0.8
    MW[2]=mi.1.DISTANCE * 0.2 + mi.3.DISTANCE * 0.8
    MW[3]=0
    MW[4]=mi.2.TIME * 0.2 + mi.4.TIME * 0.8
    MW[5]=mi.2.DISTANCE * 0.2 + mi.4.DISTANCE * 0.8
    MW[6]=0
  ENDIF
  
ENDRUN 

;copy files
*XCOPY "%OUTPUT_FOLDER%\peakcur.mat"    "%OUTPUT_FOLDER%\peakprev.mat"* /Y
*XCOPY "%OUTPUT_FOLDER%\offpeakcur.mat" "%OUTPUT_FOLDER%\offpeakprev.mat"* /Y
*XCOPY "%OUTPUT_FOLDER%\peakavg.mat"     "%OUTPUT_FOLDER%\peakcur.mat"* /Y
*XCOPY "%OUTPUT_FOLDER%\offpeakavg.mat"  "%OUTPUT_FOLDER%\offpeakcur.mat"* /Y
*XCOPY "%OUTPUT_FOLDER%\peakavg.mat"     "%OUTPUT_FOLDER%\peakavg_%ITERATION%.mat"* /Y
*XCOPY "%OUTPUT_FOLDER%\offpeakavg.mat"  "%OUTPUT_FOLDER%\offpeakavg_%ITERATION%.mat"* /Y
