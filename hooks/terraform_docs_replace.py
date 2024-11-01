"""Deprecated hook to replace README.md with the output of terraform-docs."""
import argparse
import os
import subprocess
import sys

print(
    '`terraform_docs_replace` hook is DEPRECATED.'
    'For migration instructions see ' +
    'https://github.com/antonbabenko/pre-commit-terraform/issues/248#issuecomment-1290829226',
)


def main(argv=None) -> int:
    """
    TODO: Add docstring.

    Args:
        argv (list): List of command-line arguments (default: None)

    Returns:
        int: The return value indicating the success or failure of the function
    """
    parser = argparse.ArgumentParser(
        description="""Run terraform-docs on a set of files. Follows the standard convention of
                       pulling the documentation from main.tf in order to replace the entire
                       README.md file each time.""",
    )
    parser.add_argument(
        '--dest', dest='dest', default='README.md',
    )
    parser.add_argument(
        '--sort-inputs-by-required', dest='sort', action='store_true',
        help='[deprecated] use --sort-by-required instead',
    )
    parser.add_argument(
        '--sort-by-required', dest='sort', action='store_true',
    )
    parser.add_argument(
        '--with-aggregate-type-defaults', dest='aggregate', action='store_true',
        help='[deprecated]',
    )
    parser.add_argument('filenames', nargs='*', help='Filenames to check.')
    args = parser.parse_args(argv)

    dirs = []
    for filename in args.filenames:
        if (
            os.path.realpath(filename) not in dirs and
            (filename.endswith('.tf') or filename.endswith('.tfvars'))
        ):
            dirs.append(os.path.dirname(filename))

    retval = 0

    for directory in dirs:
        try:
            proc_args = []
            proc_args.append('terraform-docs')
            if args.sort:
                proc_args.append('--sort-by-required')
            proc_args.append('md')
            proc_args.append(f'./{directory}')
            proc_args.append('>')
            proc_args.append(f'./{directory}/{args.dest}')
            subprocess.check_call(' '.join(proc_args), shell=True)
        except subprocess.CalledProcessError as exeption:
            print(exeption)
            retval = 1
    return retval


if __name__ == '__main__':
    sys.exit(main())
