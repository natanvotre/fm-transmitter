module reset_delay #(parameter DELAY = 32'hfffff, parameter LEN_LOG = 32)
(
    input clk,
    input rst_in,

    output rst_out
);

    reg rst_reg;
    reg [LEN_LOG-1:0] delay_count;
    always @(posedge clk)
    begin
        if (rst_in)
        begin
            delay_count <= 0;
            rst_reg <= 1;
        end
        else
        begin
            if (delay_count < 32'hfffff)
                delay_count <= delay_count + 1;
            else
                rst_reg <= 0;
        end
    end

    assign rst_out = rst_reg;

endmodule