import math

def rms(xs, ys):
    area = 0.0
    for i in range(1,len(xs)):
        x1 = xs[i-1]
        y1 = ys[i-1]
        x2 = xs[i]
        y2 = ys[i]
        dx = x2 - x1
        dy = y2 - y1
        area += dx*(dy**2/3 + y1*y2)
    return math.sqrt(area/(xs[-1] - xs[0]))


# A triangular wave has an RMS of Peak/sqrt(3)
N = 10**6
dt = 1/N
xs = [dt * i for i in range(N+1)]
ys = xs


# Run benchmark
import time
val = rms(xs, ys)
trials=10
times = []
tbegin = time.time()
min_time = 1e6
for i in range(trials):
    t1 = time.time()
    rms(xs, ys)
    t2 = time.time()
    min_time = min(min_time, t2 - t1)
tdone = time.time()

ns = (tdone - tbegin)/trials/N * 1e9

print("RMS of trangular wave: {val} (ans = {ans})".format(val=rms(xs, ys), ans=1/math.sqrt(3)))

print("Best time of {trials} trials: {min_time}".format(trials=trials, min_time=min_time))

import sys
ver = "{major}.{minor}.{micro}".format(major=sys.version_info[0], minor=sys.version_info[1], micro=sys.version_info[2])
print("Python {ver}     for           rms = {val} : {t:>5} ns per iteration average over {trials:>3} trials of {N} points".format(ver=ver, val=val, t=round(ns,1), trials=trials, N=N))


