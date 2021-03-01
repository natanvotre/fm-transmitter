module edge_detector #(
    parameter TYPE="RISE"
) (
    input clk,

    input stb_in,
    output stb_out
);

    reg stb_reg;
    reg stb_reg_2;
    always @(posedge clk)
    begin
        stb_reg_2 <= stb_reg;
        stb_reg <= stb_in;
    end

    generate
        if (TYPE == "RISE")
            assign stb_out = stb_reg & ~stb_reg_2;
        else if (TYPE == "FALL")
            assign stb_out = ~stb_reg & stb_reg_2;
        else
            assign stb_out = stb_reg != stb_reg_2;
    endgenerate
endmodule
