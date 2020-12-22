import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

@cocotb.test()
async def test_mock_max10(dut):
    """ Test that d propagates to q """

    clock = Clock(dut.MAX10_CLK1_50, 10, units="us")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock

    for i in range(10):
        await FallingEdge(dut.MAX10_CLK1_50)