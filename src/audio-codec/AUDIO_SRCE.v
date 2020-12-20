module  AUDIO_SRCE  (
 input      [15:0] EXT_DATA16 ,
 output reg [15:0] DATA16_MIC ,
 input             RESET_N , 
 input             MCLK, 
 //output [15:0]     DATA16_SIN ,
 input             SW_OBMIC_SIN  , 
 input             SAMPLE_TR ,

 output reg [7:0] ROM_ADDR ,
 output reg       ROM_CK ,
 output reg       L2  , 
 
 //--test
 output reg [7:0]ST  ,
 output reg [7:0]CNT 
 
 );


 always @( negedge RESET_N or posedge MCLK ) begin
 if ( !RESET_N) begin 
   ST<=0;
	CNT   <=0; 
	ROM_ADDR <=0; 
	ROM_CK <=0;
	
  end
 else begin 
  case (ST)
  0: begin 
         ST<=1 ;	      		  
  end
  1: begin   
	      ST<= 2; 
  end
  2: begin 
	  ST<= 3; 
   end
  3: begin 
	           ST<=4  ;  
			     if ( ROM_ADDR > 192 )  ROM_ADDR <=0;
			     else  ROM_ADDR <=ROM_ADDR+1 ; 		 
	end
  4: begin  
       ROM_CK <=1;		
       if ( SAMPLE_TR ) begin 
           ST<=5 ;  	
      //DATA16_MIC[15:0] <= SW_OBMIC_SIN ? DATA16_SIN[15:0] : EXT_DATA16[15:0]  ;			
		DATA16_MIC[15:0] <= SW_OBMIC_SIN ?  16'h0 : EXT_DATA16[15:0]  ;			
	   end 
  end  
  5: begin 
     ST<=6 ;  
	  ROM_CK <=0;
  end  
  6: begin 
		    ST<=0 ;   
	  	    CNT   <=0;	
	  end 
   endcase 
 
  end
  end

/*  
//SIN TABLE 
SIN s(
	.address (ROM_ADDR),
	.clock (ROM_CK) ,
	.data (0) ,
	.wren(0),
	.q (DATA16_SIN ) );
*/ 	
 
endmodule
 
  
 