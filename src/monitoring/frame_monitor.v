module frame_monitor #(
    parameter ID = "NAM",
    parameter WIDTH = 16,
    parameter LENGTH = 11
) (
    input clk,
    input rst,

    input [WIDTH-1:0] data_in,
    input stb_in
);
    localparam LENGTH_EXP=1<<LENGTH;

    wire trigger_in, trigger_out;
    wire_monitoring #( .ID({ID, "0"}), .WIDTH(1))
        monitor_trigger (trigger_in, trigger_out);

    wire ram_wren;
    reg [LENGTH-1:0] ram_addr_reg;
    reg [1:0] monitor_sm;
    localparam IDLE = 0;
    localparam WRITE = 1;
    localparam WAIT_DISABLE = 2;
    always @(posedge clk)
        if (rst)
        begin
            monitor_sm <= IDLE;
            ram_addr_reg <= 0;
        end
        else begin
            case (monitor_sm)
                IDLE:
                begin
                    ram_addr_reg <= 0;
                    if (trigger_out)
                        monitor_sm <= WRITE;
                end

                WRITE:
                begin
                    if (ram_addr_reg == LENGTH_EXP-1)
                        monitor_sm <= WAIT_DISABLE;

                    if (ram_wren)
                        ram_addr_reg <= ram_addr_reg + 1;
                end

                WAIT_DISABLE:
                begin
                    if (!trigger_out)
                        monitor_sm <= IDLE;
                end

                default:
                    monitor_sm <= IDLE;

            endcase
        end
    assign trigger_in = (monitor_sm == WAIT_DISABLE);


    assign ram_wren = stb_in & (monitor_sm == WRITE);
    ram_monitoring #(
        .ID({ID, "1"}),
        .LENGTH(LENGTH),
        .LENGTH_EXP(LENGTH_EXP),
        .WIDTH(WIDTH)
    ) ram_monitoring (
        .clk(clk),

        .addr(ram_addr_reg),
        .data(data_in),
        .wren(ram_wren)
    );

endmodule
