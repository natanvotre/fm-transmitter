`timescale 1us/1ns
module max10 (
    input MAX10_CLK1_50,
    input FPGA_RESET_n,

    // Keys
    input [9:0] SW,
    input [4:0] KEY,

	// Audio
	inout 		          		AUDIO_BCLK,
	output		          		AUDIO_DIN_MFP1,
	input 		          		AUDIO_DOUT_MFP2,
	inout 		          		AUDIO_GPIO_MFP5,
	output		          		AUDIO_MCLK,
	input 		          		AUDIO_MISO_MFP4,
	inout 		          		AUDIO_RESET_n,
	output		          		AUDIO_SCL_SS_n,
	output		          		AUDIO_SCLK_MFP3,
	inout 		          		AUDIO_SDA_MOSI,
	output		          		AUDIO_SPI_SELECT,
	inout 		          		AUDIO_WCLK,

	// DAC
	inout 		          		DAC_DATA,
	output		          		DAC_SCLK,
	output		          		DAC_SYNC_n,

    // Leds and Displays
    output [9:0] LEDR,
    output [6:0] HEX0,
    output [6:0] HEX1
);
    wire clk = MAX10_CLK1_50;
    wire rst = ~FPGA_RESET_n;

    wire rst_delayed;
    reset_delay reset_delay (
        .clk(clk),
        .rst_in(rst),

        .rst_out(rst_delayed)
    );
    wire rst_delayed_n = ~rst_delayed;

    wire MCLK_48M; // 48MHZ
    AUDIO_PLL pll (
        .inclk0(MAX10_CLK1_50),
        .c0(MCLK_48M)
    );

    // Codec
    wire [11:0] ADC_RD;
    wire ADC_RESPONSE;
    wire SAMPLE_TR;
    MAX10_ADC madc (
        .SYS_CLK(AUDIO_MCLK),
        .SYNC_TR(SAMPLE_TR),
        .RESET_n(rst_delayed_n),
        .ADC_CH(7),
        .DATA(ADC_RD),
        .DATA_VALID(ADC_RESPONSE),
        .FITER_EN(1)
    );

    wire ROM_CK;
    wire [15:0] SUM_AUDIO;
    wire [15:0] TODAC = {~SUM_AUDIO[15], SUM_AUDIO[14:0]};
    DAC16 dac1 (
        .LOAD(ROM_CK),
        .RESET_N(FPGA_RESET_n),
        .CLK_50(AUDIO_MCLK),
        .DATA16(TODAC),
        .DIN(DAC_DATA),
        .SCLK(DAC_SCLK),
        .SYNC(DAC_SYNC_n)
    );

    //=======================================================
    //  REG/WIRE declarations
    //=======================================================


    //---AUDIO CODEC SPI CONFIG ------------------------------------
    //--I2S mode ,  48ksample rate  ,MCLK = 24.567MhZ x 2
    assign AUDIO_GPIO_MFP5  =  1;   //GPIO
    assign AUDIO_SPI_SELECT =  1;   //SPI mode
    assign AUDIO_RESET_n    =  rst_delayed_n ;

    AUDIO_SPI_CTL_RD u1(
        .iRESET_n(rst_delayed_n) ,
        .iCLK_50(MAX10_CLK1_50),   //50Mhz clock
        .oCS_n(AUDIO_SCL_SS_n),   //SPI interface mode chip-select signal
        .oSCLK(AUDIO_SCLK_MFP3),  //SPI serial clock
        .oDIN(AUDIO_SDA_MOSI),   //SPI Serial data output
        .iDOUT(AUDIO_MISO_MFP4)   //SPI serial data input
    );

    //--I2S PROCESSS  CODEC LINE OUT --
    //--------------DAC out --------------------
    I2S_ASSESS  i2s(
        .SAMPLE_TR(SAMPLE_TR),
        .AUDIO_MCLK(AUDIO_MCLK) ,
        .AUDIO_BCLK(AUDIO_BCLK),
        .AUDIO_WCLK(AUDIO_WCLK),

        .SDATA_OUT(AUDIO_DIN_MFP1),
        .SDATA_IN(AUDIO_DOUT_MFP2),
        .RESET_n(rst_delayed_n),
        .ADC_MIC(ADC_RD),
        .SW_BYPASS(0),      // 0:on-board mic  , 1 :line-in
        .SW_OBMIC_SIN(0),   // 1:sin  , 0 : mic
        .ROM_ADDR(ROM_ADDR),
        .ROM_CK(ROM_CK)  ,
        .SUM_AUDIO(SUM_AUDIO)
    );
    assign AUDIO_MCLK  = MCLK_48M;


    //-- SOUND-LEVEL Dispaly to LED
    wire [8:0] LED;
    LED_METER led(
        .RESET_n(rst_delayed_n),
        .CLK(AUDIO_MCLK )  ,
        .SAMPLE_TR(SAMPLE_TR) ,
        .VALUE({~SUM_AUDIO[15], SUM_AUDIO[14:4]}) ,
        .LED(LED)
    );

    //--METER TO LED --
    assign LEDR = {1'b0, LED};

endmodule