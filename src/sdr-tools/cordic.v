module cordic #(
    parameter WIDTH = 16,
    parameter ZWIDTH = 24,
    parameter PIPE = 16,
    parameter M = 1,
    parameter MODE = 0 // 0: Rotation, 1: Vectoring
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
    // Contraints: PIPE <= WIDTH-2;
    //             M = {-1, 0, 1}; MODE = {0:"rotation", 1:"vectoring"}
    // Tested just circular (M=1) rotation and vectoring

    wire [WIDTH:0] xi_ext, yi_ext;
    wire [ZWIDTH:0] zi_ext;
    sign_extend #(WIDTH, WIDTH+1) extend_xi ( .data_in(xi), .data_out(xi_ext) );
    sign_extend #(WIDTH, WIDTH+1) extend_yi ( .data_in(yi), .data_out(yi_ext) );

    wire is_right_quadrant = (MODE == 0) ?
        (zi[ZWIDTH-1] == zi[ZWIDTH-2]) : ~xi[WIDTH-1];


    reg [WIDTH:0] xi_reg, yi_reg;
    reg [ZWIDTH-2:0] zi_reg;
    reg stb_reg;
    always @(posedge clk)
        if(rst)
        begin
            xi_reg <= 0;
            yi_reg <= 0;
            zi_reg <= 0;
            stb_reg <= 0;
        end
        else begin
            stb_reg <= stb_in;
            zi_reg <= zi[ZWIDTH-2:0];
            if (is_right_quadrant)
            begin
                xi_reg <= xi_ext;
                yi_reg <= yi_ext;
            end
            else begin
                xi_reg <= -xi_ext;
                yi_reg <= -yi_ext;
            end
        end

    wire stb_pipe [0:PIPE-1];
    wire [WIDTH:0] xi_pipe [0:PIPE-1];
    wire [WIDTH:0] yi_pipe [0:PIPE-1];
    wire [ZWIDTH-2:0] zi_pipe [0:PIPE-1];
    assign xi_pipe[0] = xi_reg;
    assign yi_pipe[0] = yi_reg;
    assign zi_pipe[0] = zi_reg[ZWIDTH-2:0];
    assign stb_pipe[0] = stb_reg;
    genvar i;
    generate
        for (i = 0; i < PIPE-1; i = i + 1) begin: cordic_pipeline
            cordic_step_rotation #(
                .WIDTH(WIDTH+1),
                .ZWIDTH(ZWIDTH-1),
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

    wire [ZWIDTH-1:0] zo_ext;
    sign_extend #(ZWIDTH-1, ZWIDTH) extend_zo (
        .data_in(zi_pipe[PIPE-1][ZWIDTH-2:0]), .data_out(zo_ext)
    );

    assign xo = xi_pipe[PIPE-1][WIDTH:1];
    assign yo = yi_pipe[PIPE-1][WIDTH:1];
    assign zo = zo_ext;
    assign stb_out = stb_pipe[PIPE-1];

endmodule
