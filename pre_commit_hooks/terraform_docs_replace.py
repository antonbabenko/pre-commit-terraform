import argparse
import os
import subprocess
import sys


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="""Run terraform-docs on a set of files. Follows the standard convention of
                       pulling the documentation from main.tf in order to replace the entire
                       README.md file each time."""
    )
    parser.add_argument("--dest", dest="dest", default="README.md")
    parser.add_argument("--sort-inputs-by-required", dest="sort", action="store_true")
    parser.add_argument(
        "--with-aggregate-type-defaults", dest="aggregate", action="store_true"
    )
    parser.add_argument("filenames", nargs="*", help="Filenames to check.")
    args = parser.parse_args(argv)

    dirs = []
    for filename in args.filenames:
        if os.path.realpath(filename) not in dirs and (
            filename.endswith(".tf") or filename.endswith(".tfvars")
        ):
            dirs.append(os.path.dirname(filename))

    retval = 0

    for dir_list in dirs:
        try:
            procargs = ["terraform-docs"]
            if args.sort:
                procargs.append("--sort-inputs-by-required")
            if args.aggregate:
                procargs.append("--with-aggregate-type-defaults")
            procargs.append("md")
            procargs.append("./{dir}".format(dir=dir_list))
            procargs.append("| sed -e '$ d' -e 'N;/^\\n$/D;P;D'")
            procargs.append(">")
            procargs.append("./{dir}/{dest}".format(dir=dir_list, dest=args.dest))
            subprocess.check_call(" ".join(procargs), shell=True)
        except subprocess.CalledProcessError as e:
            print(e)
            retval = 1
    return retval


if __name__ == "__main__":
    sys.exit(main())
