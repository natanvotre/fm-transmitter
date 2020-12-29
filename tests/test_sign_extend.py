import os
import numpy as np
import random

import pytest
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, NextTimeStep, Event,Timer
from cocotb.binary import BinaryValue, BinaryRepresentation
from cocotb.handle import ModifiableObject, HierarchyObject
from cocotb.monitors import Monitor
import cocotb.log
from utils import BaseTest


def log_test(msg):
    print(f'[Test Sign Extend] {msg}')

@cocotb.test()
async def _test_sign_extend(dut: HierarchyObject):
    """ Test Sign extend for different values of data_in """
    length_in = int(os.environ["LENGTH_IN"])
    length_out = int(os.environ["LENGTH_OUT"])

    log_test(f'len: {os.environ["LENGTH_IN"]}')
    assert length_in == len(dut.data_in.value.binstr)
    assert length_out == len(dut.data_out.value.binstr)
    dut.data_in.value = BinaryValue(
        value=int(os.environ["value"]),
        n_bits=length_in,
        bigEndian=False,
        binaryRepresentation=BinaryRepresentation.TWOS_COMPLEMENT,
    )
    await Timer(10, units="us")
    log_test(f'data_in: {dut.data_in.value.signed_integer}')
    log_test(f'data_out: {dut.data_out.value.signed_integer}')
    assert dut.data_out.value.signed_integer == int(os.environ["value"])


class TestSignExtend(BaseTest):

    @pytest.mark.parametrize("length_in, length_out, value", [
        (10, 12, 511),
        (10, 12, -512),
        (32, 40, 2**31-1),
        (32, 40, -2**31),
    ])
    def test_sign_extend(self, length_in, length_out, value):
        print(length_in, length_out)
        parameters = {
            "LENGTH_IN": length_in,
            "LENGTH_OUT": length_out,
        }
        values = {
            "value": value,
        }
        self.run_simulator('sign_extend', parameters=parameters, values=values)
