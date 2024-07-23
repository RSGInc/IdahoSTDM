;Code link area type based on buffered TAZ density
;Ben Stabler, ben.stabler@rsginc.com, 02/24/15

nZones = %NZONES%

RUN PGM=NETWORK

  nodei[1]="%INPUT_FOLDER%/itd.net"
  nodei[2]="%INPUT_FOLDER%/tazs.csv" VAR=STDM_TAZ,State(C),County(C),MPO(C),IsMPO,ITDDist,
    Area,DayPark,HourPark,AgforF,MiningF,UtilF,ConstrF,ManufF,WhlsaleF,RetailF,
    TrawhseF,InfoF,FininsF,EduK12,EduHigh,EduOthers,RealestF,ProftechF,MgmtF,
    WastadmnF,HealthF,ArtsentF,FoodlodgF,OtherF,PublicF,TotEmp,STATEFPS,
    COUNTYFPS,CNTYIDFP00,TOTPOP_T,TOTHH_T, RENAME=STDM_TAZ-N
  
	;put data into arrays for later
  array _tazn    =@nZones@ ;id
  array _tazx    =@nZones@ ;x coord
  array _tazy    =@nZones@ ;y coord
  array _tazemp  =@nZones@ ;employment
  array _tazhh   =@nZones@ ;households
  array _tazarea =@nZones@ ;area
  
	phase=input filei=ni.1
		IF (N<=@nZones@)
		  _tazn[N]    =N
		  _tazx[N]    =X
		  _tazy[N]    =Y
		ENDIF
  endphase
  
  phase=input filei=ni.2
		_tazemp[N]  =TotEmp
		_tazhh[N]   =TOTHH_T
		_tazarea[N] =Area
  endphase
  
  ;loop through tazs and calculate density
  phase=nodemerge
    
    IF (N<=@nZones@)
    
  		;find near TAZs
  		_max_dist= 805; 1/2 mile in meters
  		
  		;totals
  		_emp  =0
  		_hh   =0
  		_area =0
  		_at   =1 ; 1=rural, 2=urban, 3=cbd
  		
  		loop _index=1,@nZones@
  				;calculate distance
  				_dist = sqrt((X-_tazx[_index])^2 +(Y-_tazy[_index])^2)
  
          ;add up variables
  				if (_dist < _max_dist)
  					_emp  = _emp  + _tazemp[_index]
  					_hh   = _hh   + _tazhh[_index]
  					_area = _area + (_tazarea[_index] * 0.000000386) ;sq m to sq mi
  				ENDIF
  		ENDLOOP
  				
  		;code area type
  		IF (_area>0) 
  		  _den = (_hh + 2 * _emp) / _area
  		ENDIF
  		IF (_den >= 1000 & _den < 7000) 
  			_at = 2
  		ENDIF
  		IF (_den >= 7000 ) 
  			_at = 3
  		ENDIF
  		
  		;taz, emp, hh, area, at, x, y
  		print, form=8.0, file="%OUTPUT_FOLDER%\taz_area_type.txt",list=N, X, Y, _emp, _hh, _area, _at
  	
  	ENDIF
		
	endphase
	
ENDRUN


RUN PGM=NETWORK

  nodei[1]="%INPUT_FOLDER%/itd.net"
  nodei[2]="%OUTPUT_FOLDER%/taz_area_type.txt",VAR=N,X,Y,EMP,HH,AREA,AT
  
	;put data into arrays for later
  array _tazn    =@nZones@ ;id
  array _tazx    =@nZones@ ;x coord
  array _tazy    =@nZones@ ;y coord
  array _tazat   =@nZones@ ;area type
  
  phase=input filei=ni.2
		_tazx[N]    =X
		_tazy[N]    =Y
		_tazat[N]   =AT
  endphase
  
  ;loop through network nodes and assign nearest zone AT
  phase=nodemerge
        
    _min_dist = 999999
    _min_at   = 0
		loop _index=1,@nZones@
				;calculate distance
				_dist = sqrt((X-_tazx[_index])^2 +(Y-_tazy[_index])^2)  
				if (_dist < _min_dist)
				   _min_dist = _dist
					_min_at    = _tazat[_index]
				ENDIF
		ENDLOOP
				
		;node, area type
		print, file="%OUTPUT_FOLDER%\node_area_type.txt",list=N, _min_at
		
	endphase
	
ENDRUN

RUN PGM=NETWORK

  linki[1]="%INPUT_FOLDER%/itd.net"
  nodei[2]="%OUTPUT_FOLDER%/node_area_type.txt",VAR=N, AT
  neto="%OUTPUT_FOLDER%/itd.net"
    
  ;set link area type to max of node area types
  phase=linkmerge
    IF(A.AT<=B.AT)
     AT=B.AT
    ENDIF
    IF(A.AT>B.AT)
     AT=A.AT
    ENDIF
	endphase
	
ENDRUN
