#!/usr/bin/env -S uv run

import argparse
import linecache
import os
from pathlib import Path
from subprocess import run

parser = argparse.ArgumentParser()
parser.add_argument("jobfile", type=Path)
parser.add_argument("benchmark_directory", type=Path)
parser.add_argument("result_directory", type=Path)

args = parser.parse_args()

jobfile = args.jobfile
benchmark_directory = args.benchmark_directory
result_directory = args.result_directory


def handle_file(path: Path):
    out_dir = path.with_suffix(".lus.out")

    result_file = result_directory / path.relative_to(benchmark_directory)

    stdout_file = result_file.with_suffix(".o")
    stderr_file = result_file.with_suffix(".e")

    cmd = [
        "/home/erooke/kind2/bin/kind2",
        "--color",
        "false",
        "--slice_nodes",
        "experimental",
        "--certif_slicing",
        "true",
        "--smt_solver",
        "z3--z3_bin",
        "/home/erooke/.local/bin/z3",
        path,
    ]
    # --ind_compress false stops the errors but also slows things down
    result = run(cmd, capture_output=True)

    result_file.parent.mkdir(exist_ok=True, parents=True)

    with stdout_file.open("wb") as f:
        f.write(result.stdout)

    with stderr_file.open("wb") as f:
        f.write(result.stderr)

    if out_dir.is_dir():
        os.rename(out_dir, result_directory / out_dir.relative_to(benchmark_directory))


with open("files", "r") as f:
    files = [Path(line.rstrip()) for line in f]


def main():
    task_id = os.getenv("SGE_TASK_ID")
    assert task_id is not None
    task_id = int(task_id)
    job = Path(linecache.getline(str(jobfile), task_id).strip())
    handle_file(benchmark_directory / job)


if __name__ == "__main__":
    main()
