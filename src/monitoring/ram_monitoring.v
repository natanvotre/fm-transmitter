`timescale 1 ps / 1 ps
module ram_monitoring #(
    parameter ID = "NONE",
    parameter LENGTH = 11,
    parameter LENGTH_EXP = 2048,
    parameter WIDTH = 32
) (
    input clk,

    input [LENGTH-1:0] addr,
    input [WIDTH-1:0] data,
    input wren,
    output [WIDTH-1:0] q_a
);

    `ifdef IS_ALTERA
        wire [WIDTH-1:0] sub_wire0;
        assign q_a = sub_wire0[WIDTH-1:0];
        altsyncram altsyncram_component (
                    .address_a(addr),
                    .address_b(),
                    .clock0(clk),
                    .data_a(data),
                    .data_b(),
                    .wren_a(wren),
                    .wren_b(),
                    .q_a(sub_wire0),
                    .q_b(),
                    .aclr0(1'b0),
                    .aclr1(1'b0),
                    .addressstall_a(1'b0),
                    .addressstall_b(1'b0),
                    .byteena_a(1'b1),
                    .byteena_b(1'b1),
                    .clock1(1'b1),
                    .clocken0(1'b1),
                    .clocken1(1'b1),
                    .clocken2(1'b1),
                    .clocken3(1'b1),
                    .eccstatus(),
                    .rden_a(1'b1),
                    .rden_b(1'b1));
        defparam
            altsyncram_component.address_reg_b = "CLOCK0",
            altsyncram_component.clock_enable_input_a = "BYPASS",
            altsyncram_component.clock_enable_input_b = "BYPASS",
            altsyncram_component.clock_enable_output_a = "BYPASS",
            altsyncram_component.clock_enable_output_b = "BYPASS",
            altsyncram_component.indata_reg_b = "CLOCK0",
            altsyncram_component.intended_device_family = "Cyclone V",
		    altsyncram_component.lpm_hint = {"ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=",ID},
            altsyncram_component.lpm_type = "altsyncram",
            altsyncram_component.numwords_a = LENGTH_EXP,
            altsyncram_component.numwords_b = LENGTH_EXP,
            altsyncram_component.operation_mode = "SINGLE_PORT",
            altsyncram_component.outdata_aclr_a = "NONE",
            altsyncram_component.outdata_aclr_b = "NONE",
            altsyncram_component.outdata_reg_a = "CLOCK0",
            altsyncram_component.outdata_reg_b = "CLOCK0",
            altsyncram_component.power_up_uninitialized = "FALSE",
            altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
            altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
            altsyncram_component.read_during_write_mode_port_b = "NEW_DATA_NO_NBE_READ",
            altsyncram_component.widthad_a = LENGTH,
            altsyncram_component.widthad_b = LENGTH,
            altsyncram_component.width_a = WIDTH,
            altsyncram_component.width_b = WIDTH,
            altsyncram_component.width_byteena_a = 1,
            altsyncram_component.width_byteena_b = 1,
            altsyncram_component.wrcontrol_wraddress_reg_b = "CLOCK0";
    `else
        // Generic RAM's registers and wires
        reg [WIDTH-1:0] mem [(1<<WIDTH)-1:0];
        reg [WIDTH-1:0] data_reg;
        reg [WIDTH-1:0] qout_reg;
        reg [LENGTH-1:0] addr_reg;
        reg wren_reg;

        integer i;
        always @(posedge clk)
        begin
            addr_reg <= addr;
            wren_reg <= wren;
            data_reg <= data;
            if (wren_reg)
                mem[addr_reg] <= data_reg;

            qout_reg <= mem[addr_reg];
        end

        assign q_a = qout_reg[0];
    `endif


endmodule