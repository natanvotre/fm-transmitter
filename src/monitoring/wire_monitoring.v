module wire_monitoring #(
    parameter ID = "NAME",
    parameter INDEX = 1,
    parameter WIDTH = 16
) (
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

    `ifdef IS_ALTERA
        altsource_probe altsource_probe_component (
            .probe(data_in),
            .source(data_out)
        );
        defparam
            altsource_probe_component.instance_id = ID,
            altsource_probe_component.source_width = WIDTH,
            altsource_probe_component.probe_width = WIDTH,
            altsource_probe_component.enable_metastability = "NO",
            altsource_probe_component.sld_auto_instance_index = "NO",
            altsource_probe_component.sld_instance_index = INDEX,
            altsource_probe_component.source_initial_value = "0";
    `else
        assign data_out = data_in;
    `endif

endmodule
