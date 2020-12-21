all: build send

BOARD="${shell quartus_pgm --auto | sed -En "s/^.* (NEEK10 \[.*\])/\1/p"}"
PROJECT_NAME=FmTransmitter
OUTPUT_SOF=output_files/$(PROJECT_NAME).sof

lint:
	./tests/build.sh

build:
	quartus_map --read_settings_files=on --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}
	quartus_fit --read_settings_files=off --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}
	quartus_asm --read_settings_files=off --write_settings_files=off ${PROJECT_NAME} -c ${PROJECT_NAME}

send:
	quartus_pgm --cable=${BOARD} -m JTAG -o p\;${OUTPUT_SOF}

test:
	cd tests; python3 test.py module max10
