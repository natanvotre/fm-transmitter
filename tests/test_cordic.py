import json
from _pytest.mark import param
import matplotlib.pyplot as plt
import numpy as np
import os
import random
from dataclasses import dataclass
from numpy import array, ndarray
from pathlib import Path
from typing import List, Tuple
from numpy.core.function_base import linspace

import pytest
import cocotb
from cocotb.binary import BinaryValue, BinaryRepresentation
from cocotb.clock import Clock
from cocotb.handle import ModifiableObject, HierarchyObject
from cocotb.triggers import FallingEdge, NextTimeStep, Event, Timer

from tests.utils import BaseSignalTest, results_dir


@cocotb.test(skip = False)
def init(dut: HierarchyObject):
    """
        Test Cic Interpolator changing the input signal, rate and width
        and retrieving the output signal.

        - Test with sins and checking the SNR and output sin shape.
        - Test the cic impulsive response and save the results
    """
    test = TestCordic()
    params = TestingParameters()
    yield test.cocotb_test_cordic(
        dut,
        params,
    )
    if params.test_type == "random":
        if params.M == 1 and params.MODE == 0:
            test.check_circular_rotation()
        elif params.M == 1 and params.MODE == 1:
            test.check_circular_vectoring()
        else:
            raise NotImplementedError()


@dataclass
class Cordic:
    """
        Dataclass to make easier to address the dut fields
    """
    clk: ModifiableObject
    rst: ModifiableObject

    xi: ModifiableObject
    yi: ModifiableObject
    zi: ModifiableObject
    stb_in: ModifiableObject

    xo: ModifiableObject
    yo: ModifiableObject
    zo: ModifiableObject
    stb_out: ModifiableObject


@dataclass
class TestingParameters:
    WIDTH: int
    ZWIDTH: int
    PIPE: int
    M: int
    MODE: str

    test_type: str
    name: str

    data_i: ndarray
    data_q: ndarray
    rotation: ndarray

    def __init__(self):
        self.WIDTH = int(os.environ["WIDTH"])
        self.ZWIDTH = int(os.environ["ZWIDTH"])
        self.PIPE = int(os.environ["PIPE"])
        self.M = int(os.environ["M"])
        self.MODE = int(os.environ["MODE"])

        self.test_type = os.environ["type"]
        self.name = os.environ["name"]

        self.data_i = np.array(json.loads(os.environ["data_i"]))
        self.data_q = np.array(json.loads(os.environ["data_q"]))
        self.rotation = np.array(json.loads(os.environ["rotation"]))


def gen_random_vectors(size, abs_range=(0.1, 1)):
    abs_min, abs_max = abs_range

    rand_abs_data = np.random.random(size)*(abs_max - abs_min) + abs_min
    rand_rotations = np.random.random(size)*2*np.pi

    return rand_abs_data*np.exp(1j*rand_rotations)


def gen_random_rotations(size, range=(0, 2*np.pi)):
    range_min, range_max = range
    return np.random.random(size)*(range_max - range_min) + range_min


def generate_random_args():
    size = 100
    widths = [15, 16]
    zwidths = [18, 16]
    pipes = [17, 18]
    ms = [1, 1] # circular
    modes = [0, 1]
    data = [
        gen_random_vectors(size, (0.1, 1)),
        gen_random_vectors(size, (0.3, 1)),
    ]
    rotations = [
        gen_random_rotations(size),
        np.zeros(100),
    ]
    names = [
        f"test_randoms_M{m}_{mode}_w{w}_zw{zw}_pipe{p}"
        for m, mode, w, zw, p in zip(ms, modes, widths, zwidths, pipes)
    ]

    return [
        values for values in zip(
            widths, zwidths, pipes, ms, modes, data, rotations, names
        )
    ]


class TestCordic(BaseSignalTest):
    dut: Cordic = None
    params: TestingParameters = None
    data_in: ndarray = None
    data_out: ndarray = None
    z_in: ndarray = None
    z_out: ndarray = None

    # Pytests
    @pytest.mark.parametrize("width, zwidth, pipe, m, mode, data, rot, name", generate_random_args())
    def test_cordic_randomly(self, width, zwidth, pipe, m, mode, data, rot, name):
        parameters = {
            "WIDTH": width,
            "ZWIDTH": zwidth,
            "PIPE": pipe,
            "M": m,
            "MODE": mode,
        }
        values = {
            "data_i": data.real.tolist(),
            "data_q": data.imag.tolist(),
            "rotation": rot.tolist(),
            "type": "random",
            "name": name,
        }
        self.run_simulator(parameters=parameters, values=values)

    # Cocotb coroutines
    @cocotb.coroutine
    def cocotb_test_cordic(
        self,
        dut: Cordic,
        params: TestingParameters,
    ):
        self.data_length = params.WIDTH

        self.dut = dut
        self.params = params

        self.log(f'width: {params.WIDTH}')
        self.log(f'zwidth: {params.WIDTH}')
        self.log(f'pipe: {params.PIPE}')
        # Check widths
        assert params.WIDTH == len(dut.xi.value.binstr)
        assert params.WIDTH == len(dut.yi.value.binstr)
        assert params.WIDTH == len(dut.xo.value.binstr)
        assert params.WIDTH == len(dut.yo.value.binstr)
        assert params.ZWIDTH == len(dut.zi.value.binstr)
        assert params.ZWIDTH == len(dut.zo.value.binstr)

        # Create a 10us period clock
        clock = Clock(dut.clk, 10, units="us")
        cocotb.fork(clock.start())

        yield self.initialize_module()
        yield self.check_pipe()
        yield self.send_data()

    @cocotb.coroutine
    def initialize_module(self):
        """
            - Reset Cordic
            - Enable to be ready to start
        """
        dut = self.dut
        params = self.params

        # Reset module
        dut.rst = 1
        dut.stb_in = 0
        dut.xi = self.set_data(0)
        dut.yi = self.set_data(0)
        dut.zi = self.set_uns_data(0, params.ZWIDTH)
        # Wait 5 clock cycles
        for _ in range(5):
            yield FallingEdge(dut.clk)
        # Enable module
        dut.rst = 0
        yield FallingEdge(dut.clk)

        # Check rst
        assert dut.rst == 0

    @cocotb.coroutine
    def check_pipe(self):
        dut = self.dut
        params = self.params

        dut.stb_in = 1
        for i in range(params.PIPE+2):
            yield FallingEdge(dut.clk)
            dut.stb_in = 0
            if i == params.PIPE-1:
                assert dut.stb_out == 1
            else:
                assert dut.stb_out == 0

    @cocotb.coroutine
    def send_data(self, in_clk_rate=2):
        """
            Actions:
            - Send (drive) the data from input flow
            - Monitor the output flow
            - Return the results from input and output in ndarrays as
              self.data_in and self.data_out

            Args:
            - in_clk_rate: rate between clock frequency and stb_in
              frequency. The greater this variable is the slower the
              simulation.
        """
        dut = self.dut
        params = self.params

        input_index = 0
        data_out = []
        data_in = []
        z_in = []
        z_out = []
        len_data = len(params.data_i)

        data_i: List[int] = self.quantizer(params.data_i, params.WIDTH).tolist()
        data_q: List[int] = self.quantizer(params.data_q, params.WIDTH).tolist()
        rotation: List[int] = self.quantizer(
            np.array(params.rotation)/(2*np.pi),
            params.ZWIDTH,
            uns=True
        ).tolist()
        for i in range((len_data+params.PIPE+1)*in_clk_rate):
            yield FallingEdge(dut.clk)
            send_in = i % in_clk_rate == 0
            dut.stb_in = send_in
            if send_in:
                if input_index < len_data:
                    dut.xi = self.set_data(data_i[input_index])
                    dut.yi = self.set_data(data_q[input_index])
                    dut.zi = self.set_uns_data(rotation[input_index])
                else:
                    dut.xi = self.set_data(0)
                    dut.yi = self.set_data(0)
                    dut.zi = self.set_uns_data(0)
                input_index += 1

            if dut.stb_in == 1:
                data_in.append(
                    dut.xi.value.signed_integer +
                    1j*dut.yi.value.signed_integer
                )
                z_in.append(
                    dut.zi.value.integer
                )

            if dut.stb_out == 1:
                data_out.append(
                    dut.xo.value.signed_integer +
                    1j*dut.yo.value.signed_integer
                )
                z_out.append(dut.zo.value.signed_integer)

        self.data_in = np.array(data_in[:len_data])
        self.data_out = np.array(data_out[:len_data])
        self.z_in = np.array(z_in[:len_data])
        self.z_out = np.array(z_out[:len_data])

    # Check methods
    def check_circular_rotation(self, max_error=5, norm_max_error=1e-3):
        params = self.params
        K = 1.6467605

        max_value = 2**(params.WIDTH-1)
        max_out_value = max_value*K/2
        max_zvalue = 2**params.ZWIDTH

        expected_data_in_norm = params.data_i + 1j*params.data_q
        expected_data_out_norm = expected_data_in_norm*np.exp(1j*params.rotation)

        expected_data_in = expected_data_in_norm*max_value
        expected_data_out = expected_data_out_norm*max_out_value

        data_out_diff = expected_data_out - self.data_out
        data_out_diff_norm = expected_data_out_norm - self.data_out/max_out_value

        self.log(f'data_in: {self.data_in}')
        self.log(f'expected_data_in: {expected_data_in}')
        self.log(f'data_in_norm: {self.data_in/max_value}')
        self.log(f'expected_data_in_norm: {expected_data_in_norm}')
        self.log(f'rotation_sent: {self.z_in*2*np.pi/max_zvalue}')
        self.log(f'rotation: {params.rotation}')
        self.log(f'data_out: {self.data_out}')
        self.log(f'expected_data_out: {expected_data_out}')

        assert max(np.abs(data_out_diff.real)) < max_error
        assert max(np.abs(data_out_diff.imag)) < max_error

        assert max(np.abs(data_out_diff_norm.real)) < norm_max_error
        assert max(np.abs(data_out_diff_norm.imag)) < norm_max_error

    def check_circular_vectoring(self, max_error=5, norm_max_error=1e-3):
        params = self.params
        K = 1.6467605

        max_value = 2**(params.WIDTH-1)
        max_zvalue = 2**params.ZWIDTH
        max_out_value = max_value*K/2

        expected_data_in_norm = params.data_i + 1j*params.data_q
        expected_z_in_norm = params.rotation

        # Expects x + jy = norm_2{x_0, y_0} and
        # z = z_0 + tan^{-1}(y/x)
        expected_data_out_norm = np.abs(expected_data_in_norm)
        expected_z_out_norm = params.rotation + np.arctan(
            expected_data_in_norm.imag / expected_data_in_norm.real
        )

        expected_data_in = expected_data_in_norm*max_value
        expected_data_out = expected_data_out_norm*max_out_value
        expected_z_in = expected_z_in_norm*max_zvalue
        expected_z_out = expected_z_out_norm*max_zvalue/(2*np.pi)

        data_out_diff = expected_data_out - self.data_out
        data_out_diff_norm = expected_data_out_norm - self.data_out/max_out_value
        z_out_diff = expected_z_out - self.z_out
        z_out_diff_norm = expected_z_out_norm - self.z_out/max_zvalue*(2*np.pi)

        self.log(f'expected_data_in_norm: {expected_data_in_norm}')
        self.log(f'data_in_norm: {self.data_in/max_value}')
        self.log(f'expected_data_out_norm: {expected_data_out_norm}')
        self.log(f'data_out_norm: {self.data_out/max_out_value}')
        self.log(f'expected_z_in_norm: {expected_z_in_norm}')
        self.log(f'z_in_norm: {self.z_in/max_zvalue}')
        self.log(f'expected_z_out_norm: {expected_z_out_norm}')
        self.log(f'z_out_norm: {self.z_out/max_zvalue}')
        self.log(f'expected_data_in: {expected_data_in}')
        self.log(f'data_in: {self.data_in}')
        self.log(f'expected_data_out: {expected_data_out}')
        self.log(f'data_out: {self.data_out}')
        self.log(f'expected_z_in: {expected_z_in}')
        self.log(f'z_in: {self.z_in}')
        self.log(f'expected_z_out: {expected_z_out}')
        self.log(f'z_out: {self.z_out}')

        self.log(f'data_out_diff: {data_out_diff}')
        self.log(f'z_out_diff: {z_out_diff}')
        self.log(f'data_out_diff_norm: {data_out_diff_norm}')
        self.log(f'z_out_diff_norm: {z_out_diff_norm}')

        assert max(np.abs(data_out_diff)) < max_error
        assert max(np.abs(z_out_diff)) < max_error
        assert max(np.abs(data_out_diff_norm)) < norm_max_error
        assert max(np.abs(z_out_diff_norm)) < norm_max_error
