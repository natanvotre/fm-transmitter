module fm_modulator #(
    parameter WIDTH = 16,
    parameter FCLK = 48000000,
    parameter FS_IN = 48000,
    parameter FS_OUT = 4800000,
    parameter FC_OUT = 1000000,
    parameter K = 200000,
    parameter IEXT = 4
) (
    input clk,
    input rst,

    input [WIDTH-1:0] data_in,
    input stb_in,

    output [WIDTH-1:0] data_out_i,
    output [WIDTH-1:0] data_out_q,
    output stb_out
);
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

    localparam ZIWIDTH = WIDTH+IEXT;
    localparam ISHIFT = log2(FS_OUT/K) - IEXT;

    localparam ZEXT = 0;
    localparam ZWIDTH = WIDTH+ZEXT;

    localparam CLK_OUT_RATE = FCLK/FS_OUT;
    localparam STB_WIDTH = log2(CLK_OUT_RATE)+1;

    wire stb_cic;
    wire [STB_WIDTH-1:0] stb_rate = CLK_OUT_RATE;
    strober #(STB_WIDTH)
        strobe_out_module (clk, rst, enable, stb_rate, stb_cic);

    wire [WIDTH-1:0] data_interp;
    wire [7:0] interp_rate = FS_OUT/FS_IN;
    cic_interpolator #(WIDTH)
        interpolate_input (
        .clk(clk),
        .rst(rst),
        .enable(enable),

        .rate(interp_rate),

        .data_in(data_in),
        .stb_in(stb_in),

        .data_out(data_interp),
        .stb_out(stb_cic)
    );

    wire [ZIWIDTH-1:0] data_interp_ext;
    sign_extend #(WIDTH, ZIWIDTH)
        extend_data_interp (data_interp, data_interp_ext);

    // CORDIC will calculate e^{jw[n]}
    // where w[n] = w_c[n] + K_w*\sum{m[n]}
    // w_c[n] = 2*pi*f_c/f_s*n
    // and K_w = K_f/(2*pi)
    wire [ZIWIDTH-1:0] wc = FC_OUT/FS_OUT*2**ZIWIDTH;
    reg [ZWIDTH-1:0] wn;
    reg [ZIWIDTH-1:0] wcn;
    reg [ZIWIDTH-1:0] data_integrated;
    wire [ZIWIDTH+ISHIFT-1:0] data_int_ext;
    always @(posedge clk)
        if (rst)
        begin
            wn <= 0;
            wcn <= 0;
            data_integrated <= 0;
        end
        else if (stb_cic)
        begin
            // w_c[n]
            wcn <= wcn + wc;
            // \sum{m[n]}
            data_integrated <= data_integrated + data_interp_ext;
            // w[n] = w_c[n] + K_w*\sum{m[n]}
            wn <= wcn[ZIWIDTH-1:IEXT-ZEXT] + data_int_ext[ZIWIDTH+ISHIFT-1:IEXT+ISHIFT-ZEXT];
        end

    // Extend integrated signal to create K_w*\sum{m[n]}
    sign_extend #(ZIWIDTH, ZIWIDTH+ISHIFT)
        extend_data_int (data_integrated, data_int_ext);

    wire stb_cordic;
    wire [WIDTH-1:0] xi = {1'b0, {WIDTH-1{1'b1}}};
    wire [WIDTH-1:0] yi = 16'd0;
    wire [WIDTH-1:0] cordic_xo, cordic_yo;
    cordic #(
        .WIDTH(WIDTH),
        .ZWIDTH(ZWIDTH),
        .PIPE(WIDTH+2),
        .M(1), .MODE(0) // Circular Rotation
    ) cordic_fm_mod (
        .clk(clk), .rst(rst),

        .xi(xi), .yi(yi), .zi(wn),
        .stb_in(stb_cic),

        .xo(cordic_xo), .yo(cordic_yo), .zo(),
        .stb_out(stb_cordic)
    );

    assign data_out_i = cordic_xo;
    assign data_out_q = cordic_yo;
    assign stb_out = stb_cordic;

endmodule
