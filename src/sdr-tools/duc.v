module duc #(
    parameter WIDTH=16,
    parameter FCLK=50000000,
    parameter FS_IN=100000,
    parameter FS_OUT=1000000,
    parameter FC_IN=10000,
    parameter FC_OUT=100000,
    parameter ZEXT = 0
)(
    input clk,
    input rst,

    input [WIDTH-1:0] data_in_i,
    input [WIDTH-1:0] data_in_q,
    input stb_in,

    output [WIDTH-1:0] data_out_i,
    output [WIDTH-1:0] data_out_q,
    output stb_out
);
    // TODO: make fc_out an input

    // FS_OUT/FS_IN MUST be an integer
    // FCLK/FS_OUT must be an integer

    localparam ZWIDTH = WIDTH+ZEXT;
    wire enable = ~rst;

    function integer log2;
        input [31:0] value;
        integer i;
    begin
        log2 = 0;
        for(i = 0; 2**i < value; i = i + 1)
            log2 = i + 1;
        log2 = log2 + 1;
    end
    endfunction

    localparam CLK_OUT_RATE = FCLK/FS_OUT;
    localparam STB_WIDTH = log2(CLK_OUT_RATE)+1;

    wire stb_cic;
    wire [STB_WIDTH-1:0] stb_rate = CLK_OUT_RATE;
    strober #(STB_WIDTH)
        strobe_out_module (clk, rst, enable, stb_rate, stb_cic);

    wire [7:0] interp_rate = FS_OUT/FS_IN;

    wire [WIDTH-1:0] data_interp_i;
    cic_interpolator #(WIDTH) interpolate_i (
        .clk(clk), .rst(rst), .enable(enable),
        .rate(interp_rate),

        .data_in(data_in_i), .stb_in(stb_in),
        .data_out(data_interp_i), .stb_out(stb_cic)
    );

    wire [WIDTH-1:0] data_interp_q;
    cic_interpolator #(WIDTH) interpolate_q (
        .clk(clk), .rst(rst), .enable(enable),
        .rate(interp_rate),

        .data_in(data_in_q), .stb_in(stb_in),
        .data_out(data_interp_q), .stb_out(stb_cic)
    );

    localparam CORDIC_2_PI = {1'b1, {ZWIDTH{1'b0}}};
    wire [ZWIDTH-1:0] wc = FC_OUT/FS_OUT*CORDIC_2_PI - FC_IN/FS_OUT*CORDIC_2_PI;
    reg [ZWIDTH-1:0] wcn;
    always @(posedge clk)
        if (rst)
            wcn <= 0;
        else if (stb_cic)
            // w_c[n]
            wcn <= wcn + wc;

    wire stb_cordic;
    wire [WIDTH-1:0] cordic_xo, cordic_yo;
    cordic #(
        .WIDTH(WIDTH),
        .ZWIDTH(ZWIDTH),
        .PIPE(WIDTH+2),
        .M(1), .MODE(0) // Circular Rotation
    ) cordic_fm_mod (
        .clk(clk), .rst(rst),

        .xi(data_interp_i), .yi(data_interp_q), .zi(wcn),
        .stb_in(stb_cic),

        .xo(cordic_xo), .yo(cordic_yo), .zo(),
        .stb_out(stb_cordic)
    );

    assign data_out_i = cordic_xo;
    assign data_out_q = cordic_yo;
    assign stb_out = stb_cordic;

endmodule