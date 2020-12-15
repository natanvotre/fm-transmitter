`ifndef clock_divisor
`define clock_divisor
module clock_divisor #(
    parameter LENGTH=1000
) (
    input clk_in,
    input rst,

    output clk_out
);

    reg [31:0] count_reg;
    reg clk_reg;
    always @(posedge clk_in)
        if (rst)
        begin
            clk_reg <= 0;
            count_reg <= 0;
        end else begin
            if (count_reg == LENGTH-1)
            begin
                clk_reg <= ~clk_reg;
                count_reg <= 0;
            end else begin
                count_reg <= count_reg + 1;
            end
        end

    assign clk_out = clk_reg;

endmodule
`endif