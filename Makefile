all: build send

BOARD="NEEK10 [1-2.4]"
OUTPUT_SOF=output_files/BlinkLed.sof
PROJECT_NAME=BlinkLed

build:
	quartus_map --read_settings_files=on --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}
	quartus_fit --read_settings_files=off --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}
	quartus_asm --read_settings_files=off --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}

send:
	quartus_pgm --cable=${BOARD} -m JTAG -o p\;${OUTPUT_SOF}
