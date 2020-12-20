	component adc_qsys is
		port (
			clk_clk                              : in  std_logic                     := 'X';             -- clk
			clock_bridge_sys_out_clk_clk         : out std_logic;                                        -- clk
			modular_adc_0_command_valid          : in  std_logic                     := 'X';             -- valid
			modular_adc_0_command_channel        : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
			modular_adc_0_command_startofpacket  : in  std_logic                     := 'X';             -- startofpacket
			modular_adc_0_command_endofpacket    : in  std_logic                     := 'X';             -- endofpacket
			modular_adc_0_command_ready          : out std_logic;                                        -- ready
			modular_adc_0_response_valid         : out std_logic;                                        -- valid
			modular_adc_0_response_channel       : out std_logic_vector(4 downto 0);                     -- channel
			modular_adc_0_response_data          : out std_logic_vector(11 downto 0);                    -- data
			modular_adc_0_response_startofpacket : out std_logic;                                        -- startofpacket
			modular_adc_0_response_endofpacket   : out std_logic;                                        -- endofpacket
			reset_reset_n                        : in  std_logic                     := 'X'              -- reset_n
		);
	end component adc_qsys;

	u0 : component adc_qsys
		port map (
			clk_clk                              => CONNECTED_TO_clk_clk,                              --                      clk.clk
			clock_bridge_sys_out_clk_clk         => CONNECTED_TO_clock_bridge_sys_out_clk_clk,         -- clock_bridge_sys_out_clk.clk
			modular_adc_0_command_valid          => CONNECTED_TO_modular_adc_0_command_valid,          --    modular_adc_0_command.valid
			modular_adc_0_command_channel        => CONNECTED_TO_modular_adc_0_command_channel,        --                         .channel
			modular_adc_0_command_startofpacket  => CONNECTED_TO_modular_adc_0_command_startofpacket,  --                         .startofpacket
			modular_adc_0_command_endofpacket    => CONNECTED_TO_modular_adc_0_command_endofpacket,    --                         .endofpacket
			modular_adc_0_command_ready          => CONNECTED_TO_modular_adc_0_command_ready,          --                         .ready
			modular_adc_0_response_valid         => CONNECTED_TO_modular_adc_0_response_valid,         --   modular_adc_0_response.valid
			modular_adc_0_response_channel       => CONNECTED_TO_modular_adc_0_response_channel,       --                         .channel
			modular_adc_0_response_data          => CONNECTED_TO_modular_adc_0_response_data,          --                         .data
			modular_adc_0_response_startofpacket => CONNECTED_TO_modular_adc_0_response_startofpacket, --                         .startofpacket
			modular_adc_0_response_endofpacket   => CONNECTED_TO_modular_adc_0_response_endofpacket,   --                         .endofpacket
			reset_reset_n                        => CONNECTED_TO_reset_reset_n                         --                    reset.reset_n
		);

