#!/usr/bin/env python3

import re
import site
import subprocess
import sys
import traceback
from argparse import Namespace, ArgumentParser
from pathlib import Path

file_path = Path(__file__)
test_dir_path = file_path.parent

def clean_sim_cache():
    cache_path = test_dir_path / 'sim_build'
    if cache_path.exists():
        subprocess.check_output(
            f'rm -r {cache_path}',
            shell=True,
        )


def list_modules(src_dir: Path, **kwargs):
    """List the modules availables to be tested (in verilog)"""
    _re = re.compile(r'.*:\s*module\s+(?P<module>\w*)')
    result = subprocess.check_output(
        f'grep -r "module " {src_dir}',
        shell=True,
    ).decode("utf-8")

    modules = sorted([
        _re.match(line).groupdict()['module']
        for line in result.splitlines()
            if _re.match(line) is not None
    ])

    print('List of modules:')
    [print('\t' + m) for m in modules]


def list_available_tests(verbose=False, **kwargs):
    """List the availables tests for the verilog modules"""
    _re = re.compile(r'test_(?P<module>\w*)\.py')
    tests_path = test_dir_path / 'test_modules'

    tests = []
    for path in tests_path.glob('*'):
        _match = _re.match(path.name)
        if _match is not None:
            tests.append(_match.groupdict()['module'])

    if verbose:
        print('Available tests:')
        for test in tests:
            print('\t' + test)

    return tests


def grep_failure(result_str: str):
    _re = re.compile(f'.*(?P<msg>Test Failed.*)')
    matches = [_re.match(line) for line in result_str.splitlines()]

    failures = []
    for match in matches:
        if match is not None:
            failures.append(match.groupdict()['msg'])

    return '\n'.join(failures)


def run_test_module(name:str, src_dir: Path):
    site_pkg = site.getsitepackages()[0]
    cmd =  re.sub(' +', ' ', re.sub('\n', ' ', f"""
        COCOTB_SHARE_DIR={site_pkg}/cocotb/share
        TOPLEVEL_LANG=verilog
        TOPLEVEL={name}
        MODULE=test_modules.test_{name}
        SIM=icarus
        make -C {test_dir_path.absolute()}
    """))

    return subprocess.check_output(
        cmd,
        shell=True,
    ).decode('utf-8')


def test_all(src_dir: Path, **kwargs):
    """ Test all HDL modules """
    modules = list_available_tests()

    failures = []
    for module in modules:
        result = test_module(module, src_dir, verbose=True)
        if result == 1:
            failures.append(module)

    if failures != []:
        print(f'\nFailed!')
        for failure in failures:
            print(f'Tests Failed from test_{failure} file')
        return 1

    return 0


def test_module(name: str, src_dir: Path, verbose=True, **kwargs):
    """ Test an HDL module from src """
    clean_sim_cache()
    result = run_test_module(name, src_dir)

    failures = grep_failure(result)
    if verbose:
        if failures == "":
            print('Tests has run successfully')
        else:
            print(f'Entire process:{result}')
            print(f'\nFailed!\n{failures}')

    if failures == "":
        return 0
    else:
        return 1


def add_global_args(parser: ArgumentParser):
    parser.add_argument(
        '-d', '--source-dir',
        dest='src_dir',
        type=lambda p: Path(p),
        default=test_dir_path.parent.absolute() / "src",
        help="Source directory where all verilog files reside",
    )


def parse_arguments() -> ArgumentParser:
    """ Builds the parser and parses the command-line args"""

    parser = ArgumentParser("python3 test.py")
    add_global_args(parser)
    subs = parser.add_subparsers(title="command")
    test_module_cmd = subs.add_parser(
        "module",
        help=test_module.__doc__
    )
    test_module_cmd.set_defaults(command=test_module)
    test_module_cmd.add_argument(
        "name",
        help="HDL module name to be tested",
    )
    add_global_args(test_module_cmd)

    test_all_cmd = subs.add_parser(
        "all",
        help=test_all.__doc__,
    )
    test_all_cmd.set_defaults(command=test_all)
    add_global_args(test_all_cmd)

    list_modules_cmd = subs.add_parser(
        "list-modules",
        help=list_modules.__doc__,
    )
    list_modules_cmd.set_defaults(command=list_modules)

    list_tests_cmd = subs.add_parser(
        "list-tests",
        help=list_available_tests.__doc__,
    )
    list_tests_cmd.set_defaults(
        command=list_available_tests,
        verbose=True,
    )

    return parser


def main():
    parser = parse_arguments()
    args = parser.parse_args()
    if 'command' in args:
        result = args.command(**vars(args))
        if isinstance(result, int):
            sys.exit(result)
    else:
        sys.stderr.write('Error: please, inform what command you want to run\n.\n')
        parser.print_help()
        sys.exit(2)


if __name__ == "__main__":
    main()