
; Calculate ITD STDM Model TREDIS Inputs
; Ben Stabler, stabler@pbworld.com, 02/26/15
; Sujan Sikder, sikders@pbworld.com, 08/28/2015
; User Classes: SOV, HOV2, HOV3P, SUT, MUT, Externals

MODEL_YEAR = %MODEL_YEAR%
nZones = %NZONES%
congestedVC = 0.75

;Accumulate measures
RUN PGM=NETWORK
    
  ;Input and Output Files
  FILEI LINKI[1] = "outputs/itdamassignfinal.net"
  FILEI LINKI[2] = "outputs/itdmdassignfinal.net"  
  FILEI LINKI[3] = "outputs/itdpmassignfinal.net"
  FILEI LINKI[4] = "outputs/itdntassignfinal.net"  
  FILEO PRINTO[1]= "outputs/tredis_inputs.csv"
  
  ;Loop across links
  PHASE=INPUT FILEI=li.1
    
    ;Get link attributes
    _VolSOV_AM   = SOVAMS + SOVAML
    _VolHOV2_AM  = HOV2AMS + HOV2AML
    _VolHOV3P_AM = HOV3PAMS + HOV3PAML
    _VolSUT_AM   = SUTAM  
    _VolMUT_AM   = MUTAM  
    _VolEXT_AM   = EXTAM  
    _Miles_AM    = MILES 
    _Mph_AM      = CSPEEDAM
    
    ;Sum origin connector volume to get trips
    IF (A <= @NZONES@) 
      _TripsSOV_AM   = _TripsSOV_AM   + _VolSOV_AM
      _TripsHOV2_AM  = _TripsHOV2_AM  + _VolHOV2_AM
      _TripsHOV3P_AM = _TripsHOV3P_AM + _VolHOV3P_AM
      _TripsSUT_AM   = _TripsSUT_AM + _VolSUT_AM
      _TripsMUT_AM   = _TripsMUT_AM + _VolMUT_AM
      _TripsEXT_AM   = _TripsEXT_AM + _VolEXT_AM
      _Trips_AM = _Trips_AM + (_VolSOV_AM + _VolHOV2_AM + _VolHOV3P_AM + _VolSUT_AM + _VolMUT_AM + _VolEXT_AM)
    ENDIF
    
    ;Calculate VMT and VHT for network links (not connectors)
    IF (A > @NZONES@ & B > @NZONES@) 
      _VMTSOV_AM   = _VMTSOV_AM   + _VolSOV_AM   * _Miles_AM
      _VMTHOV2_AM  = _VMTHOV2_AM  + _VolHOV2_AM  * _Miles_AM
      _VMTHOV3P_AM = _VMTHOV3P_AM + _VolHOV3P_AM * _Miles_AM
      _VMTSUT_AM   = _VMTSUT_AM + _VolSUT_AM * _Miles_AM
      _VMTMUT_AM   = _VMTMUT_AM + _VolMUT_AM * _Miles_AM
      _VMTEXT_AM   = _VMTEXT_AM + _VolEXT_AM * _Miles_AM
      _VMT_AM = _VMT_AM + (_VolSOV_AM + _VolHOV2_AM + _VolHOV3P_AM + _VolSUT_AM + _VolMUT_AM + _VolEXT_AM) * _Miles_AM
      
      _VHTSOV_AM   = _VHTSOV_AM   + _VolSOV_AM   * (_Miles_AM / _Mph_AM)
      _VHTHOV2_AM  = _VHTHOV2_AM  + _VolHOV2_AM  * (_Miles_AM / _Mph_AM)
      _VHTHOV3P_AM = _VHTHOV3P_AM + _VolHOV3P_AM * (_Miles_AM / _Mph_AM)
      _VHTSUT_AM   = _VHTSUT_AM + _VolSUT_AM * (_Miles_AM / _Mph_AM)
      _VHTMUT_AM   = _VHTMUT_AM + _VolMUT_AM * (_Miles_AM / _Mph_AM)
      _VHTEXT_AM   = _VHTEXT_AM + _VolEXT_AM * (_Miles_AM / _Mph_AM)
      _VHT_AM = _VHT_AM + (_VolSOV_AM + _VolHOV2_AM + _VolHOV3P_AM + _VolSUT_AM + _VolMUT_AM + _VolEXT_AM) * (_Miles_AM / _Mph_AM)
      
      IF (_VC_AM > @congestedVC@)
        _CONGVMT_AM  = _CONGVMT_AM + (_VolSOV_AM + _VolHOV2_AM + _VolHOV3P_AM + _VolSUT_AM + _VolMUT_AM + _VolEXT_AM) * _Miles_AM
      ENDIF
        
    ENDIF
    
  ENDPHASE
  
  ;Loop across links
  PHASE=INPUT FILEI=li.2
    
    ;Get link attributes
    _VolSOV_MD   = SOVMDS + SOVMDL 
    _VolHOV2_MD  = HOV2MDS + HOV2MDL
    _VolHOV3P_MD = HOV3PMDS + HOV3PMDL
    _VolSUT_MD   = SUTMD  
    _VolMUT_MD   = MUTMD  
    _VolEXT_MD   = EXTMD  
    _Miles_MD    = MILES 
    _Mph_MD      = CSPEEDMD
    _VC_MD       = VCMD
    
    ;Sum origin connector volume to get trips
    IF (A <= @NZONES@) 
      _TripsSOV_MD   = _TripsSOV_MD   + _VolSOV_MD
      _TripsHOV2_MD  = _TripsHOV2_MD  + _VolHOV2_MD
      _TripsHOV3P_MD = _TripsHOV3P_MD + _VolHOV3P_MD
      _TripsSUT_MD   = _TripsSUT_MD + _VolSUT_MD
      _TripsMUT_MD   = _TripsMUT_MD + _VolMUT_MD
      _TripsEXT_MD   = _TripsEXT_MD + _VolEXT_MD
      _Trips_MD = _Trips_MD + (_VolSOV_MD + _VolHOV2_MD + _VolHOV3P_MD + _VolSUT_MD + _VolMUT_MD + _VolEXT_MD)
    ENDIF
    
    ;Calculate VMT and VHT for network links (not connectors)
    IF (A > @NZONES@ & B > @NZONES@) 
      _VMTSOV_MD   = _VMTSOV_MD   + _VolSOV_MD   * _Miles_MD
      _VMTHOV2_MD  = _VMTHOV2_MD  + _VolHOV2_MD  * _Miles_MD
      _VMTHOV3P_MD = _VMTHOV3P_MD + _VolHOV3P_MD * _Miles_MD
      _VMTSUT_MD   = _VMTSUT_MD + _VolSUT_MD * _Miles_MD
      _VMTMUT_MD   = _VMTMUT_MD + _VolMUT_MD * _Miles_MD
      _VMTEXT_MD   = _VMTEXT_MD + _VolEXT_MD * _Miles_MD
      _VMT_MD = _VMT_MD + (_VolSOV_MD + _VolHOV2_MD + _VolHOV3P_MD + _VolSUT_MD + _VolMUT_MD + _VolEXT_MD) * _Miles_MD
      
      _VHTSOV_MD   = _VHTSOV_MD   + _VolSOV_MD   * (_Miles_MD / _Mph_MD)
      _VHTHOV2_MD  = _VHTHOV2_MD  + _VolHOV2_MD  * (_Miles_MD / _Mph_MD)
      _VHTHOV3P_MD = _VHTHOV3P_MD + _VolHOV3P_MD * (_Miles_MD / _Mph_MD)
      _VHTSUT_MD   = _VHTSUT_MD + _VolSUT_MD * (_Miles_MD / _Mph_MD)
      _VHTMUT_MD   = _VHTMUT_MD + _VolMUT_MD * (_Miles_MD / _Mph_MD)
      _VHTEXT_MD   = _VHTEXT_MD + _VolEXT_MD * (_Miles_MD / _Mph_MD)
      _VHT_MD = _VHT_MD + (_VolSOV_MD + _VolHOV2_MD + _VolHOV3P_MD + _VolSUT_MD + _VolMUT_MD + _VolEXT_MD) * (_Miles_MD / _Mph_MD)
      
      IF (_VC_MD > @congestedVC@)
        _CONGVMT_MD  = _CONGVMT_MD + (_VolSOV_MD + _VolHOV2_MD + _VolHOV3P_MD + _VolSUT_MD + _VolMUT_MD + _VolEXT_MD) * _Miles_MD
      ENDIF
      
    ENDIF
    
  ENDPHASE

  ;Loop across links
  PHASE=INPUT FILEI=li.3
    
    ;Get link attributes
    _VolSOV_PM   = SOVPMS + SOVPML 
    _VolHOV2_PM  = HOV2PMS + HOV2PML
    _VolHOV3P_PM = HOV3PPMS + HOV3PPML
    _VolSUT_PM   = SUTPM  
    _VolMUT_PM   = MUTPM  
    _VolEXT_PM   = EXTPM  
    _Miles_PM    = MILES 
    _Mph_PM      = CSPEEDPM
    _VC_PM       = VCPM
    
    ;Sum origin connector volume to get trips
    IF (A <= @NZONES@) 
      _TripsSOV_PM   = _TripsSOV_PM   + _VolSOV_PM
      _TripsHOV2_PM  = _TripsHOV2_PM  + _VolHOV2_PM
      _TripsHOV3P_PM = _TripsHOV3P_PM + _VolHOV3P_PM
      _TripsSUT_PM   = _TripsSUT_PM + _VolSUT_PM
      _TripsMUT_PM   = _TripsMUT_PM + _VolMUT_PM
      _TripsEXT_PM   = _TripsEXT_PM + _VolEXT_PM
      _Trips_PM = _Trips_PM + (_VolSOV_PM + _VolHOV2_PM + _VolHOV3P_PM + _VolSUT_PM + _VolMUT_PM + _VolEXT_PM)
   ENDIF
    
    ;Calculate VMT and VHT for network links (not connectors)
    IF (A > @NZONES@ & B > @NZONES@) 
      _VMTSOV_PM   = _VMTSOV_PM   + _VolSOV_PM   * _Miles_PM
      _VMTHOV2_PM  = _VMTHOV2_PM  + _VolHOV2_PM  * _Miles_PM
      _VMTHOV3P_PM = _VMTHOV3P_PM + _VolHOV3P_PM * _Miles_PM
      _VMTSUT_PM   = _VMTSUT_PM + _VolSUT_PM * _Miles_PM
      _VMTMUT_PM   = _VMTMUT_PM + _VolMUT_PM * _Miles_PM
      _VMTEXT_PM   = _VMTEXT_PM + _VolEXT_PM * _Miles_PM
      _VMT_PM = _VMT_PM + (_VolSOV_PM + _VolHOV2_PM + _VolHOV3P_PM + _VolSUT_PM + _VolMUT_PM + _VolEXT_PM) * _Miles_PM
      
      _VHTSOV_PM   = _VHTSOV_PM   + _VolSOV_PM   * (_Miles_PM / _Mph_PM)
      _VHTHOV2_PM  = _VHTHOV2_PM  + _VolHOV2_PM  * (_Miles_PM / _Mph_PM)
      _VHTHOV3P_PM = _VHTHOV3P_PM + _VolHOV3P_PM * (_Miles_PM / _Mph_PM)
      _VHTSUT_PM   = _VHTSUT_PM + _VolSUT_PM * (_Miles_PM / _Mph_PM)
      _VHTMUT_PM   = _VHTMUT_PM + _VolMUT_PM * (_Miles_PM / _Mph_PM)
      _VHTEXT_PM   = _VHTEXT_PM + _VolEXT_PM * (_Miles_PM / _Mph_PM)
      _VHT_PM = _VHT_PM + (_VolSOV_PM + _VolHOV2_PM + _VolHOV3P_PM + _VolSUT_PM + _VolMUT_PM + _VolEXT_PM) * (_Miles_PM / _Mph_PM)
      
      IF (_VC_PM > @congestedVC@)
        _CONGVMT_PM  = _CONGVMT_PM + (_VolSOV_PM + _VolHOV2_PM + _VolHOV3P_PM + _VolSUT_PM + _VolMUT_PM + _VolEXT_PM) * _Miles_PM
      ENDIF
      
    ENDIF
    
  ENDPHASE
  
    ;Loop across links
  PHASE=INPUT FILEI=li.4
    
    ;Get link attributes
    _VolSOV_NT   = SOVNTS + SOVNTL 
    _VolHOV2_NT  = HOV2NTS + HOV2NTL
    _VolHOV3P_NT = HOV3PNTS + HOV3PNTL
    _VolSUT_NT   = SUTNT  
    _VolMUT_NT   = MUTNT  
    _VolEXT_NT   = EXTNT  
    _Miles_NT    = MILES 
    _Mph_NT      = CSPEEDNT
    _VC_NT       = VCNT
    
    ;Sum origin connector volume to get trips
    IF (A <= @NZONES@) 
      _TripsSOV_NT   = _TripsSOV_NT   + _VolSOV_NT
      _TripsHOV2_NT  = _TripsHOV2_NT  + _VolHOV2_NT
      _TripsHOV3P_NT = _TripsHOV3P_NT + _VolHOV3P_NT
      _TripsSUT_NT   = _TripsSUT_NT + _VolSUT_NT
      _TripsMUT_NT   = _TripsMUT_NT + _VolMUT_NT
      _TripsEXT_NT   = _TripsEXT_NT + _VolEXT_NT
      _Trips_NT = _Trips_NT + (_VolSOV_NT + _VolHOV2_NT + _VolHOV3P_NT + _VolSUT_NT + _VolMUT_NT + _VolEXT_NT)
    ENDIF
    
    ;Calculate VMT and VHT for network links (not connectors)
    IF (A > @NZONES@ & B > @NZONES@) 
      _VMTSOV_NT   = _VMTSOV_NT   + _VolSOV_NT   * _Miles_NT
      _VMTHOV2_NT  = _VMTHOV2_NT  + _VolHOV2_NT  * _Miles_NT
      _VMTHOV3P_NT = _VMTHOV3P_NT + _VolHOV3P_NT * _Miles_NT
      _VMTSUT_NT   = _VMTSUT_NT + _VolSUT_NT * _Miles_NT
      _VMTMUT_NT   = _VMTMUT_NT + _VolMUT_NT * _Miles_NT
      _VMTEXT_NT   = _VMTEXT_NT + _VolEXT_NT * _Miles_NT
      _VMT_NT = _VMT_NT + (_VolSOV_NT + _VolHOV2_NT + _VolHOV3P_NT + _VolSUT_NT + _VolMUT_NT + _VolEXT_NT) * _Miles_NT
      
      _VHTSOV_NT   = _VHTSOV_NT   + _VolSOV_NT   * (_Miles_NT / _Mph_NT)
      _VHTHOV2_NT  = _VHTHOV2_NT  + _VolHOV2_NT  * (_Miles_NT / _Mph_NT)
      _VHTHOV3P_NT = _VHTHOV3P_NT + _VolHOV3P_NT * (_Miles_NT / _Mph_NT)
      _VHTSUT_NT   = _VHTSUT_NT + _VolSUT_NT * (_Miles_NT / _Mph_NT)
      _VHTMUT_NT   = _VHTMUT_NT + _VolMUT_NT * (_Miles_NT / _Mph_NT)
      _VHTEXT_NT   = _VHTEXT_NT + _VolEXT_NT * (_Miles_NT / _Mph_NT)
      _VHT_NT = _VHT_NT + (_VolSOV_NT + _VolHOV2_NT + _VolHOV3P_NT + _VolSUT_NT + _VolMUT_NT + _VolEXT_NT) * (_Miles_NT / _Mph_NT)
      
      IF (_VC_NT > @congestedVC@)
        _CONGVMT_NT  = _CONGVMT_NT + (_VolSOV_NT + _VolHOV2_NT + _VolHOV3P_NT + _VolSUT_NT + _VolMUT_NT + _VolEXT_NT) * _Miles_NT
      ENDIF
      
    ENDIF
    
  ENDPHASE
  ;Write measures at the end
  PHASE=SUMMARY
  
    PRINT LIST="Measure,Period,UserClass,Value", PRINTO=1
    PRINT LIST="Year,All,All,@MODEL_YEAR@", PRINTO=1
    
    PRINT LIST="Trips,AM,SOV,",_TripsSOV_AM, PRINTO=1
    PRINT LIST="Trips,AM,HOV2,",_TripsHOV2_AM, PRINTO=1
    PRINT LIST="Trips,AM,HOV3P,",_TripsHOV3P_AM, PRINTO=1
    PRINT LIST="Trips,AM,SUT,",_TripsSUT_AM, PRINTO=1
    PRINT LIST="Trips,AM,MUT,",_TripsMUT_AM, PRINTO=1
    PRINT LIST="Trips,AM,EXT,",_TripsEXT_AM, PRINTO=1
    PRINT LIST="Trips,AM,All,",_Trips_AM, PRINTO=1
    
    PRINT LIST="Trips,MD,SOV,",_TripsSOV_MD, PRINTO=1
    PRINT LIST="Trips,MD,HOV2,",_TripsHOV2_MD, PRINTO=1
    PRINT LIST="Trips,MD,HOV3P,",_TripsHOV3P_MD, PRINTO=1
    PRINT LIST="Trips,MD,SUT,",_TripsSUT_MD, PRINTO=1
    PRINT LIST="Trips,MD,MUT,",_TripsMUT_MD, PRINTO=1
    PRINT LIST="Trips,MD,EXT,",_TripsEXT_MD, PRINTO=1
    PRINT LIST="Trips,MD,All,",_Trips_MD, PRINTO=1
    
    PRINT LIST="Trips,PM,SOV,",_TripsSOV_PM, PRINTO=1
    PRINT LIST="Trips,PM,HOV2,",_TripsHOV2_PM, PRINTO=1
    PRINT LIST="Trips,PM,HOV3P,",_TripsHOV3P_PM, PRINTO=1
    PRINT LIST="Trips,PM,SUT,",_TripsSUT_PM, PRINTO=1
    PRINT LIST="Trips,PM,MUT,",_TripsMUT_PM, PRINTO=1
    PRINT LIST="Trips,PM,EXT,",_TripsEXT_PM, PRINTO=1
    PRINT LIST="Trips,PM,All,",_Trips_PM, PRINTO=1
    
    PRINT LIST="Trips,NT,SOV,",_TripsSOV_NT, PRINTO=1
    PRINT LIST="Trips,NT,HOV2,",_TripsHOV2_NT, PRINTO=1
    PRINT LIST="Trips,NT,HOV3P,",_TripsHOV3P_NT, PRINTO=1
    PRINT LIST="Trips,NT,SUT,",_TripsSUT_NT, PRINTO=1
    PRINT LIST="Trips,NT,MUT,",_TripsMUT_NT, PRINTO=1
    PRINT LIST="Trips,NT,EXT,",_TripsEXT_NT, PRINTO=1
    PRINT LIST="Trips,NT,All,",_Trips_NT, PRINTO=1
    
    PRINT LIST="VMT,AM,SOV,",_VMTSOV_AM, PRINTO=1
    PRINT LIST="VMT,AM,HOV2,",_VMTHOV2_AM, PRINTO=1
    PRINT LIST="VMT,AM,HOV3P,",_VMTHOV3P_AM, PRINTO=1
    PRINT LIST="VMT,AM,SUT,",_VMTSUT_AM, PRINTO=1
    PRINT LIST="VMT,AM,MUT,",_VMTMUT_AM, PRINTO=1
    PRINT LIST="VMT,AM,EXT,",_VMTEXT_AM, PRINTO=1
    PRINT LIST="VMT,AM,All,",_VMT_AM, PRINTO=1
    PRINT LIST="CONGVMT,AM,All,",_CONGVMT_AM, PRINTO=1
    
    PRINT LIST="VMT,MD,SOV,",_VMTSOV_MD, PRINTO=1
    PRINT LIST="VMT,MD,HOV2,",_VMTHOV2_MD, PRINTO=1
    PRINT LIST="VMT,MD,HOV3P,",_VMTHOV3P_MD, PRINTO=1
    PRINT LIST="VMT,MD,SUT,",_VMTSUT_MD, PRINTO=1
    PRINT LIST="VMT,MD,MUT,",_VMTMUT_MD, PRINTO=1
    PRINT LIST="VMT,MD,EXT,",_VMTEXT_MD, PRINTO=1
    PRINT LIST="VMT,MD,All,",_VMT_MD, PRINTO=1
    PRINT LIST="CONGVMT,MD,All,",_CONGVMT_MD, PRINTO=1
        
    PRINT LIST="VMT,PM,SOV,",_VMTSOV_PM, PRINTO=1
    PRINT LIST="VMT,PM,HOV2,",_VMTHOV2_PM, PRINTO=1
    PRINT LIST="VMT,PM,HOV3P,",_VMTHOV3P_PM, PRINTO=1
    PRINT LIST="VMT,PM,SUT,",_VMTSUT_PM, PRINTO=1
    PRINT LIST="VMT,PM,MUT,",_VMTMUT_PM, PRINTO=1
    PRINT LIST="VMT,PM,EXT,",_VMTEXT_PM, PRINTO=1
    PRINT LIST="VMT,PM,All,",_VMT_PM, PRINTO=1
    PRINT LIST="CONGVMT,PM,All,",_CONGVMT_PM, PRINTO=1
    
    PRINT LIST="VMT,NT,SOV,",_VMTSOV_NT, PRINTO=1
    PRINT LIST="VMT,NT,HOV2,",_VMTHOV2_NT, PRINTO=1
    PRINT LIST="VMT,NT,HOV3P,",_VMTHOV3P_NT, PRINTO=1
    PRINT LIST="VMT,NT,SUT,",_VMTSUT_NT, PRINTO=1
    PRINT LIST="VMT,NT,MUT,",_VMTMUT_NT, PRINTO=1
    PRINT LIST="VMT,NT,EXT,",_VMTEXT_NT, PRINTO=1
    PRINT LIST="VMT,NT,All,",_VMT_NT, PRINTO=1
    PRINT LIST="CONGVMT,NT,All,",_CONGVMT_NT, PRINTO=1
    
    PRINT LIST="VHT,AM,SOV,",_VHTSOV_AM, PRINTO=1
    PRINT LIST="VHT,AM,HOV2,",_VHTHOV2_AM, PRINTO=1
    PRINT LIST="VHT,AM,HOV3P,",_VHTHOV3P_AM, PRINTO=1
    PRINT LIST="VHT,AM,SUT,",_VHTSUT_AM, PRINTO=1
    PRINT LIST="VHT,AM,MUT,",_VHTMUT_AM, PRINTO=1
    PRINT LIST="VHT,AM,EXT,",_VHTEXT_AM, PRINTO=1
    PRINT LIST="VHT,AM,All,",_VHT_AM, PRINTO=1
    
    PRINT LIST="VHT,MD,SOV,",_VHTSOV_MD, PRINTO=1
    PRINT LIST="VHT,MD,HOV2,",_VHTHOV2_MD, PRINTO=1
    PRINT LIST="VHT,MD,HOV3P,",_VHTHOV3P_MD, PRINTO=1
    PRINT LIST="VHT,MD,SUT,",_VHTSUT_MD, PRINTO=1
    PRINT LIST="VHT,MD,MUT,",_VHTMUT_MD, PRINTO=1
    PRINT LIST="VHT,MD,EXT,",_VHTEXT_MD, PRINTO=1
    PRINT LIST="VHT,MD,All,",_VHT_MD, PRINTO=1
    
    PRINT LIST="VHT,PM,SOV,",_VHTSOV_PM, PRINTO=1
    PRINT LIST="VHT,PM,HOV2,",_VHTHOV2_PM, PRINTO=1
    PRINT LIST="VHT,PM,HOV3P,",_VHTHOV3P_PM, PRINTO=1
    PRINT LIST="VHT,PM,SUT,",_VHTSUT_PM, PRINTO=1
    PRINT LIST="VHT,PM,MUT,",_VHTMUT_PM, PRINTO=1
    PRINT LIST="VHT,PM,EXT,",_VHTEXT_PM, PRINTO=1
    PRINT LIST="VHT,PM,All,",_VHT_PM, PRINTO=1
    
    PRINT LIST="VHT,NT,SOV,",_VHTSOV_NT, PRINTO=1
    PRINT LIST="VHT,NT,HOV2,",_VHTHOV2_NT, PRINTO=1
    PRINT LIST="VHT,NT,HOV3P,",_VHTHOV3P_NT, PRINTO=1
    PRINT LIST="VHT,NT,SUT,",_VHTSUT_NT, PRINTO=1
    PRINT LIST="VHT,NT,MUT,",_VHTMUT_NT, PRINTO=1
    PRINT LIST="VHT,NT,EXT,",_VHTEXT_NT, PRINTO=1
    PRINT LIST="VHT,NT,All,",_VHT_NT, PRINTO=1
  ENDPHASE

ENDRUN
