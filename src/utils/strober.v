module strober #(parameter WIDTH=8) (
    input clk,
    input rst,
    input enable,

    input [WIDTH-1:0] rate,
    output stb_out
);

    reg [WIDTH-1:0] counter;
    wire strobe = (rate == counter + 1);
    reg stb_reg;
    always @(posedge clk)
        if(rst && ~enable)
        begin
            counter <= 0;
            stb_reg <= 0;
        end
        else begin
            if (strobe)
                counter <= 0;
            else
                counter <= counter + 1;

            stb_reg <= strobe;
        end

    assign stb_out = stb_reg;
endmodule
