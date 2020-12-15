module max10 (
    input MAX10_CLK1_50,
    input FPGA_RESET_n,
    input [9:0] SW,
    input [4:0] KEY,

    output [9:0] LEDR,
    output [6:0] HEX0,
    output [6:0] HEX1
);
    wire clk = MAX10_CLK1_50;
    wire rst = ~FPGA_RESET_n;

    wire clk_divided;
    clock_divisor #(.LENGTH(10000000)) clk_1
    (
        .clk_in(clk),
        .rst(rst),

        .clk_out(clk_divided)
    );

    reg [9:0] leds_reg;
    always @(posedge clk_divided)
        if (rst)
            leds_reg <= 0;
        else
            leds_reg <= leds_reg + 1;

    assign LEDR = leds_reg;

endmodule