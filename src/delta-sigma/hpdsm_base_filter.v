module hpdsm_base_filter #( parameter WIDTH=16 ) (
    input clk,
    input rst,

    input [WIDTH-1:0] xi,
    output [WIDTH-1:0] yo
);

    wire [WIDTH-1:0] xi_sr_ext;
    sign_extend #(WIDTH-1, WIDTH)
        extend_input (xi[WIDTH-1:1], xi_sr_ext);

    reg [WIDTH-1:0] yo_reg;
    always @(posedge clk)
        if (rst)
            yo_reg <= 0;
        else
            yo_reg <= yo;

    assign yo = xi_sr_ext - yo_reg;

endmodule
