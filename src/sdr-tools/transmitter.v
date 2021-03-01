module transmitter #(
    parameter FCLK = 50'd200000000,
    parameter FS_IN = 50'd48000,
    parameter RATE_INT = 50'd100,
    parameter FC = 50'd99000000,
    parameter K = 50'd200000,
    parameter IEXT = 7
) (
    input clk,
    input rst,

    input [15:0] data_in,
    input stb_in,

    output [15:0] data_int,
    output stb_int,

    output rf_out,
    output stb_out
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
    localparam FS_INT = FS_IN*RATE_INT;
    localparam FS_OUT = FCLK;
    localparam FC_INT = FS_INT/8;

    wire [WIDTH-1:0] data_fm_i;
    wire [WIDTH-1:0] data_fm_q;
    wire stb_fm;
    fm_modulator #(
        .WIDTH(WIDTH),
        .FCLK(FCLK),
        .FS_IN(FS_IN),
        .FS_OUT(FS_INT),
        .FC_OUT(FC_INT),
        .K(K),
        .IEXT(IEXT)
    ) fm_modulator (
        .clk(clk), .rst(rst),

        .data_in(data_in),
        .stb_in(stb_in),

        .data_out_i(data_fm_i),
        .data_out_q(data_fm_q),
        .stb_out(stb_fm)
    );


    wire [WIDTH-1:0] duc_data_out;
    wire duc_stb_out;
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
        .stb_out(duc_stb_out)
    );

    wire dac_out;
    hpdsm #(WIDTH)
        hpdsm (clk, rst, duc_data_out, dac_out);

    assign data_int = data_fm_i;
    assign stb_int = stb_fm;

    assign rf_out = dac_out;
    assign stb_out = duc_stb_out;

    // assign rf_out = duc_data_out;
    // assign stb_out = duc_stb_out;

    // assign rf_out = data_fm_i;
    // assign stb_out = stb_fm;

endmodule