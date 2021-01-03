import os
import numpy as np
import random
from dataclasses import dataclass

import pytest
import cocotb
from cocotb.triggers import Timer
from cocotb.handle import ModifiableObject, HierarchyObject

from tests.utils import BaseSignalTest


@cocotb.test(skip = False)
def init(dut: HierarchyObject):
    """ Test Sign extend for different values of data_in """
    test = TestSignExtend()
    yield test.cocotb_test_sign_extend(
        dut=SignExtend.convert(dut),
        params=TestingParameters(),
    )


@dataclass
class SignExtend:
    data_in: ModifiableObject
    data_out: ModifiableObject

    def convert(dut: HierarchyObject):
        return SignExtend(
            dut.data_in,
            dut.data_out,
        )


@dataclass
class TestingParameters:
    data_value: int
    length_in: int
    length_out: int

    def __init__(self):
        self.data_value = int(os.environ["value"])
        self.length_in = int(os.environ["LENGTH_IN"])
        self.length_out = int(os.environ["LENGTH_OUT"])


class TestSignExtend(BaseSignalTest):

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
        self.run_simulator(parameters=parameters, values=values)

    @cocotb.coroutine
    def cocotb_test_sign_extend(
        self,
        dut: SignExtend,
        params: TestingParameters,
    ):
        self.log(f'value type: {type(dut.data_in.value)}')

        # Check lengths
        self.log(f'input length: {params.length_in}')
        self.log(f'output length: {params.length_out}')
        assert params.length_in == len(dut.data_in.value.binstr)
        assert params.length_out == len(dut.data_out.value.binstr)

        # Set test value
        dut.data_in.value = self.set_data(params.data_value, params.length_in)
        yield Timer(10, units="us")

        # Check Extended signal value at the output
        self.log(f'data_in: {dut.data_in.value.signed_integer}')
        self.log(f'data_out: {dut.data_out.value.signed_integer}')
        assert dut.data_out.value.signed_integer == params.data_value
