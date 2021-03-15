import json
from cocotb.binary import BinaryRepresentation
import matplotlib.pyplot as plt
import numpy as np
import os
from dataclasses import dataclass, field
from numpy import ndarray

import pytest
import cocotb
from cocotb.clock import Clock
from cocotb.handle import ModifiableObject, HierarchyObject
from cocotb.triggers import FallingEdge

from tests.utils import BaseSdrTest


@cocotb.test(skip=False)
def init(dut: HierarchyObject):
    """
        Test Fm Interpolator changing the input signal, rate and width
        and retrieving the output signal.

        - Test with sins and checking the SNR and output sin shape.
        - Test the fm impulsive response and save the results
    """
    test = TestLpdsmAdc()
    params = TestingParameters()
    yield test.cocotb_test_lpdsm_adc(
        dut,
        params,
    )


@dataclass
class LpdsmAdc:
    """
        Dataclass to make easier to address the dut fields
    """
    clk: ModifiableObject
    rst: ModifiableObject

    xi: ModifiableObject
    xo: ModifiableObject

    data_out: ModifiableObject
    stb_out: ModifiableObject


@dataclass
class TestingParameters:
    FCLK: int
    FS: int
    name: str
    R: float
    C: float
    RC: float

    xi_lvds_range: list
    xi_ref_voltage: float

    def __init__(self):
        self.FS = int(float(os.environ["FS"]))
        self.FCLK = int(float(os.environ["FCLK"]))
        self.FC = int(float(os.environ["FC"]))
        self.WIDTH = int(float(os.environ["WIDTH"]))
        self.name = os.environ["name"]
        self.R = float(os.environ["R"])
        self.C = float(os.environ["C"])
        self.RC = self.R * self.C
        self.xi_lvds_range = [-1, 1]
        self.xi_ref_voltage = self.xi_lvds_range[0]

    def xo_from_range(self, dut):
        if dut.xo.value == 1:
            return self.xi_lvds_range[1]
        else:
            return self.xi_lvds_range[0]


def generate_tests():
    fclks =     [50e6,50e6]#,50e6,50e6,   ]
    fs =        [50e3,50e3]#,50e3,50e3,   ]
    fcs =       [1e6,1e6]#,10e3,10e3,  ]
    widths =    [16  ,16  ]#,16  ,16  ,   ]
    Rs =        [1e3 ,1e4 ]#,1e1 ,1e0 ,   ]
    Cs =        [1e-9,1e-9]#,1e-9,1e-9,   ]
    names = [
        f'test_LPDSM_ADC_{fc:.0f}KHz_{rate/1e3:.0f}KHz_clk_{fclk/1e6:.0f}MHz_{r*c}_RC_{w}_bits'
        for fc, r, c, w, rate, fclk in zip(fcs, Rs, Cs, widths, fs, fclks)
    ]

    return [values for values in zip(
            widths, fs, fclks, fcs, Rs, Cs, names
    )]


class TestLpdsmAdc(BaseSdrTest):
    dut: LpdsmAdc = None
    params: TestingParameters = None
    data_in: ndarray = None
    data_out: ndarray = None

    # Pytests
    @pytest.mark.parametrize(
        "width, fs, fclk, fc, R, C, name",
        generate_tests()
    )
    def test_lpdsm_adc_with_sins(self, width, fs, fclk, fc, R, C, name):
        parameters = {
            "WIDTH": width,
            "FS": fs,
            "FCLK": fclk,
        }
        values = {
            "R": R,
            "C": C,
            "FC": fc,
            "name": name,
        }
        self.run_simulator(parameters=parameters, values=values)

    # Cocotb coroutines
    @cocotb.coroutine
    def cocotb_test_lpdsm_adc(
        self,
        dut: LpdsmAdc,
        params: TestingParameters,
    ):
        self.dut = dut
        self.params = params

        self.log(f'FCLK: {params.FCLK}')
        self.log(f'FS: {params.FS}')
        self.log(f'WIDTH: {params.WIDTH}')
        self.log(f'RC: {params.RC}')

        # Create the period clock
        clk_period = int(1/params.FCLK*1e9/2)*2
        clock = Clock(dut.clk, clk_period, units="ns")
        cocotb.fork(clock.start())

        yield self.initialize_module()
        yield self.run_sin()

    @cocotb.coroutine
    def initialize_module(self):
        """
            - Reset the Fm module
        """
        dut = self.dut
        params = self.params

        # Reset module
        dut.rst = 1
        dut.xi = 1

        # Wait 5 clock cycles
        for _ in range(5):
            yield FallingEdge(dut.clk)

        dut.rst = 0
        yield FallingEdge(dut.clk)

    @cocotb.coroutine
    def run_sample(self, sample):
        dut = self.dut
        params = self.params
        dut.xi = self.set_data(
            int(sample > params.xi_ref_voltage),
            data_length=1,
            representation=BinaryRepresentation.UNSIGNED,
        )
        t = 1/params.FCLK
        v0 = params.xi_ref_voltage
        vs = params.xo_from_range(dut)
        yield FallingEdge(dut.clk)
        # V(t) = Vs + (V_0 - Vs)*e^{-t/RC}
        params.xi_ref_voltage = vs + (v0 - vs)*np.exp(-t/params.RC)

    @cocotb.coroutine
    def run_sin(self):
        """
            Actions:

            Args:
        """
        dut = self.dut
        params = self.params

        data_out = []
        ref = []
        N = 50000
        clk_period = 1/params.FCLK
        for i in range(N):
            sample = np.sin(2*np.pi*clk_period*i*params.FC)
            yield self.run_sample(sample)
            if dut.stb_out == 1:
                data_out.append(dut.data_out.value.signed_integer)
                ref.append(params.xi_ref_voltage)

        data_out = np.array(data_out)
        plt.plot(ref)
        plt.show()
        self.show_fft(data_out)