# FM Transmitter

This project aims to create an FM transmitter using just an FPGA.

# Goal

Build an FPGA-based Fully Digital FM Transmitter, i.e. create an FM
transmitter just using an FPGA and everything that an FPGA can get.

## Block Diagram

![Project Block Diagram](docs/images/project_diagram.png)

# Milestones

- [x] Blink led to test the Neek10 board
- [x] Add CI
- [x] Audio Loopback using data with sample rate of 48kHz
- [ ] Create test environment and add on CI
- [ ] Create and test sample interpolators to increase fs throughout the DUC (digital up-converter) chain, search for Comb filters
- [ ] Create and test the frequency shifter to the DUC chain.
- [ ] Create and test an HPSDM (High-Pass Sigma-Delta Modulator)

# Current Code's Features

- [x] Lint CI for Verilog
- [x] Makefile with
  - [x] Lint CI
  - [x] Compile code using quartus platform
  - [x] Find and Program the Neek10 board, if attached on the computer
- [x] Loopback using:
  - [x] Onboarded Mic, which uses the ADC port for Max10 ADC protocol
  - [x] Line out of Onboarded CODEC IC [TLV320AIC3254](https://www.ti.com/lit/ds/symlink/tlv320aic3254.pdf?ts=1608386796342)
  - [x] Sample rate 48kHz
  - [x] Led meter to inform the audio energy

# Aiming New Features

- [ ] CI with unit tests (Look for CocoTb python3)
- [ ] Use a LPSDM (Low-Pass Sigma-Delta Modulator) instead of using the built-in ADC from Max10.
