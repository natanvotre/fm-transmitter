module  LED_METER  (
  input  RESET_n , 
  input CLK , 
  input [11:0] VALUE ,
  input SAMPLE_TR , 
  output [8:0]LED 
) ; 
 
//-- WAVE Rectifier -- 
reg  [11:0] pcm_abs ; 
`define ZERO_VALUE	12'h800

always @ (negedge RESET_n or posedge SAMPLE_TR ) begin 
if (!RESET_n) begin 
    pcm_abs <=0 ; 
end
else 
begin
	if ( VALUE >= `ZERO_VALUE)
		pcm_abs <= VALUE - `ZERO_VALUE;
	else if (VALUE == 0)
		pcm_abs <= `ZERO_VALUE - 1;
	else
		pcm_abs <= `ZERO_VALUE - VALUE;
end	
end
//--PEAK DELAY  --- 
wire [11:0] PEAK ; 
PEAK_DELAY  pk( 
   .RESET_n   ( RESET_n), 
	.SAMPLE_TR ( SAMPLE_TR),
	.SAMPLE_DAT ( pcm_abs)  , 
	.MPEAK  ( PEAK  ) 
) ;


//---LED OUT ----
reg [7:0] vol;
always @ (posedge SAMPLE_TR )
begin
	case(PEAK[10:8])
	 3'b000:  vol = 8'b00000001;
	 3'b001:  vol = 8'b00000011;
	 3'b010:  vol = 8'b00000111;
	 3'b011:  vol = 8'b00001111;
	 3'b100:  vol = 8'b00011111;
	 3'b101:  vol = 8'b00111111;
	 3'b110:  vol = 8'b01111111;
	 3'b111:  vol = 8'b11111111;
	endcase
end

//---LED OUT --- 
assign LED =  vol ; 




endmodule 
