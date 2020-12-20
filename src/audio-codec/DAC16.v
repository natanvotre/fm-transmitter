module  DAC16  (
 input LOAD , 
 input RESET_N , 
 input CLK_50 , 
 input [15:0] DATA16 ,
 output reg SYNC ,
 output reg SCLK,
 output reg DIN ,
 
 //--test
 output reg SYS_CLK  ,  
 output reg [7:0]ST  ,
 output reg [7:0]CNT ,
 
 output reg  [23:0] RDATA ,
 output DIN_  
 
 );
 
 parameter TIM  =  4;// 
 reg [7:0]DELAY ; 
 //-- 25MHZ --

 always @( posedge CLK_50 ) SYS_CLK <=~SYS_CLK ; 
 
 assign  DIN_ = DIN ;  
 
 //--FSM--
 
 always @( negedge RESET_N or posedge SYS_CLK  )begin
 if ( !RESET_N) begin 
   ST<=0;
	SYNC  <=1; 
	SCLK  <=0;  
	DIN   <=0 ;  	 
	CNT   <=0; 
  end
 else begin 
  case (ST)
  0: begin 
     { DIN , RDATA[23:0] }   <= {  9'h0, DATA16[15:0]  } ;
	  	CNT   <=0; 
      ST<=1 ;  
		DELAY<=0; 
  end
  1: begin 
      if ( DELAY != TIM ) DELAY<=DELAY+1 ;  
		else
		begin 
      SCLK  <=0;
      { DIN , RDATA[23:0] }   <= { RDATA[23:0] ,1'b0 } ;	  
	   SYNC  <=0; 
	   ST<= 2; 
		end
		
  end
  2: begin 
      SCLK  <=1;	  
	   CNT   <=CNT+1; 
	   ST<= 3; 
		DELAY<=0; 
   end
  3: begin 
     if ( DELAY != TIM ) DELAY<=DELAY+1 ; 
	  else
	  begin 
		SCLK  <=0;	  
		DELAY <=0;		
		if  ( CNT==24) begin   ST<=4  ;  end 
		else  ST<=1 ;  

	  end
  end
  4: begin 
       if ( DELAY != TIM ) DELAY<=DELAY+1 ; 
	  else
	  begin 

     ST<=5 ;  	
	  SYNC  <=1; 
	  DIN   <=0 ;
	  end 
  end  
  5: begin 
     if ( LOAD )   ST<=0 ;  
  end  
  
  endcase 
 
  end
 end
 
 endmodule
 
  
 