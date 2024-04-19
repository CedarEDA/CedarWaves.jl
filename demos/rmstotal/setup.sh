#!/bin/bash

virtualenv -p pypy3 pypyenv
pypyenv/bin/pip install numpy

virtualenv -p python3 cpyenv
cpyenv/bin/pip install numpy numba

julia --project build_system_image.jl