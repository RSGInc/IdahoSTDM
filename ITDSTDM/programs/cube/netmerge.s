RUN PGM=HWYNET
  NETI[1]="outputs/itdamassignfinal.net"
  NETI[2]="outputs/itdmdassignfinal.net"
  NETI[3]="outputs/itdpmassignfinal.net"
  NETI[4]="outputs/itdntassignfinal.net"
  NETO="outputs/itdassignfinal.net"                  ; output network that shows volume differences 

  MERGE RECORD=F

; create a temporary variable '_COUNT' to accumulate link counts
  _COUNT=1 
  _VOLAM=L1.VOLAM
  _VOLMD=L2.VOLMD
  _VOLPM=L3.VOLPM
  _VOLNT=L4.VOLNT
  _CAPAM=L1.CAPAM
  _CAPMD=L2.CAPMD
  _CAPPM=L3.CAPPM
  _CAPNT=L4.CAPNT
  VOL  = _VOLAM + _VOLMD + _VOLPM + _VOLNT
  CAP  = _CAPAM + _CAPMD + _CAPPM + _CAPNT
  VC   = VOL/MAX(1, CAP)
  
  IF (VC > 1)
	LOS = 'F'
  ELSE 
  IF (VC > .9)
	LOS = 'E'
  ELSE
  IF (VC > .75)
    LOS = 'D'
  ELSE
  IF (VC > .58)
	LOS = 'C'
  ELSE
  IF (VC > .35)
    LOS = 'B'
  ELSE
    LOS = 'A'
  ENDIF
  ENDIF
  ENDIF
  ENDIF
  ENDIF
  
  IF (VCAM > 1)
	LOSAM = 'F'
  ELSE 
  IF (VCAM > .9)
	LOSAM = 'E'
  ELSE
  IF (VCAM > .75)
    LOSAM = 'D'
  ELSE
  IF (VCAM > .58)
	LOSAM = 'C'
  ELSE
  IF (VCAM > .35)
    LOSAM = 'B'
  ELSE
    LOSAM = 'A'
  ENDIF
  ENDIF
  ENDIF
  ENDIF
  ENDIF
  
  IF (VCPM > 1)
	LOSPM = 'F'
  ELSE 
  IF (VCPM > .9)
	LOSPM = 'E'
  ELSE
  IF (VCPM > .75)
    LOSPM = 'D'
  ELSE
  IF (VCPM > .58)
	LOSPM = 'C'
  ELSE
  IF (VCPM > .35)
    LOSPM = 'B'
  ELSE
    LOSPM = 'A'
  ENDIF
  ENDIF
  ENDIF
  ENDIF
  ENDIF
ENDRUN

