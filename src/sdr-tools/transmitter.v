module transmitter #(
    parameter FCLK = 200000000,
    parameter FC = 99000000
) (
    input clk,
    input rst,

    output rf_out
    // output [15:0] rf_out
);
    wire enable = ~rst;

    function integer log2;
        input [31:0] value;
        integer i;
    begin
        log2 = 0;
        for(i = 0; 2**i < value; i = i + 1)
            log2 = i + 1;
        log2 = log2 + 1;
    end
    endfunction

    localparam WIDTH = 16;
    localparam CLK_IN_RATE = 100;
    localparam FS_INT = FCLK/CLK_IN_RATE;
    localparam FS_IN = FS_INT/CLK_IN_RATE;
    localparam FS_OUT = FCLK;
    localparam STB_WIDTH = log2(CLK_IN_RATE*CLK_IN_RATE)+1;
    localparam FC_INT = FS_INT/8;
    wire stb_in;
    // strober #(STB_WIDTH)
    //     strober (clk, rst, enable, CLK_IN_RATE*CLK_IN_RATE, stb_in);

    wire [WIDTH-1:0] data_fm_i;
    wire [WIDTH-1:0] data_fm_q;
    wire stb_fm;
    // fm_modulator #(
    //     .WIDTH(WIDTH),
    //     .FCLK(FCLK),
    //     .FS_IN(FS_IN),
    //     .FS_OUT(FS_INT),
    //     .FC_OUT(FC_INT),
    //     .K(),
    //     .IEXT(10)
    // ) fm_modulator (
    //     .clk(clk), .rst(rst),

    //     .data_in(0),
    //     .stb_in(stb_in),

    //     .data_out_i(data_fm_i),
    //     .data_out_q(data_fm_q),
    //     .stb_out(stb_fm)
    // );


    wire [WIDTH-1:0] duc_data_out;
    duc #(
        .WIDTH(WIDTH),
        .FCLK(FCLK),
        .FS_IN(FS_INT),
        .FS_OUT(FS_OUT),
        .FC_IN(FC_INT),
        .FC_OUT(FC),
        .ZEXT(0)
    ) duc (
        .clk(clk),
        .rst(rst),
        .data_in_i(data_fm_i),
        .data_in_q(data_fm_q),
        .stb_in(stb_fm),
        .data_out_i(duc_data_out),
        .data_out_q(),
        .stb_out()
    );

    wire dac_out;
    hpdsm #(WIDTH)
        hpdsm (clk, rst, duc_data_out, dac_out);

    assign rf_out = dac_out;
    // assign rf_out = duc_data_out;

endmodule