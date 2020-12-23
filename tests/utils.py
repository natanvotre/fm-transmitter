import os
import subprocess
from pathlib import Path

from cocotb_test import simulator

test_dir = Path(__file__).parent
src_dir = test_dir.parent / 'src'

class BaseTest:
    def setup(self):
        self.clean_sim_cache()

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

    def run_simulator(self, name, parameters=None):
        parameters = self.transform_params(parameters)

        os.environ['SIM'] = 'icarus'
        print(f'Testing {name} with parameters: {parameters}')

        return simulator.run(
            verilog_sources=self.list_verilog_files(),
            toplevel=name,
            module=f'test_{name}',
            parameters=parameters,
            extra_env=parameters,
            sim_build="sim_build/"
                + "_".join(("{}={}".format(*i) for i in parameters.items())),
        )
