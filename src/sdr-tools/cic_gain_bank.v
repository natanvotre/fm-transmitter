module cic_gain_bank #(
    parameter WIDTH=16,
    parameter MAX_BIT_GAIN=21
) (
    input clk,
    input [7:0] rate,
    input [WIDTH+MAX_BIT_GAIN-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    // N \log_{2}(RM)
    function [4:0] bit_gain;
        input [7:0] rate;
        case(rate)
            // Exact Cases
            8'd1: bit_gain = 0;
            8'd2: bit_gain = 3;
            8'd4: bit_gain = 6;
            8'd8: bit_gain = 9;
            8'd16: bit_gain = 12;
            8'd32: bit_gain = 15;
            8'd64: bit_gain = 18;
            8'd128: bit_gain = 21;

            8'd3: bit_gain = 5;
            8'd5: bit_gain = 7;
            8'd6: bit_gain = 8;
            8'd7: bit_gain = 9;
            8'd9,8'd10: bit_gain = 10;
            8'd11,8'd12: bit_gain = 11;
            8'd13,8'd14,8'd15: bit_gain = 12;
            8'd17,8'd18,8'd19,8'd20: bit_gain = 13;
            8'd21,8'd22,8'd23,8'd24,8'd25: bit_gain = 14;
            8'd26,8'd27,8'd28,8'd29,8'd30,8'd31: bit_gain = 15;
            8'd33,8'd34,8'd35,8'd36,8'd37,8'd38,8'd39,8'd40: bit_gain = 16;
            8'd41,8'd42,8'd43,8'd44,8'd45,8'd46,8'd47,8'd48,8'd49,8'd50: bit_gain = 17;
            8'd51,8'd52,8'd53,8'd54,8'd55,8'd56,8'd57,8'd58,8'd59,8'd60,8'd61,8'd62,8'd63: bit_gain = 18;
            8'd65,8'd66,8'd67,8'd68,8'd69,8'd70,8'd71,8'd72,8'd73,8'd74,8'd75,8'd76,8'd77,8'd78,8'd79,8'd80: bit_gain = 19;
            8'd81,8'd82,8'd83,8'd84,8'd85,8'd86,8'd87,8'd88,8'd89,8'd90,8'd91,8'd92,8'd93,8'd94,8'd95,8'd96,8'd97,8'd98,8'd99,8'd100,8'd101: bit_gain = 20;

            default: bit_gain = 21;
        endcase
    endfunction

    wire [4:0] shift = bit_gain(rate);

    reg [WIDTH-1:0] data_out_reg;
    always @(posedge clk)
        case(shift)
            5'd0 : data_out_reg <= data_in[0+WIDTH-1:0];
            5'd3 : data_out_reg <= data_in[3+WIDTH-1:3];
            5'd5 : data_out_reg <= data_in[5+WIDTH-1:5];
            5'd6 : data_out_reg <= data_in[6+WIDTH-1:6];
            5'd7 : data_out_reg <= data_in[7+WIDTH-1:7];
            5'd8 : data_out_reg <= data_in[8+WIDTH-1:8];
            5'd9 : data_out_reg <= data_in[9+WIDTH-1:9];
            5'd10: data_out_reg <= data_in[10+WIDTH-1:10];
            5'd11: data_out_reg <= data_in[11+WIDTH-1:11];
            5'd12: data_out_reg <= data_in[12+WIDTH-1:12];
            5'd13: data_out_reg <= data_in[13+WIDTH-1:13];
            5'd14: data_out_reg <= data_in[14+WIDTH-1:14];
            5'd15: data_out_reg <= data_in[15+WIDTH-1:15];
            5'd16: data_out_reg <= data_in[16+WIDTH-1:16];
            5'd17: data_out_reg <= data_in[17+WIDTH-1:17];
            5'd18: data_out_reg <= data_in[18+WIDTH-1:18];
            5'd19: data_out_reg <= data_in[19+WIDTH-1:19];
            5'd20: data_out_reg <= data_in[20+WIDTH-1:20];
            5'd21: data_out_reg <= data_in[21+WIDTH-1:21];
            default: data_out_reg <= data_in[21+WIDTH-1:21];
        endcase

    assign data_out = data_out_reg;
endmodule
