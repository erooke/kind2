#!/usr/bin/env -S uv run
from pathlib import Path
from subprocess import run
import argparse

jobname = "certify_slicing"
queue = "all.q"
cores = "1"
benchmark_directory = "/home/erooke/kind2-benchmarks"
command = "/home/erooke/kind2/certify.py"


parser = argparse.ArgumentParser()
parser.add_argument("jobfile", type=Path)
parser.add_argument("result_directory", type=Path)
args = parser.parse_args()

jobfile : Path = args.jobfile
result_directory : Path = args.result_directory

args = parser.parse_args()

num_jobs = str(sum(1 for _ in open(jobfile)))

command = [
    "qsub",
    "-cwd",
    "-N",
    jobname,
    "-q ",
    queue,
    "-pe",
    "smp ",
    cores,
    "-t ",
    f"1-{num_jobs}",
    command,
    jobfile.absolute(),
    benchmark_directory,
    result_directory.absolute(),
]

print("\n  ".join(str(part) for part in command))
run(command)
