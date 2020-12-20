module I2S_ASSESS ( 
 input  AUDIO_MCLK, 
 input  AUDIO_BCLK,
 input  AUDIO_WCLK,
 output SAMPLE_TR ,
 output SAMPLE_TR_n , 
 output SDATA_OUT ,
 input  SDATA_IN  ,
 input  [11:0]ADC_MIC,
 input  RESET_n,
 output [15:0] DATA16_MIC ,
 input  SW_BYPASS,    //SW[0]
 input  SW_OBMIC_SIN, //SW[9] ,
//test
 output [7:0]   ROM_ADDR ,
 output         ROM_CK,  
 output [15:0]   SUM_AUDIO
 
 
) ; 

//-----SUMMMERIA ALL SOUND DATA  12BIT  OUPUT 
assign SUM_AUDIO =  ( SW_BYPASS) ? LIND_[15:0]:DATA16_MIC[15:0]   ; 

//----I2S  DATA/MCLK OUTPUT --- 
assign SDATA_OUT =  ( SW_BYPASS )? SDATA_IN :   SD_MIC  ;  

//----I2S TO PARRALL L/R 16BIT DATA --- 
reg [15:0]WCLK_CNT ;
reg  rAUDIO_WCLK ; 
reg  rAUDIO_BCLK ; 
reg  [32:0]RDATA ;  
reg  [32:0]RDATA1 ;  
reg  [32:0]LDATA ;  
reg  [32:0]LDATA1 ; 

//--CODEC _DATA 
wire  [15:0] C_RDATA;
wire  [15:0] C_LDATA;

reg  [32:0]RDATA_ ;
reg  [32:0]LDATA_ ;


//---L-R CK Positive Negtive  ----- 
assign  SAMPLE_TR = ( !AUDIO_WCLK  && rAUDIO_WCLK )  ; 
assign  SAMPLE_TR_n = ( AUDIO_WCLK  && !rAUDIO_WCLK )  ;

//--LINE-IN I2S serail to paralled 16bit  ------
reg [15:0] LIND,LIND_;

always @( negedge RESET_n or  posedge AUDIO_MCLK) begin 
if (!RESET_n )  begin 
  rAUDIO_BCLK  <= AUDIO_BCLK;
  rAUDIO_WCLK  <= AUDIO_WCLK ;
  WCLK_CNT <=0;  
  LIND_ <= LIND ; 
end
else 
begin 
  rAUDIO_BCLK  <= AUDIO_BCLK;
  rAUDIO_WCLK  <= AUDIO_WCLK ;
  if (  !AUDIO_WCLK  && rAUDIO_WCLK ) 	 begin 
         WCLK_CNT <=0;  
		   LIND_ <= LIND ; 
	 end
  else  if  ( !AUDIO_BCLK  && rAUDIO_BCLK ) 
  begin 
         WCLK_CNT<=WCLK_CNT +1 ; 
			case (WCLK_CNT) 
			1: LIND[15] <=  SDATA_IN  ; 
			2: LIND[14] <=  SDATA_IN  ; 
			3: LIND[13] <=  SDATA_IN  ; 
			4: LIND[12] <=  SDATA_IN  ; 
			5: LIND[11] <=  SDATA_IN  ; 
			6: LIND[10] <=  SDATA_IN  ; 
			7: LIND[9] <=  SDATA_IN  ; 
			8: LIND[8] <=  SDATA_IN  ; 
			9: LIND[7] <=  SDATA_IN  ; 
			10: LIND[6] <=  SDATA_IN  ; 
			11: LIND[5] <=  SDATA_IN  ; 
			12: LIND[4] <=  SDATA_IN  ; 
			13: LIND[3] <=  SDATA_IN  ; 
			14: LIND[2] <=  SDATA_IN  ; 
			15: LIND[1] <=  SDATA_IN  ; 
			16: LIND[0] <=  SDATA_IN  ; 
         endcase 
  end
end
end



//--- MIC-SINE  PARALL to  SERIAL ---  
wire SD_MIC; 

assign SD_MIC =  (
   (( WCLK_CNT ==1 )||( WCLK_CNT ==17))?DATA16_MIC[15] :( 
   (( WCLK_CNT ==2 )||( WCLK_CNT ==18))?DATA16_MIC[14] :( 
   (( WCLK_CNT ==3 )||( WCLK_CNT ==19))?DATA16_MIC[13] :( 
   (( WCLK_CNT ==4 )||( WCLK_CNT ==20))?DATA16_MIC[12] :( 
   (( WCLK_CNT ==5 )||( WCLK_CNT ==21))?DATA16_MIC[11] :( 
   (( WCLK_CNT ==6 )||( WCLK_CNT ==22))?DATA16_MIC[10] :( 
   (( WCLK_CNT ==7 )||( WCLK_CNT ==23))?DATA16_MIC[9] :( 
   (( WCLK_CNT ==8 )||( WCLK_CNT ==24))?DATA16_MIC[8] :( 
   (( WCLK_CNT ==9 )||( WCLK_CNT ==25))?DATA16_MIC[7] :( 
   (( WCLK_CNT ==10)||( WCLK_CNT ==26))?DATA16_MIC[6] :( 
   (( WCLK_CNT ==11)||( WCLK_CNT ==27))?DATA16_MIC[5] :( 
   (( WCLK_CNT ==12)||( WCLK_CNT ==28))?DATA16_MIC[4] :( 
   (( WCLK_CNT ==13)||( WCLK_CNT ==29))?DATA16_MIC[3] :( 
   (( WCLK_CNT ==14)||( WCLK_CNT ==30))?DATA16_MIC[2] :( 
   (( WCLK_CNT ==15)||( WCLK_CNT ==31))?DATA16_MIC[1] :( 
   (( WCLK_CNT ==16)||( WCLK_CNT ==0))?DATA16_MIC[0] :DATA16_MIC[0]
	))))))))))))))));
	
	
//---from EXTERNAL MIC ADC --- 
assign    EXT_DATA16      = {~ADC_MIC[11] , ADC_MIC[10:0],4'h0 } ; 

//----- AUDIO CODE TIMING --- 
  wire [15:0]  EXT_DATA16 ;
  wire [15:0]  DATA16;
  wire [15:0]  DATA16_R ;// 
  wire  [7:0 ] CNT_SREC ;

  
 AUDIO_SRCE audi2(
 .RESET_N ( RESET_n ) , 
 .EXT_DATA16( EXT_DATA16 )  , 
 .SAMPLE_TR( SAMPLE_TR_n ) ,
 .DATA16_MIC ( DATA16_MIC) , 
 .SW_OBMIC_SIN  ( SW_OBMIC_SIN ) ,
 .MCLK          ( AUDIO_MCLK ) , 
 .ROM_ADDR  (ROM_ADDR)  ,
 .ROM_CK    (ROM_CK  ) 
 );
 
 
endmodule 
