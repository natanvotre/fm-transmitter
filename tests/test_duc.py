import json
import matplotlib.pyplot as plt
import numpy as np
import os
from dataclasses import dataclass
from numpy import ndarray

import pytest
import cocotb
from cocotb.clock import Clock
from cocotb.handle import ModifiableObject, HierarchyObject
from cocotb.triggers import FallingEdge

from tests.utils import BaseSdrTest


@cocotb.test(skip = False)
def init(dut: HierarchyObject):
    """
        Test Fm Interpolator changing the input signal, rate and width
        and retrieving the output signal.

        - Test with sins and checking the SNR and output sin shape.
        - Test the fm impulsive response and save the results
    """
    test = TestDuc()
    params = TestingParameters()
    yield test.cocotb_test_duc(
        dut,
        params,
    )
    test.check_sin_results()


@dataclass
class Duc:
    """
        Dataclass to make easier to address the dut fields
    """
    clk: ModifiableObject
    rst: ModifiableObject

    data_in_i: ModifiableObject
    data_in_q: ModifiableObject
    stb_in: ModifiableObject

    data_out_i: ModifiableObject
    data_out_q: ModifiableObject
    stb_out: ModifiableObject


@dataclass
class TestingParameters:
    WIDTH: int
    FCLK: int
    FC_IN: int
    FS_IN: int
    FC_OUT: int
    FS_OUT: int
    ZEXT: int
    data: ndarray
    name: str
    rate: int
    in_clk: int
    out_clk: int
    def __init__(self):
        self.WIDTH = int(os.environ["WIDTH"])
        self.FC_IN = int(float(os.environ["FC_IN"]))
        self.FS_IN = int(float(os.environ["FS_IN"]))
        self.FC_OUT = int(float(os.environ["FC_OUT"]))
        self.FS_OUT = int(float(os.environ["FS_OUT"]))
        self.FCLK = int(float(os.environ["FCLK"]))
        self.ZEXT = int(os.environ["ZEXT"])
        self.data_i = np.array(json.loads(os.environ["data_i"]))
        self.data_q = np.array(json.loads(os.environ["data_q"]))
        self.name = os.environ["name"]

        self.rate = int(self.FS_OUT/self.FS_IN)
        self.out_clk = int(self.FCLK/self.FS_OUT)
        self.in_clk = self.out_clk*self.rate


def generate_sin_values():
    widths = [16, 20, 26]
    sizes = [100, 100, 100]
    fc_in = [0.5e6, 1.25e6, 1e6]
    fs_in = [2.5e6, 5e6, 5e6]
    rates = [20, 40, 30]
    fc_out = [20e6, 98.46e6, 74.8e6]
    out_clks = [2, 1, 1]
    zext = [0, 0, 0]
    fs_out = [fs*r for fs, r in zip(fs_in, rates)]
    fclks = [fs*oc for fs, oc in zip(fs_out, out_clks)]
    data = [
        BaseSdrTest().generate_norm_complex_exp(s, f, fs)
        for s, f, fs in zip(sizes, fc_in, fs_in)
    ]
    names = [
        f'test_sin_{fci/1e6:.0f}MHz_fs_{fsi/1e6:.0f}MHz_{s}S_{w}b_to_{fco/1e6:.0f}MHz_fs_{fso/1e6:.0f}MHz_clk_{fclk/1e6:.0f}MHz'
        for w, s, fci, fsi, fco, fso, fclk in zip(widths, sizes, fc_in, fs_in, fc_out, fs_out, fclks)
    ]

    return [
        values for values in zip(
            data, widths, fc_in, fs_in,
            fc_out, fs_out, fclks,
            zext, names,
        )
    ]


class TestDuc(BaseSdrTest):
    dut: Duc = None
    params: TestingParameters = None
    data_in: ndarray = None
    data_out: ndarray = None

    # Pytests
    @pytest.mark.parametrize(
        "data, width, fc_in, fs_in, fc_out, fs_out, fclk, zext, name",
        generate_sin_values()
    )
    def test_duc_with_sins(self, data:ndarray, width, fc_in, fs_in,
        fc_out, fs_out, fclk, zext, name):

        parameters = {
            "WIDTH": width,
            "FCLK": fclk,
            "FS_IN": fs_in,
            "FS_OUT": fs_out,
            "FC_IN": fc_in,
            "FC_OUT": fc_out,
            "ZEXT": zext,
        }
        values = {
            "data_i": data.real.tolist(),
            "data_q": data.imag.tolist(),
            "name": name,
        }
        self.run_simulator(parameters=parameters, values=values)

    # Cocotb coroutines
    @cocotb.coroutine
    def cocotb_test_duc(
        self,
        dut: Duc,
        params: TestingParameters,
    ):
        self.data_length = params.WIDTH

        self.dut = dut
        self.params = params

        self.log(f'WIDTH: {params.WIDTH}')
        self.log(f'FCLK: {params.FCLK}')
        self.log(f'FC_IN: {params.FC_IN}')
        self.log(f'FS_IN: {params.FS_IN}')
        self.log(f'FC_OUT: {params.FC_OUT}')
        self.log(f'FS_OUT: {params.FS_OUT}')
        self.log(f'ZEXT: {params.ZEXT}')
        self.log(f'rate: {params.rate}')
        self.log(f'out clk: {params.out_clk}')

        # Check widths
        assert params.WIDTH == len(dut.data_in_i.value.binstr)
        assert params.WIDTH == len(dut.data_in_q.value.binstr)
        assert params.WIDTH == len(dut.data_out_i.value.binstr)
        assert params.WIDTH == len(dut.data_out_q.value.binstr)

        # Create the period clock
        clk_period = int(1/params.FCLK*1e9/2)*2
        self.log(clk_period)
        clock = Clock(dut.clk, clk_period, units="ns")
        cocotb.fork(clock.start())


        yield self.initialize_module()
        yield self.send_data(offset=110)

    @cocotb.coroutine
    def initialize_module(self):
        """
            - Reset the Fm module
        """
        dut = self.dut
        params = self.params

        # Reset module
        dut.rst = 1
        dut.stb_in = 0
        dut.data_in_i = self.set_data(0)
        dut.data_in_q = self.set_data(0)

        # Wait 5 clock cycles
        for _ in range(5):
            yield FallingEdge(dut.clk)

        dut.rst = 0
        yield FallingEdge(dut.clk)

    @cocotb.coroutine
    def send_data(self, end_zeros=10, offset=0):
        """
            Actions:
            - Send (drive) the data from input flow
            - Control in/out strobes
            - Monitor the output flow
            - Return the results from input and output in ndarrays as
              self.data_in_{i,q} and self.data_out_{i,q}

            Args:
            - out_clk_rate: rate between clock frequency and stb_out
              frequency. The greater this variable the slower the
              simulation.
            - offset: offset to start the output data added in order to
              get a proportional length between input and output
        """
        dut = self.dut
        params = self.params

        input_index = 0
        data_in_i = []
        data_in_q = []
        data_out_i = []
        data_out_q = []
        data_i = self.quantizer(params.data_i, params.WIDTH).tolist()
        data_q = self.quantizer(params.data_q, params.WIDTH).tolist()
        len_data = len(data_i)
        for i in range((len_data+end_zeros)*params.rate*params.out_clk):
            yield FallingEdge(dut.clk)
            dut.stb_in = i % params.in_clk == 0

            if dut.stb_out == 1:
                data_out_i.append(dut.data_out_i.value.signed_integer)
                data_out_q.append(dut.data_out_q.value.signed_integer)

            if dut.stb_in == 1:
                if input_index < len_data:
                    dut.data_in_i.value = self.set_data(data_i[input_index])
                    dut.data_in_q.value = self.set_data(data_q[input_index])
                else:
                    dut.data_in_i = self.set_data(0)
                    dut.data_in_q = self.set_data(0)
                input_index += 1
                data_in_i.append(dut.data_in_i.value.signed_integer)
                data_in_q.append(dut.data_in_q.value.signed_integer)

        self.data_in_i = np.array(data_in_i[:len_data])
        self.data_in_q = np.array(data_in_q[:len_data])
        self.data_out_i = np.array(data_out_i[offset:params.rate*len_data+offset])
        self.data_out_q = np.array(data_out_q[offset:params.rate*len_data+offset])
        self.data_in = self.data_in_i + 1j*self.data_in_q
        self.data_out = self.data_out_i + 1j*self.data_out_q

    # Check methods
    def check_sin_results(self):
        params = self.params

        max_value:int = 2**(params.WIDTH-1)
        norm_data_in = self.data_in/max_value
        norm_data_out = self.data_out/max_value

        self.save_fft_data(
            norm_data_in, 'input_fft_data',
            params.name, params.FS_IN, is_complex=True
        )
        self.save_data(
            norm_data_in[:100], 'input_data',
            params.name, params.FS_IN
        )

        self.save_fft_data(
            norm_data_out, 'output_fft_data',
            params.name, params.FS_OUT, is_complex=True
        )
        self.save_data(
            norm_data_out[:100], 'output_data',
            params.name, params.FS_OUT
        )

        self.check_sin(norm_data_out.real, params.FC_OUT, 200e3, params.FS_OUT, snr=35)
