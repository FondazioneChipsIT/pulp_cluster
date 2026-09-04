#!/usr/bin/env python3
"""Combine task result CSV files into one CSV file."""

import argparse
import csv
from pathlib import Path


def combine_csv_files(input_root: Path, output: Path, pattern: str) -> int:
    files = sorted(
        path for path in input_root.rglob(pattern) if path.resolve() != output.resolve()
    )
    if not files:
        raise FileNotFoundError(f"No CSV files matching {pattern!r} found under {input_root}")

    headers = []
    for csv_file in files:
        with csv_file.open(newline="", encoding="utf-8") as input_file:
            fieldnames = csv.DictReader(input_file).fieldnames
        if fieldnames is None:
            raise ValueError(f"CSV file has no header: {csv_file}")
        for fieldname in fieldnames:
            if fieldname not in headers:
                headers.append(fieldname)

    output.parent.mkdir(parents=True, exist_ok=True)
    row_count = 0

    with output.open("w", newline="", encoding="utf-8") as output_file:
        output_fields = ["runner", "task", "source_file", *headers]
        writer = csv.DictWriter(output_file, fieldnames=output_fields)
        writer.writeheader()
        for csv_file in files:
            with csv_file.open(newline="", encoding="utf-8") as input_file:
                reader = csv.DictReader(input_file)

                for row in reader:
                    relative_path = csv_file.relative_to(input_root)
                    task = csv_file.stem
                    if task.endswith("_CL_8"):
                        task = task[:-len("_CL_8")]
                    writer.writerow(
                        {
                            "runner": relative_path.parts[0]
                            if relative_path.parts
                            else "",
                            "task": task,
                            "source_file": str(relative_path),
                            **row,
                        }
                    )
                    row_count += 1

    print(f"Combined {len(files)} files ({row_count} rows) into {output}")
    return row_count


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input-root",
        type=Path,
        default=Path("regression_tests/play_bench/PLAY/test/runners/pulp-open/benchmarks"),
        help="Root directory searched recursively for input CSV files.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(
            "regression_tests/play_bench/PLAY/test/runners/pulp-open/benchmarks/all_tasks_CL_8.csv"
        ),
        help="Destination CSV file.",
    )
    parser.add_argument("--pattern", default="*_CL_8.csv", help="Input filename pattern.")
    args = parser.parse_args()
    combine_csv_files(args.input_root, args.output, args.pattern)


if __name__ == "__main__":
    main()