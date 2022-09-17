from setuptools import setup
import sys
import os

setup(
    name = 'app',
    version = '0.1.0',
    description = 'Python app package',
    license='MIT',
    author = 'Benjamin',
    packages = ['app'],
    package_data={
        'app': ['description.txt']
    },
    install_requires=[
        'future'
    ],
    scripts = [
        'bin/app',
        'bin/vers'
    ],
    classifiers = [
        'Programming Language :: Python :: 3.9',
        'License :: OSI Approved :: MIT License'
    ],
)
