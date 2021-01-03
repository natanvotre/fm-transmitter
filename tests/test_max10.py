import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

from tests.utils import BaseTest


@cocotb.test()
async def _test_mock_max10(dut):
    """ Test that d propagates to q """

    # Create a 10us period clock on port clk
    clock = Clock(dut.MAX10_CLK1_50, 10, units="us")
    cocotb.fork(clock.start())

    for i in range(10):
        await FallingEdge(dut.MAX10_CLK1_50)


class TestMax10(BaseTest):

    def test_mock_max10(self):
        BaseTest().run_simulator('max10')
