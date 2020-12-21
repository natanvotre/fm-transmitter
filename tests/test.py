#!/usr/bin/env python3

import re
import site
import subprocess
import sys
import traceback
from argparse import Namespace, ArgumentParser
from pathlib import Path


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


def test_all(args):
    """ Test all HDL modules """
    pass

# make SIM=icarus
# MAKE_RESULT=$(echo $?)
# FAILURE_CASES=$(grep "failure" results.xml)

# if [ ! -z "$FAILURE_CASES" ] || [ $MAKE_RESULT -ne 0 ]
# then
#     echo "Failed!\n$FAILURE_CASES"
#     exit 1
# else
#     echo "Tests has ran successfully!"
#     exit 0
# fi


def test_module(name: str, src_dir: Path, **kwargs):
    """ Test an HDL module from src """
    site_pkg = site.getsitepackages()[0]
    cmd =  re.sub(' +', ' ', re.sub('\n', ' ', f"""
        COCOTB_SHARE_DIR={site_pkg}/cocotb/share
        TOPLEVEL_LANG=verilog
        VERILOG_SOURCES="$(find {src_dir} -name \\"*.v\\")"
        TOPLEVEL={name}
        MODULE=test_{name}
        SIM=icarus
        make -f $(cocotb-config --makefiles)/Makefile.sim
    """))
    print(cmd)
    result = subprocess.call(
        cmd,
        shell=True,
    )
    exit(result)


def add_global_args(parser: ArgumentParser):
    parser.add_argument(
        '-d', '--source-dir',
        dest='src_dir',
        type=lambda p: Path(p),
        default=Path(__file__).absolute().parent.parent / "src",
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

    return parser


def main():
    parser = parse_arguments()
    args = parser.parse_args()
    if 'command' in args:
        args.command(**vars(args))
    else:
        sys.stderr.write('Error: please, inform what command you want to run\n.\n')
        parser.print_help()
        sys.exit(2)


if __name__ == "__main__":
    main()