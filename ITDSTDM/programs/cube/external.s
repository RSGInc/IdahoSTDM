;External model
;Ben Stabler, ben.stabler@rsginc.com, 02/10/15
;Sujan Sikder, sikders@pbworld.com, 03/2/15,3/13/2015,3/17/2015
;Revised to use VISITOR PERCENT of ADT calculated using AirSage visitor 
; to total trips ratio in external zone areas

;Input files: 
; 1) Adjusted_Trips.MAT(phase-1 model output matrix) or seed.mat (if application mode, seed is input instead of created)
; 2) itd.net(itd network)
; 3) external.csv(external station data) ;external station no., base year count(2010), TAZ, growth rate, street address 

;Output file: 
; 1) externals.mat ;contains I-E, E-I and E-E trips in matrix format
; 2) externalTrips.csv ;total trips by external stations in table format

;Steps:
;  Create seed
; 1) Aggregate the phase-1 model trip tables
; 2) Get the O-D flows that use each external station link 
; 3) Remove I-I trips from the above matrices(if there is any)
; 4) Allocate the taz trips to the corresponding external stations 
; 5) Create seed matrix for the fratar distribution
;  Apply model to counts
; 6) Calculate future year counts using base year counts(i.e.,2010) and growth rates
; 7) Create row and column control totals for the fratar distribution 
; 8) Fratar the seed matrix to the controlled row and column data
; 9) Output the total trips by external stations

;----------------------------------------------------------------------------------------------
;Parameters
;----------------------------------------------------------------------------------------------
 
 NZONES = %NZONES% ;no. of zones
 MAXITERANS = 1 ;no. of iterations in the assignment proecedure 
 HWYNET = 'itd.net' ;itd network file
 NEXTERNALS = 35 ;no. of external stations 
 FEXT = 6001 ;first external station
 LEXT = %NZONES% ;last external station 
 YEAR = %MODEL_YEAR% ;forecast year
 
 COMP dummy = '4344,5586,5600,5621,5631,5640,5654-5659,5661-5665,5668,5670,5671';dummy external taz
 COMP externals = '6001-%NZONES%';external stations

 APPLY = 1 ;run in application mode so use input seed.mat instead of creating it

;----------------------------------------------------------------------------------------------
;Step 0: Skip creation of seed matrix if running in application mode
; since seed matrix already exists
;----------------------------------------------------------------------------------------------

IF (APPLY=1) GOTO :Application

;----------------------------------------------------------------------------------------------
;Step 1: Aggregate the phase-1 model trip tables
;----------------------------------------------------------------------------------------------

 RUN PGM=MATRIX

    FILEI MATI[1]= inputs\Adjusted_Trips.mat
    FILEO MATO[1]= outputs\total.mat,MO=1,Name = TOTAL

    ;MW[1] = MI.1.1 + MI.1.2 + MI.1.3 + MI.1.4 + MI.1.5 ;auto(1-4)+truck(5)
    MW[1] = MI.1.4 ;visitor
   
 ENDRUN

;----------------------------------------------------------------------------------------------
;Step 2: Get the O-D flows that use each external station link 
;----------------------------------------------------------------------------------------------
 
 RUN PGM=HIGHWAY

   MATI = outputs\total.mat
   NETI = inputs\@HWYNET@
   NETO = outputs\loaded.net
   MATO = outputs\stationOne.mat,MO=1-36,dec=2 
    
    ZONES=@NZONES@
    ;Set run PARAMETERS and Controls
    PARAMETERS ZONEMSG=100,  MAXITERS=@MAXITERANS@, COMBINE=EQUI, GAP= 0.005
    
    PHASE=ILOOP
    
    
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[1] = MI.1.1, selectlink = (L=904062-904083*)
                          VOL[2] = MW[1] ;station 1  
                            
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[2] = MI.1.1, selectlink = (L=36240-36264*,36264-635321*)
                          VOL[3] = MW[2] ;station 2                         
                          
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[3] = MI.1.1, selectlink = (L=904268-904287*,904287-904341*)
                          VOL[4] = MW[3] ;station 3  
                          
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[4] = MI.1.1, selectlink = (L=904426-904432*,904432-904435*)
                          VOL[5] = MW[4] ;station 4 
                     
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[5] = MI.1.1, selectlink = (L=904268-904287*)
                          VOL[6] = MW[5] ;station 5  
                          
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[6] = MI.1.1, selectlink = (L=904266-904350*)
                          VOL[7] = MW[6] ;station 6                   
                                                             
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[7] = MI.1.1, selectlink = (L=904356-904443*)
                          VOL[8] = MW[7] ;station 7            
             
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[8] = MI.1.1, selectlink = (L=904445-904469*)
                          VOL[9] = MW[8] ;station 8  
                          
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[9] = MI.1.1, selectlink = (L=904493-904498*)
                          VOL[10] = MW[9] ;station 9            
                                       
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[10] = MI.1.1, selectlink = (L=904499-904508*)
                          VOL[11] = MW[10] ;station 10               
                   
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[11] = MI.1.1, selectlink = (L=904619-904666*)
                          VOL[12] = MW[11] ;station 11      
                          
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[12] = MI.1.1, selectlink = (L=904693-905060*,905060-905246*)
                          VOL[13] = MW[12] ;station 12  
                                         
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[13] = MI.1.1, selectlink = (L=905317-905212*)
                          VOL[14] = MW[13] ;station 13 
                     
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[14] = MI.1.1, selectlink = (L=905333-905340*)
                          VOL[15] = MW[14] ;station 14  
                          
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[15] = MI.1.1, selectlink = (L=905361-905378*)
                          VOL[16] = MW[15] ;station 15                   
                                                             
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[16] = MI.1.1, selectlink = (L=905306-905359*)
                          VOL[17] = MW[16] ;station 16            
             
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[17] = MI.1.1, selectlink = (L=905306-905359*)
                          VOL[18] = MW[17] ;station 17  
                          
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[18] = MI.1.1, selectlink = (L=904740-904749*,904749-904750*)
                          VOL[19] = MW[18] ;station 18            
                                       
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[19] = MI.1.1, selectlink = (L=98396-904333*)
                          VOL[20] = MW[19] ;station 19               
                   
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[20] = MI.1.1, selectlink = (L=903496-903561*)
                          VOL[21] = MW[20] ;station 20                       
                          
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[21] = MI.1.1, selectlink = (L=24211-24221*)
                          VOL[22] = MW[21] ;station 21      
                          
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[22] = MI.1.1, selectlink = (L=903550-903659*)
                          VOL[23] = MW[22] ;station 22  
                          
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[23] = MI.1.1, selectlink = (L=904040-904053*)
                          VOL[24] = MW[23] ;station 23 
                     
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[24] = MI.1.1, selectlink = (L=400004-904057*)
                          VOL[25] = MW[24] ;station 24  
                          
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[25] = MI.1.1, selectlink = (L=903865-903962*)
                          VOL[26] = MW[25] ;station 25                   
                                                             
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[26] = MI.1.1, selectlink = (L=825759-825811*,825811-827285*)
                          VOL[27] = MW[26] ;station 26            
             
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[27] = MI.1.1, selectlink = (L=5621-825704*)
                          VOL[28] = MW[27] ;station 27  
                          
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[28] = MI.1.1, selectlink = (L=825452-825455*,825453-825455*)
                          VOL[29] = MW[28] ;station 28            
                                      
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[29] = MI.1.1, selectlink = (L=824691-824730*)
                          VOL[30] = MW[29] ;station 29               
                   
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[30] = MI.1.1, selectlink = (L=824394-827263*)
                          VOL[31] = MW[30] ;station 30                    
                                              
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[31] = MI.1.1, selectlink = (L=819992-820032*)
                          VOL[32] = MW[31] ;station 31            
             
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[32] = MI.1.1, selectlink = (L=806915-811932*,811932-817482*)
                          VOL[33] = MW[32] ;station 32  
                          
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[33] = MI.1.1, selectlink = (L=804663-827252*)
                          VOL[34] = MW[33] ;station 33             
                                      
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[34] = MI.1.1, selectlink = (L=802059-802650*)
                          VOL[35] = MW[34] ;station 34               
                   
      PATHLOAD PATH=COST, VOL[1] = MI.1.1, MW[35] = MI.1.1, selectlink = (L=800452-827345*)
                          VOL[36] = MW[35] ;station 35                         
                                                                                                                                               
      MW[36] = MI.1.1     
                         
    ENDPHASE                  
                       
    PHASE=ADJUST
   
      FUNCTION  COST = Li.MILES/Li.SPEED*60
      FUNCTION { V = VOL[1] } 
   
    ENDPHASE
   
 ENDRUN
 


;----------------------------------------------------------------------------------------------
;Step 3: Remove I-I trips from the above matrices(if there is any)
;----------------------------------------------------------------------------------------------
 
RUN PGM=MATRIX

   MATI[1]=outputs\stationOne.mat
   MATO =outputs\stationTwo.mat,MO=1-35,DEC=2,NAME=sta1,sta2,sta3,sta4,sta5,sta6,sta7,sta8,sta9,sta10,sta11,sta12,
                                                sta13,sta14,sta15,sta16,sta17,sta18,sta19,sta20,sta21,sta22,sta23,sta24,
                                                sta25,sta26,sta27,sta28,sta29,sta30,sta31,sta32,sta33,sta34,sta35
                                         
                                                
   ZONES = @NZONES@

   
    MW[1] = mi.1.1
    MW[2] = mi.1.2
    MW[3] = mi.1.3
    MW[4] = mi.1.4
    MW[5] = mi.1.5
    MW[6] = mi.1.6
    MW[7] = mi.1.7
    MW[8] = mi.1.8
    MW[9] = mi.1.9
    MW[10] = mi.1.10 
    MW[11] = mi.1.11
    MW[12] = mi.1.12
    MW[13] = mi.1.13
    MW[14] = mi.1.14
    MW[15] = mi.1.15
    MW[16] = mi.1.16
    MW[17] = mi.1.17
    MW[18] = mi.1.18
    MW[19] = mi.1.19
    MW[20] = mi.1.20 
    MW[21] = mi.1.21
    MW[22] = mi.1.22
    MW[23] = mi.1.23
    MW[24] = mi.1.24
    MW[25] = mi.1.25
    MW[26] = mi.1.26
    MW[27] = mi.1.27
    MW[28] = mi.1.28
    MW[29] = mi.1.29
    MW[30] = mi.1.30 
    MW[31] = mi.1.31
    MW[32] = mi.1.32
    MW[33] = mi.1.33
    MW[34] = mi.1.34
    MW[35] = mi.1.35
       
    IF(!(I = @dummy@))
      JLOOP
        IF(!(J = @dummy@))
          MW[1] = 0
          MW[2] = 0
          MW[3] = 0
          MW[4] = 0
          MW[5] = 0
          MW[6] = 0
          MW[7] = 0
          MW[8] = 0
          MW[9] = 0
          MW[10] = 0    
          MW[11] = 0
          MW[12] = 0
          MW[13] = 0
          MW[14] = 0
          MW[15] = 0
          MW[16] = 0
          MW[17] = 0
          MW[18] = 0
          MW[19] = 0
          MW[20] = 0    
          MW[21] = 0
          MW[22] = 0
          MW[23] = 0
          MW[24] = 0
          MW[25] = 0
          MW[26] = 0
          MW[27] = 0
          MW[28] = 0
          MW[29] = 0
          MW[30] = 0    
          MW[31] = 0
          MW[32] = 0
          MW[33] = 0
          MW[34] = 0
          MW[35] = 0      
       ELSE  
          MW[1] = MW[1]
          MW[2] = MW[2]
          MW[3] = MW[3]
          MW[4] = MW[4]
          MW[5] = MW[5]
          MW[6] = MW[6]
          MW[7] = MW[7]
          MW[8] = MW[8] 
          MW[9] = MW[9]
          MW[10] = MW[10]                   
          MW[11] = MW[11]
          MW[12] = MW[12]
          MW[13] = MW[13]
          MW[14] = MW[14]
          MW[15] = MW[15]
          MW[16] = MW[16]
          MW[17] = MW[17]
          MW[18] = MW[18] 
          MW[19] = MW[19]
          MW[20] = MW[20]                     
          MW[21] = MW[21]
          MW[22] = MW[22]
          MW[23] = MW[23]
          MW[24] = MW[24]
          MW[25] = MW[25]
          MW[26] = MW[26]
          MW[27] = MW[27]
          MW[28] = MW[28] 
          MW[29] = MW[29]
          MW[30] = MW[30]   
          MW[31] = MW[31]
          MW[32] = MW[32]
          MW[33] = MW[33]
          MW[34] = MW[34]
          MW[35] = MW[35]        
        ENDIF
      ENDJLOOP    
    ELSE 
          MW[1] = MW[1]
          MW[2] = MW[2]
          MW[3] = MW[3]
          MW[4] = MW[4]
          MW[5] = MW[5]
          MW[6] = MW[6]
          MW[7] = MW[7]
          MW[8] = MW[8] 
          MW[9] = MW[9]
          MW[10] = MW[10]                   
          MW[11] = MW[11]
          MW[12] = MW[12]
          MW[13] = MW[13]
          MW[14] = MW[14]
          MW[15] = MW[15]
          MW[16] = MW[16]
          MW[17] = MW[17]
          MW[18] = MW[18] 
          MW[19] = MW[19]
          MW[20] = MW[20]                     
          MW[21] = MW[21]
          MW[22] = MW[22]
          MW[23] = MW[23]
          MW[24] = MW[24]
          MW[25] = MW[25]
          MW[26] = MW[26]
          MW[27] = MW[27]
          MW[28] = MW[28] 
          MW[29] = MW[29]
          MW[30] = MW[30]   
          MW[31] = MW[31]
          MW[32] = MW[32]
          MW[33] = MW[33]
          MW[34] = MW[34]
          MW[35] = MW[35]        
    ENDIF 
 ENDRUN
  
;----------------------------------------------------------------------------------------------
;Step 4: Allocate the taz trips to the corresponding external stations 
;----------------------------------------------------------------------------------------------

;-----------------------
;create external station row and columns from the taz row and columns 

 RUN PGM=MATRIX
  
   FILEI MATI[1] = outputs\stationTwo.mat
   MATO = outputs\stationThree.mat,MO=1-105
   
   MW[36] = 0
   MW[37] = 0
   MW[38] = 0
   MW[39] = 0
   MW[40] = 0
   MW[41] = 0
   MW[42] = 0
   MW[43] = 0
   MW[44] = 0
   MW[45] = 0
   MW[46] = 0
   MW[47] = 0
   MW[48] = 0
   MW[49] = 0
   MW[50] = 0
   MW[51] = 0
   MW[52] = 0
   MW[53] = 0
   MW[54] = 0
   MW[55] = 0
   MW[56] = 0
   MW[57] = 0
   MW[58] = 0
   MW[59] = 0
   MW[60] = 0
   MW[61] = 0
   MW[62] = 0
   MW[63] = 0
   MW[64] = 0
   MW[65] = 0
   MW[66] = 0
   MW[67] = 0
   MW[68] = 0
   MW[69] = 0
   MW[70] = 0
   MW[71] = 0
   MW[72] = 0
   MW[73] = 0
   MW[74] = 0
   MW[75] = 0
   MW[76] = 0
   MW[77] = 0
   MW[78] = 0
   MW[79] = 0
   MW[80] = 0
   MW[81] = 0
   MW[82] = 0
   MW[83] = 0
   MW[84] = 0
   MW[85] = 0
   MW[86] = 0
   MW[87] = 0
   MW[88] = 0
   MW[89] = 0
   MW[90] = 0
   MW[91] = 0
   MW[92] = 0
   MW[93] = 0
   MW[94] = 0
   MW[95] = 0
   MW[96] = 0
   MW[97] = 0
   MW[98] = 0
   MW[99] = 0
   MW[100] = 0
   MW[101] = 0
   MW[102] = 0
   MW[103] = 0
   MW[104] = 0
   MW[105] = 0
   
   
   JLOOP 
   
     IF ((J = 6001))
        MW[36] = mi.1.1[5631]
        MW[37] = mi.1.1.T[5631]
     ENDIF
     
     IF ((J = 6002))
        MW[38] = mi.1.2[4344]
        MW[39] = mi.1.2.T[4344] 
     ENDIF
     
     IF ((J = 6003)) 
        MW[40] = mi.1.3[5671]
        MW[41] = mi.1.3.T[5671] 
     ENDIF
     
     IF ((J = 6004)) 
        MW[42] = mi.1.4[5671]
        MW[43] = mi.1.4.T[5671] 
     ENDIF
     
     IF ((J = 6005)) 
        MW[44] = mi.1.5[5671]
        MW[45] = mi.1.5.T[5671] 
     ENDIF
     
     IF ((J = 6006))
        MW[46] = mi.1.6[5670]
        MW[47] = mi.1.6.T[5670]
     ENDIF
     
     IF ((J = 6007))
        MW[48] = mi.1.7[5670]
        MW[49] = mi.1.7.T[5670] 
     ENDIF
     
     IF ((J = 6008)) 
        MW[50] = mi.1.8[5668]
        MW[51] = mi.1.8.T[5668] 
     ENDIF
     
     IF ((J = 6009)) 
        MW[52] = mi.1.9[5668]
        MW[53] = mi.1.9.T[5668] 
     ENDIF
     
     IF ((J = 6010)) 
        MW[54] = mi.1.10[5668]
        MW[55] = mi.1.10.T[5668]
     ENDIF
          
     IF ((J = 6011)) 
        MW[56] = mi.1.11[5665]
        MW[57] = mi.1.11.T[5665]
     ENDIF
     
     IF ((J = 6012))
        MW[58] = mi.1.12[5665]
        MW[59] = mi.1.12.T[5665] 
     ENDIF
     
     IF ((J = 6013))
        MW[60] = mi.1.13[5664]
        MW[61] = mi.1.13.T[5664] 
     ENDIF
     
     IF ((J = 6014)) 
        MW[62] = mi.1.14[5664]
        MW[63] = mi.1.14.T[5664] 
     ENDIF
     
     IF ((J = 6015)) 
        MW[64] = mi.1.15[5663]
        MW[65] = mi.1.15.T[5663] 
     ENDIF
     
     IF ((J = 6016)) 
        MW[66] = mi.1.16[5661]
        MW[67] = mi.1.16.T[5661]
     ENDIF
     
     IF ((J = 6017))
        MW[68] = mi.1.17[5661]
        MW[69] = mi.1.17.T[5661] 
     ENDIF
     
     IF ((J = 6018))
        MW[70] = mi.1.18[5659]
        MW[71] = mi.1.18.T[5659] 
     ENDIF
        
     IF ((J = 6019)) 
        MW[72] = mi.1.19[5657]
        MW[73] = mi.1.19.T[5657] 
     ENDIF
     
     IF ((J = 6020)) 
       MW[74] = mi.1.20[5657]
       MW[75] = mi.1.20.T[5657] 
     ENDIF
     
     IF ((J = 6021)) 
       MW[76] = mi.1.21[5655]
       MW[77] = mi.1.21.T[5655]
     ENDIF
     
     IF ((J = 6022)) 
       MW[78] = mi.1.22[5655]
       MW[79] = mi.1.22.T[5655] 
     ENDIF
     
     IF ((J = 6023)) 
        MW[80] = mi.1.23[5043]
        MW[81] = mi.1.23.T[5670] 
     ENDIF
     
     IF ((J = 6024)) 
        MW[82] = mi.1.24[5655]
        MW[83] = mi.1.24.T[5655] 
     ENDIF
          
     IF ((J = 6025))
        MW[84] = mi.1.25[5655]
        MW[85] = mi.1.25.T[5655] 
     ENDIF
     
     IF ((J = 6026))
        MW[86] = mi.1.26[5621]
        MW[87] = mi.1.26.T[5621]
     ENDIF
     
     IF ((J = 6027)) 
        MW[88] = mi.1.27[5621]
        MW[89] = mi.1.27.T[5621] 
     ENDIF
     
     IF ((J = 6028)) 
        MW[90] = mi.1.28[5600]
        MW[91] = mi.1.28.T[5600]     
     ENDIF
     
     IF ((J = 6029)) 
        MW[92] = mi.1.29[5600]
        MW[93] = mi.1.29.T[5600] 
     ENDIF 
     
     IF ((J = 6030)) 
        MW[94] = mi.1.30[5600]
        MW[95] = mi.1.30.T[5600] 
     ENDIF
     
     IF ((J = 6031)) 
        MW[96] = mi.1.31[5640]
        MW[97] = mi.1.31.T[5640]
     ENDIF
     
      IF ((J = 6032))
         MW[98] = mi.1.32[5586]
         MW[99] = mi.1.32.T[5586] 
      ENDIF
     
     IF ((J = 6033))
         MW[100] = mi.1.33[5586]
         MW[101] = mi.1.33.T[5586] 
     ENDIF
     
     IF ((J = 6034)) 
         MW[102] = mi.1.34[5586]
         MW[103] = mi.1.34.T[5586] 
     ENDIF
     
     IF ((J = 6035)) 
        MW[104] = mi.1.35[5631]
        MW[105] = mi.1.35.T[5631] 
     ENDIF
      
   ENDJLOOP
   
   
   IF(!(i = @dummy@))
      JLOOP
        IF(!(j = @dummy@))
          MW[1]= mi.1.1
          MW[2]= mi.1.2
          MW[3]= mi.1.3
          MW[4]= mi.1.4
          MW[5]= mi.1.5
          MW[6]= mi.1.6
          MW[7]= mi.1.7
          MW[8]= mi.1.8
          MW[9]= mi.1.9
          MW[10]= mi.1.10
          MW[11]= mi.1.11
          MW[12]= mi.1.12
          MW[13]= mi.1.13
          MW[14]= mi.1.14
          MW[15]= mi.1.15
          MW[16]= mi.1.16
          MW[17]= mi.1.17
          MW[18]= mi.1.18
          MW[19]= mi.1.19
          MW[20]= mi.1.20
          MW[21]= mi.1.21
          MW[22]= mi.1.22
          MW[23]= mi.1.23
          MW[24]= mi.1.24
          MW[25]= mi.1.25
          MW[26]= mi.1.26
          MW[27]= mi.1.27
          MW[28]= mi.1.28
          MW[29]= mi.1.29
          MW[30]= mi.1.30
          MW[31]= mi.1.31
          MW[32]= mi.1.32
          MW[33]= mi.1.33
          MW[34]= mi.1.34
          MW[35]= mi.1.35
     
        ELSE  
          MW[1]= 0  
          MW[2]= 0 
          MW[3]= 0 
          MW[4]= 0  
          MW[5]= 0 
          MW[6]= 0 
          MW[7]= 0 
          MW[8]= 0 
          MW[9]= 0 
          MW[10]= 0
          MW[11]= 0 
          MW[12]= 0 
          MW[13]= 0 
          MW[14]= 0 
          MW[15]= 0 
          MW[16]= 0
          MW[17]= 0 
          MW[18]= 0 
          MW[19]= 0 
          MW[20]= 0
          MW[21]= 0 
          MW[22]= 0 
          MW[23]= 0 
          MW[24]= 0 
          MW[25]= 0 
          MW[26]= 0
          MW[27]= 0 
          MW[28]= 0 
          MW[29]= 0 
          MW[30]= 0
          MW[31]= 0  
          MW[32]= 0 
          MW[33]= 0 
          MW[34]= 0  
          MW[35]= 0      
          
        ENDIF 
      ENDJLOOP
    ELSE  
          MW[1]= 0  
          MW[2]= 0 
          MW[3]= 0 
          MW[4]= 0  
          MW[5]= 0 
          MW[6]= 0 
          MW[7]= 0 
          MW[8]= 0 
          MW[9]= 0 
          MW[10]= 0
          MW[11]= 0 
          MW[12]= 0 
          MW[13]= 0 
          MW[14]= 0 
          MW[15]= 0 
          MW[16]= 0
          MW[17]= 0 
          MW[18]= 0 
          MW[19]= 0 
          MW[20]= 0
          MW[21]= 0 
          MW[22]= 0 
          MW[23]= 0 
          MW[24]= 0 
          MW[25]= 0 
          MW[26]= 0
          MW[27]= 0 
          MW[28]= 0 
          MW[29]= 0 
          MW[30]= 0
          MW[31]= 0  
          MW[32]= 0 
          MW[33]= 0 
          MW[34]= 0  
          MW[35]= 0      
          
   ENDIF
      
 ENDRUN

;-----------------------
;create station matrices 
 
 RUN PGM=MATRIX
  
  FILEI MATI[1]= outputs\stationThree.mat
  MATO=outputs\stationFour.mat,MO=36
 
  MW[1] = mi.1.1 + mi.1.36 + mi.1.37.T
  MW[2] = mi.1.2 + mi.1.38 + mi.1.39.T
  MW[3] = mi.1.3 + mi.1.40 + mi.1.41.T
  MW[4] = mi.1.4 + mi.1.42 + mi.1.43.T
  MW[5] = mi.1.5 + mi.1.44 + mi.1.45.T
  MW[6] = mi.1.6 + mi.1.46 + mi.1.47.T
  MW[7] = mi.1.7 + mi.1.48 + mi.1.49.T
  MW[8] = mi.1.8 + mi.1.50 + mi.1.51.T
  MW[9] = mi.1.9 + mi.1.52 + mi.1.53.T
  MW[10] = mi.1.10 + mi.1.54 + mi.1.55.T
  MW[11] = mi.1.11 + mi.1.56 + mi.1.57.T
  MW[12] = mi.1.12 + mi.1.58 + mi.1.59.T
  MW[13] = mi.1.13 + mi.1.60 + mi.1.61.T
  MW[14] = mi.1.14 + mi.1.62 + mi.1.63.T
  MW[15] = mi.1.15 + mi.1.64 + mi.1.65.T
  MW[16] = mi.1.16 + mi.1.66 + mi.1.67.T
  MW[17] = mi.1.17 + mi.1.68 + mi.1.69.T
  MW[18] = mi.1.18 + mi.1.70 + mi.1.71.T
  MW[19] = mi.1.19 + mi.1.72 + mi.1.73.T
  MW[20] = mi.1.20 + mi.1.74 + mi.1.75.T
  MW[21] = mi.1.21 + mi.1.76 + mi.1.77.T
  MW[22] = mi.1.22 + mi.1.78 + mi.1.79.T
  MW[23] = mi.1.23 + mi.1.80 + mi.1.81.T
  MW[24] = mi.1.24 + mi.1.82 + mi.1.83.T
  MW[25] = mi.1.25 + mi.1.84 + mi.1.85.T
  MW[26] = mi.1.26 + mi.1.86 + mi.1.87.T
  MW[27] = mi.1.27 + mi.1.88 + mi.1.89.T
  MW[28] = mi.1.28 + mi.1.90 + mi.1.91.T
  MW[29] = mi.1.29 + mi.1.92 + mi.1.93.T
  MW[30] = mi.1.30 + mi.1.94 + mi.1.95.T
  MW[31] = mi.1.31 + mi.1.96 + mi.1.97.T
  MW[32] = mi.1.32 + mi.1.98 + mi.1.99.T
  MW[33] = mi.1.33 + mi.1.100 + mi.1.101.T
  MW[34] = mi.1.34 + mi.1.102 + mi.1.103.T
  MW[35] = mi.1.35 + mi.1.104 + mi.1.105.T
  
  MW[36] = MW[1] + MW[2] + MW[3] + MW[4] + MW[5] + MW[6] + MW[7] + MW[8] + MW[9] + MW[10] +  
           MW[11] + MW[12] + MW[13] + MW[14] + MW[15] + MW[16] + MW[17] + MW[18] + MW[19] + MW[20] +
           MW[21] + MW[22] + MW[23] + MW[24] + MW[25] + MW[26] + MW[27] + MW[28] + MW[29] + MW[30] +
           MW[31] + MW[32] + MW[33] + MW[34] + MW[35]
           
 ENDRUN

 
;-----------------------
;allocate the taz trips to the stations 
 
 RUN PGM=MATRIX

    MATI[1]=outputs\stationFour.mat
    MATO =outputs\stationFive.mat,MO=1,DEC=2,NAME=five           
            
    MW[1] = MI.1.1       
        
    ;swipe the values across the columns
    IF((I = @externals@))
      JLOOP
        IF((J = 6001))
           MW[1] = MW[1][5631]
        ENDIF
 
        IF((J = 6002))
           MW[1] = MW[1][4344]
        ENDIF
     
        IF((J = 6003)) 
           MW[1] = MW[1][5671]/3 
        ENDIF
     
        IF((J = 6004)) 
          MW[1] = MW[1][5671]/3 
        ENDIF
     
        IF((J = 6005)) 
          MW[1] = MW[1][5671]/3 
        ENDIF
     
        IF((J = 6006))
          MW[1] = MW[1][5670]/2
        ENDIF
     
        IF((J = 6007))
          MW[1] = MW[1][5670]/2
        ENDIF
     
        IF((J = 6008)) 
          MW[1] = MW[1][5668]/3
        ENDIF
     
        IF((J = 6009)) 
          MW[1] = MW[1][5668]/3 
        ENDIF
     
        IF((J = 6010)) 
          MW[1] = MW[1][5668]/3
        ENDIF
          
        IF((J = 6011)) 
          MW[1] = MW[1][5665]/2
        ENDIF
     
        IF((J = 6012))
          MW[1] = MW[1][5665]/2
        ENDIF
     
        IF((J = 6013))
          MW[1] = MW[1][5664]/2
        ENDIF
     
        IF((J = 6014)) 
          MW[1] = MW[1][5664]/2
        ENDIF
     
        IF((J = 6015)) 
          MW[1] = MW[1][5663]
        ENDIF
     
        IF((J = 6016)) 
          MW[1] = MW[1][5662]
        ENDIF
          
        IF((J = 6017))
          MW[1] = MW[1][5661]
        ENDIF
     
        IF((J = 6018))
          MW[1] = MW[1][5659]
        ENDIF
     
        IF((J = 6019)) 
          MW[1] = MW[1][5658]
        ENDIF
     
        IF((J = 6020)) 
          MW[1] = MW[1][5657]
        ENDIF
     
        IF((J = 6021)) 
          MW[1] = MW[1][5656]
        ENDIF
     
        IF((J = 6022)) 
          MW[1] = MW[1][5655]/3
        ENDIF
     
        IF((J = 6023)) 
          MW[1] = MW[1][5654]
        ENDIF
     
        IF((J = 6024)) 
          MW[1] = MW[1][5655]/3
        ENDIF
          
        IF((J = 6025))
          MW[1] = MW[1][5655]/3
        ENDIF
     
        IF((J = 6026))
          MW[1] = MW[1][5621]/2
        ENDIF
     
        IF((J = 6027)) 
          MW[1] = MW[1][5621]/2
        ENDIF
     
        IF((J = 6028)) 
          MW[1] = MW[1][5600]/3    
        ENDIF
     
        IF((J = 6029)) 
          MW[1] = MW[1][5600]/3
        ENDIF 
     
        IF((J = 6030)) 
          MW[1] = MW[1][5600]/3
        ENDIF
     
        IF((J = 6031)) 
          MW[1] = MW[1][5640]/2
        ENDIF
          
        IF((J = 6032))
          MW[1] = MW[1][5640]/2 
        ENDIF
     
        IF((J = 6033))
          MW[1] = MW[1][5586]/2 
        ENDIF
     
        IF((J = 6034)) 
          MW[1] = MW[1][5586]/2 
        ENDIF
     
        IF((J = 6035)) 
          MW[1] = MW[1][5631]
        ENDIF
       
     ENDJLOOP 
     
   ELSE     
         MW[1] = MW[1]
   ENDIF 
   
   
   ;make the intra-zonal trips zero for the external stations 
   IF((I = @externals@))
   
      JLOOP  
        IF((J = @externals@) & (I == J))
          MW[1] = 0
        ELSE   
          MW[1] = MW[1]      
        ENDIF  
      ENDJLOOP
      
    ELSE         
      MW[1] = MW[1]    
    ENDIF 
 
    
    ;make the external-dummy taz trips zero
    IF((i = @externals@))
      JLOOP             
        IF((j = @dummy@))
           IF(((i == 6001)&(j == 5631))|((i == 6002)&(j == 4344))|((i == 6003)&(j == 5671))|((i == 6004)&(j == 5671))|((i == 6005)&(j == 5671))|
              ((i == 6006)&(j == 5670))|((i == 6007)&(j == 5670))|((i == 6008)&(j == 5668))|((i == 6009)&(j == 5668))|((i == 6010)&(j == 5668))|
              ((i == 6011)&(j == 5665))|((i == 6012)&(j == 5664))|((i == 6013)&(j == 5664))|((i == 6014)&(j == 5664))|((i == 6015)&(j == 5663))|
              ((i == 6016)&(j == 5662))|((i == 6017)&(j == 5661))|((i == 6018)&(j == 5659 ))|((i == 6019)&(j == 5658))|((i == 6020)&(j == 5657))|
              ((i == 6021)&(j == 5656))|((i == 6022)&(j == 5655))|((i == 6023)&(j == 5654))|((i == 6024)&(j == 5655))|((i == 6025)&(j == 5655))|
              ((i == 6026)&(j == 5621))|((i == 6027)&(j == 5621))|((i == 6028)&(j == 5600))|((i == 6029)&(j == 5600))|((i == 6030)&(j == 5600))|
              ((i == 6031)&(j == 5640))|((i == 6032)&(j == 5640))|((i == 6033)&(j == 5586))|((i == 6034)&(j == 5586))|((i == 6035)&(j == 5631)))
              
              MW[1] = MW[1]
           ELSE    
              MW[1] = 0
           ENDIF
        ELSE  
          MW[1] = MW[1]   
        ENDIF
      ENDJLOOP
    ELSE  
          MW[1] = MW[1]   
    ENDIF
            
 ENDRUN 
 
;----------------------------------------------------------------------------------------------
;Step 5: Create seed matrix for the fratar matrix balancing procedure
;---------------------------------------------------------------------------------------------- 

 RUN PGM=MATRIX

    MATI[1]=outputs\stationFive.mat
    MATO =outputs\seed.mat,MO=1,DEC=2,NAME=seed
    
    ZONES = @NZONES@
      
    MW[1] = MI.1.1   
         
    IF(!(I = @externals@))
      JLOOP
        IF(!(J = @externals@))
          MW[1] = 0
        ENDIF
      ENDJLOOP    
    ELSE 
      MW[1] = MW[1]
    ENDIF
        
 ENDRUN


;----------------------------------------------------------------------------------------------
;Application Mode: use input seed.mat 
;----------------------------------------------------------------------------------------------

:Application

;copy seed matrix from inputs to outputs folder
IF (APPLY=1)
  *XCOPY inputs\seed.mat outputs\seed.mat* /Y
ENDIF



;----------------------------------------------------------------------------------------------
;Step 6: Calculate future year counts using base year counts(i.e.,2010) and growth rates
;----------------------------------------------------------------------------------------------

RUN PGM=NETWORK

   NODEI[1]="inputs\externals.csv",VAR=N,Vehicles,TAZ,GrowthRate,VISTPCT,Name
  
   ;put data into arrays for later
   ARRAY _STA = @NEXTERNALS@ ;station
   ARRAY _VEH = @NEXTERNALS@ ;base year count
   ARRAY _TAZ = @NEXTERNALS@ ;stdm_taz
   ARRAY _GWR = @NEXTERNALS@ ;growth rate
   ARRAY _FORECASTCNT = @NEXTERNALS@ ;future year count
   ARRAY _VISTPCT = @NEXTERNALS@ ;visitor percent of ADT
  
   PHASE=INPUT FILEI=NI.1
   
		 IF ((N>=@FEXT@ & N<=@LEXT@))
       _i=_i+1
		   _STA[_i] = N 
		   _VEH[_i] = Vehicles
		   _TAZ[_i] = TAZ
       _GWR[_i] = GrowthRate
       _VISTPCT[_i] = VISTPCT
       
       _FORECASTCNT[_i] = (_VEH[_i]*_VISTPCT[_i])*(1+(_GWR[_i]/100))^((@YEAR@)-2010)
       
       PRINT FILE="outputs\futureCntOne.dbf",LIST=_STA[_i],_FORECASTCNT[_i]      
     ENDIF 
     
   ENDPHASE   
   
 ENDRUN

;----------------------------------------------------------------------------------------------
;Step 7: Create row and column control totals for the fratar procedure
;----------------------------------------------------------------------------------------------
 
 ;-----------------------
 ;get row and column totals by taz from the above matrix
 
RUN PGM=MATRIX

    MATI[1]=outputs\seed.mat
    ZONES = @NZONES@
 
    SET VAL = 0, VARS = P,A
  
    JLOOP ;get rowsums for matrices
    
      P = P + mi.1.1[J]    
      A = A + mi.1.1.T[J] ;transpose the matrix
    
      IF(J = @NZONES@)         
      
       PRINT FILE="outputs\controlOne.dbf",LIST=(I)(16.0), P(16.2), A(16.2)
       
      ENDIF
  
    ENDJLOOP
    
 ENDRUN
 
 ;-----------------------
 ;replace the external station row and column totals by the future counts for those stations
 
 RUN PGM = MATRIX
      
    FILEI DBI[1]="outputs\futureCntOne.dbf", STDM_TAZ = 1,FORECASTCN = 2,SORT = STDM_TAZ,FORECASTCN
    FILEI DBI[2]="outputs\controlOne.dbf",I=1,P=2,A=3
             
    ZONES=1
             
    ARRAY _STATAZ = @NEXTERNALS@
    ARRAY _FORECAST = @NEXTERNALS@
    
    LOOP K=1,DBI.1.NUMRECORDS                                                   
      X=DBIReadRecord(1,K);update pointer to current record
                          
       _STATAZ[K] = DI.1.STDM_TAZ
       _FORECAST[K] = DI.1.FORECASTCN
                   
    ENDLOOP                                 
     
    LOOP M=1,DBI.2.NUMRECORDS 
      X=DBIReadRecord(2,M);update pointer to current record
        
       _I = DI.2.I
       _PCOUNT = DI.2.P
       _ACOUNT = DI.2.A
       
   
       LOOP K = 1,@NEXTERNALS@,1
         
            IF (_I = _STATAZ[K]) ;checking whether I is external TAZ
              
                  _PCOUNT = ROUND(_FORECAST[K]*0.5)
                  _ACOUNT = ROUND(_FORECAST[K]*0.5)
                  
            ENDIF
              
       ENDLOOP
                 
     PRINT LIST=_I(5.0),_PCOUNT(8.0),_ACOUNT(8.0),FILE=outputs\futureCnt.prn                 
     
    ENDLOOP 
    
 ENDRUN

;----------------------------------------------------------------------------------------------
;Step 8: Fratar the seed matrix to the controlled row and column data
;----------------------------------------------------------------------------------------------
 
 RUN PGM=FRATAR
    
	MATI=outputs\seed.mat
  MATO=outputs\externals.mat,MO=1,NAME=EXTERNALS
    ZONES = @NZONES@,MAXRMSE=0.10,MAXITERS=100
    ZONEMSG=100
  
    LOOKUP FILE=outputs\futureCnt.prn,NAME=CONT,
    LOOKUP[1]=1, RESULT=2,
    LOOKUP[2]=1, RESULT=3
   
    SETPA MW[1]=MI.1.1,P[1]=CONT(1,J),A[1]=CONT(2,J),
    CONTROL = PA
    ACOMP=1,PCOMP=1
    MARGINS=1
	
 ENDRUN
 
;----------------------------------------------------------------------------------------------
;Step 9: Output the total trips by external stations
;---------------------------------------------------------------------------------------------- 
 RUN PGM=MATRIX
 
    MATI[1] = outputs\externals.mat
    
    ZONES = @NZONES@
    
    SET VAL = 0, VARS = P,A,T
    
    IF((i = @externals@)) 
      JLOOP       
           P = P + mi.1.1[J]  
           A = A + mi.1.1.T[J] ;transpose the matrix
           T = P + A
      ENDJLOOP    
      
      PRINT FILE = "outputs\externalTrips.csv" CSV=T, LIST = I, P, A, T ;external station, production, attraction, total trips           
    ENDIF
  
 ENDRUN

 
 
 
 
 
 
 
 
 
 
 
