`timescale 1us/1ns
module max10 (
    input MAX10_CLK1_50,
    input FPGA_RESET_n,

    // Keys
    output [9:0] SW,
    input [4:0] KEY,

    // Leds and Displays
    output [9:0] LEDR,
    output [6:0] HEX0,
    output [6:0] HEX1,

    // Audio
    inout   AUDIO_BCLK,
    output  AUDIO_DIN_MFP1,
    input   AUDIO_DOUT_MFP2,
    inout   AUDIO_GPIO_MFP5,
    output  AUDIO_MCLK,
    input   AUDIO_MISO_MFP4,
    inout   AUDIO_RESET_n,
    output  AUDIO_SCL_SS_n,
    output  AUDIO_SCLK_MFP3,
    inout   AUDIO_SDA_MOSI,
    output  AUDIO_SPI_SELECT,
    inout   AUDIO_WCLK,

    // DAC
    inout   DAC_DATA,
    output  DAC_SCLK,
    output  DAC_SYNC_n,

    input [0:0] WIF

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

    wire clk_48; // 48MHZ
    AUDIO_PLL pll (
        .inclk0(clk),
        .c0(clk_48)
    );

    // Codec
    wire [11:0] ADC_RD;
    wire ADC_RESPONSE;
    wire SAMPLE_TR;
    MAX10_ADC madc (
        .SYS_CLK(clk_48),
        .SYNC_TR(SAMPLE_TR),
        .RESET_n(rst_delayed_n),
        .ADC_CH(5'd7),
        .DATA(ADC_RD),
        .DATA_VALID(ADC_RESPONSE),
        .FITER_EN(1'b1)
    );
    wire [15:0] data_in = {ADC_RD, 4'd0};

    wire clk_216;
    PLL2 PLL (
        .areset(rst),
        .inclk0(clk), // 50MHz
        .c0(clk_216)  // 216MHz
    );

    wire stb_in;
    wire [11:0] stb_rate = 4500;
    strober #(4)
        strobe_out_module (clk_216, rst, enable, stb_rate, stb_in);

    localparam WIDTH = 16;

    /************** Generate 1k frequency sinusoidal ***************/
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

        .data_in({~rf_i, {15{rf_i}}}),
        .stb_in(stb_out)
    );

    // Output assignments
    assign AUDIO_MCLK       = clk_48;
    assign AUDIO_GPIO_MFP5  = 1;
    assign AUDIO_SPI_SELECT = 1; // SPI mode
    assign AUDIO_RESET_n    = rst_delayed_n;

    assign LED = {rf_out, 7'd0};

endmodule
