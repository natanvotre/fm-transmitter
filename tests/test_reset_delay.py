import os
import numpy as np
import random

import pytest
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

from utils import BaseTest


@cocotb.test()
async def _test_reset_delay(dut):
    """ Test that set reset delay for different values of DELAY"""

    # Create a 10us period clock on port clk
    clock = Clock(dut.clk, 10, units="us")
    cocotb.fork(clock.start())

    dut.rst_in = 0

    for i in range(10):
        await FallingEdge(dut.clk)

    dut.rst_in = 1
    await FallingEdge(dut.clk)
    assert dut.rst_out == 1
    dut.rst_in = 0

    for i in range(int(os.environ["DELAY"])):
        await FallingEdge(dut.clk)
        assert dut.rst_out == 1

    await FallingEdge(dut.clk)
    assert dut.rst_out == 0


def delay_values():
    # Test fixed delays
    delays = [1000, 100, 454]

    # Test random delay
    interval = [5, 1000]
    delays.append(random.randint(*interval))

    return delays


class TestResetDelay(BaseTest):

    @pytest.mark.parametrize("delay_value", delay_values())
    def test_reset_delay(self, delay_value):
        parameters = {
            "DELAY": delay_value,
            "LEN_LOG": np.ceil(np.log2(delay_value)),
        }
        self.run_simulator('reset_delay', parameters=parameters)
