	adc_qsys u0 (
		.clk_clk                              (<connected-to-clk_clk>),                              //                      clk.clk
		.clock_bridge_sys_out_clk_clk         (<connected-to-clock_bridge_sys_out_clk_clk>),         // clock_bridge_sys_out_clk.clk
		.modular_adc_0_command_valid          (<connected-to-modular_adc_0_command_valid>),          //    modular_adc_0_command.valid
		.modular_adc_0_command_channel        (<connected-to-modular_adc_0_command_channel>),        //                         .channel
		.modular_adc_0_command_startofpacket  (<connected-to-modular_adc_0_command_startofpacket>),  //                         .startofpacket
		.modular_adc_0_command_endofpacket    (<connected-to-modular_adc_0_command_endofpacket>),    //                         .endofpacket
		.modular_adc_0_command_ready          (<connected-to-modular_adc_0_command_ready>),          //                         .ready
		.modular_adc_0_response_valid         (<connected-to-modular_adc_0_response_valid>),         //   modular_adc_0_response.valid
		.modular_adc_0_response_channel       (<connected-to-modular_adc_0_response_channel>),       //                         .channel
		.modular_adc_0_response_data          (<connected-to-modular_adc_0_response_data>),          //                         .data
		.modular_adc_0_response_startofpacket (<connected-to-modular_adc_0_response_startofpacket>), //                         .startofpacket
		.modular_adc_0_response_endofpacket   (<connected-to-modular_adc_0_response_endofpacket>),   //                         .endofpacket
		.reset_reset_n                        (<connected-to-reset_reset_n>)                         //                    reset.reset_n
	);

