module cic_interpolator #(
    parameter WIDTH=16
) (
    input clk,
    input rst,
    input enable,

    input [7:0] rate,

    input [WIDTH-1:0] data_in,
    input stb_in,

    output [WIDTH-1:0] data_out,
    input stb_out
);
    integer i;
    localparam N = 4;
    localparam RATE_LOG = 7;
    localparam max_bit_gain = RATE_LOG*(N-1);

    wire [WIDTH+max_bit_gain-1:0] data_in_ext;
    sign_extend #(WIDTH, WIDTH+max_bit_gain)
        extend_data_in (.data_in(data_in), .data_out(data_in_ext));

    // Create a pipeline of differentiators
    reg [WIDTH+max_bit_gain-1:0] differentiator_reg [0:N-1];
    reg [WIDTH+max_bit_gain-1:0] differentiator [0:N-1];
    always @(posedge clk)
        if(rst | ~enable)
        begin
            for(i=0;i<N;i=i+1)
            begin
                differentiator_reg[i] <= 0;
                differentiator[i] <= 0;
            end
        end
        else if (enable && stb_in)
        begin
            differentiator_reg[0] <= data_in_ext;
            differentiator[0] <= data_in_ext - differentiator_reg[0];
            for(i=1;i<N;i=i+1)
            begin
                differentiator_reg[i] <= differentiator[i-1];
                differentiator[i] <= differentiator[i-1] - differentiator_reg[i];
            end
        end

    // Create a pipeline of integrators
    reg [WIDTH+max_bit_gain-1:0] integrator [0:N-1];
    always @(posedge clk)
        if(rst | ~enable)
            for(i=0; i<N; i=i+1)
                integrator[i] <= 0;
        else if (enable)
        begin
            if (stb_in)
                integrator[0] <= integrator[0] + differentiator[N-1];
            if (stb_out)
                for (i=1;i<N;i=i+1)
                    integrator[i] <= integrator[i] + integrator[i-1];
        end

    wire [WIDTH-1:0] data_shifted;
    cic_gain_bank #(.WIDTH(WIDTH))
        cic_gain_bank (
            .rate(rate),
            .data_in(integrator[N-1]),
            .data_out(data_shifted)
        );

    reg [WIDTH-1:0] data_out_reg;
    always @(posedge clk)
        data_out_reg <= data_shifted;

    assign data_out = data_out_reg;

endmodule
