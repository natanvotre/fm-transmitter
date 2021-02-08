`timescale 1us/1ns
module max10 (
    input MAX10_CLK1_50,
    input FPGA_RESET,
    // input FPGA_RESET_n,
    output LEDS[7:0],
    output rf_o,
    input rf_i,

    input n_run,
    input reset_o,
    input mosi,
    input SDATA,
    input LRCLK,
    input BCLK,
    input sclk,
    input ss,

    // // Keys
    // output [9:0] SW,
    // input [4:0] KEY,

    // // Leds and Displays
    // output [9:0] LEDR,
    // output [6:0] HEX0,
    // output [6:0] HEX1,

    // Audio
    // inout   AUDIO_BCLK,
    // output  AUDIO_DIN_MFP1,
    // input   AUDIO_DOUT_MFP2,
    // inout   AUDIO_GPIO_MFP5,
    // output  AUDIO_MCLK,
    // input   AUDIO_MISO_MFP4,
    // inout   AUDIO_RESET_n,
    // output  AUDIO_SCL_SS_n,
    // output  AUDIO_SCLK_MFP3,
    // inout   AUDIO_SDA_MOSI,
    // output  AUDIO_SPI_SELECT,
    // inout   AUDIO_WCLK,

    // // DAC
    // inout   DAC_DATA,
    // output  DAC_SCLK,
    // output  DAC_SYNC_n,

    input [0:0] WIF

);
    wire clk = MAX10_CLK1_50;
    // wire rst = ~FPGA_RESET_n;
    wire rst = FPGA_RESET;

    wire rst_delayed;
    reset_delay reset_delay (
        .clk(clk),
        .rst_in(rst),

        .rst_out(rst_delayed)
    );
    wire rst_delayed_n = ~rst_delayed;

    // wire clk_48; // 48MHZ
    // AUDIO_PLL pll (
    //     .inclk0(clk),
    //     .c0(clk_48)
    // );

    // // Codec
    // wire [11:0] ADC_RD;
    // wire ADC_RESPONSE;
    // wire SAMPLE_TR;
    // MAX10_ADC madc (
    //     .SYS_CLK(clk_48),
    //     .SYNC_TR(SAMPLE_TR),
    //     .RESET_n(rst_delayed_n),
    //     .ADC_CH(5'd7),
    //     .DATA(ADC_RD),
    //     .DATA_VALID(ADC_RESPONSE),
    //     .FITER_EN(1'b1)
    // );

    // wire ROM_CK;
    // wire [15:0] SUM_AUDIO;
    // wire [15:0] TODAC = {~SUM_AUDIO[15], SUM_AUDIO[14:0]};
    // DAC16 dac1 (
    //     .LOAD(ROM_CK),
    //     .RESET_N(FPGA_RESET_n),
    //     .CLK_50(clk_48),
    //     .DATA16(TODAC),
    //     .DIN(DAC_DATA),
    //     .SCLK(DAC_SCLK),
    //     .SYNC(DAC_SYNC_n)
    // );

    // // AUDIO CODEC SPI CONFIG
    // // I2S mode; fs = 48khz; MCLK = 24.567MhZ x 2
    // AUDIO_SPI_CTL_RD u1 (
    //     .iRESET_n(rst_delayed_n),
    //     .iCLK_50(clk),
    //     .oCS_n(AUDIO_SCL_SS_n),   //SPI interface mode chip-select signal
    //     .oSCLK(AUDIO_SCLK_MFP3),  //SPI serial clock
    //     .oDIN(AUDIO_SDA_MOSI),   //SPI Serial data output
    //     .iDOUT(AUDIO_MISO_MFP4)   //SPI serial data input
    // );

    // // I2S PROCESSS CODEC LINE OUT
    // // DAC out
    // I2S_ASSESS i2s (
    //     .SAMPLE_TR(SAMPLE_TR),
    //     .AUDIO_MCLK(clk_48),
    //     .AUDIO_BCLK(AUDIO_BCLK),
    //     .AUDIO_WCLK(AUDIO_WCLK),

    //     .SDATA_OUT(AUDIO_DIN_MFP1),
    //     .SDATA_IN(AUDIO_DOUT_MFP2),
    //     .RESET_n(rst_delayed_n),
    //     .ADC_MIC(ADC_RD),
    //     .SW_BYPASS(1'b0),      // 0:on-board mic, 1 :line-in
    //     .SW_OBMIC_SIN(1'b0),   // 1:sin, 0 : mic
    //     .ROM_ADDR(),
    //     .ROM_CK(ROM_CK),
    //     .SUM_AUDIO(SUM_AUDIO)
    // );

    // // SOUND-LEVEL Display to LED
    // wire [8:0] LED;
    // LED_METER led (
    //     .RESET_n(rst_delayed_n),
    //     .CLK(clk_48),
    //     .SAMPLE_TR(SAMPLE_TR),
    //     .VALUE({~SUM_AUDIO[15], SUM_AUDIO[14:4]}),
    //     .LED(LED)
    // );

    wire clk_216;
    PLL2 PLL (
        .areset(rst),
        .inclk0(clk), // 50MHz
        .c0(clk_216), // 216MHz
        .locked()
    );

    wire stb_in;
    wire [11:0] stb_rate = 4500;
    strober #(4)
        strobe_out_module (clk_216, rst, enable, stb_rate, stb_in);

    localparam WIDTH = 16;

    // wire [WIDTH-1:0] data_in_i = {1'b0,{WIDTH-1{1'b1}}};
    // wire [WIDTH-1:0] data_in_q = 0;
    // wire [WIDTH-1:0] data_out_i, data_out_q;
    // wire duc_stb_out;
    // duc #(
    //     .WIDTH(WIDTH),
    //     .FCLK(60'd208000000),
    //     .FS_IN(100000),
    //     .FS_OUT(60'd1000000),
    //     .FC_IN(0),
    //     .FC_OUT(60'd100000),
    //     .ZEXT(0)
    // ) duc (
    //     .clk(clk_216),
    //     .rst(rst),

    //     .data_in_i(data_in_i), .data_in_q(data_in_q),
    //     .stb_in(stb_in),

    //     .data_out_i(data_out_i), .data_out_q(data_out_q),
    //     .stb_out(duc_stb_out)
    // );

    // wire [WIDTH-1:0] wc = (50'd1000*(1<<WIDTH))/50'd48000;
    // reg [WIDTH-1:0] wcn;
    // always @(posedge clk_216)
    //     if (rst)
    //         wcn <= 0;
    //     else if (stb_in)
    //         // w_c[n]
    //         wcn <= wcn + wc;

    // wire stb_in_cordic;
    // wire [WIDTH-1:0] cordic_xo;
    // cordic #(
    //     .WIDTH(WIDTH),
    //     .ZWIDTH(WIDTH),
    //     .PIPE(WIDTH+2),
    //     .M(1), .MODE(0) // Circular Rotation
    // ) cordic_fm_mod (
    //     .clk(clk), .rst(rst),

    //     .xi({1'b0,{WIDTH-1{1'b1}}}), .yi(0), .zi(wcn),
    //     .stb_in(stb_in),

    //     .xo(cordic_xo), .yo(), .zo(),
    //     .stb_out(stb_in_cordic)
    // );

    /* Gera um seno utilizando uma tabela - fs de 50KHz e seno de 2,5KHz * * * * * * * * * * * * * * * * * *
    * Com um clock de 220MHz, o valor de dezimação para chegar em 50kHz é de 4400: 22M/4400 = 50k         *
    * Com um clock de 208MHz, o valor de dezimação para chegar em 50kHz é de 4160: 200M/4160 = 50k 		 *
    * Com um clock de 196MHz, o valor de dezimação para chegar em 50kHz é de 3920: 196M/3920 = 50k 		 *
    * Com um clock de 188MHz, o valor de dezimação para chegar em 50kHz é de 3760: 196M/3760 = 50k 		 *
    * Para gerar um seno de 2.5 kHz a partir de 50 kHz deve-se ter 20 amostras 50k/20 = 2.5k					 *
    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    reg [4:0] counter;
    always @(posedge clk_216)
        if (rst)
        begin
            counter <= 0;
        end else if (stb_in)
        begin
            if (counter == 19)
                counter <= 0;
            else
                counter <= counter + 5'd1;
        end

    wire [15:0] signal_i[0:19];
    assign signal_i[0] =  16'h0000;
    assign signal_i[1] =  16'h278E;
    assign signal_i[2] =  16'h4B3C;
    assign signal_i[3] =  16'h678D;
    assign signal_i[4] =  16'h79BB;
    assign signal_i[5] =  16'h7FFF;
    assign signal_i[6] =  16'h79BB;
    assign signal_i[7] =  16'h678D;
    assign signal_i[8] =  16'h4B3C;
    assign signal_i[9] =  16'h278E;
    assign signal_i[10] = 16'h0000;
    assign signal_i[11] = 16'hD872;
    assign signal_i[12] = 16'hB4C4;
    assign signal_i[13] = 16'h9873;
    assign signal_i[14] = 16'h8645;
    assign signal_i[15] = 16'h8001;
    assign signal_i[16] = 16'h8645;
    assign signal_i[17] = 16'h9873;
    assign signal_i[18] = 16'hB4C4;
    assign signal_i[19] = 16'hD872;
    wire [15:0] signal = signal_i[counter];	//  2,5KHz
    /**********************************************************************/




    // wire [WIDTH-1:0] data_out_i, data_out_q;
    // wire fm_stb_out;
    // fm_modulator #(
    //     .WIDTH(16),
    //     .FCLK(60'd216000000),
    //     .FS_IN(60'd48000),
    //     .FS_OUT(50'd4800000),
    //     .FC_OUT(50'd1000000),
    //     .K(60'd200000),
    //     .IEXT(7)
    // ) fm_modulator (
    //     .clk(clk_216),
    //     .rst(rst),

    //     .data_in(cordic_xo), .stb_in(stb_in_cordic),

    //     .data_out_i(data_out_i), .data_out_q(data_out_q),
    //     .stb_out(fm_stb_out)
    // );

    // wire [WIDTH-1:0] rf_out;
    wire rf_out;
    wire stb_out;
    transmitter #(
        .FCLK(50'd216000000),
        .FS_IN(50'd48000),
        .RATE_INT(50'd100),
        .FC(50'd99000000),
        .K(50'd800000),
        .IEXT(4)
    ) transmitter (
        .clk(clk_216),
        .rst(rst),

        // .data_in(0),
        // .data_in(cordic_xo),
        .data_in(signal),
        .stb_in(stb_in_cordic),

        .rf_out(rf_out),
        .stb_out(stb_out)
    );


    frame_monitor #(
        .ID("NTN"),
        .WIDTH(WIDTH),
        .LENGTH(11)
    ) frame_monitor_1 (
        .clk(clk_216),
        .rst(rst),

        // .data_in(signal),
        // .stb_in(stb_in)
        .data_in({~rf_i, {15{rf_i}}}),
        .stb_in(stb_out)
    );

    // Output assignments
    // assign AUDIO_MCLK       = clk_48;
    // assign AUDIO_GPIO_MFP5  = 1;
    // assign AUDIO_SPI_SELECT = 1; // SPI mode
    // assign AUDIO_RESET_n    = rst_delayed_n;

    // assign LEDR = {rf_out, 9'd0};
    assign LED = 8'd0;
    assign rf_o = rf_out;

endmodule
