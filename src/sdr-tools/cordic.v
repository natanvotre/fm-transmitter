module cordic #(
    parameter WIDTH = 16,
    parameter ZWIDTH = 24,
    parameter STAGES = 16,
    parameter M = 1,
    parameter MODE = "rotation"
) (
    input clk,
    input rst,

    input [WIDTH-1:0] xi,
    input [WIDTH-1:0] yi,
    input [ZWIDTH-1:0] zi,
    input stb_in,

    output [WIDTH-1:0] xo,
    output [WIDTH-1:0] yo,
    output [ZWIDTH-1:0] zo,
    output stb_out
);
    // Contraints: STAGES < WIDTH; M = {-1, 0, 1}; MODE = {"rotation", "vectoring"}
    wire [WIDTH:0] xi_ext, yi_ext;
    wire [ZWIDTH:0] zi_ext;
    sign_extend #(WIDTH, WIDTH+1) extend_xi ( .data_in(xi), .data_out(xi_ext) );
    sign_extend #(WIDTH, WIDTH+1) extend_yi ( .data_in(yi), .data_out(yi_ext) );
    sign_extend #(ZWIDTH, ZWIDTH+1) extend_zi ( .data_in(zi), .data_out(zi_ext) );

    wire stb_pipe [0:STAGES];
    wire [WIDTH:0] xi_pipe [0:STAGES];
    wire [WIDTH:0] yi_pipe [0:STAGES];
    wire [ZWIDTH:0] zi_pipe [0:STAGES];
    assign xi_pipe[0] = xi_ext;
    assign yi_pipe[0] = yi_ext;
    assign zi_pipe[0] = zi_ext;
    assign stb_pipe[0] = stb_in;
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin: cordic_pipeline
            cordic_step_rotation #(
                .WIDTH(WIDTH+1),
                .ZWIDTH(ZWIDTH+1),
                .I(i),
                .M(M),
                .MODE(MODE)
            ) rotation_i (
                .clk(clk), .rst(rst),

                .xi(xi_pipe[i]), .yi(yi_pipe[i]), .zi(zi_pipe[i]),
                .stb_in(stb_pipe[i]),

                .xo(xi_pipe[i+1]), .yo(yi_pipe[i+1]), .zo(zi_pipe[i+1]),
                .stb_out(stb_pipe[i+1])
            );
        end
    endgenerate

    assign xo = xi_pipe[STAGES][WIDTH:1];
    assign yo = yi_pipe[STAGES][WIDTH:1];
    assign zo = zi_pipe[STAGES][ZWIDTH:1];
    assign stb_out = stb_pipe[STAGES];

endmodule