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
    test = TestTransmitter()
    params = TestingParameters()
    yield test.cocotb_test_transmitter(
        dut,
        params,
    )
    test.check_sin_results()


@dataclass
class Transmitter:
    """
        Dataclass to make easier to address the dut fields
    """
    clk: ModifiableObject
    rst: ModifiableObject

    rf_out: ModifiableObject


@dataclass
class TestingParameters:
    FCLK: int
    FC: int
    data: ndarray
    name: str
    def __init__(self):
        self.FC = int(float(os.environ["FC"]))
        self.FCLK = int(float(os.environ["FCLK"]))
        self.name = os.environ["name"]


def generate_sin_values():
    fcs = [100.7e6]
    fclks = [208e6]
    names = [
        f'test_FC_{fc/1e6:.0f}MHz_clk_{fclk/1e6:.0f}MHz'
        for fc, fclk in zip(fcs, fclks)
    ]

    return [
        values for values in zip(
            fcs, fclks, names
        )
    ]


class TestTransmitter(BaseSdrTest):
    dut: Transmitter = None
    params: TestingParameters = None
    data_in: ndarray = None
    data_out: ndarray = None

    # Pytests
    @pytest.mark.parametrize(
        "fc, fclk, name",
        generate_sin_values()
    )
    def test_transmitter_with_sins(self, fc, fclk, name):
        parameters = {
            "FC": fc,
            "FCLK": fclk,
        }
        values = {
            "name": name,
        }
        self.run_simulator(parameters=parameters, values=values)

    # Cocotb coroutines
    @cocotb.coroutine
    def cocotb_test_transmitter(
        self,
        dut: Transmitter,
        params: TestingParameters,
    ):
        self.dut = dut
        self.params = params

        self.log(f'FCLK: {params.FCLK}')
        self.log(f'FC: {params.FC}')

        # Create the period clock
        clk_period = int(1/params.FCLK*1e9/2)*2
        clock = Clock(dut.clk, clk_period, units="ns")
        cocotb.fork(clock.start())


        yield self.initialize_module()
        yield self.rec_data()

    @cocotb.coroutine
    def initialize_module(self):
        """
            - Reset the Fm module
        """
        dut = self.dut
        params = self.params

        # Reset module
        dut.rst = 1

        # Wait 5 clock cycles
        for _ in range(5):
            yield FallingEdge(dut.clk)

        dut.rst = 0
        yield FallingEdge(dut.clk)

    @cocotb.coroutine
    def rec_data(self):
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

        data_out = []
        N = 10000
        for i in range(N):
            yield FallingEdge(dut.clk)
            data_out.append(dut.rf_out.value.signed_integer)

        self.data = np.array(data_out).astype(float)

    # Check methods
    def check_sin_results(self):
        params = self.params

        plt.plot(self.data)
        plt.show()
        self.show_fft(self.data, fs=params.FCLK)

        # self.save_fft_data(
        #     norm_data_in, 'input_fft_data',
        #     params.name, params.FS_IN, is_complex=True
        # )
        # self.save_data(
        #     norm_data_in[:100], 'input_data',
        #     params.name, params.FS_IN
        # )

        # self.save_fft_data(
        #     norm_data_out, 'output_fft_data',
        #     params.name, params.FS_OUT, is_complex=True
        # )
        # self.save_data(
        #     norm_data_out[:100], 'output_data',
        #     params.name, params.FS_OUT
        # )

        self.check_sin(norm_data_out.real, params.FC_OUT, 200e3, params.FS_OUT, snr=35)
