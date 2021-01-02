module cordic_step_rotation #(
    parameter WIDTH = 16,
    parameter ZWIDTH = 24,
    parameter I = 0,
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
    // M = 1: "circular" and Mode = 0: "rotation" calculates the complex exponential

    function [31:0] pow;
        input m, n;
        integer m, n;
        integer i;
    begin

        pow = 1;
        if (n < 0)
            pow = 32'bx;
        else if (n == 0)
            pow = 1;
        else for (i=1; i<=n; i=i+1)
            pow = pow * m;
    end
    endfunction

    function [ZWIDTH-1:0] arctan;
        input integer n;
    begin
        case(n)
            0: arctan = 0.7853981633974483*pow(2,ZWIDTH);
            1: arctan = 0.4636476090008061*pow(2,ZWIDTH);
            2: arctan = 0.24497866312686414*pow(2,ZWIDTH);
            3: arctan = 0.12435499454676144*pow(2,ZWIDTH);
            4: arctan = 0.06241880999595735*pow(2,ZWIDTH);
            5: arctan = 0.031239833430268277*pow(2,ZWIDTH);
            6: arctan = 0.015623728620476831*pow(2,ZWIDTH);
            7: arctan = 0.007812341060101111*pow(2,ZWIDTH);
            8: arctan = 0.0039062301319669718*pow(2,ZWIDTH);
            9: arctan = 0.0019531225164788188*pow(2,ZWIDTH);
            10: arctan = 0.0009765621895593195*pow(2,ZWIDTH);
            11: arctan = 0.0004882812111948983*pow(2,ZWIDTH);
            12: arctan = 0.00024414062014936177*pow(2,ZWIDTH);
            13: arctan = 0.00012207031189367021*pow(2,ZWIDTH);
            14: arctan = 0.00006103515617420877*pow(2,ZWIDTH);
            15: arctan = 0.000030517578115526096*pow(2,ZWIDTH);
            16: arctan = 0.000015258789061315762*pow(2,ZWIDTH);
            17: arctan = 0.00000762939453110197*pow(2,ZWIDTH);
            18: arctan = 0.000003814697265606496*pow(2,ZWIDTH);
            19: arctan = 0.000001907348632810187*pow(2,ZWIDTH);
            20: arctan = 0.0000009536743164059608*pow(2,ZWIDTH);
            21: arctan = 0.00000047683715820308884*pow(2,ZWIDTH);
            22: arctan = 0.00000023841857910155797*pow(2,ZWIDTH);
            23: arctan = 0.00000011920928955078068*pow(2,ZWIDTH);
            24: arctan = 0.00000005960464477539055*pow(2,ZWIDTH);
            25: arctan = 0.000000029802322387695303*pow(2,ZWIDTH);
            26: arctan = 0.000000014901161193847655*pow(2,ZWIDTH);
            27: arctan = 0.000000007450580596923828*pow(2,ZWIDTH);
            28: arctan = 0.000000003725290298461914*pow(2,ZWIDTH);
            29: arctan = 0.000000001862645149230957*pow(2,ZWIDTH);
            30: arctan = 0.0000000009313225746154785*pow(2,ZWIDTH);
            31: arctan = 0.0000000004656612873077393*pow(2,ZWIDTH);
            default: arctan = 0;
        endcase
    end
    endfunction

    // \alpha_i = \frac{tan^{-1}(2^{-i})}{\pi} \cdot 2^{ZWIDTH-1}
    function [ZWIDTH-1:0] alpha;
        input integer n;
    begin
        alpha = arctan(n)/3.14159265;
    end
    endfunction

    // \sigma = \begin{cases}
    //     sign(z_i), \text{for rotation mode}
    //     -sign(y_i), \text{for vectoring mode}
    // \end{cases}
    wire sigma = (MODE == 0) ? ~zi[ZWIDTH-1] : yi[WIDTH-1];
    // m \cdot \sigma
    wire m_sigma = (M == 1) ? sigma : ~sigma;

    // 2^{-i} \cdot x_i
    wire [WIDTH-1:0] xi_shifted;
    sign_extend #(WIDTH-I, WIDTH) extend_xi (
        .data_in(xi[WIDTH-1:I]),
        .data_out(xi_shifted)
    );

    // 2^{-i} \cdot y_i
    wire [WIDTH-1:0] yi_shifted;
    sign_extend #(WIDTH-I, WIDTH) extend_yi (
        .data_in(yi[WIDTH-1:I]),
        .data_out(yi_shifted)
    );

    // - m \sigma_i \cdot 2^{-i} \cdot y_i
    wire [WIDTH-1:0] xi_delta = (M==0) ? 0 :
        m_sigma ? -yi_shifted : yi_shifted;

    // \sigma_i \cdot 2^{-i} \cdot y_i
    wire [WIDTH-1:0] yi_delta = sigma ? xi_shifted : -xi_shifted;

    // - \sigma_i \cdot \alpha_i
    wire [ZWIDTH-1:0] zi_delta = sigma ? -alpha(I) : alpha(I);

    reg [WIDTH-1:0] x_reg, y_reg;
    reg [ZWIDTH-1:0] z_reg;
    always @(posedge clk)
        if (rst)
        begin
            x_reg <= 0;
            y_reg <= 0;
            z_reg <= 0;
        end
        else if (stb_in)
        begin
            x_reg <= xi + xi_delta;
            y_reg <= yi + yi_delta;
            z_reg <= zi + zi_delta;
        end

    reg stb_reg;
    always @(posedge clk)
        if (rst)
            stb_reg <= 0;
        else
            stb_reg <= stb_in;

    assign xo = x_reg;
    assign yo = y_reg;
    assign zo = z_reg;
    assign stb_out = stb_reg;

endmodule
