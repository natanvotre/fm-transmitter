`timescale 1ns / 1ps
module cordic_tb;
    reg clk, rst;
    initial begin
        clk = 0;
        rst = 1;
        #1000;
        rst = 0;
    end

    always #10 clk = ~clk;

    wire [15:0] xi, yi, xo, yo;
    wire [23:0] zi, zo;
    wire stb_in, stb_out;

    assign xi = 0;
    assign yi = 0;
    assign zi = 0;
    assign stb_in = 0;
    cordic cordic (
        .clk(clk),
        .rst(rst),

        .xi(xi),
        .yi(yi),
        .zi(zi),
        .stb_in(stb_in),

        .xo(xo),
        .yo(yo),
        .zo(zo),
        .stb_out(stb_out)
    );
endmodule
