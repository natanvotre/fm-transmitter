`timescale 1us/1ns
module sign_extend #(
    parameter LENGTH_IN=16,
    parameter LENGTH_OUT=20
)(
    input [LENGTH_IN-1:0] data_in,
    output [LENGTH_OUT-1:0] data_out
);

    assign data_out = {{(LENGTH_OUT-LENGTH_IN){data_in[LENGTH_IN-1]}},data_in};

endmodule
