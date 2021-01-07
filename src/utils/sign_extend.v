`timescale 1us/1ns
module sign_extend #(
    parameter LENGTH_IN=16,
    parameter LENGTH_OUT=20
)(
    input [LENGTH_IN-1:0] data_in,
    output [LENGTH_OUT-1:0] data_out
);
    localparam integer LENGTH_DIFF = LENGTH_OUT - LENGTH_IN;

    generate
        if (LENGTH_DIFF > 0)
            assign data_out = {{LENGTH_DIFF{data_in[LENGTH_IN-1]}}, data_in};
        else
            assign data_out = data_in[LENGTH_IN-1:-LENGTH_DIFF];
    endgenerate

endmodule
