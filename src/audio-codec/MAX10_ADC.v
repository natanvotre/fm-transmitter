module  MAX10_ADC   (  
 input  SYS_CLK ,
 input  SYNC_TR,
 input  RESET_n ,
 input  [4:0]ADC_CH ,
 output reg [11:0]DATA ,
 output DATA_VALID,
 input  FITER_EN 
 );

wire sys_clk;

wire        response_valid;
wire        command_startofpacket;
wire        command_endofpacket;
wire        command_ready;



wire [4:0]  response_channel;
wire [11:0] response_data;
wire        response_startofpacket;
wire        response_endofpacket;

reg [4:0]   cur_adc_ch;
reg [11:0]  adc_sample_data;


assign DATA_VALID  =response_valid;

// continused send command
assign command_startofpacket  = 1'b1;    // ignore in altera_adc_control core
assign command_endofpacket    = 1'b1;      // ignore in altera_adc_control core


// --adc_sample_data: hold 12-bit adc sample value
// --max10 adc chanel    

adc_qsys u0 (
        .clk_clk                              (SYS_CLK ) ,// ADC_CLK_10),
        .reset_reset_n                        (RESET_n),   
        .modular_adc_0_command_valid          (SYNC_TR),          
        .modular_adc_0_command_channel        (ADC_CH),        //                       .channel
        .modular_adc_0_command_startofpacket  (command_startofpacket),  //                       .startofpacket
        .modular_adc_0_command_endofpacket    (command_endofpacket),    //                       .endofpacket
        .modular_adc_0_command_ready          (command_ready),          //                       .ready
        .modular_adc_0_response_valid         (response_valid        ),         // modular_adc_0_response.valid
        .modular_adc_0_response_channel       (response_channel      ),       //                       .channel
        .modular_adc_0_response_data          (response_data         ),          //                       .data
        .modular_adc_0_response_startofpacket (response_startofpacket),   //                       .startofpacket
        .modular_adc_0_response_endofpacket   (response_endofpacket),     //                       .endofpacket
        .clock_bridge_sys_out_clk_clk         (sys_clk)                  
    );

//--data latch 
reg response_valid_r ; 
reg [11:0] ADC_RD0,ADC_RD1,ADC_RD2,ADC_RD3,ADC_RD4,ADC_RD5 ; 
reg [2:0]  CNT ;


always @ ( posedge sys_clk )
begin
   response_valid_r  <= response_valid ; 
	if (~response_valid_r  &  response_valid)
	begin
	      { ADC_RD0,ADC_RD1,ADC_RD2,ADC_RD3,ADC_RD4,ADC_RD5 } <= { ADC_RD1,ADC_RD2,ADC_RD3,ADC_RD4, ADC_RD5,response_data };
		    DATA  <= FITER_EN ? (ADC_RD0+ADC_RD1+ADC_RD2+ADC_RD3+ADC_RD4+ADC_RD5)/6  : response_data ;//response_data;		
	end
end			


endmodule 
