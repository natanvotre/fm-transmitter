module hpdsm #(
    WIDTH = 16
) (
    input clk,
    input rst,

    input [WIDTH-1:0] xi,

    output [0:0] out
);
    localparam IWIDTH = WIDTH + 2;

    wire [IWIDTH-1:0] xi_ext;
    sign_extend #(WIDTH, IWIDTH)
        extend_input (xi, xi_ext);

    wire [IWIDTH-1:0] x_filter_1;
    wire [IWIDTH-1:0] y_filter_1;
    hpdsm_base_filter #(IWIDTH)
        filter_1 (clk, rst, x_filter_1, y_filter_1);

    wire [IWIDTH-1:0] x_filter_2;
    wire [IWIDTH-1:0] y_filter_2;
    hpdsm_base_filter #(IWIDTH)
        filter_2 (clk, rst, x_filter_2, y_filter_2);

    wire qout = ~y_filter_2[IWIDTH-1];
    wire [IWIDTH-1:0] feedback = {~qout, {IWIDTH-1{qout}}};

    reg [IWIDTH-1:0] diff_1, diff_2;
    always @(posedge clk)
        if (rst)
        begin
            diff_1 <= 0;
            diff_2 <= 0;
        end
        else begin
            diff_1 <= xi_ext - feedback;
            diff_2 <= y_filter_1 - feedback;
        end

    assign out = qout;

endmodule
