module PEAK_DELAY  ( 
input RESET_n  , 
input CLK,
input SAMPLE_TR,
input [11:0]SAMPLE_DAT ,
output reg [11:0] MPEAK

) ;

reg [11:0]   PEAK, PEAK1 ,PEAK2 ,PEAK3 ,PEAK4 ,PEAK5 ;

reg [31:0]DELAY_CNT  ; 
wire [11:0 ] SUM ; 
assign SUM = ( PEAK + PEAK1 +PEAK2 +PEAK3 +PEAK4   ) / 5  ; 

reg [7:0] CNT  ;

always @( negedge RESET_n  or posedge SAMPLE_TR )   begin 
if (!RESET_n  ) begin 
  CNT<=0;
  DELAY_CNT <=0;  
end
else 
begin  
 
 if ( CNT >10) CNT<=0;
 else CNT <=CNT +1 ; 
 // update 
  if ( CNT==0 ){ PEAK, PEAK1 ,PEAK2 ,PEAK3 ,PEAK4 ,PEAK5  } <= { PEAK1 ,PEAK2 ,PEAK3 ,PEAK4 ,PEAK5 ,SAMPLE_DAT }  ; 
		     if (  MPEAK  <  PEAK5  ) begin  MPEAK<= PEAK5  ; end 
		     else  begin 					       
			  if  (DELAY_CNT == 8) begin  
				    DELAY_CNT <=0;    
				    if ( MPEAK > 0 ) MPEAK <= MPEAK-1 ; 
			  end 
			  else DELAY_CNT  <= DELAY_CNT  + 1 ;
			  end 
				 
end
end
endmodule 
	 