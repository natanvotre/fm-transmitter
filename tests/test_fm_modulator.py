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

from tests.utils import BaseSignalTest


@cocotb.test(skip = False)
def init(dut: HierarchyObject):
    """
        Test Fm Interpolator changing the input signal, rate and width
        and retrieving the output signal.

        - Test with sins and checking the SNR and output sin shape.
        - Test the fm impulsive response and save the results
    """
    test = TestFmModulator()
    params = TestingParameters()
    yield test.cocotb_test_fm_modulator(
        dut,
        params,
    )
    test.check_sin_results()


@dataclass
class FmModulator:
    """
        Dataclass to make easier to address the dut fields
    """
    clk: ModifiableObject
    rst: ModifiableObject

    data_in: ModifiableObject
    stb_in: ModifiableObject

    data_out_i: ModifiableObject
    data_out_q: ModifiableObject
    stb_out: ModifiableObject


@dataclass
class TestingParameters:
    WIDTH: int
    FCLK: int
    FS_IN: int
    FS_OUT: int
    FC_OUT: int
    K: int
    IEXT: int

    data: ndarray
    fc: float
    name: str
    rate: int
    def __init__(self):
        self.WIDTH = int(os.environ["WIDTH"])
        self.FCLK = int(float(os.environ["FCLK"]))
        self.FS_IN = int(float(os.environ["FS_IN"]))
        self.FS_OUT = int(float(os.environ["FS_OUT"]))
        self.FC_OUT = int(float(os.environ["FC_OUT"]))
        self.K = int(float(os.environ["K"]))
        self.IEXT = int(os.environ["IEXT"])
        self.data = np.array(json.loads(os.environ["data"]))
        self.fc = float(os.environ["fc"])
        self.name = os.environ["name"]
        self.rate = int(os.environ["rate"])


def generate_values():
    widths = [16]
    sizes = [100]
    sin_fcs = [4e3]
    fs = [48e3]
    rates = [100]
    k = [100e3]
    fcs = [0.5e6]
    fclk = [48e3*2*100]
    iexts = [10]
    data = [
        BaseSignalTest().generate_norm_sin(s,f,fs)
        for s, f, fs in zip(sizes, sin_fcs, fs)
    ]
    names = [
        f'test_sin_{f/1e3:.2f}kHz_{s}S_{r}R_{w}b'
        for w, s, r, f in zip(widths, sizes, rates, fcs)
    ]

    return [
        values for values in zip(
            data, widths, sin_fcs,
            fs, rates,
            k, fcs, fclk,
            iexts,
            names,
        )
    ]


class TestFmModulator(BaseSignalTest):
    dut: FmModulator = None
    params: TestingParameters = None
    data_in: ndarray = None
    data_out: ndarray = None

    # Pytests
    @pytest.mark.parametrize(
        "data, width, sin_fc, fs, rate, k, fc, fclk, iext, name",
        generate_values()
    )
    def test_fm_modulator_with_sins(self, data, width, sin_fc,
        fs, rate, k, fc, fclk, iext, name):

        parameters = {
            "WIDTH": width,
            "FCLK": fclk,
            "FS_IN": fs,
            "FS_OUT": rate*fs,
            "FC_OUT": fc,
            "K": k,
            "IEXT": iext,
            "WIDTH": width,
        }
        values = {
            "data": data.tolist(),
            "fc": sin_fc,
            "name": name,
            "rate": rate,
        }
        self.run_simulator(parameters=parameters, values=values)

    # Cocotb coroutines
    @cocotb.coroutine
    def cocotb_test_fm_modulator(
        self,
        dut: FmModulator,
        params: TestingParameters,
    ):
        self.data_length = params.WIDTH

        self.dut = dut
        self.params = params

        self.log(f'fc_out: {params.FC_OUT}')
        self.log(f'fs_in: {params.FS_IN}')
        self.log(f'fs_out: {params.FS_OUT}')
        self.log(f'width: {params.WIDTH}')
        self.log(f'rate: {params.rate}')
        # Check widths
        assert params.WIDTH == len(dut.data_in.value.binstr)
        assert params.WIDTH == len(dut.data_out_i.value.binstr)
        assert params.WIDTH == len(dut.data_out_q.value.binstr)

        # Create the period clock
        clk_period = int(1/params.FCLK*1e9)
        clock = Clock(dut.clk, clk_period, units="ns")
        cocotb.fork(clock.start())


        yield self.initialize_module()
        yield self.send_data()

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
        dut.data_in = self.set_data(0)
        # Wait 5 clock cycles
        for _ in range(5):
            yield FallingEdge(dut.clk)
        # Enable module and set the rate
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

        out_clk_rate = int(params.FCLK/params.FS_OUT)
        in_clk_rate = out_clk_rate*params.rate
        input_index = 0
        data_out_i = []
        data_out_q = []
        data_in = []
        data = self.quantizer(params.data, params.WIDTH).tolist()
        len_data = len(data)
        for i in range((len_data+end_zeros)*params.rate*out_clk_rate):
            yield FallingEdge(dut.clk)
            dut.stb_in = i % in_clk_rate == 0

            if dut.stb_out == 1:
                data_out_i.append(dut.data_out_i.value.signed_integer)
                data_out_q.append(dut.data_out_q.value.signed_integer)

            if dut.stb_in == 1:
                if input_index < len_data:
                    dut.data_in.value = self.set_data(data[input_index])
                else:
                    dut.data_in = self.set_data(0)
                input_index += 1
                data_in.append(dut.data_in.value.signed_integer)

        self.data_in = np.array(data_in[:len_data])
        self.data_out_i = np.array(data_out_i[offset:params.rate*len_data+offset])
        self.data_out_q = np.array(data_out_q[offset:params.rate*len_data+offset])
        self.data_out = np.array(self.data_out_i) + 1j*self.data_out_q

    # Check methods
    def check_sin_results(self):
        params = self.params

        max_value:int = 2**(params.WIDTH-1)
        norm_data_in = self.data_in/max_value
        data_int = self.interpolate(self.data_in/max_value, params.rate)
        norm_data_out = self.data_out/max_value

        # self.log(f'data_out: {self.data_out}')
        # plt.plot(data_int)
        # plt.plot(norm_data_out.real)
        # plt.plot(norm_data_out.imag)
        # plt.show()

        demod_signal = self.demodulate(norm_data_out)
        plt.plot(demod_signal)
        plt.show()

        self.show_fft(demod_signal, fs=params.FS_OUT, N=10000)
        assert False

        # expected_data_out = self.interpolate(self.data_in, params.rate)
        # norm_expected_data_out = expected_data_out/max_value

        # fft_out = self.calc_fft(norm_data_out)
        # expected_fft_out = self.calc_fft(norm_expected_data_out)

        # self.save_data(params.data, f'data_in', params.name, fs=params.fs)
        # self.save_data(norm_data_out, f'data_out', params.name, fs=params.fs*params.rate)
        # self.save_data(fft_out, f'fft_out', params.name, fs=params.fs)
        # self.save_plot(norm_expected_data_out, 'expected_data_out.png', params.name)
        # self.save_plot(expected_fft_out, 'expected_fft_out.png', params.name)

        # self.check_sin(
        #     norm_data_out,
        #     params.fc,
        #     fs=params.fs*params.rate,
        #     fc_band=300,
        # )

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

    def decimate(self, data: np.ndarray, rate: int):
        len_data = len(data)
        fft = np.fft.fft(data)

        decim_len = int(len_data/rate)
        half_len = int(decim_len/2)

        interp_fft = np.zeros((decim_len,))
        interp_fft[:half_len] = fft.real[:half_len] + 1j*fft.imag[:half_len]
        interp_fft[half_len:] = fft[len_data-half_len:] + 1j*fft.imag[len_data-half_len:]
        interp_fft = interp_fft/rate

        return np.fft.ifft(interp_fft)

    def demodulate(self, data: ndarray):
        params = self.params

        len_data = len(self.data_out)
        n = np.linspace(0,len_data-1,len_data)

        fc_base = params.FC_OUT
        # rate_div =
        based_signal = data*np.exp(-1j*2*np.pi*fc_base/params.FS_OUT*n)
        self.show_fft(based_signal, params.FS_OUT, is_complex=True)
        decim_signal = self.decimate(based_signal, params.rate/10)
        len_data_dec = len(decim_signal)
        self.show_fft(decim_signal, params.FS_OUT/(params.rate/10), is_complex=True)

        message_integrated = np.arctan(decim_signal.imag/decim_signal.real)
        plt.plot(message_integrated)
        plt.show()
        demod_signal = np.zeros(len_data_dec)
        for i in range(len_data_dec-1):
            demod_signal[i+1] = message_integrated[i+1]-message_integrated[i]
            if abs(demod_signal[i+1]) > np.pi/2:
                demod_signal[i+1] -= np.sign(demod_signal[i+1])*np.pi
        plt.plot(demod_signal)
        plt.show()
        demod_signal_dec = self.decimate(demod_signal, 10)

        return demod_signal_dec
