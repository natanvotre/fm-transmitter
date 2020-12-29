import os
import numpy as np
from numpy import array
import random
import json
import matplotlib.pyplot as plt
from pathlib import Path

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
    print(f'[Test Cic Interpolator] {msg}')


def set_data(data:int):
    return BinaryValue(
        value=data,
        n_bits=int(os.environ["WIDTH"]),
        bigEndian=False,
        binaryRepresentation=BinaryRepresentation.TWOS_COMPLEMENT,
    )


def set_uns_data(data:int):
    return BinaryValue(
        value=data,
        bigEndian=False,
        binaryRepresentation=BinaryRepresentation.UNSIGNED,
    )


def interpolate(data: np.ndarray, rate: int):
    len_data = len(data)
    fft = np.fft.fft(data)
    half_len = int(len_data/2)

    interp_len = rate*len_data
    interp_fft = np.zeros((interp_len,))
    interp_fft[:half_len] = fft[:half_len]
    interp_fft[interp_len-half_len:] = fft[half_len:]
    interp_fft = interp_fft*rate

    return np.fft.ifft(interp_fft).real


def calc_fft(data):
    return 20*np.log10(np.abs(np.fft.fft(data)))[:int(len(data)/2)]

@cocotb.test()
async def _test_cic_interpolator(dut: HierarchyObject):
    """
        Test Cic Interpolator using an input signal and seeing if the
        output approaches the input signal interpolated
    """
    data = json.loads(os.environ["data"])
    rate = int(os.environ["rate"])
    width = int(os.environ["WIDTH"])

    log_test(f'width: {width}')
    log_test(f'rate: {rate}')
    assert width == len(dut.data_in.value.binstr)
    assert width == len(dut.data_out.value.binstr)

    # Create a 10us period clock on port clk
    clock = Clock(dut.clk, 10, units="us")
    cocotb.fork(clock.start())

    dut.rst = 1
    dut.enable = 0
    dut.stb_in = 0
    dut.stb_out = 0
    dut.rate = set_uns_data(0)
    dut.data_in = set_data(0)
    await Timer(100, units="us")
    dut.rst = 0
    dut.enable = 1
    dut.rate = set_uns_data(rate)
    await Timer(10, units="us")
    log_test(f'rate 2: {dut.rate.value.signed_integer}')
    assert rate == dut.rate.value.integer

    out_clk_rate = 2
    in_clk_rate = out_clk_rate*rate
    data_count = 0
    data_out = []
    data_in = []
    for i in range((len(data)+10)*rate*out_clk_rate):
        await FallingEdge(dut.clk)
        dut.stb_in = i % in_clk_rate == 0
        dut.stb_out = i % out_clk_rate == 0

        if dut.stb_out == 1:
            data_out.append(dut.data_out.value.signed_integer)

        if dut.stb_in == 1:
            if data_count < len(data):
                dut.data_in.value = set_data(data[data_count])
            else:
                dut.data_in = set_data(0)
            data_count += 1
            data_in.append(dut.data_in.value.signed_integer)


    offset = rate*8+10
    data_in = np.array(data_in[:len(data)])
    data_out = np.array(data_out[offset:rate*len(data)+offset])
    expected_data_out = interpolate(data_in, rate)

    fft_out = calc_fft(data_out)
    expected_fft_out = calc_fft(expected_data_out)

    plt.plot(data_out)
    plt.plot(expected_data_out)
    plt.show()

    plt.plot(fft_out)
    plt.plot(expected_fft_out)
    plt.plot(expected_fft_out)
    plt.show()
    # plt.savefig(str(results_path / 'cic_test_fft.png'))

    argmax = fft_out.argmax()
    log_test(f'argmax 1: {argmax}')
    log_test(f'argmax 2: {expected_fft_out.argmax()}')
    assert abs(argmax - expected_fft_out.argmax()) < 2

    max(fft_out)

    results_path = Path('results')
    results_path.mkdir(exist_ok=True)

    plt.plot(data_out)
    plt.plot(expected_data_out)
    plt.plot(data_in)
    plt.savefig(str(results_path / 'cic_test_wave.png'))

    plt.plot(fft_out)
    plt.plot(expected_fft_out)
    plt.savefig(str(results_path / 'cic_test_fft.png'))

def generate_sin(size, fc, width, fs=8e3):
    n = np.linspace(0, size-1, size)
    t = n/fs
    data_norm = np.sin(2*np.pi*fc*t)
    return (data_norm*(2**(width-1)-1)).astype(int).tolist()


def generate_values(size=100):
    widths = [16, 10, 32]
    sizes = [500, 250, 100]
    rates = [2, 10, 30]
    fcs = [1e3, 500, 3e3]
    sins = [
        generate_sin(*params)
        for params in zip(sizes, fcs, widths)
    ]

    return [
        values for values in zip(sins, widths, rates)
    ]


class TestCicInterpolator(BaseTest):

    @pytest.mark.parametrize("data, width, rate", generate_values(size=1000))
    def test_cic_interpolator(self, data, width, rate):
        parameters = {
            "WIDTH": width,
        }
        values = {
            "rate": rate,
            "data": data,
        }
        self.run_simulator('cic_interpolator', parameters=parameters, values=values)
