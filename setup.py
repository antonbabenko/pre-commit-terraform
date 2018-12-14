from setuptools import find_packages
from setuptools import setup


setup(
    name='pre-commit-terraform',
    description='Pre-commit hooks for terraform_docs_replace',
    url='https://github.com/antonbabenko/pre-commit-terraform',
    version_format='{tag}+{gitsha}',

    author='Contributors',

    classifiers=[
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: Implementation :: CPython',
        'Programming Language :: Python :: Implementation :: PyPy',
    ],

    packages=find_packages(exclude=('tests*', 'testing*')),
    install_requires=[
        'setuptools-git-version',
    ],
    entry_points={
        'console_scripts': [
            'terraform_docs_replace = pre_commit_hooks.terraform_docs_replace:main',
        ],
    },
)
