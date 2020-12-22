import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

@cocotb.test()
async def test_reset_delay(dut):
    """ Test that d propagates to q """

    clock = Clock(dut.clk, 10, units="us")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock

    dut.rst_in = 0

    for i in range(10):
        await FallingEdge(dut.clk)

    dut.rst_in = 1
    await FallingEdge(dut.clk)
    assert dut.rst_out == 1
    dut.rst_in = 0

    for i in range(10000):
        await FallingEdge(dut.clk)
        assert dut.rst_out == 1

    await FallingEdge(dut.clk)
    assert dut.rst_out == 0