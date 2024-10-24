RUN PGM=NETWORK
	FILEI NETI="%INPUT_FOLDER%\itd.net"
	FILEO LINKO="%INPUT_FOLDER%\itd_input.dbf"
ENDRUN

RUN PGM=HIGHWAY 
  NETI="%INPUT_FOLDER%\itd.net"
  MATO[1]="%INPUT_FOLDER%\check_skim.mat",MO=1,NAME=DISTANCE
  
  ZONES=%NZONES%
  
  PHASE = LINKREAD
    T0 = (LI.MILES/LI.SPEED)*60
    LW.IMPEDA  = T0 
  ENDPHASE
     
  PHASE=ILOOP
    PATHLOAD PATH=COST, DEC=1, MW[1]=pathtrace(LI.MILES), NOACCESS = -1
    COMP MW[1][I]= 0.5 * lowest(1,3,0.001,9999,I)/max(1,lowcnt)
  ENDPHASE
ENDRUN

RUN PGM=MATRIX
	FILEI MATI[1]="%INPUT_FOLDER%\check_skim.mat"
	FILEO MATO[1]="%INPUT_FOLDER%\check_skim.dbf", MO=1, PATTERN=I:JV, FORMAT=DBF
	
	MW[1] = MI.1.1
ENDRUN
	