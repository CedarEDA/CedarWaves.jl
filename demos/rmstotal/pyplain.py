import sys
from math import cos, pi, sqrt
from time import time

points = 10**int(sys.argv[1])
factor = int(sys.argv[2])
f1 = 5*factor
f2 = 7*factor

t = [p/points for p in range(points)]
y = [cos(2*pi*f1*tm) * cos(2*pi*f2*tm) for tm in t]

def rms_signal_py(xs, ys):
    area = 0.0
    for i in range(1, len(xs)):
        dx = xs[i] - xs[i-1]
        y1 = ys[i-1]
        y2 = ys[i]
        dy = y2 - y1
        area += dx*(dy**2/3 + y1*y2)  # quadratic shape
    return sqrt(area/(xs[-1] - xs[0]))

print("python plain")
ts = time()
rms_signal_py(t, y)
print("first rms time", time()-ts)
ts = time()
for _ in range(10):
    rms_signal_py(t, y)
print("rms time", time()-ts)