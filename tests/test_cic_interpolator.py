import json
import matplotlib.pyplot as plt
import numpy as np
import os
import random
from dataclasses import dataclass
from numpy import array, ndarray
from pathlib import Path
from typing import List, Tuple

import pytest
import cocotb
from cocotb.binary import BinaryValue, BinaryRepresentation
from cocotb.clock import Clock
from cocotb.handle import ModifiableObject, HierarchyObject
from cocotb.triggers import FallingEdge, NextTimeStep, Event, Timer

from utils import BaseSignalTest, results_dir


@cocotb.test(skip = False)
def init(dut: HierarchyObject):
    """
        Test Cic Interpolator changing the input signal, rate and width
        and retrieving the output signal.

        - Test with sins and checking the SNR and output sin shape.
        - Test the cic impulsive response and save the results
    """
    test = TestCicInterpolator()
    params = TestingParameters()
    yield test.cocotb_test_cic_interpolator(
        dut,
        params,
    )
    if params.is_sin:
        test.check_sin_results()


@dataclass
class CicInterpolator:
    """
        Dataclass to make easier to address the dut fields
    """
    clk: ModifiableObject
    rst: ModifiableObject
    enable: ModifiableObject

    rate: ModifiableObject

    data_in: ModifiableObject
    stb_in: ModifiableObject
    data_out: ModifiableObject
    stb_out: ModifiableObject


@dataclass
class TestingParameters:
    WIDTH: int
    data: List[int]
    rate: int
    name: str
    fc: float

    def __init__(self):
        self.WIDTH = int(os.environ["WIDTH"])
        self.data = json.loads(os.environ["data"])
        self.rate = int(os.environ["rate"])
        self.name = os.environ["name"]
        self.fc = float(os.environ.get("fc", -1))
        self.is_sin = bool(os.environ.get('sin_test', False))


def generate_values():
    widths = [16, 10, 32]
    sizes = [500, 250, 100]
    rates = [2, 10, 30]
    fcs = [1e3, 500, 2e3]
    sins = [
        BaseSignalTest().generate_sin(*params)
        for params in zip(sizes, fcs, widths)
    ]
    names = [
        f'test_sin_{f/1e3:.2f}kHz_{s}S_{r}R_{w}b'
        for w, s, r, f in zip(widths, sizes, rates, fcs)
    ]

    return [
        values for values in zip(sins, fcs, widths, rates, names)
    ]


class TestCicInterpolator(BaseSignalTest):
    dut: CicInterpolator = None
    params: TestingParameters = None
    data_in: ndarray = None
    data_out: ndarray = None

    # Pytests
    @pytest.mark.parametrize("data, fc, width, rate, name", generate_values())
    def test_cic_with_sins(self, data, fc, width, rate, name):
        parameters = {
            "WIDTH": width,
        }
        values = {
            "data": data,
            "fc": fc,
            "name": name,
            "rate": rate,
            "sin_test": True,
        }
        self.run_simulator(parameters=parameters, values=values)

    def test_cic_impulse_response(self):
        width = 32
        size = 256
        rate = 10
        impulse = np.zeros((size,)).astype(int).tolist()
        impulse[0] = 2**(width-1)-1
        print(impulse)

        parameters = {
            "WIDTH": width,
        }
        values = {
            "data": impulse,
            "name": 'impulse_test',
            "rate": rate,
        }
        self.run_simulator(parameters=parameters, values=values)

    # Cocotb coroutines
    @cocotb.coroutine
    def cocotb_test_cic_interpolator(
        self,
        dut: CicInterpolator,
        params: TestingParameters,
    ):
        self.data_length = params.WIDTH

        self.dut = dut
        self.params = params

        self.log(f'width: {params.WIDTH}')
        self.log(f'rate: {params.rate}')
        # Check widths
        assert params.WIDTH == len(dut.data_in.value.binstr)
        assert params.WIDTH == len(dut.data_out.value.binstr)

        # Create a 10us period clock
        clock = Clock(dut.clk, 10, units="us")
        cocotb.fork(clock.start())

        if params.is_sin:
            offset = params.rate*8+10
        else:
            offset = 0

        yield self.initialize_module()
        yield self.send_data(
            end_zeros=10,
            offset=offset,
        )

        max_value = 2**(params.WIDTH-1)
        norm_data_out = self.data_out/max_value
        print(norm_data_out)
        plt.plot(norm_data_out)
        plt.savefig(self.folder_dir / f'{params.name}_data_out.png')

        fft_out = self.calc_fft(norm_data_out)
        plt.clf()
        plt.plot(fft_out)
        plt.savefig(self.folder_dir / f'{params.name}_data_out_fft.png')

    @cocotb.coroutine
    def initialize_module(self):
        """
            - Reset the Cic module
            - Enable to be ready to start
            - Set the rate value
        """
        dut = self.dut
        params = self.params

        # Reset module
        dut.rst = 1
        dut.enable = 0
        dut.stb_in = 0
        dut.stb_out = 0
        dut.rate = self.set_uns_data(0)
        dut.data_in = self.set_data(0)
        # Wait 5 clock cycles
        for _ in range(5):
            yield FallingEdge(dut.clk)
        # Enable module and set the rate
        dut.rst = 0
        dut.enable = 1
        dut.rate = self.set_uns_data(params.rate)
        yield FallingEdge(dut.clk)

        # Check the rate
        self.log(f'Rate set: {dut.rate.value.signed_integer}')
        assert params.rate == dut.rate.value.integer

    @cocotb.coroutine
    def send_data(self, out_clk_rate=2, end_zeros=10, offset=0):
        """
            Actions:
            - Send (drive) the data from input flow
            - Control in/out strobes
            - Monitor the output flow
            - Return the results from input and output in ndarrays as
              self.data_in and self.data_out

            Args:
            - out_clk_rate: rate between clock frequency and stb_out
              frequency. The greater this variable the slower the
              simulation.
            - end_zeros: number of zeros to be sent after sending the
              actual data in order to retrieve the remaining data
            - offset: offset to start the output data added in order to
              get a proportional length between input and output
        """
        dut = self.dut
        params = self.params

        in_clk_rate = out_clk_rate*params.rate
        input_index = 0
        data_out = []
        data_in = []
        data = params.data
        len_data = len(data)
        for i in range((len_data+end_zeros)*params.rate*out_clk_rate):
            yield FallingEdge(dut.clk)
            dut.stb_in = i % in_clk_rate == 0
            dut.stb_out = i % out_clk_rate == 0

            if dut.stb_out == 1:
                data_out.append(dut.data_out.value.signed_integer)

            if dut.stb_in == 1:
                if input_index < len_data:
                    dut.data_in.value = self.set_data(data[input_index])
                else:
                    dut.data_in = self.set_data(0)
                input_index += 1
                data_in.append(dut.data_in.value.signed_integer)

        self.data_in = np.array(data_in[:len_data])
        self.data_out = np.array(data_out[offset:params.rate*len_data+offset])

    # Check methods
    def check_sin_results(self):
        dut = self.dut
        params = self.params

        plt.clf()
        plt.plot(self.data_in)
        plt.savefig(self.folder_dir / f'{params.name}_data_in.png')

        max_value = 2**(params.WIDTH-1)
        norm_data_out = self.data_out/max_value
        expected_data_out = self.interpolate(self.data_in, params.rate)
        norm_expected_data_out = expected_data_out/max_value
        plt.clf()
        plt.plot(norm_expected_data_out)
        plt.savefig(self.folder_dir / f'{params.name}_expected_data_out.png')

        expected_fft_out = self.calc_fft(norm_expected_data_out)
        plt.clf()
        plt.plot(expected_fft_out)
        plt.savefig(self.folder_dir / f'{params.name}_expected_data_out_fft.png')

        self.check_sin(
            norm_data_out,
            params.fc,
            fs=8e3*params.rate,
            fc_band=300,
        )

    def interpolate(self, data: np.ndarray, rate: int):
        len_data = len(data)
        fft = np.fft.fft(data)
        half_len = int(len_data/2)

        interp_len = rate*len_data
        interp_fft = np.zeros((interp_len,))
        interp_fft[:half_len] = fft.real[:half_len] + 1j*fft.imag[:half_len]
        interp_fft[interp_len-half_len:] = fft[half_len:] + 1j*fft.imag[half_len:]
        interp_fft = interp_fft*rate

        return np.fft.ifft(interp_fft).real