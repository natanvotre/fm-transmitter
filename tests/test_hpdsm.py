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

from tests.utils import BaseSignalTest


@cocotb.test(skip = False)
def init(dut: HierarchyObject):
    """
        Test Hpdsm changing the input signal and width,
        and retrieving the output signal.

        - Test with sins and checking the SNR and output sin shape.
    """
    test = TestHpdsm()
    params = TestingParameters()
    yield test.cocotb_test_hpdsm(
        dut,
        params,
    )
    test.check_sin_results()


@dataclass
class Hpdsm:
    """
        Dataclass to make easier to address the dut fields
    """
    clk: ModifiableObject
    rst: ModifiableObject

    xi: ModifiableObject
    yo: ModifiableObject


@dataclass
class TestingParameters:
    WIDTH: int
    data: ndarray
    name: str

    def __init__(self):
        self.WIDTH = int(os.environ["WIDTH"])
        self.size = int(os.environ["size"])
        self.fc = float(os.environ["fc"])
        self.fs = float(os.environ["fs"])
        self.data = BaseSignalTest().generate_norm_sin(
            self.size,
            self.fc,
            fs=self.fs,
        )
        self.name = os.environ["name"]


def filter(x: ndarray):
    """
        Filter the input signal:
            H(z) = 0.5z^-1/(1+0.98z^-1)
    """
    y = np.zeros((len(x),))

    for i in range(len(x)-1):
        y[i+1] = 0.5*x[i] - 0.98*y[i]

    return y


def generate_values():
    widths = [24, 16, 32]
    sizes = [10000, 10000, 10000]
    fcs = [99e6, 99.5e6, 99.8e6]
    fs = [200e6, 200e6, 200e6]
    names = [
        f'test_sin_{f/1e3:.2f}kHz_{s}S_{w}b'
        for w, s, f in zip(widths, sizes, fcs)
    ]

    return [
        values for values in zip(sizes, fcs, fs, widths, names)
    ]


class TestHpdsm(BaseSignalTest):
    dut: Hpdsm = None
    params: TestingParameters = None
    data_in: ndarray = None
    data_out: ndarray = None

    # Pytests
    @pytest.mark.parametrize("size, fc, fs, width, name", generate_values())
    def test_hpdsm_with_sins(self, size, fc, fs, width, name):
        parameters = {
            "WIDTH": width,
        }
        values = {
            "size": size,
            "fc": fc,
            "fs": fs,
            "name": name,
        }
        self.run_simulator(parameters=parameters, values=values)

    # Cocotb coroutines
    @cocotb.coroutine
    def cocotb_test_hpdsm(
        self,
        dut: Hpdsm,
        params: TestingParameters,
    ):
        self.data_length = params.WIDTH

        self.dut = dut
        self.params = params

        self.log(f'width: {params.WIDTH}')

        # Check widths
        assert params.WIDTH == len(dut.xi.value.binstr)

        # Create a 10us period clock
        clock = Clock(dut.clk, 10, units="us")
        cocotb.fork(clock.start())

        yield self.initialize_module()
        yield self.send_data()

    @cocotb.coroutine
    def initialize_module(self):
        """
            - Reset the Hpdsm module
        """
        dut = self.dut

        # Reset module
        dut.rst = 1
        dut.xi = self.set_data(0)
        # Wait 5 clock cycles
        for _ in range(5):
            yield FallingEdge(dut.clk)
        # Enable module and set the rate
        dut.rst = 0

    @cocotb.coroutine
    def send_data(self, offset=2):
        """
            Actions:
            - Send (drive) the data to the input
            - Return the results from input and output in ndarrays as
              self.data_in and self.data_out
        """
        dut = self.dut
        params = self.params

        data_out = []
        data_in = []
        data = self.quantizer(params.data, params.WIDTH).tolist()
        # data = (np.sin(2*np.pi*np.linspace(0, 999, 1000)*3.8e3/8e3)*2**(params.WIDTH-1)).astype(int).tolist()
        len_data = len(data)
        for i in range(len_data+offset):
            if i < len_data:
                dut.xi = self.set_data(data[i], data_length=params.WIDTH)
            else:
                dut.xi = self.set_data(0)

            yield FallingEdge(dut.clk)
            data_in.append(dut.xi.value.signed_integer)
            data_out.append(dut.yo.value.signed_integer)

        self.data_in = np.array(data_in[:len_data]).astype(float)
        self.log(f'len_data_in: {len(self.data_in)}')
        self.data_out = np.array(data_out[offset:len_data+offset]).astype(float)

    # Check methods
    def check_sin_results(self):
        dut = self.dut
        params = self.params
        assert dut.rst == 0

        max_value = 2**(params.WIDTH-1)

        norm_data_in = self.data_in/max_value
        norm_data_out = self.data_out*2
        fs = params.fs
        fft_out = self.calc_fft(norm_data_out)

        self.save_wav_data(norm_data_in, f'data_in.wav', params.name, fs=20000)
        self.save_wav_data(norm_data_out, f'data_out.wav', params.name, fs=20000)
        self.save_wav_data(fft_out, f'fft_out.wav', params.name, fs=20000)

        self.check_signal_integrity(
            data_in=norm_data_in,
            data_out=norm_data_out,
            freq_band=(0.985*fs/2, fs/2),
            fs=fs,
            min_db=-40,
            max_diff_db=0.5,
        )
