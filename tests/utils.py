import os
import subprocess
import matplotlib.pyplot as plt
import numpy as np
from numpy import ndarray
from pathlib import Path
from scipy.io import wavfile
from stringcase import titlecase, snakecase

from cocotb.binary import BinaryValue, BinaryRepresentation
from cocotb_test import simulator
test_dir = Path(__file__).parent
src_dir = test_dir.parent / 'src'
results_dir = test_dir / 'results'

class BaseTest:
    _module_name = None
    _title_name = None

    def setup(self):
        self.clean_sim_cache()

    @property
    def module_name(self):
        if self._module_name is None:
            pascal_name = self.__class__.__name__.split('Test')[1]
            self._module_name = snakecase(pascal_name)
        return self._module_name

    @property
    def title_name(self):
        if self._title_name is None:
            self._title_name = titlecase(self.__class__.__name__)
        return self._title_name

    @property
    def folder_dir(self) -> Path:
        # Create folder if does not exist
        results_dir.mkdir(exist_ok=True)
        folder_dir = results_dir / self.module_name
        folder_dir.mkdir(exist_ok=True)
        return folder_dir

    def log(self, msg):
        print(f'[{self.title_name}] {msg}')

    def clean_sim_cache(self):
        cache_path = test_dir / 'sim_build'
        if cache_path.exists():
            subprocess.check_output(
                f'rm -r {cache_path}',
                shell=True,
            )

    def list_verilog_files(self):
        return [str(p.absolute()) for p in src_dir.glob('**/*.v')]

    def transform_params(self, parameters):
        str_params = {}
        if parameters is not None:
            for key, value in parameters.items():
                str_params[key] = str(value)

        return str_params

    def run_simulator(self, name=None, parameters=None, module=None, values=None):
        if name is None:
            name = self.module_name
        if module is None:
            module = f'tests.test_{name}'

        parameters = self.transform_params(parameters)
        values = self.transform_params(values)

        os.environ['SIM'] = 'icarus'
        print(f'Testing {name} with parameters: {parameters}')
        print(f'Testing {name} with values: {values}')
        extra_env = {}
        if parameters is not None:
            for key, value in parameters.items():
                extra_env[key] = value
        if values is not None:
            for key, value in values.items():
                extra_env[key] = value

        return simulator.run(
            verilog_sources=self.list_verilog_files(),
            toplevel=name,
            module=module,
            parameters=parameters,
            extra_env=extra_env,
            sim_build="sim_build/"
                + "_".join(("{}={}".format(*i) for i in parameters.items())),
        )

class BaseSignalTest(BaseTest):
    data_length = 16

    def set_data(
        self,
        data:int,
        data_length=None,
        representation=BinaryRepresentation.TWOS_COMPLEMENT,
    ):
        if data_length is not None:
            self.data_length = data_length

        return BinaryValue(
            value=data,
            n_bits=self.data_length,
            bigEndian=False,
            binaryRepresentation=representation,
        )

    def set_uns_data(self, data:int, data_length=None):
        return self.set_data(
            data=data,
            data_length=data_length,
            representation=BinaryRepresentation.UNSIGNED,
        )

    def quantizer(self, data, width, uns=False) -> ndarray:
        if uns:
            d_min = 0
            d_max = 2**width - 1
            gain = 2**width
        else:
            d_min = -2**(width-1)
            d_max = 2**(width-1)-1
            gain = 2**(width-1)
        return np.clip(np.array(data)*gain, d_min, d_max).astype(int)

    def generate_norm_sin(self, size, fc, fs=8e3):
        n = np.linspace(0, size-1, size)
        t = n/fs
        return np.sin(2*np.pi*fc*t)

    def generate_sin(self, size, fc, width, fs=8e3):
        data_norm = self.generate_norm_sin(size, fc, fs)
        return (data_norm*(2**(width-1)-1)).astype(int).tolist()

    def calc_fft(self, data: ndarray):
        len_data = len(data)
        self.log(f'data shape: {data.shape}')
        windowed_data = data * np.hanning(len_data)
        return 20*np.log10(
            np.abs(
                np.fft.fft(windowed_data)
            )[:int(len_data/2)] / len_data
        )

    def save_plot(self, data, name, test_name):
        test_dir: Path = self.folder_dir / test_name
        test_dir.mkdir(exist_ok=True)
        output_file = test_dir / name
        plt.clf()
        plt.plot(data)
        plt.savefig(output_file)

    def save_wav_data(self, data, name, test_name, fs=8000):
        test_dir: Path = self.folder_dir / test_name
        test_dir.mkdir(exist_ok=True)
        output_file = test_dir / name
        wavfile.write(str(output_file), int(fs), data)

    def save_data(self, data, name, test_name, fs=8000):
        self.save_wav_data(data, f'{name}.wav', test_name, fs)
        self.save_plot(data, f'{name}.png', test_name)

    def check_sin(self, data: ndarray, fc: float, fc_band=200, fs=8e3, snr=30):
        len_data = len(data)
        len_fft = int(len(data)/2)

        windowed_data = data * np.hanning(len_data)
        fft_data: ndarray = np.abs(np.fft.fft(windowed_data))[:len_fft]
        half_fs = fs/2

        fc_bin = fc*len_fft/half_fs
        half_bw_bin = fc_band*len_fft/(2*half_fs)
        bw_low_bin = int(np.floor(fc_bin-half_bw_bin))
        bw_high_bin = int(np.ceil(fc_bin+half_bw_bin))
        self.log(f'fc BW bins: {(bw_low_bin, bw_high_bin)}')
        self.log(f'fc bin: {fc_bin}')

        # Check sin frequency is within the specified bounds
        max_bin = fft_data.argmax()
        self.log(f'max bin: {max_bin}')
        assert bw_low_bin <= max_bin and max_bin <= bw_high_bin

        # Check SNR
        sin_data = fft_data[bw_low_bin:bw_high_bin+1]
        noise_data = fft_data*1.0
        noise_data[bw_low_bin:bw_high_bin+1] = 0
        powered_sin = np.sum(np.power(sin_data, 2))
        powered_noise = np.sum(np.power(noise_data, 2))
        sin_snr = 10*np.log10(powered_sin/powered_noise)
        self.log(f'Power sin: {powered_sin}')
        self.log(f'Power noise: {powered_noise}')
        self.log(f'Perceived SNR: {sin_snr}')
        assert sin_snr > snr

    def check_signal_integrity(
        self,
        data_in,
        data_out,
        freq_band,
        fs,
        min_db,
        max_diff_db,
    ):
        len_data = len(data_in)
        min_bin, max_bin = (int(f/fs*len_data) for f in freq_band)

        fft_in = self.calc_fft(data_in)[min_bin:max_bin]
        fft_out = self.calc_fft(data_out)[min_bin:max_bin]

        clipped_in = np.clip(fft_in, min_db, 10)
        clipped_out = np.clip(fft_out, min_db, 10)

        diff_abs = np.abs(clipped_out - clipped_in)
        assert max(diff_abs) < max_diff_db
