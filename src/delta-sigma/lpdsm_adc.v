module lpdsm_adc #(
    parameter WIDTH = 16,
    parameter FCLK = 40'd50000000,
    parameter FS = 40'd50000
) (
    input clk,
    input rst,

    input xi,
    output xo,

    output [WIDTH-1:0] data_out,
    output [0:0] stb_out
);
    wire enable = ~rst;

    // xi must be a lvds port
    // xo must be connected to a RC circuit to the xi_neg port.
    // xo -> R -> C -> xi_neg
    //            '--> gnd
    reg xi_reg;
    always @(posedge clk)
        if (rst)
            xi_reg <= 0;
        else
            xi_reg <= xi;
    assign xo = xi_reg;

    localparam CLK_OUT_RATE = FCLK/100;
    localparam STB_WIDTH = log2(CLK_OUT_RATE)+1;

    wire stb_cic;
    wire [STB_WIDTH-1:0] stb_rate = CLK_OUT_RATE;
    strober #(STB_WIDTH)
        strobe_out_module (clk, rst, enable, stb_rate, stb_cic);

    wire [WIDTH-1:0] data_noisy = {~xi, {WIDTH-1{xi}}};
    cic_decimator #(WIDTH) (
        .clk(clk),
        .rst(rst),
        .enable(enable),

        .rate(stb_rate),

        .data_in(data_noisy),
        .stb_in(1),

        .data_out(data_out),
        .stb_out(stb_out)
);
    // test
    assign stb_out = 1;

endmodule
